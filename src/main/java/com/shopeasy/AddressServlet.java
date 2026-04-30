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

@WebServlet("/AddressServlet")
public class AddressServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        int userId = (int) session.getAttribute("userId");
        String action = request.getParameter("action");

        try {
            Connection conn = DBConnection.getConnection();

            if ("add".equals(action)) {
                String fullname = request.getParameter("fullname");
                String phone = request.getParameter("phone");
                String address = request.getParameter("address");
                boolean isDefault = "on".equals(request.getParameter("isDefault"));

                if (isDefault) {
                    PreparedStatement ps = conn.prepareStatement(
                        "UPDATE customer_address SET is_default=0 WHERE customer_id=?");
                    ps.setInt(1, userId);
                    ps.executeUpdate();
                    ps.close();
                }

                // Check if first address — auto set as default
                PreparedStatement countPs = conn.prepareStatement(
                    "SELECT COUNT(*) FROM customer_address WHERE customer_id=?");
                countPs.setInt(1, userId);
                ResultSet countRs = countPs.executeQuery();
                countRs.next();
                int count = countRs.getInt(1);
                countPs.close();

                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO customer_address (customer_id, full_name, phone, address, is_default) VALUES (?,?,?,?,?)");
                ps.setInt(1, userId);
                ps.setString(2, fullname);
                ps.setString(3, phone);
                ps.setString(4, address);
                ps.setInt(5, (isDefault || count == 0) ? 1 : 0);
                ps.executeUpdate();
                ps.close();

            } else if ("delete".equals(action)) {
                int addressId = Integer.parseInt(request.getParameter("addressId"));
                PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM customer_address WHERE address_id=? AND customer_id=?");
                ps.setInt(1, addressId);
                ps.setInt(2, userId);
                ps.executeUpdate();
                ps.close();

            } else if ("setDefault".equals(action)) {
                int addressId = Integer.parseInt(request.getParameter("addressId"));
                PreparedStatement ps = conn.prepareStatement(
                    "UPDATE customer_address SET is_default=0 WHERE customer_id=?");
                ps.setInt(1, userId);
                ps.executeUpdate();
                ps.close();

                ps = conn.prepareStatement(
                    "UPDATE customer_address SET is_default=1 WHERE address_id=? AND customer_id=?");
                ps.setInt(1, addressId);
                ps.setInt(2, userId);
                ps.executeUpdate();
                ps.close();

            } else if ("edit".equals(action)) {
                int addressId = Integer.parseInt(request.getParameter("addressId"));
                String fullname = request.getParameter("fullname");
                String phone = request.getParameter("phone");
                String address = request.getParameter("address");

                PreparedStatement ps = conn.prepareStatement(
                    "UPDATE customer_address SET full_name=?, phone=?, address=? WHERE address_id=? AND customer_id=?");
                ps.setString(1, fullname);
                ps.setString(2, phone);
                ps.setString(3, address);
                ps.setInt(4, addressId);
                ps.setInt(5, userId);
                ps.executeUpdate();
                
                ps.close();
            }

            conn.close();
            response.sendRedirect("customer.jsp?tab=address&msg=success");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("customer.jsp?tab=address&msg=error");
        }
    }
}