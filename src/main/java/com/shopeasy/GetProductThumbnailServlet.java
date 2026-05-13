package com.shopeasy;

import java.io.*;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/GetProductThumbnailServlet")
public class GetProductThumbnailServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        String productId = request.getParameter("productId");
        String galleryParam = request.getParameter("gallery");
        boolean includeGallery = "true".equals(galleryParam);
        
        String thumbnail = "";
        StringBuilder galleryJson = new StringBuilder("[");
        
        try {
            Connection conn = DBConnection.getConnection();
            
            // Always get thumbnail
            PreparedStatement ps = conn.prepareStatement(
                "SELECT thumbnail FROM product WHERE product_id=?");
            ps.setInt(1, Integer.parseInt(productId));
            ResultSet rs = ps.executeQuery();
            if (rs.next() && rs.getString("thumbnail") != null)
                thumbnail = rs.getString("thumbnail");
            rs.close(); ps.close();
            
            // Get gallery images if requested
            if (includeGallery) {
                PreparedStatement galPs = conn.prepareStatement(
                    "SELECT image FROM product_gallery WHERE product_id=? ORDER BY sort_order ASC");
                galPs.setInt(1, Integer.parseInt(productId));
                ResultSet galRs = galPs.executeQuery();
                boolean first = true;
                while (galRs.next()) {
                    String img = galRs.getString("image");
                    if (img != null && !img.isEmpty()) {
                        if (!first) galleryJson.append(",");
                        galleryJson.append("\"")
                            .append(img.replace("\\", "\\\\")
                                      .replace("\"", "\\\"")
                                      .replace("\n", "")
                                      .replace("\r", ""))
                            .append("\"");
                        first = false;
                    }
                }
                galRs.close(); galPs.close();
            }
            conn.close();
        } catch (Exception e) { e.printStackTrace(); }
        
        galleryJson.append("]");
        
        String thumbEscaped = thumbnail.replace("\\", "\\\\")
                                       .replace("\"", "\\\"")
                                       .replace("\n", "")
                                       .replace("\r", "");
        
        response.getWriter().print(
            "{\"thumbnail\":\"" + thumbEscaped + "\"" +
            (includeGallery ? ",\"gallery\":" + galleryJson.toString() : "") +
            "}"
        );
        
    }
}