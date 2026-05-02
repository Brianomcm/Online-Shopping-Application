package com.shopeasy;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/CartServlet")
public class CartServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        Integer userId = (Integer) session.getAttribute("userId");
        String role = (String) session.getAttribute("userRole");

        if (userId == null || !"customer".equals(role)) {
            response.sendRedirect("index.jsp");
            return;
        }

        List<Map<String, Object>> cartItems = new ArrayList<>();
        double total = 0;

        try {
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(
                "SELECT ci.cartitem_id, ci.quantity, ci.variation_id, " +
                "p.product_id, p.name, p.price, p.image, p.stock, " +
                "pv.variation_type, pv.variation_value " +
                "FROM cart c " +
                "JOIN cartitem ci ON c.cart_id = ci.cart_id " +
                "JOIN product p ON ci.product_id = p.product_id " +
                "LEFT JOIN product_variation pv ON ci.variation_id = pv.variation_id " +
                "WHERE c.customer_id = ?");
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> item = new HashMap<>();
                item.put("cartitemId",      rs.getInt("cartitem_id"));
                item.put("productId",       rs.getInt("product_id"));
                item.put("name",            rs.getString("name"));
                item.put("price",           rs.getDouble("price"));
                item.put("image",           rs.getString("image"));
                item.put("stock",           rs.getInt("stock"));
                item.put("quantity",        rs.getInt("quantity"));
                item.put("subtotal",        rs.getDouble("price") * rs.getInt("quantity"));
                item.put("variationType",   rs.getString("variation_type"));   // null if no variation
                item.put("variationValue",  rs.getString("variation_value"));  // null if no variation
                total += rs.getDouble("price") * rs.getInt("quantity");
                cartItems.add(item);
            }
            rs.close();
            ps.close();
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }

        request.setAttribute("cartItems", cartItems);
        request.setAttribute("cartTotal", total);
        request.getRequestDispatcher("cart.jsp").forward(request, response);
    }
}