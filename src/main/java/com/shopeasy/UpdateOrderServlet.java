package com.shopeasy;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

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
            } else {
                ps = conn.prepareStatement(
                    "UPDATE orders SET status=? WHERE order_id=?");
                ps.setString(1, status);
                ps.setInt(2, orderId);
            }
            ps.executeUpdate();
            ps.close();

            // Notify customer
            PreparedStatement custPs = conn.prepareStatement(
                    "SELECT o.customer_id, c.user_id FROM orders o JOIN customer c ON c.customer_id = o.customer_id WHERE o.order_id=?");
            custPs.setInt(1, orderId);
            java.sql.ResultSet custRs = custPs.executeQuery();
            if (custRs.next()) {
                int custId = custRs.getInt("customer_id");
                PreparedStatement notifPs = conn.prepareStatement(
                    "INSERT INTO notifications (user_id, user_type, message) VALUES (?, 'customer', ?)");
                int custUserId = custRs.getInt("user_id");
                notifPs.setInt(1, custUserId);
                notifPs.setString(2, "Your order #" + orderId + " status has been updated to: " + status);
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