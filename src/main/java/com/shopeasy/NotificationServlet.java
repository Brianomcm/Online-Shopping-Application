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
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        java.io.PrintWriter out = response.getWriter();
        HttpSession session = request.getSession();
        if (session.getAttribute("userId") == null) {
            out.print("{\"notifications\":[]}");
            return;
        }
        String action = request.getParameter("action");
        int userId = (int) session.getAttribute("userId");
        try {
            Connection conn = DBConnection.getConnection();
            if ("getLatest".equals(action)) {
                PreparedStatement ps = conn.prepareStatement(
                    "SELECT MAX(notif_id) as latest FROM notifications WHERE user_id=? AND user_type='customer'");
                ps.setInt(1, userId);
                java.sql.ResultSet rs = ps.executeQuery();
                int latest = rs.next() ? rs.getInt("latest") : 0;
                rs.close(); ps.close(); conn.close();
                out.print("{\"latestId\":" + latest + "}");
            } else if ("getNew".equals(action)) {
                int since = Integer.parseInt(request.getParameter("since") != null ? request.getParameter("since") : "0");
                PreparedStatement ps = conn.prepareStatement(
                    "SELECT notif_id, message FROM notifications WHERE user_id=? AND user_type='customer' AND notif_id > ? ORDER BY notif_id ASC");
                ps.setInt(1, userId);
                ps.setInt(2, since);
                java.sql.ResultSet rs = ps.executeQuery();
                StringBuilder sb = new StringBuilder("[");
                boolean first = true;
                while (rs.next()) {
                    if (!first) sb.append(",");
                    sb.append("{\"id\":").append(rs.getInt("notif_id"))
                      .append(",\"message\":\"").append(rs.getString("message")
                      .replace("\"", "\\\"")).append("\"}");
                    first = false;
                }
                sb.append("]");
                rs.close(); ps.close(); conn.close();
                out.print("{\"notifications\":" + sb + "}");
            }
        } catch (Exception e) {
            out.print("{\"notifications\":[]}");
        }
    }
	
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