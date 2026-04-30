package com.shopeasy;
import java.sql.ResultSet;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/RegisterServlet")
public class RegisterServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String fullname = request.getParameter("fullname");
        String username = request.getParameter("username");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String password = request.getParameter("password");
        String accountType = request.getParameter("accountType");

        String businessName = request.getParameter("businessName");
        String businessAddress = request.getParameter("businessAddress");

        try {
            Connection conn = DBConnection.getConnection();
            HttpSession session = request.getSession();

            if (accountType.equals("customer")) {
                String sql = "INSERT INTO customer (name, email, password, address, phone, username) VALUES (?, ?, ?, ?, ?, ?)";
                PreparedStatement ps = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS);
                ps.setString(1, fullname);
                ps.setString(2, email);
                ps.setString(3, password);
                ps.setString(4, "");
                ps.setString(5, phone);
                ps.setString(6, username);
                ps.executeUpdate();

                ResultSet generatedKeys = ps.getGeneratedKeys();
                if (generatedKeys.next()) {
                    session.setAttribute("userId", generatedKeys.getInt(1));
                }
                ps.close();

                session.setAttribute("userName", fullname);
                session.setAttribute("userEmail", email);
                session.setAttribute("userPhone", phone);
                session.setAttribute("userUsername", username);
                session.setAttribute("userRole", "customer");
                conn.close();
                response.sendRedirect("index.jsp?loggedin=true");

            } else {
                String businessType = request.getParameter("businessType");
                
                String sql = "INSERT INTO seller (name, username, email, password, address, phone, business_name, business_type) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
                PreparedStatement ps = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS);
                ps.setString(1, fullname);
                ps.setString(2, username);
                ps.setString(3, email);
                ps.setString(4, password);
                ps.setString(5, businessAddress != null ? businessAddress : "");
                ps.setString(6, phone);
                ps.setString(7, businessName != null ? businessName : "");
                ps.setString(8, businessType != null ? businessType : "");
                ps.executeUpdate();
                
                ResultSet generatedKeys = ps.getGeneratedKeys();
                if (generatedKeys.next()) {
                    session.setAttribute("userId", generatedKeys.getInt(1));
                }
                
                ps.close();
                session.setAttribute("userName", fullname);
                session.setAttribute("userEmail", email);
                session.setAttribute("userPhone", phone);
                session.setAttribute("userUsername", username);
                session.setAttribute("userBusinessName", businessName);
                session.setAttribute("userBusinessType", businessType);
                session.setAttribute("userRole", "seller");
                conn.close();
                response.sendRedirect("seller.jsp?loggedin=true");
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("index.jsp?error=true");
        }
    }
}