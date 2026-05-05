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

@WebServlet("/NotificationServlet")
public class NotificationServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        if (session.getAttribute("userId") == null) return;

        int userId = (int) session.getAttribute("userId");
        String action = request.getParameter("action");

        try {
            Connection conn = DBConnection.getConnection();
            String userType = request.getParameter("userType") != null ? request.getParameter("userType") : "customer";
            if ("markRead".equals(action)) {
                int notifId = Integer.parseInt(request.getParameter("notifId"));
                PreparedStatement ps = conn.prepareStatement(
                    "UPDATE notifications SET is_read=1 WHERE notif_id=? AND user_id=?");
                ps.setInt(1, notifId);
                ps.setInt(2, userId);
                ps.executeUpdate();
                ps.close();
            } else if ("markAllRead".equals(action)) {
                PreparedStatement ps = conn.prepareStatement(
                    "UPDATE notifications SET is_read=1 WHERE user_id=? AND user_type=?");
                ps.setInt(1, userId);
                ps.setString(2, userType);
                ps.executeUpdate();
                ps.close();
            } else if ("clearAll".equals(action)) {
                PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM notifications WHERE user_id=? AND user_type=?");
                ps.setInt(1, userId);
                ps.setString(2, userType);
                ps.executeUpdate();
                ps.close();
            }
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        response.getWriter().print("ok");
    }
}