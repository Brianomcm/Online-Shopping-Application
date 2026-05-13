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
     // Check actual role from DB, not session (session might be stale)
        String userRole = "customer";
        try {
            Connection roleConn = DBConnection.getConnection();
            PreparedStatement rolePs = roleConn.prepareStatement(
                "SELECT role FROM users WHERE user_id = ?");
            rolePs.setInt(1, userId);
            ResultSet roleRs = rolePs.executeQuery();
            if (roleRs.next()) userRole = roleRs.getString("role");
            roleRs.close(); rolePs.close(); roleConn.close();
        } catch (Exception re) { re.printStackTrace(); }

        if ("seller".equals(userRole) || "both".equals(userRole)) {
            response.sendRedirect("seller-apply.jsp?error=already");
            return;
        }

        // Check kung may approved application na sa DB kahit stale pa ang session
        try {
            Connection appConn = DBConnection.getConnection();
            PreparedStatement appPs = appConn.prepareStatement(
                "SELECT COUNT(*) FROM seller_application WHERE user_id=? AND status='approved'");
            appPs.setInt(1, userId);
            ResultSet appRs = appPs.executeQuery();
            if (appRs.next() && appRs.getInt(1) > 0) {
                appRs.close(); appPs.close(); appConn.close();
                response.sendRedirect("seller-apply.jsp?error=relogin");
                return;
            }
            appRs.close(); appPs.close(); appConn.close();
        } catch (Exception ae) { ae.printStackTrace(); }

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

        	// 1. Insert into seller_application — PENDING lang, hindi auto-approve
        	String insertApp = "INSERT INTO seller_application (user_id, customer_id, business_name, business_type, " +
                    "shop_description, shop_location, status) VALUES (?, ?, ?, ?, ?, ?, 'pending')";
 try (PreparedStatement ps = conn.prepareStatement(insertApp)) {
     ps.setInt(1, userId);
     ps.setInt(2, userId);
     ps.setString(3, businessName);
     ps.setString(4, businessType);
     ps.setString(5, shopDescription);
     ps.setString(6, shopLocation);
     ps.executeUpdate();
 }
        	conn.commit();
        	conn.setAutoCommit(true);

        	// 2. Notify the user — application is under review
        	try {
        	    Connection notifConn = DBConnection.getConnection();
        	    String insertNotif = "INSERT INTO notifications (user_id, user_type, message, is_read) VALUES (?, 'customer', ?, 0)";
        	    PreparedStatement notifPs = notifConn.prepareStatement(insertNotif);
        	    notifPs.setInt(1, userId);
        	    notifPs.setString(2, "Your seller application has been submitted! Please wait for admin approval. We'll notify you once it's reviewed.");
        	    notifPs.executeUpdate();
        	    notifPs.close();
        	    notifConn.close();
        	} catch (Exception notifEx) {
        	    notifEx.printStackTrace();
        	}

        	response.sendRedirect("index.jsp?sellerPending=true");

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