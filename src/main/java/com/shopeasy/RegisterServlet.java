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

         // ── CHECK: Duplicate phone ──
            PreparedStatement checkPhone = conn.prepareStatement("SELECT customer_id FROM customer WHERE phone = ?");
            checkPhone.setString(1, phone);
            ResultSet phoneRs = checkPhone.executeQuery();
            if (phoneRs.next()) {
                checkPhone.close(); conn.close();
                response.sendRedirect("index.jsp?error=phone_taken"
                        + "&fn=" + java.net.URLEncoder.encode(firstName, "UTF-8")
                        + "&ln=" + java.net.URLEncoder.encode(lastName, "UTF-8")
                        + "&mi=" + java.net.URLEncoder.encode(middleInitial, "UTF-8")
                        + "&un=" + java.net.URLEncoder.encode(username, "UTF-8")
                        + "&em=" + java.net.URLEncoder.encode(email, "UTF-8")
                        + "&ph=" + java.net.URLEncoder.encode(phone, "UTF-8"));
                return;
            }
            checkPhone.close();
            
            // ── CHECK: Duplicate email ──
            PreparedStatement checkEmail = conn.prepareStatement("SELECT user_id FROM users WHERE email = ?");
            checkEmail.setString(1, email);
            ResultSet emailRs = checkEmail.executeQuery();
            if (emailRs.next()) {
                checkEmail.close(); conn.close();
                response.sendRedirect("index.jsp?error=email_taken"
                        + "&fn=" + java.net.URLEncoder.encode(firstName, "UTF-8")
                        + "&ln=" + java.net.URLEncoder.encode(lastName, "UTF-8")
                        + "&mi=" + java.net.URLEncoder.encode(middleInitial, "UTF-8")
                        + "&un=" + java.net.URLEncoder.encode(username, "UTF-8")
                        + "&em=" + java.net.URLEncoder.encode(email, "UTF-8")
                        + "&ph=" + java.net.URLEncoder.encode(phone, "UTF-8"));
                return;
            }
            checkEmail.close();

            // ── CHECK: Duplicate username ──
            PreparedStatement checkUser = conn.prepareStatement("SELECT customer_id FROM customer WHERE username = ?");
            checkUser.setString(1, username);
            ResultSet userRs = checkUser.executeQuery();
            if (userRs.next()) {
                checkUser.close(); conn.close();
                response.sendRedirect("index.jsp?error=username_taken"
                    + "&fn=" + java.net.URLEncoder.encode(firstName, "UTF-8")
                    + "&ln=" + java.net.URLEncoder.encode(lastName, "UTF-8")
                    + "&mi=" + java.net.URLEncoder.encode(middleInitial, "UTF-8")
                    + "&em=" + java.net.URLEncoder.encode(email, "UTF-8")
                    + "&ph=" + java.net.URLEncoder.encode(phone, "UTF-8"));
                return;
            }
            checkUser.close();

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

         // ── STEP 4: Generate Welcome Voucher ──
            String welcomeCode = "WELCOME-" + Long.toHexString(System.currentTimeMillis()).toUpperCase().substring(0, 7);
            java.sql.Timestamp vcExpiry = new java.sql.Timestamp(System.currentTimeMillis() + 7L * 86400 * 1000);
            PreparedStatement vcPs = conn.prepareStatement(
                "INSERT INTO customer_vouchers (customer_id, code, type, value, min_order, max_uses, expiry_date) VALUES (?,?,?,?,?,?,?)");
            vcPs.setInt(1, customerId);
            vcPs.setString(2, welcomeCode);
            vcPs.setString(3, "fixed");
            vcPs.setDouble(4, 50);
            vcPs.setDouble(5, 150);
            vcPs.setInt(6, 1);
            vcPs.setTimestamp(7, vcExpiry);
            vcPs.executeUpdate();
            vcPs.close();
            conn.close();

            response.sendRedirect("index.jsp?loggedin=true&newuser=true");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("index.jsp?error=true");
        }
    }
}