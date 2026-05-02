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

@WebServlet("/WishlistServlet")
public class WishlistServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        HttpSession session = request.getSession();
        if (session.getAttribute("userId") == null) {
            out.print("{\"wishlisted\":false}");
            return;
        }
        int customerId = (int) session.getAttribute("userId");
        int productId = Integer.parseInt(request.getParameter("check"));
        try {
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(
                "SELECT wishlist_id FROM wishlist WHERE customer_id=? AND product_id=?");
            ps.setInt(1, customerId);
            ps.setInt(2, productId);
            ResultSet rs = ps.executeQuery();
            boolean wishlisted = rs.next();
            rs.close(); ps.close(); conn.close();
            out.print("{\"wishlisted\":" + wishlisted + "}");
        } catch (Exception e) {
            out.print("{\"wishlisted\":false}");
        }
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        HttpSession session = request.getSession();
        if (session.getAttribute("userId") == null) {
            out.print("{\"success\":false}");
            return;
        }
        int customerId = (int) session.getAttribute("userId");
        String productIdParam = request.getParameter("productId");
        String action = request.getParameter("action");
        int productId = Integer.parseInt(productIdParam);

        try {
            Connection conn = DBConnection.getConnection();

            // If action=remove (from customer.jsp button)
            if ("remove".equals(action)) {
                PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM wishlist WHERE customer_id=? AND product_id=?");
                ps.setInt(1, customerId);
                ps.setInt(2, productId);
                ps.executeUpdate();
                ps.close(); conn.close();
                response.sendRedirect("customer.jsp?tab=wishlist");
                return;
            }

            // Toggle from product page
            PreparedStatement checkPs = conn.prepareStatement(
                "SELECT wishlist_id FROM wishlist WHERE customer_id=? AND product_id=?");
            checkPs.setInt(1, customerId);
            checkPs.setInt(2, productId);
            ResultSet rs = checkPs.executeQuery();
            if (rs.next()) {
                // Remove
                rs.close(); checkPs.close();
                PreparedStatement delPs = conn.prepareStatement(
                    "DELETE FROM wishlist WHERE customer_id=? AND product_id=?");
                delPs.setInt(1, customerId);
                delPs.setInt(2, productId);
                delPs.executeUpdate();
                delPs.close();
                conn.close();
                out.print("{\"success\":true,\"action\":\"removed\"}");
            } else {
                // Add
                rs.close(); checkPs.close();
                PreparedStatement insPs = conn.prepareStatement(
                    "INSERT INTO wishlist (customer_id, product_id) VALUES (?,?)");
                insPs.setInt(1, customerId);
                insPs.setInt(2, productId);
                insPs.executeUpdate();
                insPs.close();
                conn.close();
                out.print("{\"success\":true,\"action\":\"added\"}");
            }
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\":false}");
        }
    }
}