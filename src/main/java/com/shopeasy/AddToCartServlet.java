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

@WebServlet("/AddToCartServlet")
public class AddToCartServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        Integer userId = (Integer) session.getAttribute("userId");
        String role = (String) session.getAttribute("userRole");

        if (userId == null || !"customer".equals(role)) {
            response.setContentType("application/json");
            response.getWriter().print("{\"success\":false,\"message\":\"Not logged in\"}");
            return;
        }

        String productIdParam  = request.getParameter("productId");
        String variationIdParam = request.getParameter("variationId");

        if (productIdParam == null || productIdParam.trim().isEmpty()) {
            response.setContentType("application/json");
            response.getWriter().print("{\"success\":false,\"message\":\"Invalid product\"}");
            return;
        }

        int productId = Integer.parseInt(productIdParam.trim());
        Integer variationId = null;
        if (variationIdParam != null && !variationIdParam.trim().isEmpty()) {
            variationId = Integer.parseInt(variationIdParam.trim());
        }

        try {
            Connection conn = DBConnection.getConnection();

            // Get or create cart
            int cartId = -1;
            PreparedStatement ps = conn.prepareStatement(
                "SELECT cart_id FROM cart WHERE customer_id=?");
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                cartId = rs.getInt("cart_id");
            } else {
                PreparedStatement ins = conn.prepareStatement(
                    "INSERT INTO cart (customer_id) VALUES (?)",
                    PreparedStatement.RETURN_GENERATED_KEYS);
                ins.setInt(1, userId);
                ins.executeUpdate();
                ResultSet keys = ins.getGeneratedKeys();
                if (keys.next()) cartId = keys.getInt(1);
                ins.close();
            }
            rs.close(); ps.close();

            // Check if same product + same variation already in cart
            String checkSql = variationId != null
                ? "SELECT cartitem_id, quantity FROM cartitem WHERE cart_id=? AND product_id=? AND variation_id=?"
                : "SELECT cartitem_id, quantity FROM cartitem WHERE cart_id=? AND product_id=? AND variation_id IS NULL";

            ps = conn.prepareStatement(checkSql);
            ps.setInt(1, cartId);
            ps.setInt(2, productId);
            if (variationId != null) ps.setInt(3, variationId);
            rs = ps.executeQuery();

            if (rs.next()) {
                // Update quantity
                int newQty = rs.getInt("quantity") + 1;
                int itemId = rs.getInt("cartitem_id");
                ps.close();
                ps = conn.prepareStatement(
                    "UPDATE cartitem SET quantity=? WHERE cartitem_id=?");
                ps.setInt(1, newQty);
                ps.setInt(2, itemId);
                ps.executeUpdate();
            } else {
                // Insert new cart item
                ps.close();
                ps = conn.prepareStatement(
                    "INSERT INTO cartitem (cart_id, product_id, quantity, variation_id) VALUES (?,?,?,?)");
                ps.setInt(1, cartId);
                ps.setInt(2, productId);
                ps.setInt(3, 1);
                if (variationId != null) ps.setInt(4, variationId);
                else ps.setNull(4, java.sql.Types.INTEGER);
                ps.executeUpdate();
            }
            rs.close(); ps.close(); conn.close();

            response.setContentType("application/json");
            response.getWriter().print("{\"success\":true}");

        } catch (Exception e) {
            e.printStackTrace();
            response.setContentType("application/json");
            response.getWriter().print("{\"success\":false,\"message\":\"" + e.getMessage() + "\"}");
        }
    }
}