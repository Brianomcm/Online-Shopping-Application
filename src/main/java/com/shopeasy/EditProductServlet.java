package com.shopeasy;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/EditProductServlet")
public class EditProductServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        String editRole = (String) session.getAttribute("userRole");
        if (session.getAttribute("userId") == null || (!"seller".equals(editRole) && !"both".equals(editRole))) {
            response.sendRedirect("index.jsp");
            return;
        }
        String productId    = request.getParameter("productId");
        String productName  = request.getParameter("productName");
        String price        = request.getParameter("price");
        String stock        = request.getParameter("stock");
        String description  = request.getParameter("description");
        String originalPrice = request.getParameter("originalPrice");
        String categoryId = request.getParameter("categoryId");

        // Variation arrays
        String[] varIds            = request.getParameterValues("editVarId[]");
        String[] varTypes          = request.getParameterValues("editVarType[]");
        String[] varValues         = request.getParameterValues("editVarValue[]");
        String[] varPrices         = request.getParameterValues("editVarPrice[]");
        String[] varOriginalPrices = request.getParameterValues("editVarOriginalPrice[]");
        String[] varStocks         = request.getParameterValues("editVarStock[]");
        String[] varImages     = request.getParameterValues("editVarImage[]");
        String[] varKeepImages = request.getParameterValues("editVarKeepImage[]");
        String thumbnail           = request.getParameter("thumbnail");
        String galleryImage        = request.getParameter("productImage");

        try {
            Connection conn = DBConnection.getConnection();

            // 1. Update product basic info
         // Build UPDATE query — only update thumbnail if provided
            String updateSql;
            boolean hasThumb = thumbnail != null && !thumbnail.isEmpty();
            boolean hasImage = galleryImage != null && !galleryImage.isEmpty();
            if (hasThumb && hasImage) {
                updateSql = "UPDATE product SET name=?, price=?, original_price=?, stock=?, description=?, category_id=?, thumbnail=?, image=? WHERE product_id=?";
            } else if (hasThumb) {
                updateSql = "UPDATE product SET name=?, price=?, original_price=?, stock=?, description=?, category_id=?, thumbnail=? WHERE product_id=?";
            } else if (hasImage) {
                updateSql = "UPDATE product SET name=?, price=?, original_price=?, stock=?, description=?, category_id=?, image=? WHERE product_id=?";
            } else {
                updateSql = "UPDATE product SET name=?, price=?, original_price=?, stock=?, description=?, category_id=? WHERE product_id=?";
            }
            PreparedStatement ps = conn.prepareStatement(updateSql);
            ps.setString(1, productName);
            ps.setDouble(2, (price != null && !price.isEmpty()) ? Double.parseDouble(price) : 0.0);
            if (originalPrice != null && !originalPrice.isEmpty()) {
                ps.setDouble(3, Double.parseDouble(originalPrice));
            } else {
                ps.setNull(3, java.sql.Types.DECIMAL);
            }
            ps.setInt(4, (stock != null && !stock.isEmpty()) ? Integer.parseInt(stock) : 0);
            ps.setString(5, description);
            if (categoryId != null && !categoryId.isEmpty()) {
                ps.setInt(6, Integer.parseInt(categoryId));
            } else {
                ps.setNull(6, java.sql.Types.INTEGER);
            }
            if (hasThumb && hasImage) {
                ps.setString(7, thumbnail);
                ps.setString(8, galleryImage);
                ps.setInt(9, Integer.parseInt(productId));
            } else if (hasThumb) {
                ps.setString(7, thumbnail);
                ps.setInt(8, Integer.parseInt(productId));
            } else if (hasImage) {
                ps.setString(7, galleryImage);
                ps.setInt(8, Integer.parseInt(productId));
            } else {
                ps.setInt(7, Integer.parseInt(productId));
            }
            ps.executeUpdate();
            ps.close();

         // 2. Pre-fetch existing variation images BEFORE deleting
            java.util.Map<String, String> existingVarImages = new java.util.HashMap<>();
            if (varIds != null) {
                for (String vid : varIds) {
                    if (vid != null && !vid.isEmpty()) {
                        PreparedStatement fetchImgPs = conn.prepareStatement(
                            "SELECT image FROM product_variation WHERE variation_id=?");
                        fetchImgPs.setInt(1, Integer.parseInt(vid));
                        ResultSet fetchImgRs = fetchImgPs.executeQuery();
                        if (fetchImgRs.next()) existingVarImages.put(vid, fetchImgRs.getString("image"));
                        fetchImgRs.close(); fetchImgPs.close();
                    }
                }
            }

         // 3. Update existing variations, insert new ones
            if (varTypes != null && varValues != null) {
                PreparedStatement varPs = conn.prepareStatement(
                    "INSERT INTO product_variation (product_id, variation_type, variation_value, price, original_price, stock, image) VALUES (?,?,?,?,?,?,?) " +
                    "ON DUPLICATE KEY UPDATE variation_type=VALUES(variation_type), variation_value=VALUES(variation_value), price=VALUES(price), original_price=VALUES(original_price), stock=VALUES(stock), image=VALUES(image)");
            	for (int i = 0; i < varTypes.length; i++) {
                        String t = varTypes[i];
                        String v = (i < varValues.length) ? varValues[i] : "";
                        if (t != null && !t.trim().isEmpty() && v != null && !v.trim().isEmpty()) {
                            varPs.setInt(1, Integer.parseInt(productId));
                            varPs.setString(2, t.trim());
                            varPs.setString(3, v.trim());
                            String vp  = (varPrices != null && i < varPrices.length && varPrices[i] != null && !varPrices[i].isEmpty()) ? varPrices[i] : null;
                            String vop = (varOriginalPrices != null && i < varOriginalPrices.length && varOriginalPrices[i] != null && !varOriginalPrices[i].isEmpty()) ? varOriginalPrices[i] : null;
                            String vs  = (varStocks != null && i < varStocks.length && varStocks[i] != null && !varStocks[i].isEmpty()) ? varStocks[i] : null;
                            String vi = null;
                            if (varImages != null && i < varImages.length && varImages[i] != null && !varImages[i].isEmpty()) {
                                vi = varImages[i]; // new image uploaded
                            } else {
                                // Use pre-fetched existing image
                                String origVarId = (varIds != null && i < varIds.length) ? varIds[i] : null;
                                if (origVarId != null && !origVarId.isEmpty()) {
                                    vi = existingVarImages.get(origVarId);
                                }
                            }
                            if (vp != null) varPs.setDouble(4, Double.parseDouble(vp));
                            else varPs.setNull(4, java.sql.Types.DECIMAL);
                            if (vop != null) varPs.setDouble(5, Double.parseDouble(vop));
                            else varPs.setNull(5, java.sql.Types.DECIMAL);
                            if (vs != null) varPs.setInt(6, Integer.parseInt(vs));
                            else varPs.setNull(6, java.sql.Types.INTEGER);
                            if (vi != null) varPs.setString(7, vi);
                            else varPs.setNull(7, java.sql.Types.VARCHAR);
                            varPs.addBatch();
                        }
                    }
            	varPs.executeBatch();
                varPs.close();

                // Update cart items to point to new variation_id
                PreparedStatement cartFixPs = conn.prepareStatement(
                    "UPDATE cartitem ci " +
                    "JOIN product_variation pv ON pv.product_id = ? " +
                    "  AND pv.variation_type = (SELECT pv2.variation_type FROM product_variation pv2 WHERE pv2.variation_id = ci.variation_id) " +
                    "  AND pv.variation_value = (SELECT pv3.variation_value FROM product_variation pv3 WHERE pv3.variation_id = ci.variation_id) " +
                    "SET ci.variation_id = pv.variation_id " +
                    "WHERE ci.variation_id IN (SELECT variation_id FROM product_variation WHERE product_id = ?)");
                cartFixPs.setInt(1, Integer.parseInt(productId));
                cartFixPs.setInt(2, Integer.parseInt(productId));
                cartFixPs.executeUpdate();
                cartFixPs.close();

        // 4. If variation product, update main product price+stock from variants
        PreparedStatement syncPs = conn.prepareStatement(
            "UPDATE product SET " +
            "price = (SELECT MIN(COALESCE(pv.original_price, pv.price)) FROM product_variation pv WHERE pv.product_id = ?), " +
            "stock = (SELECT SUM(pv.stock) FROM product_variation pv WHERE pv.product_id = ?) " +
            "WHERE product_id = ?");
        syncPs.setInt(1, Integer.parseInt(productId));
        syncPs.setInt(2, Integer.parseInt(productId));
        syncPs.setInt(3, Integer.parseInt(productId));
        syncPs.executeUpdate();
        syncPs.close();
        }

         // Save new gallery images if uploaded
            String editGalleryJson = request.getParameter("galleryImages");
            if (editGalleryJson != null && !editGalleryJson.isEmpty()) {
                try {
                    // Delete existing gallery images for this product first
                    PreparedStatement delGalPs = conn.prepareStatement(
                        "DELETE FROM product_gallery WHERE product_id = ?");
                    delGalPs.setInt(1, Integer.parseInt(productId));
                    delGalPs.executeUpdate();
                    delGalPs.close();

                    String[] imgArr = editGalleryJson.trim().replaceAll("^\\[|\\]$", "").split(",(?=\"data:)");
                    PreparedStatement galPs = conn.prepareStatement(
                        "INSERT INTO product_gallery (product_id, image, sort_order) VALUES (?, ?, ?)");
                    for (int g = 0; g < imgArr.length; g++) {
                        String imgData = imgArr[g].trim().replaceAll("^\"|\"$", "");
                        if (imgData != null && !imgData.isEmpty()) {
                            galPs.setInt(1, Integer.parseInt(productId));
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
            response.sendRedirect("seller.jsp?error=true");
        }
    }
}