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

@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email = request.getParameter("email");
        String password = request.getParameter("password");

        try {
            Connection conn = DBConnection.getConnection();

            // Check customer table first
            String sql = "SELECT * FROM customer WHERE email=? AND password=?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, email);
            ps.setString(2, password);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                HttpSession session = request.getSession();
                session.setAttribute("userId", rs.getInt("customer_id"));
                session.setAttribute("userName", rs.getString("name"));
                session.setAttribute("userEmail", rs.getString("email"));
                session.setAttribute("userPhone", rs.getString("phone"));
                session.setAttribute("userUsername", rs.getString("username"));
                session.setAttribute("userAvatar", rs.getString("profile_picture"));
                session.setAttribute("userBirthday", rs.getString("birthday"));
                session.setAttribute("userGender", rs.getString("gender"));
                session.setAttribute("userRole", "customer");

             // Transfer guest cart items to database
             String guestCartJson = request.getParameter("guestCart");
             if (guestCartJson != null && !guestCartJson.equals("[]") && !guestCartJson.isEmpty()) {
                 try {
                     int custId = rs.getInt("customer_id");
                     Connection cartConn = DBConnection.getConnection();
                     
                     // Get cart_id
                     PreparedStatement cartPs = cartConn.prepareStatement(
                         "SELECT cart_id FROM cart WHERE customer_id = ?");
                     cartPs.setInt(1, custId);
                     ResultSet cartRs = cartPs.executeQuery();
                     int cartId;
                     if (cartRs.next()) {
                         cartId = cartRs.getInt("cart_id");
                     } else {
                         PreparedStatement createCart = cartConn.prepareStatement(
                             "INSERT INTO cart (customer_id) VALUES (?)", 
                             PreparedStatement.RETURN_GENERATED_KEYS);
                         createCart.setInt(1, custId);
                         createCart.executeUpdate();
                         ResultSet keys = createCart.getGeneratedKeys();
                         keys.next();
                         cartId = keys.getInt(1);
                         createCart.close();
                     }
                     cartRs.close();
                     cartPs.close();

                     guestCartJson = guestCartJson.trim();
                     guestCartJson = guestCartJson.substring(1, guestCartJson.length() - 1);
                     if (!guestCartJson.isEmpty()) {
                         String[] items = guestCartJson.split("\\},\\{");
                         for (String item : items) {
                             item = item.replace("{", "").replace("}", "");
                             int productId = 0;
                             int qty = 1;
                             for (String part : item.split(",")) {
                                 if (part.contains("\"id\"")) {
                                     productId = Integer.parseInt(part.split(":")[1].trim());
                                 }
                                 if (part.contains("\"qty\"")) {
                                     qty = Integer.parseInt(part.split(":")[1].trim());
                                 }
                             }
                             if (productId > 0) {
                                 PreparedStatement checkPs = cartConn.prepareStatement(
                                     "SELECT cartitem_id FROM cartitem WHERE cart_id=? AND product_id=?");
                                 checkPs.setInt(1, cartId);
                                 checkPs.setInt(2, productId);
                                 ResultSet checkRs = checkPs.executeQuery();
                                 if (checkRs.next()) {
                                     PreparedStatement updatePs = cartConn.prepareStatement(
                                         "UPDATE cartitem SET quantity=quantity+? WHERE cartitem_id=?");
                                     updatePs.setInt(1, qty);
                                     updatePs.setInt(2, checkRs.getInt("cartitem_id"));
                                     updatePs.executeUpdate();
                                     updatePs.close();
                                 } else {
                                     PreparedStatement insertPs = cartConn.prepareStatement(
                                         "INSERT INTO cartitem (cart_id, product_id, quantity) VALUES (?,?,?)");
                                     insertPs.setInt(1, cartId);
                                     insertPs.setInt(2, productId);
                                     insertPs.setInt(3, qty);
                                     insertPs.executeUpdate();
                                     insertPs.close();
                                 }
                                 checkRs.close();
                                 checkPs.close();
                             }
                         }
                     }
                     cartConn.close();
                 } catch (Exception ex) {
                     ex.printStackTrace();
                 }
             }

             conn.close();
             response.sendRedirect("index.jsp?loggedin=true");
             return;
            }

            // Check seller table
            sql = "SELECT * FROM seller WHERE email=? AND password=?";
            ps = conn.prepareStatement(sql);
            ps.setString(1, email);
            ps.setString(2, password);
            rs = ps.executeQuery();

            if (rs.next()) {
                HttpSession session = request.getSession();
                session.setAttribute("userId", rs.getInt("seller_id"));
                session.setAttribute("userName", rs.getString("name"));
                session.setAttribute("userEmail", rs.getString("email"));
                session.setAttribute("userPhone", rs.getString("phone"));
                session.setAttribute("userUsername", rs.getString("username"));
                session.setAttribute("userAvatar", rs.getString("profile_picture"));
                session.setAttribute("userBirthday", rs.getString("birthday"));
                session.setAttribute("userGender", rs.getString("gender"));
                session.setAttribute("userBusinessName", rs.getString("business_name"));
                session.setAttribute("userBusinessType", rs.getString("business_type"));
                session.setAttribute("userShopDescription", rs.getString("shop_description"));
                session.setAttribute("userProfilePicture", rs.getString("profile_picture"));
                session.setAttribute("userBannerPicture", rs.getString("banner_picture"));
                session.setAttribute("userAddress", rs.getString("address"));
                session.setAttribute("userRole", "seller");
                conn.close();
                response.sendRedirect("SellerProfileServlet");
                return;
            }
            // Check admin table
            sql = "SELECT * FROM admin WHERE username=? AND password=?";
            ps = conn.prepareStatement(sql);
            ps.setString(1, email);
            ps.setString(2, password);
            rs = ps.executeQuery();

            if (rs.next()) {
                HttpSession session = request.getSession();
                session.setAttribute("userId", rs.getInt("admin_id"));
                session.setAttribute("userName", rs.getString("username"));
                session.setAttribute("userRole", "admin");
                conn.close();
                response.sendRedirect("index.jsp");
                return;
            }

            conn.close();
            response.sendRedirect("index.jsp?error=login");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("index.jsp?error=true");
        }
    }
}