package com.shopeasy;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/ForgotPasswordServlet")
public class ForgotPasswordServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        String action = request.getParameter("action");

        try {
            Connection conn = DBConnection.getConnection();

            if ("verify".equals(action)) {
                String email = request.getParameter("email");
                String username = request.getParameter("username");

                // Check customer
                PreparedStatement ps = conn.prepareStatement(
                    "SELECT customer_id FROM customer WHERE email=? AND username=?");
                ps.setString(1, email);
                ps.setString(2, username);
                ResultSet rs = ps.executeQuery();

                if (rs.next()) {
                    out.print("{\"success\":true}");
                    conn.close();
                    return;
                }

                // Check seller
                ps = conn.prepareStatement(
                    "SELECT seller_id FROM seller WHERE email=? AND username=?");
                ps.setString(1, email);
                ps.setString(2, username);
                rs = ps.executeQuery();

                if (rs.next()) {
                    out.print("{\"success\":true}");
                    conn.close();
                    return;
                }

                out.print("{\"success\":false,\"message\":\"Email or username not found.\"}");

            } else if ("reset".equals(action)) {
                String email = request.getParameter("email");
                String newPassword = request.getParameter("newPassword");

                // Update customer
                PreparedStatement ps = conn.prepareStatement(
                    "UPDATE customer SET password=? WHERE email=?");
                ps.setString(1, newPassword);
                ps.setString(2, email);
                int rows = ps.executeUpdate();

                if (rows == 0) {
                    // Try seller
                    ps = conn.prepareStatement(
                        "UPDATE seller SET password=? WHERE email=?");
                    ps.setString(1, newPassword);
                    ps.setString(2, email);
                    rows = ps.executeUpdate();
                }

                if (rows > 0) {
                    out.print("{\"success\":true}");
                } else {
                    out.print("{\"success\":false,\"message\":\"Failed to update password.\"}");
                }
            }

            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\":false,\"message\":\"Server error.\"}");
        }
    }
}