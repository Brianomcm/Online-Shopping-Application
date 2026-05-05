package com.shopeasy;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/CancelOrderServlet")
public class CancelOrderServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        if (session.getAttribute("userId") == null) {
            response.sendRedirect("index.jsp");
            return;
        }
        int customerId = (int) session.getAttribute("userId");
        int orderId = Integer.parseInt(request.getParameter("orderId"));
        try {
            Connection conn = DBConnection.getConnection();
            // Only cancel if it's Pending and belongs to this customer
            PreparedStatement ps = conn.prepareStatement(
                "UPDATE orders SET status='Cancelled' WHERE order_id=? AND customer_id=? AND status='Pending'");
            ps.setInt(1, orderId);
            ps.setInt(2, customerId);
            int rowsAffected = ps.executeUpdate();
            ps.close();

            // Notify seller if successfully cancelled
            if (rowsAffected > 0) {
                PreparedStatement sellerPs = conn.prepareStatement(
                    "SELECT DISTINCT oi.seller_id FROM order_items oi WHERE oi.order_id=?");
                sellerPs.setInt(1, orderId);
                java.sql.ResultSet sellerRs = sellerPs.executeQuery();
                while (sellerRs.next()) {
                    int sellerId = sellerRs.getInt("seller_id");
                    PreparedStatement notifPs = conn.prepareStatement(
                        "INSERT INTO notifications (user_id, user_type, message) VALUES (?, 'seller', ?)");
                    notifPs.setInt(1, sellerId);
                    notifPs.setString(2, "Order #" + orderId + " has been cancelled by the customer.");
                    notifPs.executeUpdate();
                    notifPs.close();
                }
                sellerRs.close();
                sellerPs.close();
            }
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        response.sendRedirect("customer.jsp?tab=orders&msg=cancelled");
    }
}