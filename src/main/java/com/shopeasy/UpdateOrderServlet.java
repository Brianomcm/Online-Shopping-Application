package com.shopeasy;

import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/UpdateOrderServlet")
public class UpdateOrderServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int orderId = Integer.parseInt(request.getParameter("orderId"));
        String status = request.getParameter("status");

        try {
            Connection conn = DBConnection.getConnection();
            String reason = request.getParameter("reason");

            PreparedStatement ps;
            if (reason != null && !reason.isEmpty()) {
            	ps = conn.prepareStatement(
            		    "UPDATE orders SET status=?, cancel_reason=? WHERE order_id=?");
                ps.setString(1, status);
                ps.setString(2, reason);
                ps.setInt(3, orderId);
            } else if ("Completed".equals(status)) {
                ps = conn.prepareStatement(
                    "UPDATE orders SET status=?, completed_at=NOW() WHERE order_id=?");
                ps.setString(1, status);
                ps.setInt(2, orderId);
            } else {
                ps = conn.prepareStatement(
                    "UPDATE orders SET status=? WHERE order_id=?");
                ps.setString(1, status);
                ps.setInt(2, orderId);
            }
            ps.executeUpdate();
            ps.close();

            // If cancelling, restore stock + refund wallet if needed
            if ("Cancelled".equals(status)) {
                // Restore stock
                PreparedStatement stockPs = conn.prepareStatement(
                    "UPDATE product p JOIN order_items oi ON p.product_id = oi.product_id " +
                    "SET p.stock = p.stock + oi.quantity WHERE oi.order_id = ?");
                stockPs.setInt(1, orderId);
                stockPs.executeUpdate();
                stockPs.close();

                // Refund wallet if payment was via Wallet
                PreparedStatement paymentPs = conn.prepareStatement(
                    "SELECT payment_method, total_amount, customer_id FROM orders WHERE order_id=?");
                paymentPs.setInt(1, orderId);
                ResultSet paymentRs = paymentPs.executeQuery();
                if (paymentRs.next()) {
                    String payMethod = paymentRs.getString("payment_method");
                    double totalAmt = paymentRs.getDouble("total_amount");
                    int custId = paymentRs.getInt("customer_id");

                    if ("Wallet".equals(payMethod) && totalAmt > 0) {
                    	PreparedStatement walletPs = conn.prepareStatement(
                    		    "UPDATE customer SET wallet_balance = wallet_balance + ? WHERE customer_id=?");
                        walletPs.setDouble(1, totalAmt);
                        walletPs.setInt(2, custId);
                        walletPs.executeUpdate();
                        walletPs.close();

                        PreparedStatement walletTxPs = conn.prepareStatement(
                            "INSERT INTO wallet_transactions (customer_id, amount, type, description) VALUES (?, ?, 'refund', ?)");
                        walletTxPs.setInt(1, custId);
                        walletTxPs.setDouble(2, totalAmt);
                        walletTxPs.setString(3, "Refund for cancelled Order #SE-" + orderId);
                        walletTxPs.executeUpdate();
                        walletTxPs.close();
                    }
                }
                paymentRs.close();
                paymentPs.close();
            }

            // Notify customer
            PreparedStatement custPs = conn.prepareStatement(
                "SELECT o.customer_id, c.user_id FROM orders o JOIN customer c ON c.customer_id = o.customer_id WHERE o.order_id=?");
            custPs.setInt(1, orderId);
            ResultSet custRs = custPs.executeQuery();
            if (custRs.next()) {
                int custUserId = custRs.getInt("user_id");
                String notifMsg = "Cancelled".equals(status)
                    ? "Your order #SE-" + orderId + " has been cancelled by the seller."
                    : "Your order #SE-" + orderId + " status has been updated to: " + status;

                PreparedStatement notifPs = conn.prepareStatement(
                    "INSERT INTO notifications (user_id, user_type, message) VALUES (?, 'customer', ?)");
                notifPs.setInt(1, custUserId);
                notifPs.setString(2, notifMsg);
                notifPs.executeUpdate();
                notifPs.close();
            }
            custRs.close();
            custPs.close();
            conn.close();

        } catch (Exception e) {
            e.printStackTrace();
        }

        response.setContentType("text/plain");
        response.getWriter().print("ok");
    }
}