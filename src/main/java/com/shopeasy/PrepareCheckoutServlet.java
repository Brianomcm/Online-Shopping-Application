package com.shopeasy;

import java.io.IOException;
import java.io.PrintWriter;
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

@WebServlet("/PrepareCheckoutServlet")
public class PrepareCheckoutServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession();

        if (session.getAttribute("userId") == null) {
            out.print("{\"success\":false,\"message\":\"Not logged in\"}");
            return;
        }

        int customerId = (int) session.getAttribute("userId");

        try {
            Connection conn = DBConnection.getConnection();

            String sql = "SELECT ci.cartitem_id, ci.quantity, p.product_id, p.seller_id, p.name, p.price, p.stock, p.image " +
                    "FROM cartitem ci " +
                    "JOIN cart c ON ci.cart_id = c.cart_id " +
                    "JOIN product p ON ci.product_id = p.product_id " +
                    "WHERE c.customer_id = ?";

            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, customerId);
            ResultSet rs = ps.executeQuery();

            List<Map<String, Object>> items = new ArrayList<>();
            double total = 0;

            while (rs.next()) {
                Map<String, Object> item = new HashMap<>();
                item.put("cartitemId", rs.getInt("cartitem_id"));
                item.put("productId", rs.getInt("product_id"));
                item.put("sellerId", rs.getInt("seller_id"));
                item.put("name", rs.getString("name"));
                item.put("price", rs.getDouble("price"));
                item.put("quantity", rs.getInt("quantity"));
                item.put("stock", rs.getInt("stock"));
                item.put("image", rs.getString("image"));
                double subtotal = rs.getDouble("price") * rs.getInt("quantity");
                item.put("subtotal", subtotal);
                total += subtotal;
                items.add(item);
            }

            rs.close();
            ps.close();
            conn.close();

            if (items.isEmpty()) {
                out.print("{\"success\":false,\"message\":\"Your cart is empty!\"}");
                return;
            }

            session.setAttribute("checkoutItems", items);
            session.setAttribute("checkoutTotal", total);

            out.print("{\"success\":true}");

        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\":false,\"message\":\"" + e.getMessage() + "\"}");
        }
    }
}