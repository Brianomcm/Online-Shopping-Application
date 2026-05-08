package com.shopeasy;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import java.util.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/BuyNowServlet")
public class BuyNowServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession();
        if (session.getAttribute("userId") == null) {
            out.print("{\"success\":false,\"message\":\"Not logged in\"}");
            return;
        }

        Integer customerId = (Integer) session.getAttribute("customerId");
        if (customerId == null) customerId = (int) session.getAttribute("userId");
        String productIdParam = request.getParameter("productId");
        String variationIdParam = request.getParameter("variationId");
        String quantityParam = request.getParameter("quantity");

        if (productIdParam == null) {
            out.print("{\"success\":false,\"message\":\"No product specified\"}");
            return;
        }

        int productId = Integer.parseInt(productIdParam);
        int quantity = (quantityParam != null && !quantityParam.isEmpty()) ? Integer.parseInt(quantityParam) : 1;
        Integer variationId = (variationIdParam != null && !variationIdParam.isEmpty()) ? Integer.parseInt(variationIdParam) : null;

        try {
            Connection conn = DBConnection.getConnection();

            // Get product info
            PreparedStatement ps = conn.prepareStatement(
                "SELECT p.*, s.seller_id FROM product p " +
                "JOIN seller s ON p.seller_id = s.seller_id " +
                "WHERE p.product_id = ? AND p.status = 'active'");
            ps.setInt(1, productId);
            ResultSet rs = ps.executeQuery();

            if (!rs.next()) {
                out.print("{\"success\":false,\"message\":\"Product not found\"}");
                return;
            }

            double price = rs.getDouble("price");
            double originalPrice = rs.getDouble("original_price");
            double usePrice = (originalPrice > 0 && originalPrice < price) ? originalPrice : price;
            int stock = rs.getInt("stock");
            String name = rs.getString("name");
            String image = rs.getString("image");
            int sellerId = rs.getInt("seller_id");
            rs.close(); ps.close();

            if (quantity > stock) {
                out.print("{\"success\":false,\"message\":\"Not enough stock\"}");
                conn.close();
                return;
            }

            // Build buyNow item directly in session — NO cart involved
            List<Map<String, Object>> items = new ArrayList<>();
            Map<String, Object> item = new HashMap<>();
            item.put("productId", productId);
            item.put("sellerId", sellerId);
            item.put("name", name);
            item.put("price", price);
            item.put("originalPrice", originalPrice);
            item.put("quantity", quantity);
            item.put("stock", stock);
            item.put("image", image);
            item.put("subtotal", usePrice * quantity);
            item.put("isBuyNow", true);
            if (variationId != null) item.put("variationId", variationId);
            items.add(item);

            conn.close();

            // Store in session as buyNow — separate from cart
            session.setAttribute("buyNowItems", items);
            session.setAttribute("buyNowTotal", usePrice * quantity);

            out.print("{\"success\":true}");

        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\":false,\"message\":\"" + e.getMessage() + "\"}");
        }
    }
}