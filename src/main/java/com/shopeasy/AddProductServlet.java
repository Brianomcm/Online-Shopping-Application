package com.shopeasy;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/AddProductServlet")
public class AddProductServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        String role = (String) session.getAttribute("userRole");
        if (session.getAttribute("userId") == null || (!"seller".equals(role) && !"both".equals(role))) {
            response.sendRedirect("index.jsp");
            return;
        }

        int userId = (int) session.getAttribute("userId");
        String productName   = request.getParameter("productName");
        String description   = request.getParameter("description");
        String price         = request.getParameter("price");
        String stock         = request.getParameter("stock");
        String categoryId    = request.getParameter("categoryId");
        String productImage    = request.getParameter("productImage");
        String originalPrice   = request.getParameter("originalPrice");
        String productThumbnail = request.getParameter("productThumbnail");

        // Variation arrays from form
        String[] variationTypes  = request.getParameterValues("variationType[]");
        String[] variationValues = request.getParameterValues("variationValue[]");
        String[] variationPrices         = request.getParameterValues("variationPrice[]");
        String[] variationOriginalPrices  = request.getParameterValues("variationOriginalPrice[]");
        String[] variationStocks          = request.getParameterValues("variationStock[]");
        String[] variationImages          = request.getParameterValues("variationImage[]");

        try {
            Connection conn = DBConnection.getConnection();

            // 0. Get seller_id from seller table using user_id
            int sellerId = -1;
            PreparedStatement sellerPs = conn.prepareStatement("SELECT seller_id FROM seller WHERE user_id = ?");
            sellerPs.setInt(1, userId);
            ResultSet sellerRs = sellerPs.executeQuery();
            if (sellerRs.next()) {
                sellerId = sellerRs.getInt("seller_id");
            }
            sellerRs.close();
            sellerPs.close();

            if (sellerId == -1) {
                response.sendRedirect("SellerProfileServlet?error=true");
                return;
            }

            // 1. Insert product and get generated product_id
            String sql = "INSERT INTO product (seller_id, category_id, name, description, price, original_price, stock, image, thumbnail, status) "
                    + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')";
            PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setInt(1, sellerId);
            ps.setInt(2, categoryId != null && !categoryId.isEmpty() ? Integer.parseInt(categoryId) : 1);
            ps.setString(3, productName);
            ps.setString(4, description);
            ps.setDouble(5, (price != null && !price.isEmpty()) ? Double.parseDouble(price) : 0.0);
            if (originalPrice != null && !originalPrice.isEmpty()) {
                ps.setDouble(6, Double.parseDouble(originalPrice));
            } else {
                ps.setNull(6, java.sql.Types.DECIMAL);
            }
            ps.setInt(7, (stock != null && !stock.isEmpty()) ? Integer.parseInt(stock) : 0);
            if (productImage != null && !productImage.isEmpty()) {
                ps.setString(8, productImage);
            } else {
                ps.setNull(8, java.sql.Types.VARCHAR);
            }
         // If no thumbnail, auto-use gallery image as thumbnail
            String thumbToSave = (productThumbnail != null && !productThumbnail.isEmpty()) 
                ? productThumbnail 
                : (productImage != null && !productImage.isEmpty() ? productImage : null);
            if (thumbToSave != null) {
                ps.setString(9, thumbToSave);
            } else {
                ps.setNull(9, java.sql.Types.VARCHAR);
            }
            ps.executeUpdate();

            // 2. Get the new product_id
            int newProductId = -1;
            ResultSet generatedKeys = ps.getGeneratedKeys();
            if (generatedKeys.next()) {
                newProductId = generatedKeys.getInt(1);
            }
            generatedKeys.close();
            ps.close();

            // 3. Insert variations if any
            if (newProductId > 0 && variationTypes != null && variationValues != null) {
            	String varSql = "INSERT INTO product_variation (product_id, variation_type, variation_value, price, original_price, stock, image) "
                        + "VALUES (?, ?, ?, ?, ?, ?, ?)";
                PreparedStatement varPs = conn.prepareStatement(varSql);
                for (int i = 0; i < variationTypes.length; i++) {
                    String type  = variationTypes[i];
                    String value = (i < variationValues.length) ? variationValues[i] : "";
                    if (type != null && !type.isEmpty() && value != null && !value.trim().isEmpty()) {
                        varPs.setInt(1, newProductId);
                        varPs.setString(2, type.trim());
                        varPs.setString(3, value.trim());
                        String vPrice = (variationPrices != null && i < variationPrices.length && variationPrices[i] != null && !variationPrices[i].isEmpty()) ? variationPrices[i] : null;
                        String vStock = (variationStocks != null && i < variationStocks.length && variationStocks[i] != null && !variationStocks[i].isEmpty()) ? variationStocks[i] : null;
                        String vImage = (variationImages != null && i < variationImages.length && variationImages[i] != null && !variationImages[i].isEmpty()) ? variationImages[i] : null;
                        String vOrigPrice = (variationOriginalPrices != null && i < variationOriginalPrices.length && variationOriginalPrices[i] != null && !variationOriginalPrices[i].isEmpty()) ? variationOriginalPrices[i] : null;
                        if (vPrice != null) varPs.setDouble(4, Double.parseDouble(vPrice));
                        else varPs.setNull(4, java.sql.Types.DECIMAL);
                        if (vOrigPrice != null) varPs.setDouble(5, Double.parseDouble(vOrigPrice));
                        else varPs.setNull(5, java.sql.Types.DECIMAL);
                        if (vStock != null) varPs.setInt(6, Integer.parseInt(vStock));
                        else varPs.setNull(6, java.sql.Types.INTEGER);
                        if (vImage != null) varPs.setString(7, vImage);
                        else varPs.setNull(7, java.sql.Types.VARCHAR);
                        varPs.addBatch();
                    }
                }
                varPs.executeBatch();
                varPs.close();

            // Sync main product price+stock from variants
            PreparedStatement syncPs = conn.prepareStatement(
                "UPDATE product SET " +
                "price = (SELECT MIN(COALESCE(pv.original_price, pv.price)) FROM product_variation pv WHERE pv.product_id = ?), " +
                "stock = (SELECT SUM(pv.stock) FROM product_variation pv WHERE pv.product_id = ?) " +
                "WHERE product_id = ?");
            syncPs.setInt(1, newProductId);
            syncPs.setInt(2, newProductId);
            syncPs.setInt(3, newProductId);
            syncPs.executeUpdate();
            syncPs.close();
            }

         // 4. Save gallery images to product_gallery table
            String galleryImagesJson = request.getParameter("galleryImages");
            if (galleryImagesJson != null && !galleryImagesJson.isEmpty() && newProductId > 0) {
                try {
                    // Simple JSON array parse (split by commas inside brackets)
                    galleryImagesJson = galleryImagesJson.trim();
                    if (galleryImagesJson.startsWith("[")) galleryImagesJson = galleryImagesJson.substring(1);
                    if (galleryImagesJson.endsWith("]")) galleryImagesJson = galleryImagesJson.substring(0, galleryImagesJson.length()-1);
                    // Use org.json or manual split — manual approach for base64
                    String[] imgArr = galleryImagesJson.trim().replaceAll("^\\[|\\]$", "").split(",(?=\"data:)");
                    PreparedStatement galPs = conn.prepareStatement(
                        "INSERT INTO product_gallery (product_id, image, sort_order) VALUES (?, ?, ?)");
                    for (int g = 0; g < imgArr.length; g++) {
                        String imgData = imgArr[g].trim().replaceAll("^\"|\"$", "");
                        if (imgData != null && !imgData.isEmpty()) {
                            galPs.setInt(1, newProductId);
                            galPs.setString(2, imgData);
                            galPs.setInt(3, g);
                            galPs.addBatch();
                        }
                    }
                    galPs.executeBatch();
                    galPs.close();
                } catch (Exception ge) { ge.printStackTrace(); }
            }

            conn.close();
            response.sendRedirect("seller.jsp?updated=true&msg=product&tab=products");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("SellerProfileServlet?error=true");
        }
    }
}