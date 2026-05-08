package com.shopeasy;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.*;
import java.sql.*;

@WebServlet("/PayoutServlet")
public class PayoutServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("sellerId") == null) {
            out.print("{\"success\":false,\"message\":\"Not logged in\"}");
            return;
        }

        int sellerId = (Integer) session.getAttribute("sellerId");
        String method = request.getParameter("method");
        String account = request.getParameter("account");
        String amountStr = request.getParameter("amount");

        try {
            if (method == null || account == null || amountStr == null) {
                out.print("{\"success\":false,\"message\":\"Missing required fields\"}");
                return;
            }
            double amount = Double.parseDouble(amountStr);
            if (amount < 50) {
                out.print("{\"success\":false,\"message\":\"Minimum withdrawal is ₱50.00\"}");
                return;
            }

            Connection conn = DBConnection.getConnection();

            // Check available balance
            PreparedStatement balPs = conn.prepareStatement(
                "SELECT COALESCE(SUM(oi.subtotal),0) FROM order_items oi " +
                "JOIN orders o ON oi.order_id=o.order_id " +
                "WHERE oi.seller_id=? AND o.status='Completed'");
            balPs.setInt(1, sellerId);
            ResultSet balRs = balPs.executeQuery();
            double balance = balRs.next() ? balRs.getDouble(1) : 0.0;
            balRs.close(); balPs.close();

            if (amount > balance) {
                out.print("{\"success\":false,\"message\":\"Amount exceeds available balance\"}");
                conn.close();
                return;
            }

            // Insert payout request
            PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO payout_requests (seller_id, method, account_number, amount, status) VALUES (?,?,?,?,?)");
            ps.setInt(1, sellerId);
            ps.setString(2, method);
            ps.setString(3, account);
            ps.setDouble(4, amount);
            ps.setString(5, "Completed");
            ps.executeUpdate();
            ps.close();

            // Get user_id from seller
            int userId = 0;
            PreparedStatement uidPs = conn.prepareStatement(
                "SELECT user_id FROM seller WHERE seller_id=?");
            uidPs.setInt(1, sellerId);
            ResultSet uidRs = uidPs.executeQuery();
            if (uidRs.next()) userId = uidRs.getInt(1);
            uidRs.close(); uidPs.close();

            // Insert notification
            if (userId > 0) {
                PreparedStatement notifPs = conn.prepareStatement(
                    "INSERT INTO notifications (user_id, user_type, message, is_read) VALUES (?,?,?,0)");
                notifPs.setInt(1, userId);
                notifPs.setString(2, "seller");
                notifPs.setString(3, String.format(
                    "✅ Payout of ₱%.2f via %s has been processed successfully!", amount, method));
                notifPs.executeUpdate();
                notifPs.close();
            }
            conn.close();

            out.print("{\"success\":true}");
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\":false,\"message\":\"Server error\"}");
        }
    }
}