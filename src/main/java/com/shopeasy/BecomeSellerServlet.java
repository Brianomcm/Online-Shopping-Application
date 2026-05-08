package com.shopeasy;

import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/BecomeSellerServlet")
public class BecomeSellerServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int userId = (int) session.getAttribute("userId");
        String userRole = (String) session.getAttribute("userRole"); // FIXED: was "role"

        // Already a seller or both
        if ("seller".equals(userRole) || "both".equals(userRole)) {
            response.sendRedirect("seller-apply.jsp?error=already");
            return;
        }

        String businessName    = request.getParameter("businessName");
        String businessType    = request.getParameter("businessType");
        String shopDescription = request.getParameter("shopDescription");
        String primaryCategory = request.getParameter("primaryCategory");
        String shopLocation    = request.getParameter("shopLocation");
        if (primaryCategory == null) primaryCategory = "";
        if (shopLocation == null) shopLocation = "";

        if (businessName == null || businessName.trim().isEmpty() ||
            businessType == null || businessType.trim().isEmpty() ||
            shopDescription == null || shopDescription.trim().length() < 20) {
            response.sendRedirect("seller-apply.jsp?error=invalid");
            return;
        }

        businessName    = businessName.trim();
        businessType    = businessType.trim();
        shopDescription = shopDescription.trim();

        Connection conn = null;
        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            // 1. Get customer info from customer table using userId
            String custName = null, custEmail = null, custPhone = null;
            String custAddress = null, custUsername = null, custPassword = null;

            String fetchCust = "SELECT name, email, phone, address, username, password FROM customer WHERE user_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(fetchCust)) {
                ps.setInt(1, userId); // FIXED: userId na, hindi customerId
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    custName     = rs.getString("name");
                    custEmail    = rs.getString("email");
                    custPhone    = rs.getString("phone");
                    custAddress  = rs.getString("address");
                    custUsername = rs.getString("username");
                    custPassword = rs.getString("password");
                }
            }

            // 2. Insert into seller table
            int newSellerId = -1;

            String insertSeller = "INSERT INTO seller (name, email, password, address, phone, username, " +
                    "business_name, business_type, shop_description, primary_category, shop_location, user_id) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            try (PreparedStatement ps = conn.prepareStatement(insertSeller, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, custName);
                ps.setString(2, custEmail);
                ps.setString(3, custPassword);
                ps.setString(4, custAddress);
                ps.setString(5, custPhone);
                ps.setString(6, custUsername);
                ps.setString(7, businessName);
                ps.setString(8, businessType);
                ps.setString(9, shopDescription);
                ps.setString(10, primaryCategory);
                ps.setString(11, shopLocation);
                ps.setInt(12, userId);
                ps.executeUpdate();

                ResultSet keys = ps.getGeneratedKeys();
                if (keys.next()) {
                    newSellerId = keys.getInt(1);
                }
            }

         // 3. Insert into seller_application — auto approved
            String insertApp = "INSERT INTO seller_application (user_id, customer_id, business_name, business_type, " +
                               "shop_description, status, reviewed_at) VALUES (?, ?, ?, ?, ?, 'approved', NOW())";
            try (PreparedStatement ps = conn.prepareStatement(insertApp)) {
                ps.setInt(1, userId);
                ps.setInt(2, userId);
                ps.setString(3, businessName);
                ps.setString(4, businessType);
                ps.setString(5, shopDescription);
                ps.executeUpdate();
            }

         // 3.5 Update users table role to 'both'
            String updateRole = "UPDATE users SET role = 'both' WHERE user_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(updateRole)) {
                ps.setInt(1, userId);
                ps.executeUpdate();
            }

            conn.commit();
            conn.setAutoCommit(true); // ← IMPORTANT: i-enable muna bago ang notif insert

            // 4. Insert notification — separate connection para safe
            try {
                Connection notifConn = DBConnection.getConnection();
                String insertNotif = "INSERT INTO notifications (user_id, user_type, message, is_read) VALUES (?, 'customer', ?, 0)";
                PreparedStatement notifPs = notifConn.prepareStatement(insertNotif);
                notifPs.setInt(1, userId);
                notifPs.setString(2, "Congratulations! Your seller application has been approved. You can now enable Seller Mode from your profile dropdown to start selling on ShopEasy.");
                notifPs.executeUpdate();
                notifPs.close();
                notifConn.close();
            } catch (Exception notifEx) {
                notifEx.printStackTrace(); // log but don't fail the main flow
            }

            // 5. Update session
            session.setAttribute("userRole", "both");     // FIXED: consistent sa LoginServlet
            session.setAttribute("activeMode", "customer");
            session.setAttribute("sellerId", newSellerId);
            session.setAttribute("userBusinessName", businessName);
            session.setAttribute("shopDescription", shopDescription);
            session.setAttribute("shopLocation", shopLocation);
            session.setAttribute("userBusinessType", businessType);
            session.setAttribute("shopDescription", shopDescription);
            session.setAttribute("primaryCategory", primaryCategory);
            session.setAttribute("shopLocation", shopLocation);

            response.sendRedirect("index.jsp?sellerWelcome=true");

        } catch (Exception e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            }
            e.printStackTrace();
            response.sendRedirect("seller-apply.jsp?error=server");

        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); } catch (SQLException e) { e.printStackTrace(); }
            }
        }
    }
}