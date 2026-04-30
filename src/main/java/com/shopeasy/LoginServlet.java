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

@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email = request.getParameter("email");
        String password = request.getParameter("password");

        try {
            Connection conn = DBConnection.getConnection();

            // Check customer table first
            String sql = "SELECT * FROM customer WHERE email=? AND password=?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, email);
            ps.setString(2, password);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                HttpSession session = request.getSession();
                session.setAttribute("userId", rs.getInt("customer_id"));
                session.setAttribute("userName", rs.getString("name"));
                session.setAttribute("userEmail", rs.getString("email"));
                session.setAttribute("userPhone", rs.getString("phone"));
                session.setAttribute("userUsername", rs.getString("username"));
                session.setAttribute("userAvatar", rs.getString("profile_picture"));
                session.setAttribute("userBirthday", rs.getString("birthday"));
                session.setAttribute("userGender", rs.getString("gender"));
                session.setAttribute("userRole", "customer");
                conn.close();
                response.sendRedirect("index.jsp?loggedin=true");
                return;
            }

            // Check seller table
            sql = "SELECT * FROM seller WHERE email=? AND password=?";
            ps = conn.prepareStatement(sql);
            ps.setString(1, email);
            ps.setString(2, password);
            rs = ps.executeQuery();

            if (rs.next()) {
                HttpSession session = request.getSession();
                session.setAttribute("userId", rs.getInt("seller_id"));
                session.setAttribute("userName", rs.getString("name"));
                session.setAttribute("userEmail", rs.getString("email"));
                session.setAttribute("userPhone", rs.getString("phone"));
                session.setAttribute("userUsername", rs.getString("username"));
                session.setAttribute("userAvatar", rs.getString("profile_picture"));
                session.setAttribute("userBirthday", rs.getString("birthday"));
                session.setAttribute("userGender", rs.getString("gender"));
                session.setAttribute("userBusinessName", rs.getString("business_name"));
                session.setAttribute("userBusinessType", rs.getString("business_type"));
                session.setAttribute("userShopDescription", rs.getString("shop_description"));
                session.setAttribute("userProfilePicture", rs.getString("profile_picture"));
                session.setAttribute("userBannerPicture", rs.getString("banner_picture"));
                session.setAttribute("userAddress", rs.getString("address"));
                session.setAttribute("userRole", "seller");
                conn.close();
                response.sendRedirect("SellerProfileServlet");
                return;
            }
            // Check admin table
            sql = "SELECT * FROM admin WHERE username=? AND password=?";
            ps = conn.prepareStatement(sql);
            ps.setString(1, email);
            ps.setString(2, password);
            rs = ps.executeQuery();

            if (rs.next()) {
                HttpSession session = request.getSession();
                session.setAttribute("userId", rs.getInt("admin_id"));
                session.setAttribute("userName", rs.getString("username"));
                session.setAttribute("userRole", "admin");
                conn.close();
                response.sendRedirect("index.jsp");
                return;
            }

            conn.close();
            response.sendRedirect("index.jsp?error=login");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("index.jsp?error=true");
        }
    }
}