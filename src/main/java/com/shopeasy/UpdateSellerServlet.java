package com.shopeasy;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/UpdateSellerServlet")
@MultipartConfig(maxFileSize = 5242880, maxRequestSize = 10485760)
public class UpdateSellerServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        int userId = (int) session.getAttribute("userId");

        response.setCharacterEncoding("UTF-8");
        request.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");

        try {
            Connection conn = DBConnection.getConnection();

            if ("profile".equals(action)) {
                String fullname = request.getParameter("fullname");
                String username = request.getParameter("username");
                String phone = request.getParameter("phone");
                String birthday = request.getParameter("birthday");
                String gender = request.getParameter("gender");
                String profilePicture = request.getParameter("profilePicture");

                if (fullname == null || fullname.trim().isEmpty())
                    fullname = (String) session.getAttribute("userName");
                if (username == null || username.trim().isEmpty())
                    username = (String) session.getAttribute("userUsername");
                if (phone == null || phone.trim().isEmpty())
                    phone = (String) session.getAttribute("userPhone");
                if (profilePicture == null || profilePicture.isEmpty())
                    profilePicture = (String) session.getAttribute("userProfilePicture");

                String sql = "UPDATE seller SET name=?, username=?, phone=?, birthday=?, gender=?, profile_picture=? WHERE seller_id=?";
                PreparedStatement ps = conn.prepareStatement(sql);
                ps.setString(1, fullname);
                ps.setString(2, username);
                ps.setString(3, phone);
                ps.setString(4, (birthday != null && !birthday.isEmpty()) ? birthday : null);
                ps.setString(5, (gender != null && !gender.isEmpty()) ? gender : null);
                ps.setString(6, profilePicture);
                ps.setInt(7, userId);
                ps.executeUpdate();
                ps.close();

                session.setAttribute("userName", fullname);
                session.setAttribute("userUsername", username);
                session.setAttribute("userPhone", phone);
                session.setAttribute("userBirthday", birthday);
                session.setAttribute("userGender", gender);
                if (profilePicture != null && !profilePicture.isEmpty()) {
                    session.setAttribute("userProfilePicture", profilePicture);
                }

            } else if ("shop".equals(action)) {
                String businessName = request.getParameter("businessName");
                String businessType = request.getParameter("businessType");
                String shopDescription = request.getParameter("shopDescription");
                String address = request.getParameter("address");

                if (businessName == null || businessName.trim().isEmpty())
                    businessName = (String) session.getAttribute("userBusinessName");
                if (address == null || address.trim().isEmpty())
                    address = (String) session.getAttribute("userAddress");

                String sql = "UPDATE seller SET business_name=?, business_type=?, shop_description=?, address=? WHERE seller_id=?";
                PreparedStatement ps = conn.prepareStatement(sql);
                ps.setString(1, businessName);
                ps.setString(2, businessType);
                ps.setString(3, shopDescription);
                ps.setString(4, address);
                ps.setInt(5, userId);
                ps.executeUpdate();
                ps.close();

                session.setAttribute("userBusinessName", businessName);
                session.setAttribute("userBusinessType", businessType);
                session.setAttribute("userShopDescription", shopDescription);
                session.setAttribute("userAddress", address);
            } else if ("avatar".equals(action)) {
                String profilePicture = request.getParameter("profilePicture");
                if (profilePicture != null && !profilePicture.isEmpty()) {
                    String sql = "UPDATE seller SET profile_picture=? WHERE seller_id=?";
                    PreparedStatement ps = conn.prepareStatement(sql);
                    ps.setString(1, profilePicture);
                    ps.setInt(2, userId);
                    ps.executeUpdate();
                    ps.close();
                    session.setAttribute("userProfilePicture", profilePicture);
                }
                conn.close();
                response.sendRedirect("SellerProfileServlet?updated=true&msg=avatar");
                return;
            } else if ("banner".equals(action)) {
                String bannerPicture = request.getParameter("bannerPicture");
                String removeBanner = request.getParameter("removeBanner");

                if ("true".equals(removeBanner)) {
                    bannerPicture = null;
                } else if (bannerPicture == null || bannerPicture.isEmpty()) {
                    bannerPicture = (String) session.getAttribute("userBannerPicture");
                }

                String sql = "UPDATE seller SET banner_picture=? WHERE seller_id=?";
                PreparedStatement ps = conn.prepareStatement(sql);
                ps.setString(1, bannerPicture);
                ps.setInt(2, userId);
                ps.executeUpdate();
                ps.close();

                if (bannerPicture != null && !bannerPicture.isEmpty()) {
                    session.setAttribute("userBannerPicture", bannerPicture);
                } else {
                    session.setAttribute("userBannerPicture", "");
                }

                conn.close();
                response.sendRedirect("SellerProfileServlet?updated=true&msg=banner");
                return;
            }

            conn.close();
            response.sendRedirect("SellerProfileServlet?updated=true&msg=" + action);

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("SellerProfileServlet?error=true");
        }
    }
}