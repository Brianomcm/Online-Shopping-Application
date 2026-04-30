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

@WebServlet("/SellerProfileServlet")
public class SellerProfileServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();

        if (session.getAttribute("userId") == null || 
            !"seller".equals(session.getAttribute("userRole"))) {
            response.sendRedirect("index.jsp");
            return;
        }

        int userId = (int) session.getAttribute("userId");

        try {
            Connection conn = DBConnection.getConnection();
            String sql = "SELECT * FROM seller WHERE seller_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                session.setAttribute("userName", rs.getString("name"));
                session.setAttribute("userEmail", rs.getString("email"));
                session.setAttribute("userPhone", rs.getString("phone"));
                session.setAttribute("userUsername", rs.getString("username"));
                session.setAttribute("userBusinessName", rs.getString("business_name"));
                session.setAttribute("userBusinessType", rs.getString("business_type"));
                session.setAttribute("userShopDescription", rs.getString("shop_description"));
                session.setAttribute("userAddress", rs.getString("address"));
                session.setAttribute("userBirthday", rs.getString("birthday"));
                session.setAttribute("userGender", rs.getString("gender"));
                session.setAttribute("userProfilePicture", rs.getString("profile_picture"));
                session.setAttribute("userBannerPicture", rs.getString("banner_picture"));
            }
         // Fetch products
            java.util.List<java.util.Map<String, String>> products = new java.util.ArrayList<>();
            String productSql = "SELECT p.*, c.name as category_name FROM product p LEFT JOIN category c ON p.category_id = c.category_id WHERE p.seller_id = ?";
            PreparedStatement productPs = conn.prepareStatement(productSql);
            productPs.setInt(1, userId);
            ResultSet productRs = productPs.executeQuery();
            while (productRs.next()) {
                java.util.Map<String, String> product = new java.util.HashMap<>();
                product.put("product_id", productRs.getString("product_id"));
                product.put("name", productRs.getString("name"));
                product.put("description", productRs.getString("description"));
                product.put("price", productRs.getString("price"));
                product.put("stock", productRs.getString("stock"));
                product.put("image", productRs.getString("image"));
                product.put("category_name", productRs.getString("category_name"));
                product.put("status", productRs.getString("status"));
                products.add(product);
            }
            productRs.close();
            productPs.close();
            session.setAttribute("sellerProducts", products);
            
            rs.close();
            ps.close();
            conn.close();

            String updated = request.getParameter("updated");
            String error = request.getParameter("error");

            if ("true".equals(updated)) {
                response.sendRedirect("seller.jsp?updated=true");
            } else if ("true".equals(error)) {
                response.sendRedirect("seller.jsp?error=true");
            } else {
                response.sendRedirect("seller.jsp");
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("seller.jsp");
        }
    }
}