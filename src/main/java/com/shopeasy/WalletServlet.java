package com.shopeasy;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.*;
import java.sql.*;

@WebServlet("/WalletServlet")
public class WalletServlet extends HttpServlet {
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
            // Get customer_id
            int userId = (Integer) session.getAttribute("userId");
            PreparedStatement cidPs = conn.prepareStatement(
                "SELECT customer_id, wallet_balance FROM customer WHERE user_id=?");
            cidPs.setInt(1, userId);
            ResultSet cidRs = cidPs.executeQuery();
            int customerId = 0; double walletBalance = 0;
            if (cidRs.next()) {
                customerId = cidRs.getInt("customer_id");
                walletBalance = cidRs.getDouble("wallet_balance");
            }
            cidRs.close(); cidPs.close();

            if ("getBalance".equals(action)) {
                out.print("{\"success\":true,\"balance\":" + walletBalance + "}");
            }
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\":false,\"message\":\"Server error\"}");
        }
    }
}