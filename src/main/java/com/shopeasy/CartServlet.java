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

        if (userId == null || role == null || 
                (!role.equals("customer") && !role.equals("both"))) {
                response.sendRedirect("index.jsp");
                return;
            }

        List<Map<String, Object>> cartItems = new ArrayList<>();
        double total = 0;

        try {
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(
            		"SELECT ci.cartitem_id, ci.quantity, ci.variation_id, " +
            				"p.product_id, p.name, p.price, p.original_price, p.image, p.stock, " +
            				"pv.variation_type, pv.variation_value, pv.price as var_price, pv.original_price as var_original_price, " +
            		"s.seller_id, s.business_name " +
            		"FROM cart c " +
            		"JOIN cartitem ci ON c.cart_id = ci.cart_id " +
            		"JOIN product p ON ci.product_id = p.product_id " +
            		"LEFT JOIN product_variation pv ON pv.variation_id = (" +
            		"  SELECT pv2.variation_id FROM product_variation pv2 " +
            		"  WHERE pv2.product_id = p.product_id " +
            		"  AND pv2.variation_id = ci.variation_id " +
            		"  UNION " +
            		"  SELECT pv3.variation_id FROM product_variation pv3 " +
            		"  JOIN product_variation pv_old ON pv_old.variation_id = ci.variation_id " +
            		"  WHERE pv3.product_id = p.product_id " +
            		"  AND pv3.variation_type = pv_old.variation_type " +
            		"  AND pv3.variation_value = pv_old.variation_value " +
            		"  LIMIT 1) " +
            		"JOIN seller s ON p.seller_id = s.seller_id " +
            		"WHERE c.customer_id = ?");
            Integer customerId = (Integer) session.getAttribute("customerId");
            if (customerId == null) customerId = userId;
            ps.setInt(1, customerId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, Object> item = new HashMap<>();
                item.put("cartitemId",      rs.getInt("cartitem_id"));
                item.put("productId",       rs.getInt("product_id"));
                item.put("name",            rs.getString("name"));
                item.put("originalPrice",   rs.getDouble("original_price"));
                String cartImg = rs.getString("image");
                // Use variation image if available, else fallback to thumbnail
                if (rs.getString("variation_type") != null) {
                    try {
                        Connection imgConn = DBConnection.getConnection();
                        // Try variation image first
                        PreparedStatement imgPs = imgConn.prepareStatement(
                            "SELECT pv.image, p.thumbnail FROM product_variation pv " +
                            "JOIN product p ON pv.product_id = p.product_id " +
                            "WHERE pv.variation_id=? LIMIT 1");
                        imgPs.setInt(1, rs.getInt("variation_id"));
                        ResultSet imgRs = imgPs.executeQuery();
                        if (imgRs.next()) {
                            String varImg = imgRs.getString("image");
                            String thumbImg = imgRs.getString("thumbnail");
                            if (varImg != null && !varImg.isEmpty()) cartImg = varImg;
                            else if (thumbImg != null && !thumbImg.isEmpty()) cartImg = thumbImg;
                            // else keep main product image
                        }
                        imgRs.close(); imgPs.close(); imgConn.close();
                    } catch (Exception ignored) {}
                }
                item.put("image", cartImg);
                item.put("stock",           rs.getInt("stock"));
                item.put("quantity",        rs.getInt("quantity"));
                double basePrice = rs.getDouble("var_price") > 0 ? rs.getDouble("var_price") : rs.getDouble("price");
                double baseOriginal = rs.getDouble("var_original_price") > 0 ? rs.getDouble("var_original_price") : rs.getDouble("original_price");
                double cartUsePrice = (baseOriginal > 0 && baseOriginal < basePrice) ? baseOriginal : basePrice;
                item.put("price", basePrice);
                item.put("originalPrice", baseOriginal);
                item.put("subtotal", cartUsePrice * rs.getInt("quantity"));
                item.put("variationType",   rs.getString("variation_type"));
                item.put("variationValue",  rs.getString("variation_value"));
                item.put("sellerId",        rs.getInt("seller_id"));
                item.put("businessName",    rs.getString("business_name"));
                total += cartUsePrice * rs.getInt("quantity");
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