package com.shopeasy;

import java.io.*;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/ApproveCancelServlet")
public class ApproveCancelServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession();
        String acRole = (String) session.getAttribute("userRole");
        if (session.getAttribute("userId") == null || (!"seller".equals(acRole) && !"both".equals(acRole))) {
            out.print("{\"success\":false,\"message\":\"Unauthorized\"}");
            return;
        }

        String orderIdParam = request.getParameter("orderId");
        String action = request.getParameter("action"); // "approve" or "decline"
        String declineReason = request.getParameter("declineReason");
        if (declineReason == null) declineReason = "";

        if (orderIdParam == null || action == null) {
            out.print("{\"success\":false,\"message\":\"Missing data\"}");
            return;
        }

        int orderId = Integer.parseInt(orderIdParam);

        try {
            Connection conn = DBConnection.getConnection();

            // Get customer_id for notification
            PreparedStatement infoPs = conn.prepareStatement(
                "SELECT customer_id FROM orders WHERE order_id=?");
            infoPs.setInt(1, orderId);
            ResultSet infoRs = infoPs.executeQuery();
            int customerId = 0;
            if (infoRs.next()) customerId = infoRs.getInt("customer_id");
            infoRs.close(); infoPs.close();

            String newStatus;
            String custMessage;

            if ("approve".equals(action)) {
                newStatus = "Cancelled";
                custMessage = "Your cancellation request for Order #SE-" + orderId + " has been approved. Your order is now cancelled.";

                // Restore stock
                PreparedStatement itemsPs = conn.prepareStatement(
                    "SELECT product_id, quantity FROM order_items WHERE order_id=?");
                itemsPs.setInt(1, orderId);
                ResultSet itemsRs = itemsPs.executeQuery();
                while (itemsRs.next()) {
                    PreparedStatement restorePs = conn.prepareStatement(
                        "UPDATE product SET stock = stock + ? WHERE product_id = ?");
                    restorePs.setInt(1, itemsRs.getInt("quantity"));
                    restorePs.setInt(2, itemsRs.getInt("product_id"));
                    restorePs.executeUpdate();
                    restorePs.close();
                }
                itemsRs.close(); itemsPs.close();

                // Update order status (approve — just status)
                PreparedStatement updatePs = conn.prepareStatement(
                    "UPDATE orders SET status=? WHERE order_id=?");
                updatePs.setString(1, newStatus);
                updatePs.setInt(2, orderId);
                updatePs.executeUpdate();
                updatePs.close();

            } else {
                newStatus = "Processing";
                String reasonText = declineReason.isEmpty() ? "" : " Reason: " + declineReason;
                custMessage = "Your cancellation request for Order #SE-" + orderId +
                    " was declined by the seller." + reasonText + " Your order is still being processed.";

                // Update status AND set cancel_rejected = 1
                PreparedStatement updatePs = conn.prepareStatement(
                    "UPDATE orders SET status=?, cancel_rejected=1 WHERE order_id=?");
                updatePs.setString(1, newStatus);
                updatePs.setInt(2, orderId);
                updatePs.executeUpdate();
                updatePs.close();
            }

            // Notify customer
            if (customerId > 0) {
                PreparedStatement notifPs = conn.prepareStatement(
                    "INSERT INTO notifications (user_id, user_type, message) VALUES (?, 'customer', ?)");
                notifPs.setInt(1, customerId);
                notifPs.setString(2, custMessage);
                notifPs.executeUpdate();
                notifPs.close();
            }

            conn.close();
            out.print("{\"success\":true,\"newStatus\":\"" + newStatus + "\"}");

        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\":false,\"message\":\"" + e.getMessage() + "\"}");
        }
    }
}