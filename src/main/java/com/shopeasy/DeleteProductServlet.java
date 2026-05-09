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
   
        String delRole = (String) session.getAttribute("userRole");
        if (session.getAttribute("userId") == null || (!"seller".equals(delRole) && !"both".equals(delRole))) {
            response.sendRedirect("index.jsp");
            return;
        }
        String productId = request.getParameter("productId");
        try {
        	Connection conn = DBConnection.getConnection();

            // Delete related records first to avoid foreign key constraint errors
            String[] relatedTables = {
                "DELETE FROM product_variation WHERE product_id=?",
                "DELETE FROM cartitem WHERE product_id=?",
                "DELETE FROM wishlist WHERE product_id=?",
                "DELETE FROM review WHERE product_id=?",
                "DELETE FROM product WHERE product_id=?"
            };
            for (String sql : relatedTables) {
                try {
                    PreparedStatement rps = conn.prepareStatement(sql);
                    rps.setInt(1, Integer.parseInt(productId));
                    rps.executeUpdate();
                    rps.close();
                } catch (Exception ignored) {}
            }
            conn.close();
            response.sendRedirect("SellerProfileServlet?updated=true&msg=deleted&tab=products");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("SellerProfileServlet?error=true");
            
            
        }
    }
    
    
}