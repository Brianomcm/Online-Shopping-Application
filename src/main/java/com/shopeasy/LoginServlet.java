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

        String email    = request.getParameter("email");
        String password = request.getParameter("password");

        try {
            Connection conn = DBConnection.getConnection();

            // -------------------------------------------------------
            // 1. Check users table first to get role and active_mode
            // -------------------------------------------------------
            String userSql = "SELECT u.* FROM users u LEFT JOIN customer c ON u.user_id = c.user_id WHERE (u.email=? OR c.username=?) AND u.password=?";
            PreparedStatement userPs = conn.prepareStatement(userSql);
            userPs.setString(1, email);
            userPs.setString(2, email);
            userPs.setString(3, password);

            ResultSet userRs = userPs.executeQuery();

            if (!userRs.next()) {
                conn.close();
                response.sendRedirect("index.jsp?error=login");
                return;
            }

         // Found in users table
            int    userId     = userRs.getInt("user_id");
            String role       = userRs.getString("role");       // customer / seller / both
            String activeMode = userRs.getString("active_mode"); // customer / seller

            // Safety: if role is customer-only, force activeMode to customer
            if ("customer".equals(role)) {
                activeMode = "customer";
            }
            // Safety: if activeMode is null, default to customer
            if (activeMode == null) {
                activeMode = "customer";
            }

         // Check if banned — store in session but still allow login
            String userStatus = userRs.getString("status");
            HttpSession session = request.getSession();
            session.setAttribute("userStatus", userStatus);

            session.setAttribute("userId",     userId);
            session.setAttribute("userRole",   role);
            session.setAttribute("activeMode", activeMode);

            // -------------------------------------------------------
            // 2. Always load customer profile (if exists)
            // -------------------------------------------------------
            String custSql = "SELECT * FROM customer WHERE user_id=?";
            PreparedStatement custPs = conn.prepareStatement(custSql);
            custPs.setInt(1, userId);
            ResultSet custRs = custPs.executeQuery();

            if (custRs.next()) {
        	    session.setAttribute("customerId",      custRs.getInt("customer_id"));
        	    session.setAttribute("userName",        custRs.getString("name"));
        	    session.setAttribute("userFirstName",   custRs.getString("first_name"));
        	    session.setAttribute("userLastName",    custRs.getString("last_name"));
        	    String _mi = custRs.getString("middle_initial");
        	    session.setAttribute("userMiddleInitial", _mi != null ? _mi : "");
        	    session.setAttribute("userEmail",       custRs.getString("email"));
        	    session.setAttribute("userPhone",       custRs.getString("phone"));
        	    session.setAttribute("userUsername",    custRs.getString("username"));
            String _custPic = custRs.getString("profile_picture");
                session.setAttribute("userAvatar", (_custPic != null && !_custPic.isEmpty()) ? _custPic : null);
                String _bday = custRs.getString("birthday");
                session.setAttribute("userBirthday", _bday);
                // Set age status
                if (_bday == null || _bday.isEmpty()) {
                    session.setAttribute("userAgeStatus", "no_birthday");
                } else {
                    java.time.LocalDate dob = java.time.LocalDate.parse(_bday);
                    int age = java.time.Period.between(dob, java.time.LocalDate.now()).getYears();
                    if (age < 13) session.setAttribute("userAgeStatus", "too_young");
                    else session.setAttribute("userAgeStatus", "ok");
                }
                session.setAttribute("userGender",      custRs.getString("gender"));
                session.setAttribute("userAddress",     custRs.getString("address"));
            }

            // -------------------------------------------------------
            // 3. Always load seller profile (if exists)
            // -------------------------------------------------------
            String sellSql = "SELECT * FROM seller WHERE user_id=?";
            PreparedStatement sellPs = conn.prepareStatement(sellSql);
            sellPs.setInt(1, userId);
            ResultSet sellRs = sellPs.executeQuery();

            if (sellRs.next()) {
                session.setAttribute("sellerId",            sellRs.getInt("seller_id"));
                session.setAttribute("userBusinessName",    sellRs.getString("business_name"));
                session.setAttribute("userBusinessType",    sellRs.getString("business_type"));
                session.setAttribute("userShopDescription", sellRs.getString("shop_description"));
                String _sellPic = sellRs.getString("profile_picture");
                session.setAttribute("userProfilePicture", (_sellPic != null && !_sellPic.isEmpty()) ? _sellPic : null);
                session.setAttribute("userBannerPicture",  sellRs.getString("banner_picture"));
                session.setAttribute("userShopLogo",       sellRs.getString("shop_logo"));
            }

            // -------------------------------------------------------
            // 4. Transfer guest cart (customer only)
            // -------------------------------------------------------
            String guestCartJson = request.getParameter("guestCart");
            Integer customerId = (Integer) session.getAttribute("customerId");
            if (customerId != null && guestCartJson != null
                    && !guestCartJson.equals("[]") && !guestCartJson.isEmpty()) {
                try {
                    PreparedStatement cartPs = conn.prepareStatement(
                        "SELECT cart_id FROM cart WHERE customer_id=?");
                    cartPs.setInt(1, customerId);
                    ResultSet cartRs = cartPs.executeQuery();
                    int cartId;
                    if (cartRs.next()) {
                        cartId = cartRs.getInt("cart_id");
                    } else {
                        PreparedStatement createCart = conn.prepareStatement(
                            "INSERT INTO cart (customer_id) VALUES (?)",
                            PreparedStatement.RETURN_GENERATED_KEYS);
                        createCart.setInt(1, customerId);
                        createCart.executeUpdate();
                        ResultSet keys = createCart.getGeneratedKeys();
                        keys.next();
                        cartId = keys.getInt(1);
                        createCart.close();
                    }
                    cartRs.close(); cartPs.close();

                    guestCartJson = guestCartJson.trim();
                    guestCartJson = guestCartJson.substring(1, guestCartJson.length() - 1);
                    if (!guestCartJson.isEmpty()) {
                        String[] items = guestCartJson.split("\\},\\{");
                        for (String item : items) {
                            item = item.replace("{", "").replace("}", "");
                            int productId = 0, qty = 1;
                            for (String part : item.split(",")) {
                                if (part.contains("\"id\""))
                                    productId = Integer.parseInt(part.split(":")[1].trim());
                                if (part.contains("\"qty\""))
                                    qty = Integer.parseInt(part.split(":")[1].trim());
                            }
                            if (productId > 0) {
                                // Check if product exists first
                                PreparedStatement prodCheck = conn.prepareStatement(
                                    "SELECT product_id FROM product WHERE product_id=?");
                                prodCheck.setInt(1, productId);
                                ResultSet prodRs = prodCheck.executeQuery();
                                if (!prodRs.next()) { prodRs.close(); prodCheck.close(); continue; }
                                prodRs.close(); prodCheck.close();
                                PreparedStatement checkPs = conn.prepareStatement(
                                    "SELECT cartitem_id FROM cartitem WHERE cart_id=? AND product_id=?");
                                checkPs.setInt(1, cartId); checkPs.setInt(2, productId);
                                ResultSet checkRs = checkPs.executeQuery();
                                if (checkRs.next()) {
                                    PreparedStatement upPs = conn.prepareStatement(
                                        "UPDATE cartitem SET quantity=quantity+? WHERE cartitem_id=?");
                                    upPs.setInt(1, qty); upPs.setInt(2, checkRs.getInt("cartitem_id"));
                                    upPs.executeUpdate(); upPs.close();
                                } else {
                                    PreparedStatement inPs = conn.prepareStatement(
                                        "INSERT INTO cartitem (cart_id, product_id, quantity) VALUES (?,?,?)");
                                    inPs.setInt(1, cartId); inPs.setInt(2, productId); inPs.setInt(3, qty);
                                    inPs.executeUpdate(); inPs.close();
                                }
                                checkRs.close(); checkPs.close();
                            }
                        }
                    }
                } catch (Exception ex) {
                    ex.printStackTrace();
                }
            }

            conn.close();

            // -------------------------------------------------------
            // 5. Redirect based on active_mode
            // -------------------------------------------------------
            if ("admin".equals(role)) {
                response.sendRedirect("admin.jsp");
            } else if ("seller".equals(activeMode)) {
                response.sendRedirect("seller.jsp");
            } else {
                response.sendRedirect("index.jsp?loggedin=true");
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("index.jsp?error=true");
        }
    }
}