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

@WebServlet("/UpdateProfileServlet")
@MultipartConfig(maxFileSize = 5242880, maxRequestSize = 10485760)
public class UpdateProfileServlet extends HttpServlet {
	
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

    	HttpSession session = request.getSession();
    	int userId = (int) session.getAttribute("userId");

    	// Increase request buffer size for base64 images
    	response.setCharacterEncoding("UTF-8");
    	request.setCharacterEncoding("UTF-8");

    	String firstName = request.getParameter("first_name");
    	String lastName  = request.getParameter("last_name");
    	String middleInitial = request.getParameter("middle_initial");
    	if (firstName == null) firstName = (String) session.getAttribute("userFirstName");
    	if (lastName == null) lastName = (String) session.getAttribute("userLastName");
    	if (middleInitial == null) middleInitial = "";
    	String fullname = lastName + ", " + firstName + (middleInitial.isEmpty() ? "" : " " + middleInitial + ".");
        String username = request.getParameter("username");
        String phone = request.getParameter("phone");
        String birthday = request.getParameter("birthday");
        String gender = request.getParameter("gender");

        // Don't overwrite with null — keep existing session value if empty
        if (fullname == null || fullname.trim().isEmpty()) {
            fullname = (String) session.getAttribute("userName");
        }
        if (username == null || username.trim().isEmpty()) {
            username = (String) session.getAttribute("userUsername");
        }
        if (phone == null || phone.trim().isEmpty()) {
            phone = (String) session.getAttribute("userPhone");
        }

        try {
            Connection conn = DBConnection.getConnection();
            String profilePicture = request.getParameter("profilePicture");

         // Keep existing avatar if no new one uploaded
         if (profilePicture == null || profilePicture.isEmpty()) {
             profilePicture = (String) session.getAttribute("userAvatar");
         }

         String sql = "UPDATE customer SET name=?, first_name=?, last_name=?, middle_initial=?, username=?, phone=?, birthday=?, gender=?, profile_picture=? WHERE user_id=?";
         PreparedStatement ps = conn.prepareStatement(sql);
         ps.setString(1, fullname);
         ps.setString(2, firstName);
         ps.setString(3, lastName);
         ps.setString(4, middleInitial.isEmpty() ? null : middleInitial);
         ps.setString(5, username);
         ps.setString(6, phone);
         ps.setString(7, (birthday != null && !birthday.isEmpty()) ? birthday : null);
         ps.setString(8, (gender != null && !gender.isEmpty()) ? gender : null);
         ps.setString(9, profilePicture);
         ps.setInt(10, userId);
            ps.executeUpdate();
            ps.close();
            conn.close();

            session.setAttribute("userName", fullname);
            session.setAttribute("userUsername", username);
            session.setAttribute("userPhone", phone);
            session.setAttribute("userBirthday", birthday);
            // Set age status + lock birthday
            if (birthday == null || birthday.isEmpty()) {
                session.setAttribute("userAgeStatus", "no_birthday");
            } else {
                java.time.LocalDate dob = java.time.LocalDate.parse(birthday);
                int age = java.time.Period.between(dob, java.time.LocalDate.now()).getYears();
                if (age < 13) session.setAttribute("userAgeStatus", "too_young");
                else session.setAttribute("userAgeStatus", "ok");
                // Lock birthday (one-time only)
                Connection lockConn = DBConnection.getConnection();
                PreparedStatement lockPs = lockConn.prepareStatement(
                    "UPDATE customer SET birthday_locked=1 WHERE user_id=?");
                lockPs.setInt(1, userId);
                lockPs.executeUpdate();
                lockPs.close(); lockConn.close();
            }
            session.setAttribute("userGender", gender);
            if (profilePicture != null && !profilePicture.isEmpty()) {
                session.setAttribute("userAvatar", profilePicture);
            }
            session.setAttribute("userFirstName", firstName);
            session.setAttribute("userLastName", lastName);
            session.setAttribute("userMiddleInitial", middleInitial);
            response.sendRedirect("ProfileServlet?updated=true&msg=avatar");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("ProfileServlet?error=true");
        }
    }
}