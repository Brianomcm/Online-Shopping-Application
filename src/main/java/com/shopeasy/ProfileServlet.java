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

@WebServlet("/ProfileServlet")
public class ProfileServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("index.html");
            return;
        }
        try {
            Connection conn = DBConnection.getConnection();
            String sql = "SELECT * FROM customer WHERE customer_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, (Integer) session.getAttribute("userId"));
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                session.setAttribute("userName", rs.getString("name"));
                session.setAttribute("userUsername", rs.getString("username"));
                session.setAttribute("userPhone", rs.getString("phone"));
                session.setAttribute("userBirthday", rs.getString("birthday"));
                session.setAttribute("userGender", rs.getString("gender"));
                String pic = rs.getString("profile_picture");
                if (pic != null && !pic.isEmpty()) {
                    session.setAttribute("userAvatar", pic);
                }
            }
            rs.close();
            ps.close();
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }

        String updated = request.getParameter("updated");
        String error = request.getParameter("error");

        if ("true".equals(updated)) {
            response.sendRedirect("customer.jsp?updated=true");
        } else if ("true".equals(error)) {
            response.sendRedirect("customer.jsp?error=true");
        } else {
            response.sendRedirect("customer.jsp");
        }
    }
}