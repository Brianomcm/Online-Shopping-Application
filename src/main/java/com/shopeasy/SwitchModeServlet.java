package com.shopeasy;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/SwitchModeServlet")
public class SwitchModeServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        Integer userId = (Integer) session.getAttribute("userId");

        if (userId == null) {
            response.sendRedirect("index.jsp");
            return;
        }

        String currentMode = (String) session.getAttribute("activeMode");
        String userRole    = (String) session.getAttribute("userRole");

        // Only users with role 'both' or 'seller' can switch
        if (!"both".equals(userRole) && !"seller".equals(userRole)) {
            response.sendRedirect("index.jsp?error=norole");
            return;
        }

        String newMode;
        String redirectPage;

        if ("customer".equals(currentMode)) {
            newMode      = "seller";
            redirectPage = "seller.jsp";
        } else {
            newMode      = "customer";
            redirectPage = "index.jsp";
        }

        // Update active_mode in DB
        try {
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(
                "UPDATE users SET active_mode=? WHERE user_id=?");
            ps.setString(1, newMode);
            ps.setInt(2, userId);
            ps.executeUpdate();
            ps.close();
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }

        // Update session
        session.setAttribute("activeMode", newMode);
        // If switching to customer, make sure customer.jsp won't redirect back
        if ("customer".equals(newMode)) {
            session.setAttribute("userRole", session.getAttribute("userRole")); // keep role
        }
        response.sendRedirect(redirectPage);
    }
}