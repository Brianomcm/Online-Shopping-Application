package com.shopeasy;

import java.io.*;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/EditReviewServlet")
public class EditReviewServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession();
        if (session.getAttribute("userId") == null) {
            out.print("{\"success\":false,\"message\":\"Not logged in\"}");
            return;
        }

        int customerId = (int) session.getAttribute("userId");
        String reviewIdParam = request.getParameter("reviewId");
        String ratingParam   = request.getParameter("rating");
        String comment       = request.getParameter("comment");
        String newPhoto      = request.getParameter("newPhoto");

        if (reviewIdParam == null || ratingParam == null) {
            out.print("{\"success\":false,\"message\":\"Missing data\"}");
            return;
        }

        try {
            int reviewId = Integer.parseInt(reviewIdParam);
            int rating   = Integer.parseInt(ratingParam);

            Connection conn = DBConnection.getConnection();

            // Verify ownership
            PreparedStatement checkPs = conn.prepareStatement(
                "SELECT review_id FROM review WHERE review_id=? AND customer_id=?");
            checkPs.setInt(1, reviewId);
            checkPs.setInt(2, customerId);
            ResultSet checkRs = checkPs.executeQuery();
            if (!checkRs.next()) {
                out.print("{\"success\":false,\"message\":\"Review not found\"}");
                checkRs.close(); checkPs.close(); conn.close();
                return;
            }
            checkRs.close(); checkPs.close();

            // Check 7-day edit window
            PreparedStatement datePs = conn.prepareStatement(
                "SELECT created_at FROM review WHERE review_id=?");
            datePs.setInt(1, reviewId);
            ResultSet dateRs = datePs.executeQuery();
            if (dateRs.next()) {
                java.sql.Timestamp createdAt = dateRs.getTimestamp("created_at");
                long daysSince = (System.currentTimeMillis() - createdAt.getTime()) / (1000 * 60 * 60 * 24);
                if (daysSince > 7) {
                    out.print("{\"success\":false,\"message\":\"Edit period has expired (7 days only)\"}");
                    dateRs.close(); datePs.close(); conn.close();
                    return;
                }
            }
            dateRs.close(); datePs.close();

         // Check if already edited
            PreparedStatement editCheckPs = conn.prepareStatement(
                "SELECT is_edited FROM review WHERE review_id=?");
            editCheckPs.setInt(1, reviewId);
            ResultSet editCheckRs = editCheckPs.executeQuery();
            if (editCheckRs.next() && editCheckRs.getInt("is_edited") == 1) {
                out.print("{\"success\":false,\"message\":\"You can only edit a review once.\"}");
                editCheckRs.close(); editCheckPs.close(); conn.close();
                return;
            }
            editCheckRs.close(); editCheckPs.close();

            if (newPhoto != null && !newPhoto.isEmpty()) {
                PreparedStatement updatePs = conn.prepareStatement(
                    "UPDATE review SET rating=?, comment=?, photo=?, is_edited=1 WHERE review_id=?");
                updatePs.setInt(1, rating);
                updatePs.setString(2, comment != null ? comment.trim() : "");
                updatePs.setString(3, newPhoto);
                updatePs.setInt(4, reviewId);
                updatePs.executeUpdate();
                updatePs.close();
            } else {
                PreparedStatement updatePs = conn.prepareStatement(
                    "UPDATE review SET rating=?, comment=?, is_edited=1 WHERE review_id=?");
                updatePs.setInt(1, rating);
                updatePs.setString(2, comment != null ? comment.trim() : "");
                updatePs.setInt(3, reviewId);
                updatePs.executeUpdate();
                updatePs.close();
            }

            conn.close();
            out.print("{\"success\":true}");

        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\":false,\"message\":\"" + e.getMessage() + "\"}");
        }
    }
}