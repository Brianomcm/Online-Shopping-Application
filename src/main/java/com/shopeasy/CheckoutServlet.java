package com.shopeasy;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.List;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/CheckoutServlet")
public class CheckoutServlet extends HttpServlet {

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

        int customerId = (int) session.getAttribute("userId");
        String shipName = request.getParameter("shipName");
        String shipAddress = request.getParameter("shipAddress");
        String shipPhone = request.getParameter("shipPhone");
        String paymentMethod = request.getParameter("paymentMethod");

        List<Map<String, Object>> cartItems =
            (List<Map<String, Object>>) session.getAttribute("checkoutItems");
        Double cartTotal = (Double) session.getAttribute("checkoutTotal");

        if (cartItems == null || cartItems.isEmpty()) {
            out.print("{\"success\":false,\"message\":\"Cart is empty\"}");
            return;
        }

        try {
            Connection conn = DBConnection.getConnection();

            // Insert into orders table
            String fullAddress = shipName + " | " + shipPhone + " | " + shipAddress;
            String orderSql = "INSERT INTO orders (customer_id, total_amount, status, payment_method, shipping_address) VALUES (?, ?, 'Pending', ?, ?)";
            PreparedStatement orderPs = conn.prepareStatement(orderSql, PreparedStatement.RETURN_GENERATED_KEYS);
            orderPs.setInt(1, customerId);
            orderPs.setDouble(2, cartTotal);
            orderPs.setString(3, paymentMethod);
            orderPs.setString(4, fullAddress);
            orderPs.executeUpdate();

            ResultSet generatedKeys = orderPs.getGeneratedKeys();
            int orderId = 0;
            if (generatedKeys.next()) {
                orderId = generatedKeys.getInt(1);
            }
            orderPs.close();

            // Insert order items
            String itemSql = "INSERT INTO order_items (order_id, product_id, seller_id, quantity, price, subtotal) VALUES (?, ?, ?, ?, ?, ?)";
            PreparedStatement itemPs = conn.prepareStatement(itemSql);

            for (Map<String, Object> item : cartItems) {
                itemPs.setInt(1, orderId);
                itemPs.setInt(2, (Integer) item.get("productId"));
                itemPs.setInt(3, (Integer) item.get("sellerId"));
                itemPs.setInt(4, (Integer) item.get("quantity"));
                itemPs.setDouble(5, (Double) item.get("price"));
                itemPs.setDouble(6, (Double) item.get("subtotal"));
                itemPs.addBatch();

                // Reduce stock
                String stockSql = "UPDATE product SET stock = stock - ? WHERE product_id = ?";
                PreparedStatement stockPs = conn.prepareStatement(stockSql);
                stockPs.setInt(1, (Integer) item.get("quantity"));
                stockPs.setInt(2, (Integer) item.get("productId"));
                stockPs.executeUpdate();
                stockPs.close();
            }
            itemPs.executeBatch();
            itemPs.close();

            // Clear cart from database
            String clearSql = "DELETE FROM cartitem WHERE cart_id IN (SELECT cart_id FROM cart WHERE customer_id = ?)";
            PreparedStatement clearPs = conn.prepareStatement(clearSql);
            clearPs.setInt(1, customerId);
            clearPs.executeUpdate();
            clearPs.close();

            conn.close();

            // Clear session cart
            session.removeAttribute("checkoutItems");
            session.removeAttribute("checkoutTotal");
            session.setAttribute("cartCount", 0);

            out.print("{\"success\":true,\"orderId\":" + orderId + "}");

        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\":false,\"message\":\"" + e.getMessage() + "\"}");
        }
    }
}