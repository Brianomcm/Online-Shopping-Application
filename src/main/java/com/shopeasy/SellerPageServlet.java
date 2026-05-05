package com.shopeasy;

import java.io.IOException;
import java.sql.*;
import java.util.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/SellerPageServlet")
public class SellerPageServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String sellerIdParam = request.getParameter("id");
        if (sellerIdParam == null) {
            response.sendRedirect("index.jsp");
            return;
        }

        try {
            int sellerId = Integer.parseInt(sellerIdParam);
            Connection conn = DBConnection.getConnection();

            // Get seller info
            PreparedStatement ps = conn.prepareStatement(
                "SELECT * FROM seller WHERE seller_id = ?");
            ps.setInt(1, sellerId);
            ResultSet rs = ps.executeQuery();

            if (!rs.next()) {
                response.sendRedirect("index.jsp");
                return;
            }

            Map<String, String> seller = new HashMap<>();
            seller.put("seller_id", rs.getString("seller_id"));
            seller.put("name", rs.getString("name"));
            seller.put("business_name", rs.getString("business_name"));
            seller.put("shop_description", rs.getString("shop_description"));
            seller.put("profile_picture", rs.getString("profile_picture"));
            seller.put("banner_picture", rs.getString("banner_picture"));
            seller.put("address", rs.getString("address"));
            rs.close(); ps.close();

            // Get seller products
            PreparedStatement ps2 = conn.prepareStatement(
                "SELECT p.*, c.name as category_name FROM product p " +
                "LEFT JOIN category c ON p.category_id = c.category_id " +
                "WHERE p.seller_id = ? AND p.status = 'active' " +
                "ORDER BY p.product_id DESC");
            ps2.setInt(1, sellerId);
            ResultSet rs2 = ps2.executeQuery();

            List<Map<String, Object>> products = new ArrayList<>();
            while (rs2.next()) {
                Map<String, Object> prod = new HashMap<>();
                prod.put("product_id", rs2.getInt("product_id"));
                prod.put("name", rs2.getString("name"));
                prod.put("price", rs2.getDouble("price"));
                prod.put("stock", rs2.getInt("stock"));
                prod.put("image", rs2.getString("image"));
                prod.put("category_name", rs2.getString("category_name"));
                prod.put("description", rs2.getString("description"));
                products.add(prod);
            }
            rs2.close(); ps2.close();
            conn.close();

            request.setAttribute("seller", seller);
            request.setAttribute("products", products);
            request.getRequestDispatcher("sellerProfile.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("index.jsp");
        }
    }
}