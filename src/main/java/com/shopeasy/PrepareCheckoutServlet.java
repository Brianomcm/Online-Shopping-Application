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

	protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        if (session.getAttribute("userId") == null) {
            response.sendRedirect("index.jsp");
            return;
        }

        int customerId = (int) session.getAttribute("userId");
        String productIdParam = request.getParameter("productId");
        if (productIdParam == null) { response.sendRedirect("index.jsp"); return; }
        int productId = Integer.parseInt(productIdParam);

        try {
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(
            		"SELECT ci.cartitem_id, ci.quantity, ci.variation_id, p.product_id, p.seller_id, p.name, p.price, p.original_price, p.stock, p.image " +
            				"FROM cartitem ci " +
            				"JOIN cart c ON ci.cart_id = c.cart_id " +
            				"JOIN product p ON ci.product_id = p.product_id " +
            				"WHERE c.customer_id = ? AND p.product_id = ? " +
                "ORDER BY ci.cartitem_id DESC LIMIT 1");
            ps.setInt(1, customerId);
            ps.setInt(2, productId);
            ResultSet rs = ps.executeQuery();

            List<Map<String, Object>> items = new ArrayList<>();
            double total = 0;

            if (rs.next()) {
                Map<String, Object> item = new HashMap<>();
                item.put("cartitemId", rs.getInt("cartitem_id"));
                item.put("productId", rs.getInt("product_id"));
                item.put("sellerId", rs.getInt("seller_id"));
                item.put("name", rs.getString("name"));
                item.put("name", rs.getString("name"));
                double getOrigPrice = rs.getDouble("original_price");
                double getRealPrice = rs.getDouble("price");
                double getUsePrice = (getOrigPrice > 0 && getOrigPrice < getRealPrice) ? getOrigPrice : getRealPrice;
                item.put("price", getRealPrice);
                item.put("originalPrice", getOrigPrice);
                item.put("quantity", rs.getInt("quantity"));
                item.put("stock", rs.getInt("stock"));
                item.put("image", rs.getString("image"));
                int varId = rs.getInt("variation_id");
                if (!rs.wasNull()) item.put("variationId", varId);
                double subtotal = getUsePrice * rs.getInt("quantity");
                item.put("subtotal", subtotal);
                total += subtotal;
                items.add(item);
            }
            rs.close(); ps.close(); conn.close();

            session.setAttribute("checkoutItems", items);
            session.setAttribute("checkoutTotal", total);
            response.sendRedirect("checkout.jsp");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("index.jsp");
        }
    }

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

            String sql = "SELECT ci.cartitem_id, ci.quantity, ci.variation_id, p.product_id, p.seller_id, p.name, p.price, p.original_price, p.stock, p.image " +
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
                double pcoOrigPrice = rs.getDouble("original_price");
                double pcoUsePrice = (pcoOrigPrice > 0 && pcoOrigPrice < rs.getDouble("price")) ? pcoOrigPrice : rs.getDouble("price");
                item.put("originalPrice", pcoOrigPrice);
                item.put("originalPrice", rs.getDouble("original_price"));
                item.put("quantity", rs.getInt("quantity"));
                item.put("stock", rs.getInt("stock"));
                item.put("image", rs.getString("image"));
                int varId = rs.getInt("variation_id");
                if (!rs.wasNull()) {
                    item.put("variationId", varId);
                }
                int qty = rs.getInt("quantity");
                if (qty <= 0) continue;
                double postOrigPrice = (Double) item.get("originalPrice");
                double postRealPrice = (Double) item.get("price");
                double postUsePrice = (postOrigPrice > 0 && postOrigPrice < postRealPrice) ? postOrigPrice : postRealPrice;
                double subtotal = postUsePrice * qty;
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