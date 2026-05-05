package com.shopeasy;

import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/RemoveAllCartServlet")
public class RemoveAllCartServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        if (session.getAttribute("userId") == null) {
            response.sendRedirect("index.jsp");
            return;
        }
        int customerId = (int) session.getAttribute("userId");
        try {
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(
                "DELETE FROM cartitem WHERE cart_id IN (SELECT cart_id FROM cart WHERE customer_id = ?)");
            ps.setInt(1, customerId);
            ps.executeUpdate();
            ps.close();
            conn.close();
            session.setAttribute("cartCount", 0);
        } catch (Exception e) {
            e.printStackTrace();
        }
        response.sendRedirect("CartServlet");
    }
}