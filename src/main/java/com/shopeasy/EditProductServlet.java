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

@WebServlet("/EditProductServlet")
public class EditProductServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        if (session.getAttribute("userId") == null || !"seller".equals(session.getAttribute("userRole"))) {
            response.sendRedirect("index.jsp");
            return;
        }
        String productId    = request.getParameter("productId");
        String productName  = request.getParameter("productName");
        String price        = request.getParameter("price");
        String stock        = request.getParameter("stock");
        String description  = request.getParameter("description");

        // Variation arrays
        String[] varIds     = request.getParameterValues("editVarId[]");
        String[] varTypes   = request.getParameterValues("editVarType[]");
        String[] varValues  = request.getParameterValues("editVarValue[]");

        try {
            Connection conn = DBConnection.getConnection();

            // 1. Update product basic info
            PreparedStatement ps = conn.prepareStatement(
                "UPDATE product SET name=?, price=?, stock=?, description=? WHERE product_id=?");
            ps.setString(1, productName);
            ps.setDouble(2, Double.parseDouble(price));
            ps.setInt(3, Integer.parseInt(stock));
            ps.setString(4, description);
            ps.setInt(5, Integer.parseInt(productId));
            ps.executeUpdate();
            ps.close();

            // 2. Delete all old variations then re-insert
            PreparedStatement delPs = conn.prepareStatement(
                "DELETE FROM product_variation WHERE product_id=?");
            delPs.setInt(1, Integer.parseInt(productId));
            delPs.executeUpdate();
            delPs.close();

            // 3. Insert updated variations
            if (varTypes != null && varValues != null) {
                PreparedStatement varPs = conn.prepareStatement(
                    "INSERT INTO product_variation (product_id, variation_type, variation_value) VALUES (?,?,?)");
                for (int i = 0; i < varTypes.length; i++) {
                    String t = varTypes[i];
                    String v = (i < varValues.length) ? varValues[i] : "";
                    if (t != null && !t.trim().isEmpty() && v != null && !v.trim().isEmpty()) {
                        varPs.setInt(1, Integer.parseInt(productId));
                        varPs.setString(2, t.trim());
                        varPs.setString(3, v.trim());
                        varPs.addBatch();
                    }
                }
                varPs.executeBatch();
                varPs.close();
            }

            conn.close();
            response.sendRedirect("SellerProfileServlet?updated=true&msg=product&tab=products");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("SellerProfileServlet?error=true");
        }
    }
}