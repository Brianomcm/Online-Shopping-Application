package com.shopeasy;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.List;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/CheckoutServlet")
public class CheckoutServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession();

        if (session.getAttribute("userId") == null) {
            out.print("{\"success\":false,\"message\":\"Not logged in\"}");
            return;
        }

        Integer customerId = (Integer) session.getAttribute("customerId");
        if (customerId == null) customerId = (int) session.getAttribute("userId");
        String shipName = request.getParameter("shipName");
        String shipAddress = request.getParameter("shipAddress");
        String shipPhone = request.getParameter("shipPhone");
        String paymentMethod = request.getParameter("paymentMethod");

        String isBuyNowParam = request.getParameter("isBuyNow");
        boolean isBuyNow = "true".equals(isBuyNowParam);

        List<Map<String, Object>> cartItems;
        Double cartTotal;

        if (isBuyNow) {
            cartItems = (List<Map<String, Object>>) session.getAttribute("buyNowItems");
            cartTotal = (Double) session.getAttribute("buyNowTotal");
        } else {
            cartItems = (List<Map<String, Object>>) session.getAttribute("checkoutItems");
            cartTotal = (Double) session.getAttribute("checkoutTotal");
        }

        if (cartItems == null || cartItems.isEmpty()) {
            out.print("{\"success\":false,\"message\":\"Cart is empty\"}");
            return;
        }

        try {
            Connection conn = DBConnection.getConnection();
         // SERVER-SIDE STOCK VALIDATION
            for (Map<String, Object> item : cartItems) {
                int productId = (Integer) item.get("productId");
                int requestedQty = (Integer) item.get("quantity");
                
                PreparedStatement stockCheckPs = conn.prepareStatement(
                    "SELECT stock, name FROM product WHERE product_id=?");
                stockCheckPs.setInt(1, productId);
                ResultSet stockRs = stockCheckPs.executeQuery();
                
                if (stockRs.next()) {
                    int availableStock = stockRs.getInt("stock");
                    String productName = stockRs.getString("name");
                    if (availableStock < requestedQty) {
                        stockRs.close(); stockCheckPs.close(); conn.close();
                        out.print("{\"success\":false,\"message\":\"Sorry, '" + 
                            productName + "' only has " + availableStock + " left in stock!\"}");
                        return;
                    }
                }
                stockRs.close(); stockCheckPs.close();
            }

            // Insert into orders table
            String fullAddress = shipName + " | " + shipPhone + " | " + shipAddress;
            String initialStatus = "Pending";
            double walletDeduct = 0;
            try { walletDeduct = Double.parseDouble(request.getParameter("walletDeduct")); } catch (Exception ignored) {}

            // Voucher discount from session
            double voucherDiscount = 0;
            String appliedVoucherCode = (String) session.getAttribute("appliedVoucherCode");
            if (appliedVoucherCode != null) {
                Object vd = session.getAttribute("appliedVoucherDiscount");
                if (vd != null) voucherDiscount = (Double) vd;
            }

         // Group items by seller
            java.util.LinkedHashMap<Integer, List<Map<String, Object>>> itemsBySeller = new java.util.LinkedHashMap<>();
            for (Map<String, Object> item : cartItems) {
                int sid = (Integer) item.get("sellerId");
                itemsBySeller.computeIfAbsent(sid, k -> new java.util.ArrayList<>()).add(item);
            }

            // Distribute voucher discount proportionally across sellers
            double shippingFee = cartTotal >= 500 ? 0 : 38;
            double totalDiscount = walletDeduct + voucherDiscount;

            int lastOrderId = 0;
            java.util.List<Integer> allOrderIds = new java.util.ArrayList<>();

            String orderSql = "INSERT INTO orders (customer_id, total_amount, status, payment_method, shipping_address) VALUES (?, ?, ?, ?, ?)";
            String itemSql = "INSERT INTO order_items (order_id, product_id, seller_id, quantity, price, discounted_price, subtotal, variation_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

            for (Map.Entry<Integer, List<Map<String, Object>>> entry : itemsBySeller.entrySet()) {
                List<Map<String, Object>> sellerItems = entry.getValue();

                // Compute this seller's subtotal
                double sellerSubtotal = 0;
                for (Map<String, Object> item : sellerItems) {
                    sellerSubtotal += (Double) item.get("subtotal");
                }

                // Proportional discount for this seller
                double sellerDiscount = (cartTotal > 0) ? (sellerSubtotal / cartTotal) * totalDiscount : 0;
                double sellerShipping = sellerSubtotal >= 500 ? 0 : 38;
                double sellerFinal = Math.max(0, sellerSubtotal + sellerShipping - sellerDiscount);

                PreparedStatement orderPs = conn.prepareStatement(orderSql, PreparedStatement.RETURN_GENERATED_KEYS);
                orderPs.setInt(1, customerId);
                orderPs.setDouble(2, "Wallet".equals(paymentMethod) ? sellerSubtotal : sellerFinal);
                orderPs.setString(3, initialStatus);
                orderPs.setString(4, paymentMethod);
                orderPs.setString(5, fullAddress);
                orderPs.executeUpdate();

                ResultSet generatedKeys = orderPs.getGeneratedKeys();
                int orderId = 0;
                if (generatedKeys.next()) orderId = generatedKeys.getInt(1);
                orderPs.close();

                allOrderIds.add(orderId);
                lastOrderId = orderId;

                PreparedStatement itemPs = conn.prepareStatement(itemSql);
                for (Map<String, Object> item : sellerItems) {
                    itemPs.setInt(1, orderId);
                    itemPs.setInt(2, (Integer) item.get("productId"));
                    itemPs.setInt(3, (Integer) item.get("sellerId"));
                    itemPs.setInt(4, (Integer) item.get("quantity"));
                    itemPs.setDouble(5, (Double) item.get("price"));
                    Double discPrice = item.get("discountedPrice") != null ? (Double) item.get("discountedPrice") : (Double) item.get("price");
                    itemPs.setDouble(6, discPrice);
                    itemPs.setDouble(7, (Double) item.get("subtotal"));
                    Object varId = item.get("variationId");
                    if (varId != null) { itemPs.setInt(8, (Integer) varId); }
                    else { itemPs.setNull(8, java.sql.Types.INTEGER); }
                    itemPs.addBatch();

                    // Reduce stock
                    PreparedStatement stockPs = conn.prepareStatement("UPDATE product SET stock = stock - ? WHERE product_id = ?");
                    stockPs.setInt(1, (Integer) item.get("quantity"));
                    stockPs.setInt(2, (Integer) item.get("productId"));
                    stockPs.executeUpdate();
                    stockPs.close();
                }
                itemPs.executeBatch();
                itemPs.close();
            }

            int orderId = lastOrderId;
            double finalTotal = Math.max(0, cartTotal + shippingFee - totalDiscount);

         // Wallet deduction if payment method is Wallet
            String useWallet = request.getParameter("useWallet");
            if ("true".equals(useWallet) || "Wallet".equals(paymentMethod)) {
                PreparedStatement walletCheckPs = conn.prepareStatement(
                    "SELECT wallet_balance FROM customer WHERE customer_id=?");
                walletCheckPs.setInt(1, customerId);
                ResultSet walletRs = walletCheckPs.executeQuery();
                double currentBalance = walletRs.next() ? walletRs.getDouble("wallet_balance") : 0;
                walletRs.close(); walletCheckPs.close();

                double deduct = Math.min(currentBalance, cartTotal);
                if (deduct > 0) {
                    PreparedStatement walletDeductPs = conn.prepareStatement(
                        "UPDATE customer SET wallet_balance = wallet_balance - ? WHERE customer_id=?");
                    walletDeductPs.setDouble(1, deduct);
                    walletDeductPs.setInt(2, customerId);
                    walletDeductPs.executeUpdate();
                    walletDeductPs.close();

                    // Log wallet transaction
                    PreparedStatement walletLogPs = conn.prepareStatement(
                        "INSERT INTO wallet_transactions (customer_id, amount, type, description, reference_id) VALUES (?,?,'purchase',?,?)");
                    walletLogPs.setInt(1, customerId);
                    walletLogPs.setDouble(2, deduct);
                    walletLogPs.setString(3, "Used for Order #SE-" + orderId);
                    walletLogPs.setInt(4, orderId);
                    walletLogPs.executeUpdate();
                    walletLogPs.close();
                }
            }

            // Notify customer
            int notifUserId = (int) session.getAttribute("userId");
            PreparedStatement custNotifPs = conn.prepareStatement(
                "INSERT INTO notifications (user_id, user_type, message) VALUES (?, 'customer', ?)");
            custNotifPs.setInt(1, notifUserId);
            custNotifPs.setString(2, "Your order #" + orderId + " has been placed successfully! Total: ₱" + String.format("%.2f", finalTotal));
            custNotifPs.executeUpdate();
            custNotifPs.close();

            // Notify each seller
            java.util.Set<Integer> notifiedSellers = new java.util.HashSet<>();
            for (Map<String, Object> item : cartItems) {
                int sellerId = (Integer) item.get("sellerId");
                if (notifiedSellers.add(sellerId)) {
                	// Get user_id from seller_id
                	PreparedStatement sellerUserPs = conn.prepareStatement(
                	    "SELECT user_id FROM seller WHERE seller_id = ?");
                	sellerUserPs.setInt(1, sellerId);
                	ResultSet sellerUserRs = sellerUserPs.executeQuery();
                	int sellerUserId = sellerId; // fallback
                	if (sellerUserRs.next()) sellerUserId = sellerUserRs.getInt("user_id");
                	sellerUserRs.close(); sellerUserPs.close();

                	PreparedStatement sellerNotifPs = conn.prepareStatement(
                	    "INSERT INTO notifications (user_id, user_type, message) VALUES (?, 'seller', ?)");
                	sellerNotifPs.setInt(1, sellerUserId);
                    sellerNotifPs.setString(2, "You have a new order #" + orderId + " from a customer!");
                    sellerNotifPs.executeUpdate();
                    sellerNotifPs.close();
                }
            }

            if (isBuyNow) {
                // Buy Now — clear only buyNow session, NOT the cart
                session.removeAttribute("buyNowItems");
                session.removeAttribute("buyNowTotal");
            } else {
                // Cart checkout — clear cart from database
                String clearSql = "DELETE FROM cartitem WHERE cart_id IN (SELECT cart_id FROM cart WHERE customer_id = ?)";
                PreparedStatement clearPs = conn.prepareStatement(clearSql);
                clearPs.setInt(1, customerId);
                clearPs.executeUpdate();
                clearPs.close();

                // Clear session cart
                session.removeAttribute("checkoutItems");
                session.removeAttribute("checkoutTotal");
                session.setAttribute("cartCount", 0);
            }

            conn.close();

            // Record voucher usage and increment used_count
            if (appliedVoucherCode != null) {
                Connection vcConn = DBConnection.getConnection();
                Integer voucherId = (Integer) session.getAttribute("appliedVoucherId");
                if (voucherId != null) {
                    PreparedStatement vuPs = vcConn.prepareStatement(
                        "INSERT INTO voucher_usage (voucher_id, voucher_type, user_id, order_id) VALUES (?,?,?,?)");
                    vuPs.setInt(1, voucherId);
                    vuPs.setString(2, "platform");
                    vuPs.setInt(3, (int) session.getAttribute("userId"));
                    vuPs.setInt(4, orderId);
                    vuPs.executeUpdate(); vuPs.close();

                    PreparedStatement vcUpdatePs = vcConn.prepareStatement(
                        "UPDATE vouchers SET used_count = used_count + 1 WHERE voucher_id=?");
                    vcUpdatePs.setInt(1, voucherId);
                    vcUpdatePs.executeUpdate(); vcUpdatePs.close();
                }
                vcConn.close();
                session.removeAttribute("appliedVoucherCode");
                session.removeAttribute("appliedVoucherDiscount");
                session.removeAttribute("appliedVoucherId");
            }
            
         // Record personal (welcome) voucher usage
            String voucherCodeParam = request.getParameter("voucherCode");
            if (voucherCodeParam != null && !voucherCodeParam.isEmpty() && voucherCodeParam.startsWith("WELCOME-")) {
                Connection vcConn2 = DBConnection.getConnection();
                PreparedStatement cvPs = vcConn2.prepareStatement(
                    "UPDATE customer_vouchers SET used_count = used_count + 1, is_active = 0 WHERE code=? AND customer_id=?");
                cvPs.setString(1, voucherCodeParam.toUpperCase().trim());
                cvPs.setInt(2, customerId);
                cvPs.executeUpdate();
                cvPs.close();
                vcConn2.close();
            }

            out.print("{\"success\":true,\"orderId\":" + orderId + ",\"orderIds\":" + allOrderIds.toString().replace(" ","") + "}");

        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\":false,\"message\":\"" + e.getMessage() + "\"}");
        }
    }
}