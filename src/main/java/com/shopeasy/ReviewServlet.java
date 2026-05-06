package com.shopeasy;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/ReviewServlet")
public class ReviewServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        if (session.getAttribute("userId") == null) {
            response.sendRedirect("index.jsp");
            return;
        }

        int customerId = (int) session.getAttribute("userId");

        String productIdParam = request.getParameter("productId");
        String orderIdParam = request.getParameter("orderId");
        String ratingParam = request.getParameter("rating");
        String comment = request.getParameter("comment");
        String reviewPhoto = request.getParameter("reviewPhoto");

        // Debug — print all params
        System.out.println("DEBUG productId=" + productIdParam);
        System.out.println("DEBUG orderId=" + orderIdParam);
        System.out.println("DEBUG rating=" + ratingParam);
        System.out.println("DEBUG comment=" + comment);

        if (productIdParam == null || orderIdParam == null || ratingParam == null) {
            response.setContentType("text/plain");
            response.getWriter().print("error: missing params - productId=" + productIdParam + " orderId=" + orderIdParam + " rating=" + ratingParam);
            return;
        }

        int productId = Integer.parseInt(productIdParam);
        int orderId = Integer.parseInt(orderIdParam);
        int rating = Integer.parseInt(ratingParam);

        try {
            Connection conn = DBConnection.getConnection();

         // Check if already reviewed for THIS specific order
            PreparedStatement checkPs = conn.prepareStatement(
                "SELECT review_id FROM review WHERE customer_id=? AND product_id=? AND order_id=?");
            checkPs.setInt(1, customerId);
            checkPs.setInt(2, productId);
            checkPs.setInt(3, orderId);
            ResultSet checkRs = checkPs.executeQuery();
            if (checkRs.next()) {
                checkRs.close(); checkPs.close(); conn.close();
                response.setContentType("text/plain");
                response.getWriter().print("already_reviewed");
                return;
            }
            checkRs.close(); checkPs.close();

            // Insert review
            PreparedStatement ps = conn.prepareStatement(
            	    "INSERT INTO review (customer_id, product_id, order_id, rating, comment, photo) " +
            	    "VALUES (?, ?, ?, ?, ?, ?)");
            	ps.setInt(1, customerId);
            	ps.setInt(2, productId);
            	ps.setInt(3, orderId);
            	ps.setInt(4, rating);
            	ps.setString(5, comment);
            	if (reviewPhoto != null && !reviewPhoto.isEmpty()) {
            	    ps.setString(6, reviewPhoto);
            	} else {
            	    ps.setNull(6, java.sql.Types.VARCHAR);
            	}
            	ps.executeUpdate();
                ps.close();

                // Notify seller
                PreparedStatement sellerPs = conn.prepareStatement(
                    "SELECT s.seller_id, c.name AS cname FROM product p " +
                    "JOIN seller s ON p.seller_id = s.seller_id " +
                    "JOIN customer c ON c.customer_id = ? " +
                    "WHERE p.product_id = ?");
                sellerPs.setInt(1, customerId);
                sellerPs.setInt(2, productId);
                ResultSet sellerRs = sellerPs.executeQuery();
                if (sellerRs.next()) {
                    int sellerId = sellerRs.getInt("seller_id");
                    String cname = sellerRs.getString("cname");
                    PreparedStatement notifPs = conn.prepareStatement(
                        "INSERT INTO notifications (user_id, user_type, message) VALUES (?, 'seller', ?)");
                    notifPs.setInt(1, sellerId);
                    notifPs.setString(2, cname + " left a " + rating + "-star review on your product!");
                    notifPs.executeUpdate();
                    notifPs.close();
                }
                sellerRs.close(); sellerPs.close();
                conn.close();

                response.setContentType("text/plain");
            response.getWriter().print("ok");
        } catch (Exception e) {
            e.printStackTrace();
            response.setContentType("text/plain");
            response.getWriter().print("error: " + e.getMessage());
        }
    }
}