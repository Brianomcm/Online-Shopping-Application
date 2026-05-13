package com.shopeasy;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/VoucherServlet")
public class VoucherServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession();
        if (session.getAttribute("userId") == null) {
            out.print("{\"success\":false,\"message\":\"Not logged in\"}");
            return;
        }

        String action = request.getParameter("action");
        String code = request.getParameter("code");
        double cartTotal = 0;
        try { cartTotal = Double.parseDouble(request.getParameter("cartTotal")); } catch (Exception ignored) {}

        if ("listAll".equals(action)) {
            try {
                Connection conn = DBConnection.getConnection();
                int userId = (int) session.getAttribute("userId");
                int customerId = (int) session.getAttribute("customerId");
                StringBuilder sb = new StringBuilder("{\"vouchers\":[");
                boolean first = true;

                // ── Platform vouchers ──
                PreparedStatement ps = conn.prepareStatement(
                    "SELECT *, 'platform' as source FROM vouchers WHERE is_active=1 ORDER BY created_at DESC");
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    if (!first) sb.append(",");
                    first = false;
                    String vCode = rs.getString("code");
                    String type = rs.getString("type");
                    double value = rs.getDouble("value");
                    double minOrder = rs.getDouble("min_order");
                    int maxUses = rs.getInt("max_uses");
                    int usedCount = rs.getInt("used_count");
                    String expiry = rs.getString("expiry_date");
                    int voucherId = rs.getInt("voucher_id");

                    boolean eligible = true;
                    String reason = "";
                    if (cartTotal < minOrder) { eligible = false; reason = "Min. order ₱" + String.format("%.0f", minOrder); }
                    if (maxUses > 0 && usedCount >= maxUses) { eligible = false; reason = "Max uses reached"; }
                    if (expiry != null) {
                        try {
                            java.sql.Timestamp expiryTs = java.sql.Timestamp.valueOf(expiry);
                            if (expiryTs.before(new java.util.Date())) { eligible = false; reason = "Expired"; }
                        } catch (Exception ignored) {}
                    }
                    PreparedStatement usedPs = conn.prepareStatement(
                        "SELECT id FROM voucher_usage WHERE voucher_id=? AND voucher_type='platform' AND user_id=?");
                    usedPs.setInt(1, voucherId); usedPs.setInt(2, userId);
                    ResultSet usedRs = usedPs.executeQuery();
                    if (usedRs.next()) { eligible = false; reason = "Already used"; }
                    usedRs.close(); usedPs.close();

                    boolean isFreeShip = "freeshipping".equals(type);
                    double discount = isFreeShip ? 38 : ("fixed".equals(type) ? value : Math.min(cartTotal, cartTotal * value / 100));
                    String desc = isFreeShip ? "Free Shipping 🚚" : "fixed".equals(type) ? "₱" + String.format("%.0f", value) + " off" : value + "% off your order";

                    sb.append("{\"code\":\"").append(vCode).append("\"")
                      .append(",\"type\":\"").append(type).append("\"")
                      .append(",\"value\":").append(value)
                      .append(",\"min_order\":").append(minOrder)
                      .append(",\"discount\":").append(discount)
                      .append(",\"description\":\"").append(desc).append("\"")
                      .append(",\"expiry\":").append(expiry != null ? "\"" + expiry + "\"" : "null")
                      .append(",\"eligible\":").append(eligible)
                      .append(",\"reason\":\"").append(reason).append("\"")
                      .append(",\"source\":\"platform\"")
                      .append("}");
                }
                rs.close(); ps.close();

                // ── Personal (welcome) vouchers ──
                PreparedStatement ps2 = conn.prepareStatement(
                    "SELECT * FROM customer_vouchers WHERE customer_id=? AND is_active=1 AND used_count < max_uses AND (expiry_date IS NULL OR expiry_date > NOW()) ORDER BY created_at DESC");
                ps2.setInt(1, customerId);
                ResultSet rs2 = ps2.executeQuery();
                while (rs2.next()) {
                    if (!first) sb.append(",");
                    first = false;
                    String vCode = rs2.getString("code");
                    String type = rs2.getString("type");
                    double value = rs2.getDouble("value");
                    double minOrder = rs2.getDouble("min_order");
                    String expiry = rs2.getString("expiry_date");
                    boolean eligible = cartTotal >= minOrder;
                    String reason = eligible ? "" : "Min. order ₱" + String.format("%.0f", minOrder);
                    double discount = "fixed".equals(type) ? value : cartTotal * value / 100;
                    String desc = "₱" + String.format("%.0f", value) + " off (Welcome Gift 🎁)";
                    sb.append("{\"code\":\"").append(vCode).append("\"")
                      .append(",\"type\":\"").append(type).append("\"")
                      .append(",\"value\":").append(value)
                      .append(",\"min_order\":").append(minOrder)
                      .append(",\"discount\":").append(discount)
                      .append(",\"description\":\"").append(desc).append("\"")
                      .append(",\"expiry\":").append(expiry != null ? "\"" + expiry + "\"" : "null")
                      .append(",\"eligible\":").append(eligible)
                      .append(",\"reason\":\"").append(reason).append("\"")
                      .append(",\"source\":\"personal\"")
                      .append("}");
                }
                rs2.close(); ps2.close();
                conn.close();
                sb.append("]}");
                out.print(sb.toString());
            } catch (Exception e) {
                e.printStackTrace();
                out.print("{\"vouchers\":[]}");
            }
            return;
        }
        
        if ("list".equals(action)) {
            try {
                Connection conn = DBConnection.getConnection();
                PreparedStatement ps = conn.prepareStatement(
                    "SELECT * FROM vouchers WHERE is_active=1 ORDER BY created_at DESC");
                ResultSet rs = ps.executeQuery();
                StringBuilder sb = new StringBuilder("{\"vouchers\":[");
                boolean first = true;
                int userId = (int) session.getAttribute("userId");
                while (rs.next()) {
                    if (!first) sb.append(",");
                    first = false;
                    String vCode = rs.getString("code");
                    String type = rs.getString("type");
                    double value = rs.getDouble("value");
                    double minOrder = rs.getDouble("min_order");
                    int maxUses = rs.getInt("max_uses");
                    int usedCount = rs.getInt("used_count");
                    String expiry = rs.getString("expiry_date");
                    int voucherId = rs.getInt("voucher_id");

                    // Check eligibility
                    boolean eligible = true;
                    String reason = "";
                    if (cartTotal < minOrder) { eligible = false; reason = "Min. order ₱" + String.format("%.0f", minOrder); }
                    if (maxUses > 0 && usedCount >= maxUses) { eligible = false; reason = "Max uses reached"; }
                    if (expiry != null) {
                        try {
                            java.sql.Date expiryDate = java.sql.Date.valueOf(expiry);
                            if (expiryDate.before(new java.util.Date())) { eligible = false; reason = "Expired"; }
                        } catch (Exception ignored) {}
                    }
                    // Check if user already used
                    PreparedStatement usedPs = conn.prepareStatement(
                        "SELECT id FROM voucher_usage WHERE voucher_id=? AND voucher_type='platform' AND user_id=?");
                    usedPs.setInt(1, voucherId); usedPs.setInt(2, userId);
                    ResultSet usedRs = usedPs.executeQuery();
                    if (usedRs.next()) { eligible = false; reason = "Already used"; }
                    usedRs.close(); usedPs.close();

                    double discount = "fixed".equals(type) ? value : Math.min(cartTotal, cartTotal * value / 100);
                    String desc = "fixed".equals(type) ? "₱" + String.format("%.0f", value) + " off" : value + "% off your order";

                    sb.append("{\"code\":\"").append(vCode).append("\"")
                      .append(",\"type\":\"").append(type).append("\"")
                      .append(",\"value\":").append(value)
                      .append(",\"min_order\":").append(minOrder)
                      .append(",\"discount\":").append(discount)
                      .append(",\"description\":\"").append(desc).append("\"")
                      .append(",\"expiry\":").append(expiry != null ? "\"" + expiry + "\"" : "null")
                      .append(",\"eligible\":").append(eligible)
                      .append(",\"reason\":\"").append(reason).append("\"")
                      .append("}");
                }
                sb.append("]}");
                rs.close(); ps.close(); conn.close();
                out.print(sb.toString());
            } catch (Exception e) {
                out.print("{\"vouchers\":[]}");
            }
            return;
        }
        
        
        if ("apply".equals(action)) {
            try {
                Connection conn = DBConnection.getConnection();
                PreparedStatement ps = conn.prepareStatement(
                    "SELECT * FROM vouchers WHERE code=? AND is_active=1");
                ps.setString(1, code.toUpperCase().trim());
                ResultSet rs = ps.executeQuery();

                if (!rs.next()) {
                    out.print("{\"success\":false,\"message\":\"Invalid or expired voucher code.\"}");
                    rs.close(); ps.close(); conn.close(); return;
                }

                // Check expiry
                java.sql.Date expiry = rs.getDate("expiry_date");
                if (expiry != null && expiry.before(new java.util.Date())) {
                    out.print("{\"success\":false,\"message\":\"This voucher has already expired.\"}");
                    rs.close(); ps.close(); conn.close(); return;
                }

                // Check max uses
                int maxUses = rs.getInt("max_uses");
                int usedCount = rs.getInt("used_count");
                if (maxUses > 0 && usedCount >= maxUses) {
                    out.print("{\"success\":false,\"message\":\"This voucher has reached its usage limit.\"}");
                    rs.close(); ps.close(); conn.close(); return;
                }

                // Check min order
                double minOrder = rs.getDouble("min_order");
                if (cartTotal < minOrder) {
                    out.print("{\"success\":false,\"message\":\"Minimum order of ₱" + String.format("%.2f", minOrder) + " required.\"}");
                    rs.close(); ps.close(); conn.close(); return;
                }

                // Check if user already used this voucher
                int userId = (int) session.getAttribute("userId");
                int voucherId = rs.getInt("voucher_id");
                PreparedStatement usedPs = conn.prepareStatement(
                    "SELECT id FROM voucher_usage WHERE voucher_id=? AND voucher_type='platform' AND user_id=?");
                usedPs.setInt(1, voucherId);
                usedPs.setInt(2, userId);
                ResultSet usedRs = usedPs.executeQuery();
                if (usedRs.next()) {
                    out.print("{\"success\":false,\"message\":\"You have already used this voucher.\"}");
                    usedRs.close(); usedPs.close(); rs.close(); ps.close(); conn.close(); return;
                }
                usedRs.close(); usedPs.close();

             // Compute discount
                String type = rs.getString("type");
                double value = rs.getDouble("value");
                boolean isFreeShipping = "freeshipping".equals(type);
                double discount = isFreeShipping ? 38 : ("fixed".equals(type) ? value : Math.min(cartTotal, cartTotal * value / 100));
                discount = Math.min(discount, cartTotal);

                rs.close(); ps.close(); conn.close();

                // Save to session
                session.setAttribute("appliedVoucherCode", code.toUpperCase().trim());
                session.setAttribute("appliedVoucherDiscount", isFreeShipping ? 0 : discount);
                session.setAttribute("appliedVoucherId", voucherId);
                session.setAttribute("appliedVoucherFreeShipping", isFreeShipping);

                String msg = isFreeShipping ? "Free Shipping applied!" : "Voucher applied! You save ₱" + String.format("%.2f", discount);
                out.print("{\"success\":true,\"message\":\"" + msg + "\",\"discount\":" + discount + ",\"freeshipping\":" + isFreeShipping + "}");

            } catch (Exception e) {
                e.printStackTrace();
                out.print("{\"success\":false,\"message\":\"Error applying voucher.\"}");
            }
        }
    }
}