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

@WebServlet("/DeleteProductServlet")
public class DeleteProductServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        if (session.getAttribute("userId") == null || !"seller".equals(session.getAttribute("userRole"))) {
            response.sendRedirect("index.jsp");
            return;
        }
        String productId = request.getParameter("productId");
        try {
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement("DELETE FROM product WHERE product_id=?");
            ps.setInt(1, Integer.parseInt(productId));
            ps.executeUpdate();
            ps.close();
            conn.close();
            response.sendRedirect("SellerProfileServlet?updated=true&msg=deleted&tab=products");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("SellerProfileServlet?error=true");
        }
    }
}