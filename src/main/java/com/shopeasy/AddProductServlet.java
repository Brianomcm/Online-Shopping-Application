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

@WebServlet("/AddProductServlet")
public class AddProductServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();

        if (session.getAttribute("userId") == null || !"seller".equals(session.getAttribute("userRole"))) {
            response.sendRedirect("index.jsp");
            return;
        }

        int sellerId = (int) session.getAttribute("userId");

        String productName = request.getParameter("productName");
        String description = request.getParameter("description");
        String price = request.getParameter("price");
        String stock = request.getParameter("stock");
        String categoryId = request.getParameter("categoryId");
        String productImage = request.getParameter("productImage");

        try {
            Connection conn = DBConnection.getConnection();
            String sql = "INSERT INTO product (seller_id, category_id, name, description, price, stock, image, status) VALUES (?, ?, ?, ?, ?, ?, ?, 'active')";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, sellerId);
            ps.setInt(2, categoryId != null && !categoryId.isEmpty() ? Integer.parseInt(categoryId) : 1);
            ps.setString(3, productName);
            ps.setString(4, description);
            ps.setDouble(5, Double.parseDouble(price));
            ps.setInt(6, Integer.parseInt(stock));
            ps.setString(7, productImage != null && !productImage.isEmpty() ? productImage : null);
            ps.executeUpdate();
            ps.close();
            conn.close();

            response.sendRedirect("seller.jsp?updated=true&msg=product&tab=products");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("SellerProfileServlet?error=true");
        }
    }
}