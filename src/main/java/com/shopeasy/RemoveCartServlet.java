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
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
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
            response.getWriter().write("ok");
        } catch (Exception e) {
            e.printStackTrace();
            response.getWriter().write("error");
        }
    }
}