package com.shopeasy;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.*;
import java.sql.*;

@WebServlet("/RefundServlet")
public class RefundServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            out.print("{\"success\":false,\"message\":\"Not logged in\"}");
            return;
        }

        String action = request.getParameter("action");

        try {
            Connection conn = DBConnection.getConnection();

            // BUYER: Submit refund request
            if ("submit".equals(action)) {
                int orderId = Integer.parseInt(request.getParameter("orderId"));
                String reason = request.getParameter("reason");
                String description = request.getParameter("description");
                String proofImage = request.getParameter("proofImage");

                // Get customer_id
                int userId = (Integer) session.getAttribute("userId");
                PreparedStatement cidPs = conn.prepareStatement(
                    "SELECT customer_id FROM customer WHERE user_id=?");
                cidPs.setInt(1, userId);
                ResultSet cidRs = cidPs.executeQuery();
                int customerId = cidRs.next() ? cidRs.getInt(1) : 0;
                cidRs.close(); cidPs.close();

                // Get seller_id from order
                PreparedStatement sidPs = conn.prepareStatement(
                    "SELECT DISTINCT seller_id FROM order_items WHERE order_id=? LIMIT 1");
                sidPs.setInt(1, orderId);
                ResultSet sidRs = sidPs.executeQuery();
                int sellerId = sidRs.next() ? sidRs.getInt(1) : 0;
                sidRs.close(); sidPs.close();

                // Check if refund already exists
                PreparedStatement chkPs = conn.prepareStatement(
                    "SELECT COUNT(*) FROM refund_requests WHERE order_id=? AND customer_id=?");
                chkPs.setInt(1, orderId); chkPs.setInt(2, customerId);
                ResultSet chkRs = chkPs.executeQuery();
                if (chkRs.next() && chkRs.getInt(1) > 0) {
                    out.print("{\"success\":false,\"message\":\"Refund already submitted\"}");
                    conn.close(); return;
                }
                chkRs.close(); chkPs.close();

                // Check 7-day eligibility
                PreparedStatement datePs = conn.prepareStatement(
                    "SELECT DATEDIFF(NOW(), order_date) FROM orders WHERE order_id=?");
                datePs.setInt(1, orderId);
                ResultSet dateRs = datePs.executeQuery();
                int daysSince = dateRs.next() ? dateRs.getInt(1) : 999;
                dateRs.close(); datePs.close();
                if (daysSince > 7) {
                    out.print("{\"success\":false,\"message\":\"Refund period has expired (7 days)\"}");
                    conn.close(); return;
                }

                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO refund_requests (order_id, customer_id, seller_id, reason, description, proof_image) VALUES (?,?,?,?,?,?)");
                ps.setInt(1, orderId); ps.setInt(2, customerId); ps.setInt(3, sellerId);
                ps.setString(4, reason); ps.setString(5, description);
                ps.setString(6, (proofImage != null && !proofImage.isEmpty()) ? proofImage : null);
                ps.executeUpdate(); ps.close();

                // Notify seller
                PreparedStatement selUserPs = conn.prepareStatement(
                    "SELECT user_id FROM seller WHERE seller_id=?");
                selUserPs.setInt(1, sellerId);
                ResultSet selUserRs = selUserPs.executeQuery();
                if (selUserRs.next()) {
                    PreparedStatement notifPs = conn.prepareStatement(
                        "INSERT INTO notifications (user_id, user_type, message, is_read) VALUES (?,?,?,0)");
                    notifPs.setInt(1, selUserRs.getInt(1));
                    notifPs.setString(2, "seller");
                    notifPs.setString(3, "🔁 A customer submitted a refund request for Order #SE-" + orderId + ". Reason: " + reason);
                    notifPs.executeUpdate(); notifPs.close();
                }
                selUserRs.close(); selUserPs.close();
                conn.close();
                out.print("{\"success\":true}");

            // SELLER: Approve or Reject
            } else if ("approve".equals(action) || "reject".equals(action)) {
                int refundId = Integer.parseInt(request.getParameter("refundId"));
                String newStatus = "approve".equals(action) ? "Refunded" : "Rejected";

                PreparedStatement ps = conn.prepareStatement(
                        "UPDATE refund_requests SET status=?, reviewed_at=NOW() WHERE refund_id=?");
                    ps.setString(1, newStatus); ps.setInt(2, refundId);
                    ps.executeUpdate(); ps.close();

                    // If approved — credit wallet + log transaction
                    if ("Refunded".equals(newStatus)) {
                        PreparedStatement amtPs = conn.prepareStatement(
                            "SELECT rr.order_id, o.total_amount, rr.customer_id " +
                            "FROM refund_requests rr JOIN orders o ON rr.order_id=o.order_id " +
                            "WHERE rr.refund_id=?");
                        amtPs.setInt(1, refundId);
                        ResultSet amtRs = amtPs.executeQuery();
                        if (amtRs.next()) {
                            int custId = amtRs.getInt("customer_id");
                            double refundAmt = amtRs.getDouble("total_amount");
                            int ordId = amtRs.getInt("order_id");
                            // Add to wallet
                            PreparedStatement walletPs = conn.prepareStatement(
                                "UPDATE customer SET wallet_balance = wallet_balance + ? WHERE customer_id=?");
                            walletPs.setDouble(1, refundAmt);
                            walletPs.setInt(2, custId);
                            walletPs.executeUpdate(); walletPs.close();
                            // Log transaction
                            PreparedStatement logPs = conn.prepareStatement(
                                "INSERT INTO wallet_transactions (customer_id, amount, type, description, reference_id) VALUES (?,?,'refund',?,?)");
                            logPs.setInt(1, custId);
                            logPs.setDouble(2, refundAmt);
                            logPs.setString(3, "Refund for Order #SE-" + ordId);
                            logPs.setInt(4, ordId);
                            logPs.executeUpdate(); logPs.close();
                        }
                        amtRs.close(); amtPs.close();
                    }

              

                    // Get order_id and customer user_id for notification
                    PreparedStatement infoPs = conn.prepareStatement(
                        "SELECT rr.order_id, c.user_id FROM refund_requests rr " +
                        "JOIN customer c ON rr.customer_id=c.customer_id WHERE rr.refund_id=?");
                infoPs.setInt(1, refundId);
                ResultSet infoRs = infoPs.executeQuery();
                if (infoRs.next()) {
                    int ordId = infoRs.getInt("order_id");
                    int custUserId = infoRs.getInt("user_id");
                    String msg = "approve".equals(action)
                        ? "💸 Your refund request for Order #SE-" + ordId + " has been approved!"
                        : "❌ Your refund request for Order #SE-" + ordId + " was rejected by the seller.";
                    PreparedStatement notifPs = conn.prepareStatement(
                        "INSERT INTO notifications (user_id, user_type, message, is_read) VALUES (?,?,?,0)");
                    notifPs.setInt(1, custUserId);
                    notifPs.setString(2, "customer");
                    notifPs.setString(3, msg);
                    notifPs.executeUpdate(); notifPs.close();
                }
                infoRs.close(); infoPs.close();
                conn.close();
                out.print("{\"success\":true}");

            // CUSTOMER: Appeal to Admin after seller rejected
            } else if ("appeal".equals(action)) {
                int refundId = Integer.parseInt(request.getParameter("refundId"));
                String orderId = request.getParameter("orderId");
                PreparedStatement ps = conn.prepareStatement(
                    "UPDATE refund_requests SET status='Appealed' WHERE refund_id=? AND status='Rejected'");
                ps.setInt(1, refundId);
                ps.executeUpdate(); ps.close();

             // Notify admin
                PreparedStatement adminPs = conn.prepareStatement(
                    "SELECT admin_id FROM admin LIMIT 1");
                ResultSet adminRs = adminPs.executeQuery();
                if (adminRs.next()) {
                    PreparedStatement notifPs = conn.prepareStatement(
                        "INSERT INTO notifications (user_id, user_type, message, is_read) VALUES (?,?,?,0)");
                    notifPs.setInt(1, adminRs.getInt("admin_id"));
                    notifPs.setString(2, "admin");
                    notifPs.setString(3, "⚠️ A customer appealed a rejected refund for Order #SE-" + orderId);
                    notifPs.executeUpdate(); notifPs.close();
                }
                adminRs.close(); adminPs.close();
                conn.close();
                out.print("{\"success\":true}");

            // ADMIN: Final decision on appealed refund
            } else if ("adminAction".equals(action)) {
                int refundId = Integer.parseInt(request.getParameter("refundId"));
                String adminDecision = request.getParameter("decision");
                String newStatus = "approve".equals(adminDecision) ? "Refunded" : "Rejected";

                PreparedStatement ps = conn.prepareStatement(
                    "UPDATE refund_requests SET status=?, admin_action=?, admin_reviewed_at=NOW() WHERE refund_id=?");
                ps.setString(1, newStatus);
                ps.setString(2, adminDecision);
                ps.setInt(3, refundId);
                ps.executeUpdate(); ps.close();

                if ("Refunded".equals(newStatus)) {
                    PreparedStatement amtPs = conn.prepareStatement(
                        "SELECT rr.order_id, o.total_amount, rr.customer_id " +
                        "FROM refund_requests rr JOIN orders o ON rr.order_id=o.order_id " +
                        "WHERE rr.refund_id=?");
                    amtPs.setInt(1, refundId);
                    ResultSet amtRs = amtPs.executeQuery();
                    if (amtRs.next()) {
                        int custId = amtRs.getInt("customer_id");
                        double refundAmt = amtRs.getDouble("total_amount");
                        int ordId = amtRs.getInt("order_id");
                        PreparedStatement walletPs = conn.prepareStatement(
                            "UPDATE customer SET wallet_balance = wallet_balance + ? WHERE customer_id=?");
                        walletPs.setDouble(1, refundAmt); walletPs.setInt(2, custId);
                        walletPs.executeUpdate(); walletPs.close();
                        PreparedStatement logPs = conn.prepareStatement(
                            "INSERT INTO wallet_transactions (customer_id, amount, type, description, reference_id) VALUES (?,?,'refund',?,?)");
                        logPs.setInt(1, custId); logPs.setDouble(2, refundAmt);
                        logPs.setString(3, "Refund approved by Admin for Order #SE-" + ordId);
                        logPs.setInt(4, ordId);
                        logPs.executeUpdate(); logPs.close();
                    }
                    amtRs.close(); amtPs.close();
                }

                PreparedStatement infoPs2 = conn.prepareStatement(
                    "SELECT rr.order_id, c.user_id FROM refund_requests rr " +
                    "JOIN customer c ON rr.customer_id=c.customer_id WHERE rr.refund_id=?");
                infoPs2.setInt(1, refundId);
                ResultSet infoRs2 = infoPs2.executeQuery();
                if (infoRs2.next()) {
                    int ordId = infoRs2.getInt("order_id");
                    int custUserId = infoRs2.getInt("user_id");
                    String msg = "approve".equals(adminDecision)
                        ? "💸 Your refund appeal for Order #SE-" + ordId + " was approved by Admin!"
                        : "❌ Your refund appeal for Order #SE-" + ordId + " was rejected by Admin.";
                    PreparedStatement notifPs = conn.prepareStatement(
                        "INSERT INTO notifications (user_id, user_type, message, is_read) VALUES (?,?,?,0)");
                    notifPs.setInt(1, custUserId);
                    notifPs.setString(2, "customer");
                    notifPs.setString(3, msg);
                    notifPs.executeUpdate(); notifPs.close();
                }
                infoRs2.close(); infoPs2.close();
                conn.close();
                out.print("{\"success\":true}");
            }
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\":false,\"message\":\"Server error\"}");
        }
    }
}