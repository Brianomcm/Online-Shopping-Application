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
            seller.put("shop_logo", rs.getString("shop_logo"));
            seller.put("banner_picture", rs.getString("banner_picture"));
            seller.put("address", rs.getString("address"));
            seller.put("user_id", rs.getString("user_id"));
            rs.close(); ps.close();
            
         // Get store average rating
            PreparedStatement ratingPs = conn.prepareStatement(
                "SELECT COALESCE(AVG(r.rating), 0) AS store_avg, COUNT(r.review_id) AS store_reviews " +
                "FROM review r JOIN product p ON r.product_id = p.product_id " +
                "WHERE p.seller_id = ?");
            ratingPs.setInt(1, sellerId);
            ResultSet ratingRs = ratingPs.executeQuery();
            if (ratingRs.next()) {
                seller.put("storeAvgRating", String.valueOf(ratingRs.getDouble("store_avg")));
                seller.put("storeReviewCount", String.valueOf(ratingRs.getInt("store_reviews")));
            }
            ratingRs.close(); ratingPs.close();

            // Get seller products
            PreparedStatement ps2 = conn.prepareStatement(
            	    "SELECT p.*, c.name as category_name, " +
            	    "COALESCE((SELECT AVG(r.rating) FROM review r WHERE r.product_id = p.product_id), 0) AS avg_rating, " +
            	    "COALESCE((SELECT COUNT(*) FROM review r WHERE r.product_id = p.product_id), 0) AS review_count, " +
            	    "COALESCE((SELECT SUM(oi.quantity) FROM order_items oi JOIN orders o ON oi.order_id = o.order_id WHERE oi.product_id = p.product_id AND o.status='Completed'), 0) AS total_sold " +
            	    "FROM product p LEFT JOIN category c ON p.category_id = c.category_id " +
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
                prod.put("category_name", rs2.getString("category_name"));
                prod.put("description", rs2.getString("description"));
                prod.put("avgRating", rs2.getDouble("avg_rating"));
                prod.put("reviewCount", rs2.getInt("review_count"));
                prod.put("totalSold", rs2.getInt("total_sold"));
                prod.put("originalPrice", rs2.getDouble("original_price"));
                // thumbnail > image > cheapest variation image
                String pImg = rs2.getString("thumbnail");
                if (pImg == null || pImg.isEmpty()) pImg = rs2.getString("image");
                if (pImg == null || pImg.isEmpty()) {
                    try {
                        PreparedStatement varImgPs = conn.prepareStatement(
                            "SELECT image FROM product_variation WHERE product_id=? AND image IS NOT NULL ORDER BY price ASC LIMIT 1");
                        varImgPs.setInt(1, rs2.getInt("product_id"));
                        ResultSet varImgRs = varImgPs.executeQuery();
                        if (varImgRs.next()) pImg = varImgRs.getString("image");
                        varImgRs.close(); varImgPs.close();
                    } catch (Exception ignored) {}
                }
                prod.put("image", pImg);
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