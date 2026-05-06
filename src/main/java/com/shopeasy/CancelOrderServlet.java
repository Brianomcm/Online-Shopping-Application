package com.shopeasy;

import java.io.*;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/CancelOrderServlet")
public class CancelOrderServlet extends HttpServlet {
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
        String orderIdParam = request.getParameter("orderId");
        String reason = request.getParameter("reason");
        String cancelType = request.getParameter("type");

        if (orderIdParam == null) {
            out.print("{\"success\":false,\"message\":\"Missing data\"}");
            return;
        }

        int orderId = Integer.parseInt(orderIdParam);

        try {
            Connection conn = DBConnection.getConnection();

            PreparedStatement checkPs = conn.prepareStatement(
                "SELECT status FROM orders WHERE order_id=? AND customer_id=?");
            checkPs.setInt(1, orderId);
            checkPs.setInt(2, customerId);
            ResultSet checkRs = checkPs.executeQuery();

            if (!checkRs.next()) {
                out.print("{\"success\":false,\"message\":\"Order not found\"}");
                checkRs.close(); checkPs.close(); conn.close();
                return;
            }

            String currentStatus = checkRs.getString("status");
            checkRs.close(); checkPs.close();

            if ("direct".equals(cancelType)) {
                // PENDING → direct cancel
                if (!"Pending".equals(currentStatus)) {
                    out.print("{\"success\":false,\"message\":\"Order can no longer be directly cancelled\"}");
                    conn.close();
                    return;
                }

                // Restore stock
                PreparedStatement stockPs = conn.prepareStatement(
                    "UPDATE product p JOIN order_items oi ON p.product_id = oi.product_id " +
                    "SET p.stock = p.stock + oi.quantity WHERE oi.order_id = ?");
                stockPs.setInt(1, orderId);
                stockPs.executeUpdate();
                stockPs.close();

                // Set Cancelled
                PreparedStatement updatePs = conn.prepareStatement(
                	    "UPDATE orders SET status='Cancelled', cancel_reason=?, cancel_requested_at=NOW() WHERE order_id=?");
                	updatePs.setString(1, reason != null && !reason.trim().isEmpty() ? reason.trim() : "Cancelled by customer");
                updatePs.setInt(2, orderId);
                updatePs.executeUpdate();
                updatePs.close();

                // Notify customer
                PreparedStatement custNotif = conn.prepareStatement(
                    "INSERT INTO notifications (user_id, user_type, message) VALUES (?, 'customer', ?)");
                custNotif.setInt(1, customerId);
                custNotif.setString(2, "Your Order #SE-" + orderId + " has been cancelled successfully.");
                custNotif.executeUpdate();
                custNotif.close();

                // Notify seller
                PreparedStatement sellerIdPs = conn.prepareStatement(
                    "SELECT DISTINCT seller_id FROM order_items WHERE order_id=?");
                sellerIdPs.setInt(1, orderId);
                ResultSet sellerRs = sellerIdPs.executeQuery();
                while (sellerRs.next()) {
                    int sellerId = sellerRs.getInt("seller_id");
                    PreparedStatement sellerNotif = conn.prepareStatement(
                        "INSERT INTO notifications (user_id, user_type, message) VALUES (?, 'seller', ?)");
                    sellerNotif.setInt(1, sellerId);
                    sellerNotif.setString(2, "Order #SE-" + orderId + " was cancelled by the customer.");
                    sellerNotif.executeUpdate();
                    sellerNotif.close();
                }
                sellerRs.close(); sellerIdPs.close();

            } else {
                // PROCESSING → cancel request
                if (reason == null || reason.trim().isEmpty()) {
                    out.print("{\"success\":false,\"message\":\"Missing reason\"}");
                    conn.close();
                    return;
                }
                if (!"Processing".equals(currentStatus)) {
                    out.print("{\"success\":false,\"message\":\"Order can no longer be cancelled\"}");
                    conn.close();
                    return;
                }

                PreparedStatement updatePs = conn.prepareStatement(
                    "UPDATE orders SET status='Cancellation Requested', cancel_reason=?, cancel_requested_at=NOW() WHERE order_id=?");
                updatePs.setString(1, reason.trim());
                updatePs.setInt(2, orderId);
                updatePs.executeUpdate();
                updatePs.close();

                // Notify customer
                PreparedStatement custNotif = conn.prepareStatement(
                    "INSERT INTO notifications (user_id, user_type, message) VALUES (?, 'customer', ?)");
                custNotif.setInt(1, customerId);
                custNotif.setString(2, "Your cancellation request for Order #SE-" + orderId + " has been submitted. Waiting for seller approval.");
                custNotif.executeUpdate();
                custNotif.close();

                // Notify seller
                PreparedStatement sellerIdPs = conn.prepareStatement(
                    "SELECT DISTINCT seller_id FROM order_items WHERE order_id=?");
                sellerIdPs.setInt(1, orderId);
                ResultSet sellerRs = sellerIdPs.executeQuery();
                while (sellerRs.next()) {
                    int sellerId = sellerRs.getInt("seller_id");
                    PreparedStatement sellerNotif = conn.prepareStatement(
                        "INSERT INTO notifications (user_id, user_type, message) VALUES (?, 'seller', ?)");
                    sellerNotif.setInt(1, sellerId);
                    sellerNotif.setString(2, "Customer requested cancellation for Order #SE-" + orderId + ". Reason: " + reason.trim());
                    sellerNotif.executeUpdate();
                    sellerNotif.close();
                }
                sellerRs.close(); sellerIdPs.close();
            }

            conn.close();
            out.print("{\"success\":true}");

        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\":false,\"message\":\"" + e.getMessage() + "\"}");
        }
    }
}