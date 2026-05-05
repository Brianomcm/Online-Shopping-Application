package com.shopeasy;

import java.io.*;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/UpdatePasswordServlet")
public class UpdatePasswordServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession();
        Integer userId = (Integer) session.getAttribute("userId");
        String role = (String) session.getAttribute("userRole");

        if (userId == null) {
            out.print("{\"success\":false,\"message\":\"Not logged in.\"}");
            return;
        }

        String currentPassword = request.getParameter("currentPassword");
        String newPassword = request.getParameter("newPassword");

        try {
            Connection conn = DBConnection.getConnection();
            String table = "customer".equals(role) ? "customer" : "seller";
            String idCol = "customer".equals(role) ? "customer_id" : "seller_id";

            // Verify current password
            PreparedStatement ps = conn.prepareStatement(
                "SELECT * FROM " + table + " WHERE " + idCol + "=? AND password=?");
            ps.setInt(1, userId);
            ps.setString(2, currentPassword);
            ResultSet rs = ps.executeQuery();

            if (!rs.next()) {
                out.print("{\"success\":false,\"message\":\"Current password is incorrect.\"}");
                conn.close();
                return;
            }

            // Update password
            PreparedStatement updatePs = conn.prepareStatement(
                "UPDATE " + table + " SET password=? WHERE " + idCol + "=?");
            updatePs.setString(1, newPassword);
            updatePs.setInt(2, userId);
            updatePs.executeUpdate();

            conn.close();
            out.print("{\"success\":true}");

        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\":false,\"message\":\"Server error.\"}");
        }
    }
}