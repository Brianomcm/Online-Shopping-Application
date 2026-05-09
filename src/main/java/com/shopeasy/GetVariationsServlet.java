package com.shopeasy;

import java.io.*;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/GetVariationsServlet")
public class GetVariationsServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        String productId = request.getParameter("productId");
        if (productId == null) { out.print("[]"); return; }

        try {
            Connection conn = DBConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(
                    "SELECT variation_id, variation_type, variation_value, price, original_price, stock, image " +
                    "FROM product_variation WHERE product_id=? ORDER BY variation_id");
            ps.setInt(1, Integer.parseInt(productId));
            ResultSet rs = ps.executeQuery();

            StringBuilder json = new StringBuilder("[");
            boolean first = true;
            while (rs.next()) {
                if (!first) json.append(",");
                json.append("{")
                    .append("\"id\":").append(rs.getInt("variation_id")).append(",")
                    .append("\"type\":\"").append(rs.getString("variation_type")).append("\",")
                    .append("\"value\":\"").append(rs.getString("variation_value").replace("\"","\\\"")).append("\",")
                    .append("\"price\":").append(rs.getObject("price") != null ? rs.getDouble("price") : "null").append(",")
                    .append("\"originalPrice\":").append(rs.getObject("original_price") != null ? rs.getDouble("original_price") : "null").append(",")
                    .append("\"stock\":").append(rs.getObject("stock") != null ? rs.getInt("stock") : "null").append(",")
                    .append("\"image\":").append(rs.getString("image") != null ? "\"" + rs.getString("image").replace("\"","\\\"") + "\"" : "null")
                    .append("}");
                first = false;
            }
            json.append("]");
            rs.close(); ps.close(); conn.close();
            out.print(json.toString());
        } catch (Exception e) {
            e.printStackTrace();
            out.print("[]");
        }
    }
}