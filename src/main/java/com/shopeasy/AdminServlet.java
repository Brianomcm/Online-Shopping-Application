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
import javax.servlet.http.HttpSession;

@WebServlet("/AdminServlet")
public class AdminServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        // Admin auth check
        HttpSession session = request.getSession(false);
        if (session == null || !"admin".equals(session.getAttribute("userRole"))) {
            out.print("{\"success\":false,\"message\":\"Unauthorized\"}");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) {
            out.print("{\"success\":false,\"message\":\"No action specified\"}");
            return;
        }

        try {
            Connection conn = DBConnection.getConnection();

            switch (action) {

            
         // -------------------------------------------------------
            // SEND OFFENSE
            // -------------------------------------------------------
            case "sendOffense": {
                String userIdStr = request.getParameter("userId");
                String offenseStr = request.getParameter("offense");
                String reason = request.getParameter("reason");
                if (userIdStr == null || offenseStr == null || reason == null || reason.trim().isEmpty()) {
                    out.print("{\"success\":false,\"message\":\"Missing parameters\"}");
                    break;
                }
                int userId = Integer.parseInt(userIdStr);
                int offense = Integer.parseInt(offenseStr);

                // Check not admin
                PreparedStatement chkPs = conn.prepareStatement("SELECT role FROM users WHERE user_id=?");
                chkPs.setInt(1, userId);
                java.sql.ResultSet chkRs = chkPs.executeQuery();
                if (chkRs.next() && "admin".equals(chkRs.getString("role"))) {
                    chkRs.close(); chkPs.close();
                    out.print("{\"success\":false,\"message\":\"Cannot send offense to admin!\"}");
                    break;
                }
                chkRs.close(); chkPs.close();

                // Insert violation
                PreparedStatement insPs = conn.prepareStatement(
                    "INSERT INTO user_violations (user_id, offense_level, reason) VALUES (?,?,?)");
                insPs.setInt(1, userId);
                insPs.setInt(2, offense);
                insPs.setString(3, reason.trim());
                insPs.executeUpdate();
                insPs.close();

                // Auto-ban on 3rd offense
                if (offense >= 3) {
                    PreparedStatement banPs = conn.prepareStatement(
                        "UPDATE users SET status='Banned' WHERE user_id=?");
                    banPs.setInt(1, userId);
                    banPs.executeUpdate();
                    banPs.close();
                }

                // Send notification
                String[] offenseLabels = {"", "1st", "2nd", "3rd"};
                String label = offense <= 3 ? offenseLabels[offense] : offense + "th";
                String notifMsg = "⚠️ You have received a " + label + " offense warning. Reason: " + reason.trim() +
                	    (offense >= 3 ? " Your account has been suspended due to repeated violations." : " Please review our community guidelines.") +
                	    " If you think this is a mistake, appeal at: support@shopeasy.com";
                PreparedStatement notifPs = conn.prepareStatement(
                	    "INSERT INTO notifications (user_id, user_type, message, is_read) VALUES (?, 'customer', ?, 0)");
                	notifPs.setInt(1, userId);
                	notifPs.setString(2, notifMsg);
                	notifPs.executeUpdate();
                	notifPs.close();

                String msg = offense >= 3 ? "3rd offense issued — user auto-banned." : label + " offense sent successfully.";
                out.print("{\"success\":true,\"message\":\"" + msg + "\"}");
                break;
            }
            
            
            case "revertOffense": {
                int userId = Integer.parseInt(request.getParameter("userId"));
                
                // Get the offense level before deleting
                PreparedStatement getPs = conn.prepareStatement(
                    "SELECT offense_level FROM user_violations WHERE user_id=? ORDER BY created_at DESC LIMIT 1");
                getPs.setInt(1, userId);
                ResultSet getRs = getPs.executeQuery();
                int revertedLevel = 0;
                if (getRs.next()) revertedLevel = getRs.getInt("offense_level");
                getRs.close(); getPs.close();
                
                PreparedStatement delPs = conn.prepareStatement(
                    "DELETE FROM user_violations WHERE user_id=? ORDER BY created_at DESC LIMIT 1");
                delPs.setInt(1, userId);
                int deleted = delPs.executeUpdate();
                delPs.close();
                
                if (deleted > 0) {
                    // Send notification to user
                    String[] offenseLabels = {"", "1st", "2nd", "3rd"};
                    String rvLabel = revertedLevel >= 1 && revertedLevel <= 3 ? offenseLabels[revertedLevel] : revertedLevel + "th";
                    String revertMsg = "✅ Your " + rvLabel + " offense record has been reviewed and reverted by the admin. "
                        + "This means the violation has been lifted from your account. "
                        + "If you have concerns, contact us at: support@shopeasy.com";
                    PreparedStatement revertNotifPs = conn.prepareStatement(
                        "INSERT INTO notifications (user_id, user_type, message, is_read) VALUES (?, 'customer', ?, 0)");
                    revertNotifPs.setInt(1, userId);
                    revertNotifPs.setString(2, revertMsg);
                    revertNotifPs.executeUpdate();
                    revertNotifPs.close();
                    
                    out.print("{\"success\":true,\"message\":\"Last offense reverted and user notified.\"}");
                } else {
                    out.print("{\"success\":false,\"message\":\"No offense found.\"}");
                }
                break;
            }
                // -------------------------------------------------------
                // BAN USER — deletes user from users table
                // -------------------------------------------------------
                case "banUser": {
                    String userIdStr = request.getParameter("userId");
                    if (userIdStr == null) { out.print("{\"success\":false,\"message\":\"Missing userId\"}"); break; }
                    int userId = Integer.parseInt(userIdStr);

                    // Don't allow banning admin
                    PreparedStatement checkPs = conn.prepareStatement(
                        "SELECT role FROM users WHERE user_id=?");
                    checkPs.setInt(1, userId);
                    java.sql.ResultSet checkRs = checkPs.executeQuery();
                    if (checkRs.next() && "admin".equals(checkRs.getString("role"))) {
                        checkRs.close(); checkPs.close();
                        out.print("{\"success\":false,\"message\":\"Cannot ban admin!\"}");
                        break;
                    }
                    checkRs.close(); checkPs.close();

                    PreparedStatement ps = conn.prepareStatement(
                    	    "UPDATE users SET status='Banned' WHERE user_id=?");
                    ps.setInt(1, userId);
                    int rows = ps.executeUpdate();
                    ps.close();
                    if (rows > 0) {
                        out.print("{\"success\":true,\"message\":\"User banned successfully.\"}");
                    } else {
                        out.print("{\"success\":false,\"message\":\"User not found.\"}");
                    }
                    break;
                }

                // -------------------------------------------------------
                // ACTIVATE USER
                // -------------------------------------------------------
                case "activateUser": {
                    String userIdStr = request.getParameter("userId");
                    if (userIdStr == null) { out.print("{\"success\":false,\"message\":\"Missing userId\"}"); break; }
                    int userId = Integer.parseInt(userIdStr);

                    PreparedStatement ps = conn.prepareStatement(
                        "UPDATE users SET status='Active' WHERE user_id=?");
                    ps.setInt(1, userId);
                    int rows = ps.executeUpdate();
                    ps.close();
                    if (rows > 0) {
                        out.print("{\"success\":true,\"message\":\"User activated successfully.\"}");
                    } else {
                        out.print("{\"success\":false,\"message\":\"User not found.\"}");
                    }
                    break;
                }

                // -------------------------------------------------------
                // APPROVE SELLER APPLICATION
                // -------------------------------------------------------
                case "approveSeller": {
                    String appIdStr = request.getParameter("sellerId");
                    if (appIdStr == null) { out.print("{\"success\":false,\"message\":\"Missing sellerId\"}"); break; }
                    int appUserId = Integer.parseInt(appIdStr);

                    // 1. Get application data
                    PreparedStatement getApp = conn.prepareStatement(
                        "SELECT * FROM seller_application WHERE user_id=? AND status='pending' ORDER BY applied_at DESC LIMIT 1");
                    getApp.setInt(1, appUserId);
                    java.sql.ResultSet appRs = getApp.executeQuery();

                    if (!appRs.next()) {
                        out.print("{\"success\":false,\"message\":\"No pending application found.\"}");
                        appRs.close(); getApp.close(); break;
                    }

                    String bizName     = appRs.getString("business_name");
                    String bizType     = appRs.getString("business_type");
                    String bizDesc     = appRs.getString("shop_description");
                    String bizLocation = appRs.getString("shop_location");
                    if (bizLocation == null) bizLocation = "";
                    appRs.close(); getApp.close();

                    // 2. Get customer info
                    String custName = null, custEmail = null, custPhone = null, custAddr = null, custUser = null, custPass = null;
                    PreparedStatement getCust = conn.prepareStatement(
                        "SELECT name, email, phone, address, username, password FROM customer WHERE user_id=?");
                    getCust.setInt(1, appUserId);
                    java.sql.ResultSet custRs = getCust.executeQuery();
                    if (custRs.next()) {
                        custName  = custRs.getString("name");
                        custEmail = custRs.getString("email");
                        custPhone = custRs.getString("phone");
                        custAddr  = custRs.getString("address");
                        custUser  = custRs.getString("username");
                        custPass  = custRs.getString("password");
                    }
                    custRs.close(); getCust.close();

                    // 3. Insert into seller table
                    PreparedStatement insSeller = conn.prepareStatement(
                            "INSERT INTO seller (name, email, password, address, phone, username, " +
                            "business_name, business_type, shop_description, shop_location, user_id) " +
                            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
                        insSeller.setString(1, custName);
                        insSeller.setString(2, custEmail);
                        insSeller.setString(3, custPass);
                        insSeller.setString(4, custAddr);
                        insSeller.setString(5, custPhone);
                        insSeller.setString(6, custUser);
                        insSeller.setString(7, bizName);
                        insSeller.setString(8, bizType);
                        insSeller.setString(9, bizDesc);
                        insSeller.setString(10, bizLocation);
                        insSeller.setInt(11, appUserId);
                        insSeller.executeUpdate();
                        insSeller.close();

                    // 4. Update seller_application status
                    PreparedStatement updApp = conn.prepareStatement(
                        "UPDATE seller_application SET status='approved', reviewed_at=NOW() WHERE user_id=? AND status='pending'");
                    updApp.setInt(1, appUserId);
                    updApp.executeUpdate();
                    updApp.close();

                    // 5. Update users role to 'both'
                    PreparedStatement updRole = conn.prepareStatement(
                        "UPDATE users SET role='both' WHERE user_id=?");
                    updRole.setInt(1, appUserId);
                    updRole.executeUpdate();
                    updRole.close();

                    // 6. Notify user
                    try {
                        PreparedStatement notif = conn.prepareStatement(
                            "INSERT INTO notifications (user_id, user_type, message, is_read) VALUES (?, 'customer', ?, 0)");
                        notif.setInt(1, appUserId);
                        notif.setString(2, "Congratulations! Your seller application has been approved. You can now enable Seller Mode from your profile dropdown to start selling on ShopEasy.");
                        notif.executeUpdate();
                        notif.close();
                    } catch (Exception ex) { ex.printStackTrace(); }

                    out.print("{\"success\":true,\"message\":\"Seller approved successfully.\"}");
                    break;
                }

                // -------------------------------------------------------
                // REJECT SELLER APPLICATION
                // -------------------------------------------------------
                case "rejectSeller": {
                    String appIdStr = request.getParameter("sellerId");
                    if (appIdStr == null) { out.print("{\"success\":false,\"message\":\"Missing sellerId\"}"); break; }
                    int appUserId = Integer.parseInt(appIdStr);

                    // Update seller_application status only — no seller record to delete
                    PreparedStatement ps = conn.prepareStatement(
                        "UPDATE seller_application SET status='rejected', reviewed_at=NOW() WHERE user_id=? AND status='pending'");
                    ps.setInt(1, appUserId);
                    int rows = ps.executeUpdate();
                    ps.close();

                    // Notify user
                    try {
                        PreparedStatement notif = conn.prepareStatement(
                            "INSERT INTO notifications (user_id, user_type, message, is_read) VALUES (?, 'customer', ?, 0)");
                        notif.setInt(1, appUserId);
                        notif.setString(2, "Your seller application was not approved at this time. You may reapply after reviewing our seller requirements.");
                        notif.executeUpdate();
                        notif.close();
                    } catch (Exception ex) { ex.printStackTrace(); }

                    if (rows > 0) {
                        out.print("{\"success\":true,\"message\":\"Seller application rejected.\"}");
                    } else {
                        out.print("{\"success\":false,\"message\":\"No pending application found.\"}");
                    }
                    break;
                }

                // -------------------------------------------------------
                // SUSPEND SELLER — removes from seller table
                // -------------------------------------------------------
                case "suspendSeller": {
                    String sellerIdStr = request.getParameter("sellerId");
                    if (sellerIdStr == null) { out.print("{\"success\":false,\"message\":\"Missing sellerId\"}"); break; }
                    int sellerId = Integer.parseInt(sellerIdStr);

                    // Revert user role back to customer
                    PreparedStatement rolePs = conn.prepareStatement(
                        "UPDATE users SET role='customer', active_mode='customer' " +
                        "WHERE user_id=(SELECT user_id FROM seller WHERE seller_id=?)");
                    rolePs.setInt(1, sellerId);
                    rolePs.executeUpdate();
                    rolePs.close();

                    // Delete from seller table
                    PreparedStatement ps = conn.prepareStatement(
                    	    "DELETE FROM seller WHERE seller_id=?");
                    ps.setInt(1, sellerId);
                    int rows = ps.executeUpdate();
                    ps.close();

                    if (rows > 0) {
                        out.print("{\"success\":true,\"message\":\"Seller suspended successfully.\"}");
                    } else {
                        out.print("{\"success\":false,\"message\":\"Seller not found.\"}");
                    }
                    break;
                }

                // -------------------------------------------------------
                // REMOVE PRODUCT
                // -------------------------------------------------------
                case "removeProduct": {
                    String productIdStr = request.getParameter("productId");
                    if (productIdStr == null) { out.print("{\"success\":false,\"message\":\"Missing productId\"}"); break; }
                    int productId = Integer.parseInt(productIdStr);
                    String removeReason = request.getParameter("reason");
                    if (removeReason == null || removeReason.trim().isEmpty()) removeReason = "Violates platform policies";

                    // Get product name and seller user_id BEFORE deleting
                    String removedProdName = "";
                    int removedSellerUserId = 0;
                    try {
                        PreparedStatement infoPs = conn.prepareStatement(
                            "SELECT p.name, s.user_id FROM product p JOIN seller s ON p.seller_id = s.seller_id WHERE p.product_id=?");
                        infoPs.setInt(1, productId);
                        ResultSet infoRs = infoPs.executeQuery();
                        if (infoRs.next()) {
                            removedProdName = infoRs.getString("name");
                            removedSellerUserId = infoRs.getInt("user_id");
                        }
                        infoRs.close(); infoPs.close();
                    } catch(Exception ex) {}

                    // Delete gallery first (FK constraint)
                    try {
                        PreparedStatement galPs = conn.prepareStatement(
                            "DELETE FROM product_gallery WHERE product_id=?");
                        galPs.setInt(1, productId);
                        galPs.executeUpdate();
                        galPs.close();
                    } catch(Exception ex) {}

                    // Delete product variations
                    try {
                        PreparedStatement varPs = conn.prepareStatement(
                            "DELETE FROM product_variation WHERE product_id=?");
                        varPs.setInt(1, productId);
                        varPs.executeUpdate();
                        varPs.close();
                    } catch(Exception ex) {}

                    // Delete the product
                    PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM product WHERE product_id=?");
                    ps.setInt(1, productId);
                    int rows = ps.executeUpdate();
                    ps.close();

                    if (rows > 0) {
                        // Send notification to seller
                        if (removedSellerUserId > 0 && !removedProdName.isEmpty()) {
                            try {
                                PreparedStatement notifPs = conn.prepareStatement(
                                    "INSERT INTO notifications (user_id, user_type, message, is_read) VALUES (?, 'seller', ?, 0)");
                                notifPs.setInt(1, removedSellerUserId);
                                notifPs.setString(2, "🚫 Your product \"" + removedProdName + "\" has been removed by the admin. Reason: " + removeReason);
                                notifPs.executeUpdate();
                                notifPs.close();
                            } catch(Exception ex) {}
                        }
                        out.print("{\"success\":true,\"message\":\"Product removed successfully.\"}");
                    } else {
                        out.print("{\"success\":false,\"message\":\"Product not found.\"}");
                    }
                    break;
                }

                // -------------------------------------------------------
                // APPROVE REFUND
                // -------------------------------------------------------
                case "approveRefund": {
                    String refundIdStr = request.getParameter("refundId");
                    if (refundIdStr == null) { out.print("{\"success\":false,\"message\":\"Missing refundId\"}"); break; }
                    int refundId = Integer.parseInt(refundIdStr);

                    PreparedStatement ps = conn.prepareStatement(
                        "UPDATE refund_requests SET status='approved' WHERE refund_id=?");
                    ps.setInt(1, refundId);
                    int rows = ps.executeUpdate();
                    ps.close();

                    if (rows > 0) {
                        out.print("{\"success\":true,\"message\":\"Refund approved.\"}");
                    } else {
                        out.print("{\"success\":false,\"message\":\"Refund not found.\"}");
                    }
                    break;
                }

                // -------------------------------------------------------
                // REJECT REFUND
                // -------------------------------------------------------
                case "rejectRefund": {
                    String refundIdStr = request.getParameter("refundId");
                    if (refundIdStr == null) { out.print("{\"success\":false,\"message\":\"Missing refundId\"}"); break; }
                    int refundId = Integer.parseInt(refundIdStr);

                    PreparedStatement ps = conn.prepareStatement(
                        "UPDATE refund_requests SET status='rejected' WHERE refund_id=?");
                    ps.setInt(1, refundId);
                    int rows = ps.executeUpdate();
                    ps.close();

                    if (rows > 0) {
                        out.print("{\"success\":true,\"message\":\"Refund rejected.\"}");
                    } else {
                        out.print("{\"success\":false,\"message\":\"Refund not found.\"}");
                    }
                    break;
                }
             // -------------------------------------------------------
                // UPDATE ORDER STATUS
                // -------------------------------------------------------
                case "updateOrderStatus": {
                    String orderIdStr = request.getParameter("orderId");
                    String newStatus = request.getParameter("status");
                    if (orderIdStr == null || newStatus == null) {
                        out.print("{\"success\":false,\"message\":\"Missing params\"}"); break;
                    }
                    int orderId = Integer.parseInt(orderIdStr);
                    PreparedStatement ps = conn.prepareStatement(
                        "UPDATE orders SET status=? WHERE order_id=?");
                    ps.setString(1, newStatus);
                    ps.setInt(2, orderId);
                    int rows = ps.executeUpdate();
                    ps.close();
                    if (rows > 0) {
                        out.print("{\"success\":true,\"message\":\"Order status updated.\"}");
                    } else {
                        out.print("{\"success\":false,\"message\":\"Order not found.\"}");
                    }
                    break;
                }
                
                case "approveProduct": {
                    String prodIdStr = request.getParameter("productId");
                    if (prodIdStr == null) {
                        out.print("{\"success\":false,\"message\":\"Missing productId\"}"); break;
                    }
                    int prodId = Integer.parseInt(prodIdStr);
                    PreparedStatement ps = conn.prepareStatement(
                        "UPDATE product SET status='active' WHERE product_id=?");
                    ps.setInt(1, prodId);
                    int rows = ps.executeUpdate();
                    ps.close();
                    if (rows > 0) {
                        try {
                            PreparedStatement selPs = conn.prepareStatement(
                                "SELECT s.user_id, p.name FROM product p " +
                                "JOIN seller s ON p.seller_id = s.seller_id " +
                                "WHERE p.product_id=?");
                            selPs.setInt(1, prodId);
                            ResultSet selRs = selPs.executeQuery();
                            if (selRs.next()) {
                                int selUserId = selRs.getInt("user_id");
                                String prodName = selRs.getString("name");
                                PreparedStatement notifPs = conn.prepareStatement(
                                    "INSERT INTO notifications (user_id, user_type, message, is_read) VALUES (?, 'seller', ?, 0)");
                                notifPs.setInt(1, selUserId);
                                notifPs.setString(2, "✅ Your product \"" + prodName + "\" has been approved and is now live!");
                                notifPs.executeUpdate();
                                notifPs.close();
                            }
                            selRs.close(); selPs.close();
                        } catch(Exception ne) { ne.printStackTrace(); }
                        out.print("{\"success\":true}");
                    } else {
                        out.print("{\"success\":false,\"message\":\"Product not found.\"}");
                    }
                    break;
                }

                case "rejectProduct": {
                    String prodIdStr2 = request.getParameter("productId");
                    if (prodIdStr2 == null) {
                        out.print("{\"success\":false,\"message\":\"Missing productId\"}"); break;
                    }
                    int prodId2 = Integer.parseInt(prodIdStr2);
                    String rejectReason = request.getParameter("reason");
                    if (rejectReason == null || rejectReason.trim().isEmpty()) rejectReason = "Does not meet platform standards";
                    PreparedStatement ps2 = conn.prepareStatement(
                        "UPDATE product SET status='rejected' WHERE product_id=?");
                    ps2.setInt(1, prodId2);
                    int rows2 = ps2.executeUpdate();
                    ps2.close();
                    if (rows2 > 0) {
                        try {
                            PreparedStatement selPs2 = conn.prepareStatement(
                                "SELECT s.user_id, p.name FROM product p " +
                                "JOIN seller s ON p.seller_id = s.seller_id " +
                                "WHERE p.product_id=?");
                            selPs2.setInt(1, prodId2);
                            ResultSet selRs2 = selPs2.executeQuery();
                            if (selRs2.next()) {
                                int selUserId2 = selRs2.getInt("user_id");
                                String prodName2 = selRs2.getString("name");
                                PreparedStatement notifPs2 = conn.prepareStatement(
                                    "INSERT INTO notifications (user_id, user_type, message, is_read) VALUES (?, 'seller', ?, 0)");
                                notifPs2.setInt(1, selUserId2);
                                notifPs2.setString(2, "❌ Your product \"" + prodName2 + "\" has been rejected. Reason: " + rejectReason + ". Please review and resubmit.");
                                notifPs2.executeUpdate();
                                notifPs2.close();
                            }
                            selRs2.close(); selPs2.close();
                        } catch(Exception ne) { ne.printStackTrace(); }
                        out.print("{\"success\":true}");
                    } else {
                        out.print("{\"success\":false,\"message\":\"Product not found.\"}");
                    }
                    break;
                }
                
                case "approvePayout": {
                    String payoutIdStr = request.getParameter("payoutId");
                    if (payoutIdStr == null) { out.print("{\"success\":false,\"message\":\"Missing payoutId\"}"); break; }
                    int payoutId = Integer.parseInt(payoutIdStr);

                    // Get payout info before updating
                    double payAmount = 0; int paySellerUserId = 0; String payMethod = "";
                    try {
                        PreparedStatement payInfoPs = conn.prepareStatement(
                            "SELECT pr.amount, pr.method, s.user_id FROM payout_requests pr " +
                            "JOIN seller s ON pr.seller_id = s.seller_id WHERE pr.payout_id=?");
                        payInfoPs.setInt(1, payoutId);
                        ResultSet payInfoRs = payInfoPs.executeQuery();
                        if (payInfoRs.next()) {
                            payAmount = payInfoRs.getDouble("amount");
                            payMethod = payInfoRs.getString("method");
                            paySellerUserId = payInfoRs.getInt("user_id");
                        }
                        payInfoRs.close(); payInfoPs.close();
                    } catch(Exception ex) {}

                    PreparedStatement payPs = conn.prepareStatement(
                        "UPDATE payout_requests SET status='Completed' WHERE payout_id=?");
                    payPs.setInt(1, payoutId);
                    int payRows = payPs.executeUpdate();
                    payPs.close();

                    if (payRows > 0) {
                        // Notify seller
                        if (paySellerUserId > 0) {
                            try {
                                PreparedStatement notifPs = conn.prepareStatement(
                                    "INSERT INTO notifications (user_id, user_type, message, is_read) VALUES (?, 'seller', ?, 0)");
                                notifPs.setInt(1, paySellerUserId);
                                notifPs.setString(2, "💸 Your payout request of ₱" + String.format("%.2f", payAmount) + " via " + payMethod + " has been approved and processed!");
                                notifPs.executeUpdate();
                                notifPs.close();
                            } catch(Exception ex) {}
                        }
                        out.print("{\"success\":true,\"message\":\"Payout approved.\"}");
                    } else {
                        out.print("{\"success\":false,\"message\":\"Payout not found.\"}");
                    }
                    break;
                }

                case "rejectPayout": {
                    String rejectPayoutIdStr = request.getParameter("payoutId");
                    if (rejectPayoutIdStr == null) { out.print("{\"success\":false,\"message\":\"Missing payoutId\"}"); break; }
                    int rejectPayoutId = Integer.parseInt(rejectPayoutIdStr);
                    String rejectPayoutReason = request.getParameter("reason");
                    if (rejectPayoutReason == null || rejectPayoutReason.trim().isEmpty()) rejectPayoutReason = "Does not meet requirements";

                    // Get payout info
                    double rPayAmount = 0; int rPaySellerUserId = 0; String rPayMethod = "";
                    try {
                        PreparedStatement rPayInfoPs = conn.prepareStatement(
                            "SELECT pr.amount, pr.method, s.user_id FROM payout_requests pr " +
                            "JOIN seller s ON pr.seller_id = s.seller_id WHERE pr.payout_id=?");
                        rPayInfoPs.setInt(1, rejectPayoutId);
                        ResultSet rPayInfoRs = rPayInfoPs.executeQuery();
                        if (rPayInfoRs.next()) {
                            rPayAmount = rPayInfoRs.getDouble("amount");
                            rPayMethod = rPayInfoRs.getString("method");
                            rPaySellerUserId = rPayInfoRs.getInt("user_id");
                        }
                        rPayInfoRs.close(); rPayInfoPs.close();
                    } catch(Exception ex) {}

                    PreparedStatement rPayPs = conn.prepareStatement(
                        "UPDATE payout_requests SET status='Rejected' WHERE payout_id=?");
                    rPayPs.setInt(1, rejectPayoutId);
                    int rPayRows = rPayPs.executeUpdate();
                    rPayPs.close();

                    if (rPayRows > 0) {
                        if (rPaySellerUserId > 0) {
                            try {
                                PreparedStatement notifPs = conn.prepareStatement(
                                    "INSERT INTO notifications (user_id, user_type, message, is_read) VALUES (?, 'seller', ?, 0)");
                                notifPs.setInt(1, rPaySellerUserId);
                                notifPs.setString(2, "❌ Your payout request of ₱" + String.format("%.2f", rPayAmount) + " via " + rPayMethod + " has been rejected. Reason: " + rejectPayoutReason);
                                notifPs.executeUpdate();
                                notifPs.close();
                            } catch(Exception ex) {}
                        }
                        out.print("{\"success\":true,\"message\":\"Payout rejected.\"}");
                    } else {
                        out.print("{\"success\":false,\"message\":\"Payout not found.\"}");
                    }
                    break;
                }

                case "createVoucher": {
                    String vcCode = request.getParameter("code").toUpperCase().trim();
                    String vcType = request.getParameter("type");
                    double vcValue = Double.parseDouble(request.getParameter("value"));
                    double vcMinOrder = Double.parseDouble(request.getParameter("minOrder"));
                    String vcMaxUses = request.getParameter("maxUses");
                    String durationValue = request.getParameter("durationValue");
                    String durationUnit = request.getParameter("durationUnit");
                    java.sql.Timestamp expiryTs = null;
                    if (durationValue != null && !durationValue.isEmpty() && durationUnit != null && !durationUnit.isEmpty()) {
                        int dVal = Integer.parseInt(durationValue);
                        long millis = System.currentTimeMillis();
                        if ("hours".equals(durationUnit)) millis += (long) dVal * 3600 * 1000;
                        else if ("days".equals(durationUnit)) millis += (long) dVal * 86400 * 1000;
                        else if ("weeks".equals(durationUnit)) millis += (long) dVal * 7 * 86400 * 1000;
                        expiryTs = new java.sql.Timestamp(millis);
                    }
                    PreparedStatement vcPs = conn.prepareStatement(
                        "INSERT INTO vouchers (code, type, value, min_order, max_uses, expiry_date) VALUES (?,?,?,?,?,?)");
                    vcPs.setString(1, vcCode);
                    vcPs.setString(2, vcType);
                    vcPs.setDouble(3, vcValue);
                    vcPs.setDouble(4, vcMinOrder);
                    vcPs.setObject(5, (vcMaxUses != null && !vcMaxUses.isEmpty()) ? Integer.parseInt(vcMaxUses) : null);
                    vcPs.setObject(6, expiryTs);
                    vcPs.executeUpdate();
                    vcPs.close();
                    out.print("{\"success\":true,\"message\":\"Voucher created!\"}");
                    break;
                }
                case "editVoucher": {
                    int vcId = Integer.parseInt(request.getParameter("voucherId"));
                    String vcCode = request.getParameter("code").toUpperCase().trim();
                    String vcType = request.getParameter("type");
                    double vcValue = Double.parseDouble(request.getParameter("value"));
                    double vcMinOrder = Double.parseDouble(request.getParameter("minOrder"));
                    String vcMaxUses = request.getParameter("maxUses");
                    String durationValue = request.getParameter("durationValue");
                    String durationUnit = request.getParameter("durationUnit");
                    java.sql.Timestamp expiryTs = null;
                    if (durationValue != null && !durationValue.isEmpty() && durationUnit != null && !durationUnit.isEmpty()) {
                        int dVal = Integer.parseInt(durationValue);
                        long millis = System.currentTimeMillis();
                        if ("hours".equals(durationUnit)) millis += (long) dVal * 3600 * 1000;
                        else if ("days".equals(durationUnit)) millis += (long) dVal * 86400 * 1000;
                        else if ("weeks".equals(durationUnit)) millis += (long) dVal * 7 * 86400 * 1000;
                        expiryTs = new java.sql.Timestamp(millis);
                    }
                    PreparedStatement vcPs = conn.prepareStatement(
                        "UPDATE vouchers SET code=?, type=?, value=?, min_order=?, max_uses=?, expiry_date=? WHERE voucher_id=?");
                    vcPs.setString(1, vcCode);
                    vcPs.setString(2, vcType);
                    vcPs.setDouble(3, vcValue);
                    vcPs.setDouble(4, vcMinOrder);
                    vcPs.setObject(5, (vcMaxUses != null && !vcMaxUses.isEmpty()) ? Integer.parseInt(vcMaxUses) : null);
                    vcPs.setObject(6, expiryTs);
                    vcPs.setInt(7, vcId);
                    vcPs.executeUpdate(); vcPs.close();
                    out.print("{\"success\":true,\"message\":\"Voucher updated!\"}");
                    break;
                }
                case "deleteVoucher": {
                    int vcId = Integer.parseInt(request.getParameter("voucherId"));
                    PreparedStatement vcPs = conn.prepareStatement("DELETE FROM vouchers WHERE voucher_id=?");
                    vcPs.setInt(1, vcId);
                    vcPs.executeUpdate(); vcPs.close();
                    out.print("{\"success\":true,\"message\":\"Voucher deleted.\"}");
                    break;
                }
                case "deactivateVoucher": {
                    int vcId = Integer.parseInt(request.getParameter("voucherId"));
                    PreparedStatement vcPs = conn.prepareStatement("UPDATE vouchers SET is_active=0 WHERE voucher_id=?");
                    vcPs.setInt(1, vcId);
                    vcPs.executeUpdate(); vcPs.close();
                    out.print("{\"success\":true,\"message\":\"Voucher deactivated.\"}");
                    break;
                }
                case "activateVoucher": {
                    int vcId = Integer.parseInt(request.getParameter("voucherId"));
                    PreparedStatement vcPs = conn.prepareStatement("UPDATE vouchers SET is_active=1 WHERE voucher_id=?");
                    vcPs.setInt(1, vcId);
                    vcPs.executeUpdate(); vcPs.close();
                    out.print("{\"success\":true,\"message\":\"Voucher activated.\"}");
                    break;
                }
                default:
                    out.print("{\"success\":false,\"message\":\"Unknown action\"}");
                    break;
            }

            conn.close();

        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\":false,\"message\":\"Server error: " + e.getMessage() + "\"}");
        }
    }

    // Also handle GET (for direct URL access)
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doPost(request, response);
    }
}