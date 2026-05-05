package com.shopeasy;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/RemoveCartServlet")
public class RemoveCartServlet extends HttpServlet {
    // Ginawa nating doGet para mas madaling tawagin mula sa link/button
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            int cartitemId = Integer.parseInt(request.getParameter("cartitemId"));
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(
                "DELETE FROM cartitem WHERE cartitem_id=?");
            ps.setInt(1, cartitemId);
            ps.executeUpdate();
            
            ps.close();
            conn.close();

            // ITO ANG PINAKAMAHALAGANG PALIT:
            // Imbes na "ok", ire-redirect natin siya sa CartServlet 
            // para ma-fetch ulit ang bagong listahan ng items.
            response.sendRedirect("CartServlet");

        } catch (Exception e) {
            e.printStackTrace();
            // Pag may error, pabalikin pa rin sa cart para makita ang result
            response.sendRedirect("CartServlet");
        }
    }

    // Para sigurado, tawagin din ang doGet kahit POST ang gamitin
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}