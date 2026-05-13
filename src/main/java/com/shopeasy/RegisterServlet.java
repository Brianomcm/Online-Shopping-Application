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

@WebServlet("/RegisterServlet")
public class RegisterServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

    	String firstName = request.getParameter("first_name");
    	String lastName  = request.getParameter("last_name");
    	String middleInitial = request.getParameter("middle_initial");
    	if (middleInitial == null) middleInitial = "";
    	String fullname = lastName + ", " + firstName + (middleInitial.isEmpty() ? "" : " " + middleInitial + ".");
        String username  = request.getParameter("username");
        String email     = request.getParameter("email");
        String phone     = request.getParameter("phone");
        String password  = request.getParameter("password");

        try {
            Connection conn = DBConnection.getConnection();
            HttpSession session = request.getSession();

            // ── STEP 1: Insert into users table (always customer by default) ──
            String userSql = "INSERT INTO users (email, password, role, active_mode) VALUES (?, ?, 'customer', 'customer')";
            PreparedStatement userPs = conn.prepareStatement(userSql, PreparedStatement.RETURN_GENERATED_KEYS);
            userPs.setString(1, email);
            userPs.setString(2, password);
            userPs.executeUpdate();

            ResultSet userKeys = userPs.getGeneratedKeys();
            int userId = 0;
            if (userKeys.next()) userId = userKeys.getInt(1);
            userPs.close();

            // ── STEP 2: Insert into customer table ────────────────────────────
            String custSql = "INSERT INTO customer (user_id, name, first_name, last_name, middle_initial, email, password, address, phone, username) VALUES (?, ?, ?, ?, ?, ?, ?, '', ?, ?)";
            PreparedStatement custPs = conn.prepareStatement(custSql, PreparedStatement.RETURN_GENERATED_KEYS);
            custPs.setInt(1, userId);
            custPs.setString(2, fullname);
            custPs.setString(3, firstName);
            custPs.setString(4, lastName);
            custPs.setString(5, middleInitial.isEmpty() ? null : middleInitial);
            custPs.setString(6, email);
            custPs.setString(7, password);
            custPs.setString(8, phone);
            custPs.setString(9, username);
            custPs.executeUpdate();

            ResultSet custKeys = custPs.getGeneratedKeys();
            int customerId = 0;
            if (custKeys.next()) customerId = custKeys.getInt(1);
            custPs.close();
            conn.close();

            // ── STEP 3: Set session ───────────────────────────────────────────
            session.setAttribute("userId",      userId);
            session.setAttribute("customerId",  customerId);
            session.setAttribute("userName",       fullname);
            session.setAttribute("userFirstName",  firstName);
            session.setAttribute("userLastName",   lastName);
            session.setAttribute("userMiddleInitial", middleInitial);
            session.setAttribute("userEmail",      email);
            session.setAttribute("userPhone",   phone);
            session.setAttribute("userUsername",username);
            session.setAttribute("userRole",    "customer");
            session.setAttribute("activeMode",  "customer");

            response.sendRedirect("index.jsp?loggedin=true");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("index.jsp?error=true");
        }
    }
}