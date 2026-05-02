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
        if (session.getAttribute("userId") == null || !"seller".equals(session.getAttribute("userRole"))) {
            response.sendRedirect("index.jsp");
            return;
        }

        int sellerId = (int) session.getAttribute("userId");
        String productName   = request.getParameter("productName");
        String description   = request.getParameter("description");
        String price         = request.getParameter("price");
        String stock         = request.getParameter("stock");
        String categoryId    = request.getParameter("categoryId");
        String productImage  = request.getParameter("productImage");

        // Variation arrays from form
        String[] variationTypes  = request.getParameterValues("variationType[]");
        String[] variationValues = request.getParameterValues("variationValue[]");

        try {
            Connection conn = DBConnection.getConnection();

            // 1. Insert product and get generated product_id
            String sql = "INSERT INTO product (seller_id, category_id, name, description, price, stock, image, status) "
                       + "VALUES (?, ?, ?, ?, ?, ?, ?, 'active')";
            PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            ps.setInt(1, sellerId);
            ps.setInt(2, categoryId != null && !categoryId.isEmpty() ? Integer.parseInt(categoryId) : 1);
            ps.setString(3, productName);
            ps.setString(4, description);
            ps.setDouble(5, Double.parseDouble(price));
            ps.setInt(6, Integer.parseInt(stock));
            if (productImage != null && !productImage.isEmpty()) {
                ps.setString(7, productImage);
            } else {
                ps.setNull(7, java.sql.Types.VARCHAR);
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
                String varSql = "INSERT INTO product_variation (product_id, variation_type, variation_value) "
                              + "VALUES (?, ?, ?)";
                PreparedStatement varPs = conn.prepareStatement(varSql);
                for (int i = 0; i < variationTypes.length; i++) {
                    String type  = variationTypes[i];
                    String value = (i < variationValues.length) ? variationValues[i] : "";
                    if (type != null && !type.isEmpty() && value != null && !value.trim().isEmpty()) {
                        varPs.setInt(1, newProductId);
                        varPs.setString(2, type.trim());
                        varPs.setString(3, value.trim());
                        varPs.addBatch();
                    }
                }
                varPs.executeBatch();
                varPs.close();
            }

            conn.close();
            response.sendRedirect("SellerProfileServlet?updated=true&msg=product&tab=products");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("SellerProfileServlet?error=true");
        }
    }
}