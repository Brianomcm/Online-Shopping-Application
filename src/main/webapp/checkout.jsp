<%@ page session="true" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%
String ckRole = (String) session.getAttribute("userRole");
if(session.getAttribute("userId") == null || ckRole == null ||
   (!ckRole.equals("customer") && !ckRole.equals("both"))) {
        response.sendRedirect("index.jsp");
        return;
    }
String userName = (String) session.getAttribute("userName");
String ckFirstName = (String) session.getAttribute("userFirstName");
String ckLastName  = (String) session.getAttribute("userLastName");
String ckMI        = (String) session.getAttribute("userMiddleInitial");
if (ckFirstName == null) ckFirstName = "";
if (ckLastName  == null) ckLastName  = "";
if (ckMI        == null) ckMI        = "";
String ckFullName = !ckFirstName.isEmpty()
? ckFirstName + (!ckMI.isEmpty() ? " " + ckMI + "." : "") + " " + ckLastName
: userName != null ? userName : "";
String userAvatar = (String) session.getAttribute("userAvatar");
String userAddress = (String) session.getAttribute("userAddress");
if (userAddress == null) userAddress = "";

// Check if Buy Now or Cart checkout
boolean isBuyNow = "true".equals(request.getParameter("buyNow")) || 
                   session.getAttribute("buyNowItems") != null && "true".equals(request.getParameter("buyNow"));

List<Map<String, Object>> cartItems;
Double cartTotal;

if (isBuyNow) {
    cartItems = (List<Map<String, Object>>) session.getAttribute("buyNowItems");
    cartTotal = (Double) session.getAttribute("buyNowTotal");
} else {
    cartItems = (List<Map<String, Object>>) session.getAttribute("checkoutItems");
    cartTotal = (Double) session.getAttribute("checkoutTotal");
}

if (cartItems == null) { response.sendRedirect("CartServlet"); return; }
if (cartTotal == null) cartTotal = 0.0;
 // Load saved addresses from database
    java.util.List<java.util.Map<String, Object>> savedAddresses = new java.util.ArrayList<>();
    try {
    	Integer custId = (Integer) session.getAttribute("customerId");
        if (custId == null) custId = (int) session.getAttribute("userId");
        java.sql.Connection addrConn = com.shopeasy.DBConnection.getConnection();
        java.sql.PreparedStatement addrPs = addrConn.prepareStatement(
            "SELECT * FROM customer_address WHERE customer_id=? ORDER BY is_default DESC");
        addrPs.setInt(1, custId);
        java.sql.ResultSet addrRs = addrPs.executeQuery();
        while (addrRs.next()) {
            java.util.Map<String, Object> addr = new java.util.HashMap<>();
            addr.put("id", addrRs.getInt("address_id"));
            addr.put("fullname", addrRs.getString("full_name"));
            addr.put("phone", addrRs.getString("phone"));
            addr.put("address", addrRs.getString("address"));
            addr.put("isDefault", addrRs.getInt("is_default") == 1);
            savedAddresses.add(addr);
        }
        addrRs.close(); addrPs.close(); addrConn.close();
    } catch (Exception ex) { ex.printStackTrace(); }
    
    
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Checkout - ShopEasy</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css">
  <style>
     body { background: #f8f9fa; font-family: 'Segoe UI', sans-serif; }
        .navbar-brand { font-weight: 800; color: #0d6efd !important; font-size: 22px; }
        .card-section { background: white; border-radius: 16px; box-shadow: 0 2px 16px rgba(13,110,253,0.07); padding: 24px; margin-bottom: 16px; border: 1px solid #e8f0fe; }
        .section-title { font-size: 14px; font-weight: 700; color: #0d6efd; margin-bottom: 16px; padding-bottom: 10px; border-bottom: 2px solid #e8f0fe; display: flex; align-items: center; gap: 8px; }
        .product-img { width: 64px; height: 64px; object-fit: cover; border-radius: 10px; border: 1px solid #eee; }
        .product-img-placeholder { width: 64px; height: 64px; background: #f0f0f0; border-radius: 10px; display: flex; align-items: center; justify-content: center; color: #aaa; font-size: 22px; }
        .payment-option { border: 2px solid #e8f0fe; border-radius: 12px; padding: 14px 18px; cursor: pointer; transition: 0.2s; margin-bottom: 10px; background: #fafbff; }
        .payment-option:hover { border-color: #0d6efd; background: #f0f4ff; }
        .payment-option.selected { border-color: #0d6efd; background: #f0f4ff; box-shadow: 0 0 0 3px rgba(13,110,253,0.1); }
        .summary-card { background: white; border-radius: 16px; box-shadow: 0 2px 16px rgba(13,110,253,0.07); padding: 24px; position: sticky; top: 80px; border: 1px solid #e8f0fe; }
        .place-order-btn { background: linear-gradient(135deg, #0d6efd, #6610f2); border: none; border-radius: 12px; padding: 14px; font-size: 16px; font-weight: 700; }
        .place-order-btn:hover { opacity: 0.92; transform: translateY(-1px); transition: 0.2s; }
        .step-badge { background: linear-gradient(135deg, #0d6efd, #6610f2); color: white; border-radius: 50%; width: 28px; height: 28px; display: inline-flex; align-items: center; justify-content: center; font-weight: 700; font-size: 13px; flex-shrink: 0; }
        .saved-addr-card { transition: 0.2s; border-radius: 12px !important; }
        .saved-addr-card:hover { border-color: #0d6efd !important; background: #f0f4ff !important; }
        .item-row { padding: 12px 0; border-bottom: 1px solid #f0f4ff; }
        .item-row:last-child { border-bottom: none; }
    
    @media (max-width: 576px) {
    .card-section { padding: 14px 12px !important; border-radius: 12px !important; margin-bottom: 10px !important; }
    .summary-card { padding: 14px 12px !important; border-radius: 12px !important; position: static !important; }
    .section-title { font-size: 13px !important; margin-bottom: 10px !important; }
    .payment-option { padding: 10px 12px !important; border-radius: 10px !important; margin-bottom: 8px !important; }
    .payment-option .fw-bold { font-size: 13px !important; }
    .payment-option .text-muted { font-size: 11px !important; }
    .place-order-btn { padding: 12px !important; font-size: 14px !important; border-radius: 10px !important; }
    .step-badge { width: 24px !important; height: 24px !important; font-size: 11px !important; }
    .product-img { width: 52px !important; height: 52px !important; }
    .saved-addr-card { padding: 10px !important; }
    .saved-addr-card .fw-semibold { font-size: 13px !important; }
    .saved-addr-card .text-muted { font-size: 11px !important; }
    .item-row { padding: 8px 0 !important; }
    .container { padding-left: 12px !important; padding-right: 12px !important; }
    .summary-card .fs-5 { font-size: 15px !important; }
}
    
    </style>
</head>
<body>

<!-- NAVBAR -->
<% request.setAttribute("navType", "checkout"); %>
<%@ include file="navbar.jsp" %>

<!-- BREADCRUMB -->
<div class="bg-white border-bottom px-4 py-2">
   <nav aria-label="breadcrumb" class="d-none d-md-block">
        <ol class="breadcrumb mb-0" style="font-size:13px;">
            <li class="breadcrumb-item"><a href="index.jsp" class="text-decoration-none text-primary">Home</a></li>
            <%
                String ckCrumb = (String) session.getAttribute("breadcrumb");
                Integer lpId = (Integer) session.getAttribute("lastProductId");
                String lpName = (String) session.getAttribute("lastProduct");
                if (isBuyNow && lpId != null && lpName != null) {
            %>
                <li class="breadcrumb-item">
                    <a href="product.jsp?id=<%= lpId %>" class="text-decoration-none text-primary"><%= lpName %></a>
                </li>
            <% } else if ("product-cart".equals(ckCrumb) && lpId != null && lpName != null) { %>
                <li class="breadcrumb-item">
                    <a href="product.jsp?id=<%= lpId %>" class="text-decoration-none text-primary"><%= lpName %></a>
                </li>
                <li class="breadcrumb-item"><a href="CartServlet" class="text-decoration-none text-primary">Cart</a></li>
            <% } else if (!"product-checkout".equals(ckCrumb)) { %>
                <li class="breadcrumb-item"><a href="CartServlet" class="text-decoration-none text-primary">Cart</a></li>
            <% } %>
            <li class="breadcrumb-item active text-muted">Checkout</li>
        </ol>
    </nav>
</div>

<div class="container py-4">
  <h5 class="fw-bold mb-4 d-flex align-items-center gap-2">
        <span style="background:linear-gradient(135deg,#0d6efd,#6610f2); color:white; border-radius:10px; padding:6px 12px; font-size:14px;">
            <i class="bi bi-bag-check-fill"></i> Checkout
        </span>
    </h5>

    <div class="row g-4">
  <div class="col-lg-8 order-2 order-lg-1">

           <!-- SHIPPING ADDRESS -->
            <div class="card-section">
                <p class="section-title"><span class="step-badge">1</span> Shipping Address</p>

                <% if (!savedAddresses.isEmpty()) { %>
                <!-- SAVED ADDRESSES -->
                <p class="fw-bold mb-2" style="font-size:13px;">Select a saved address:</p>
                <% for (java.util.Map<String, Object> addr : savedAddresses) { %>
                <div class="border rounded-3 p-3 mb-2 saved-addr-card" 
                     style="cursor:pointer; <%= (boolean)addr.get("isDefault") ? "border-color:#0d6efd !important; background:#f0f4ff;" : "" %>"
                     onclick="selectAddress('<%= addr.get("fullname") %>', '<%= addr.get("phone") %>', '<%= ((String)addr.get("address")).replace("'", "\\'") %>', this)">
                    <div class="d-flex justify-content-between align-items-start">
                        <div>
                            <p class="mb-0 fw-bold" style="font-size:13px;"><%= addr.get("fullname") %> &nbsp; <span class="text-muted">+63 <%= addr.get("phone") %></span></p>
                            <p class="mb-0 text-muted" style="font-size:12px;"><%= addr.get("address") %></p>
                        </div>
                        <% if ((boolean)addr.get("isDefault")) { %>
                            <span class="badge bg-primary ms-2" style="font-size:10px;">Default</span>
                        <% } %>
                    </div>
                </div>
                <% } %>
               <hr>
                <button type="button" class="btn btn-outline-primary btn-sm mb-3" onclick="toggleNewAddress()">
                    <i class="bi bi-plus-circle"></i> Use a Different Address
                </button>
                <% } %>

                <div class="row g-3" id="newAddressForm" style="<%= savedAddresses.isEmpty() ? "" : "display:none;" %>">
                    <div class="col-12">
                        <label class="form-label fw-bold" style="font-size:13px;">Full Name</label>
                     <input type="text" class="form-control" id="shipName" value="<%= ckFullName %>">
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-bold" style="font-size:13px;">Delivery Address</label>
                        <textarea class="form-control" rows="2" id="shipAddress" placeholder="Enter your full delivery address"><%= userAddress %></textarea>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold" style="font-size:13px;">Phone Number</label>
                        <div class="input-group">
                            <span class="input-group-text">+63</span>
                         <input type="tel" class="form-control" id="shipPhone" 
       value="<%= session.getAttribute("userPhone") != null ? session.getAttribute("userPhone") : "" %>"
       maxlength="10"
       oninput="this.value = this.value.replace(/[^0-9]/g, '')"
       onblur="if(this.value.length > 0 && this.value.length < 10) { this.classList.add('is-invalid'); } else { this.classList.remove('is-invalid'); }">
<div class="invalid-feedback" style="font-size:11px;">Phone number must be 10 digits.</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- PAYMENT METHOD -->
            <div class="card-section">
                <p class="section-title"><span class="step-badge">2</span> Payment Method</p>
                <div class="payment-option selected" onclick="selectPayment(this, 'COD')">
                    <div class="d-flex align-items-center gap-3">
                        <i class="bi bi-cash-coin fs-4 text-success"></i>
                        <div>
                            <p class="mb-0 fw-bold" style="font-size:14px;">Cash on Delivery</p>
                            <p class="mb-0 text-muted" style="font-size:12px;">Pay when your order arrives</p>
                        </div>
                        <i class="bi bi-check-circle-fill text-primary ms-auto" id="check_COD"></i>
                    </div>
                </div>
                <div class="payment-option" onclick="selectPayment(this, 'GCash')">
                    <div class="d-flex align-items-center gap-3">
                        <i class="bi bi-phone fs-4 text-primary"></i>
                        <div>
                            <p class="mb-0 fw-bold" style="font-size:14px;">GCash</p>
                            <p class="mb-0 text-muted" style="font-size:12px;">Pay via GCash mobile wallet</p>
                        </div>
                        <i class="bi bi-circle text-muted ms-auto" id="check_GCash"></i>
                    </div>
                </div>
                <div class="payment-option" onclick="selectPayment(this, 'Card')">
                    <div class="d-flex align-items-center gap-3">
                        <i class="bi bi-credit-card fs-4 text-warning"></i>
                        <div>
                            <p class="mb-0 fw-bold" style="font-size:14px;">Credit / Debit Card</p>
                            <p class="mb-0 text-muted" style="font-size:12px;">Visa, Mastercard accepted</p>
                        </div>
                        <i class="bi bi-circle text-muted ms-auto" id="check_Card"></i>
                    </div>
                </div>
               <%
                double checkoutWalletBal = 0;
                try {
                    Integer ckCustId = (Integer) session.getAttribute("customerId");
                    if (ckCustId == null) ckCustId = (int) session.getAttribute("userId");
                    java.sql.Connection ckWConn = com.shopeasy.DBConnection.getConnection();
                    java.sql.PreparedStatement ckWPs = ckWConn.prepareStatement(
                        "SELECT wallet_balance FROM customer WHERE customer_id=?");
                    ckWPs.setInt(1, ckCustId);
                    java.sql.ResultSet ckWRs = ckWPs.executeQuery();
                    if (ckWRs.next()) checkoutWalletBal = ckWRs.getDouble("wallet_balance");
                    ckWRs.close(); ckWPs.close(); ckWConn.close();
                } catch (Exception ckWEx) { ckWEx.printStackTrace(); }
                %>
               <div class="payment-option <%= checkoutWalletBal >= cartTotal ? "" : "opacity-50" %>"
     onclick="<%= checkoutWalletBal >= cartTotal ? "selectPayment(this, 'Wallet')" : "alert('Insufficient wallet balance for this order.')" %>">
                    <div class="d-flex align-items-center gap-3">
                        <i class="bi bi-wallet2 fs-4 text-primary"></i>
                        <div>
                            <p class="mb-0 fw-bold" style="font-size:14px;">ShopEasy Wallet</p>
                            <p class="mb-0 text-muted" style="font-size:12px;">Balance: ₱<%= String.format("%.2f", checkoutWalletBal) %></p>
                        </div>
                        <i class="bi bi-circle text-muted ms-auto" id="check_Wallet"></i>
                    </div>
                </div>
                <input type="hidden" id="selectedPayment" value="COD">
                <input type="hidden" id="walletBalance" value="<%= checkoutWalletBal %>">
            </div>

            <!-- ORDER ITEMS -->
            <div class="card-section">
             <%
int totalQty = 0;
for (Map<String, Object> item : cartItems) {
    totalQty += item.get("quantity") != null ? (Integer) item.get("quantity") : 0;
}
%>
<p class="section-title"><span class="step-badge">3</span> Order Items (<%= cartItems.size() %> <%= cartItems.size() == 1 ? "item" : "items" %>, <%= totalQty %> <%= totalQty == 1 ? "pc" : "pcs" %>)</p>
                <% for (Map<String, Object> item : cartItems) { %>
                <div class="d-flex gap-3 align-items-center mb-3 pb-3 border-bottom">
                    <% if (item.get("image") != null) { %>
                        <img src="<%= item.get("image") %>" class="product-img" alt="">
                    <% } else { %>
                        <div class="product-img-placeholder"><i class="bi bi-image"></i></div>
                    <% } %>
                    <div class="flex-grow-1">
    <p class="mb-0 fw-bold" style="font-size:14px;"><%= item.get("name") %></p>
    <p class="mb-0 text-muted" style="font-size:12px;">Qty: <%= item.get("quantity") %></p>
    <% if (item.get("variationType") != null) { %>
    <span class="badge bg-light text-dark border" style="font-size:11px;">
        <i class="bi bi-tag"></i> <%= item.get("variationType") %>: <%= item.get("variationValue") %>
    </span>
    <% } %>
    <%
        double coDiscPrice = item.get("originalPrice") != null ? (Double) item.get("originalPrice") : 0;
        double coRealPrice = item.get("price") != null ? (Double) item.get("price") : 0;
        if (coDiscPrice > 0 && coDiscPrice < coRealPrice) {
            int coPct = (int) Math.round((coRealPrice - coDiscPrice) / coRealPrice * 100);
    %>
        <span class="badge bg-danger" style="font-size:10px;">-<%= coPct %>% OFF</span>
        <span class="text-muted text-decoration-line-through" style="font-size:10px;">₱<%= String.format("%.2f", coRealPrice) %></span>
    <% } %>
</div>
<p class="mb-0 fw-bold text-danger">₱<%= String.format("%.2f", item.get("subtotal")) %></p>
                </div>
                <% } %>
            </div>

        </div>

        <!-- ORDER SUMMARY -->
      <div class="col-lg-4 order-1 order-lg-2">
            <div class="summary-card">
                <h6 class="fw-bold mb-3">Order Summary</h6>
                <%
                double ckSavings = 0;
                for (Map<String, Object> item : cartItems) {
                    double ckPrice = item.get("price") != null ? (Double) item.get("price") : 0;
                    double ckOriginal = item.get("originalPrice") != null ? (Double) item.get("originalPrice") : 0;
                    int ckQty = item.get("quantity") != null ? (Integer) item.get("quantity") : 0;
                    if (ckOriginal > 0 && ckOriginal < ckPrice) {
                        ckSavings += (ckPrice - ckOriginal) * ckQty;
                    }
                }
                // Add shipping savings ONCE (outside loop)
                if (cartTotal >= 500) ckSavings += 38;
                %>
       <div class="d-flex justify-content-between mb-2" id="youSaveRow" style="<%= ckSavings > 0 ? "" : "display:none;" %>">
                    <span class="text-success fw-bold"><i class="bi bi-tag-fill"></i> You save</span>
                    <span class="text-success fw-bold" id="youSaveAmt">-₱<%= String.format("%.2f", ckSavings) %></span>
                </div>
               <div class="d-flex justify-content-between mb-2">
                    <span class="text-muted">Shipping</span>
                    <span id="shippingDisplay" class="<%= cartTotal >= 500 ? "text-success fw-bold" : "text-danger fw-bold" %>">
                        <% if (cartTotal >= 500) { %>
                            <i class="bi bi-truck"></i> Free
                        <% } else { %>
                            ₱38.00
                        <% } %>
                    </span>
                </div>
                <div id="freeShipHint" class="mb-2 p-2 rounded-2" style="background:#fff3cd; border:1px solid #ffc107; font-size:11px; <%= cartTotal >= 500 ? "display:none;" : "" %>">
                    <i class="bi bi-info-circle text-warning"></i> Add <strong>₱<%= String.format("%.2f", 500 - cartTotal) %></strong> more for Free Shipping!
                </div>
               
           <div class="d-flex justify-content-between mb-2">
                    <span class="text-muted">Items (<%= cartItems.size() %>)</span>
                    <span class="text-muted">₱<%= String.format("%.2f", cartTotal) %></span>
                </div>
                
                <div class="d-flex justify-content-between mb-2">
                    <span class="text-muted"><i class="bi bi-truck"></i> Estimated Delivery</span>
                    <%
                        java.util.Calendar deliveryMin = java.util.Calendar.getInstance();
                        java.util.Calendar deliveryMax = java.util.Calendar.getInstance();
                        // Skip weekends for min (3 business days)
                        int bDays = 0;
                        while (bDays < 3) {
                            deliveryMin.add(java.util.Calendar.DAY_OF_MONTH, 1);
                            int dow = deliveryMin.get(java.util.Calendar.DAY_OF_WEEK);
                            if (dow != java.util.Calendar.SATURDAY && dow != java.util.Calendar.SUNDAY) bDays++;
                        }
                        bDays = 0;
                        while (bDays < 5) {
                            deliveryMax.add(java.util.Calendar.DAY_OF_MONTH, 1);
                            int dow = deliveryMax.get(java.util.Calendar.DAY_OF_WEEK);
                            if (dow != java.util.Calendar.SATURDAY && dow != java.util.Calendar.SUNDAY) bDays++;
                        }
                        java.text.SimpleDateFormat deliveryFmt = new java.text.SimpleDateFormat("MMM d");
                        String deliveryRange = deliveryFmt.format(deliveryMin.getTime()) + " – " + deliveryFmt.format(deliveryMax.getTime());
                    %>
                    <span class="text-muted" style="font-size:12px;"><%= deliveryRange %></span>
                </div>
                <hr>
           <div class="mb-2">
                    <label class="form-label fw-bold" style="font-size:13px;"><i class="bi bi-ticket-perforated text-primary me-1"></i> Platform Voucher</label>
                    <div id="voucherSelectedBox" class="d-none d-flex justify-content-between align-items-center p-2 rounded-3 mb-2" style="background:#f0fdf4; border:1px solid #86efac; font-size:13px;">
                        <span><i class="bi bi-ticket-perforated text-success me-1"></i><strong id="voucherSelectedCode"></strong> — <span id="voucherSelectedDesc" class="text-success"></span></span>
                        <button class="btn btn-sm btn-link text-danger p-0" onclick="removeVoucher()"><i class="bi bi-x-circle"></i></button>
                    </div>
                    <button class="btn btn-outline-primary btn-sm w-100" id="openVoucherBtn" onclick="openVoucherModal('platform')">
                        <i class="bi bi-ticket-perforated me-1"></i> Select Voucher
                    </button>
                    <div id="voucherMsg" class="mt-1" style="font-size:12px;"></div>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-bold" style="font-size:13px;"><i class="bi bi-truck text-success me-1"></i> Free Shipping Voucher</label>
                    <div id="freeShipSelectedBox" class="d-none d-flex justify-content-between align-items-center p-2 rounded-3 mb-2" style="background:#f0fdf4; border:1px solid #86efac; font-size:13px;">
                        <span><i class="bi bi-truck text-success me-1"></i><strong id="freeShipSelectedCode"></strong> — <span class="text-success">Free Shipping</span></span>
                        <button class="btn btn-sm btn-link text-danger p-0" onclick="removeFreeShip()"><i class="bi bi-x-circle"></i></button>
                    </div>
                    <button class="btn btn-outline-success btn-sm w-100" id="openFreeShipBtn" onclick="openVoucherModal('freeshipping')">
                        <i class="bi bi-truck me-1"></i> Select Free Shipping Voucher
                    </button>
                </div>
             <div id="voucherDiscountRow" class="d-flex justify-content-between mb-2 text-success" style="display:none !important; font-size:13px;">
                    <span><i class="bi bi-ticket-perforated me-1"></i>Voucher Applied</span>
                    <span id="voucherDiscountAmt">-₱0.00</span>
                </div>
          <div id="walletDiscountRow" class="justify-content-between mb-2 text-success" style="display:none; font-size:13px;">
                    <span><i class="bi bi-wallet2 me-1"></i>Wallet Applied</span>
                    <span id="walletDiscountAmt">-₱0.00</span>
                </div>
                <div class="d-flex justify-content-between fw-bold fs-5 mb-4">
                    <span>Total</span>
                  <span class="text-primary" id="finalTotalDisplay">₱<%= String.format("%.2f", cartTotal >= 500 ? cartTotal : cartTotal + 38) %></span>
                </div>
                <button class="btn btn-primary place-order-btn w-100 text-white" onclick="placeOrder()">
                    <i class="bi bi-bag-check"></i> Place Order
                </button>
                <% if (isBuyNow) { %>
                    <a href="javascript:history.back()" class="btn btn-outline-secondary w-100 mt-2">
                        <i class="bi bi-arrow-left"></i> Back to Product
                    </a>
                <% } else { %>
                    <a href="CartServlet" class="btn btn-outline-secondary w-100 mt-2">
                        <i class="bi bi-arrow-left"></i> Back to Cart
                    </a>
                <% } %>
            </div>
        </div>
    </div>
</div>


<!-- VOUCHER PICKER MODAL -->
<div class="modal fade" id="voucherPickerModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-header border-0 pb-0">
                <h5 class="modal-title fw-bold"><i class="bi bi-ticket-perforated text-primary me-2"></i>Select Voucher</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
    <div class="modal-body px-4 pb-4">
                <div class="input-group mb-3">
                    <input type="text" id="manualVoucherCode" class="form-control text-uppercase" placeholder="Enter voucher code manually">
                    <button class="btn btn-primary" onclick="applyManualVoucher()">Apply</button>
                </div>
                <div id="manualVoucherMsg" class="mb-2" style="font-size:12px;"></div>
                <hr class="my-2">
                <p class="fw-bold mb-2" style="font-size:13px;">Available Vouchers:</p>
                <div id="voucherListContainer" style="max-height:350px; overflow-y:auto;">
                    <div class="text-center py-4"><div class="spinner-border spinner-border-sm text-primary"></div></div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- GCASH PAYMENT MODAL -->
<div class="modal fade" id="gcashModal" tabindex="-1" data-bs-backdrop="static">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow-lg overflow-hidden">
            <!-- GCash Header -->
            <div style="background: linear-gradient(135deg, #0070E0 0%, #00C2FF 100%); padding: 28px 24px 20px; position:relative;">
                <div class="d-flex align-items-center gap-3">
                    <div style="background:white; border-radius:14px; width:52px; height:52px; display:flex; align-items:center; justify-content:center;">
                        <svg width="32" height="32" viewBox="0 0 40 40" fill="none">
                            <circle cx="20" cy="20" r="20" fill="#0070E0"/>
                            <text x="20" y="26" text-anchor="middle" fill="white" font-size="16" font-weight="bold" font-family="Arial">G</text>
                        </svg>
                    </div>
                    <div>
                        <p class="mb-0 text-white fw-bold fs-5">GCash Payment</p>
                        <p class="mb-0 text-white opacity-75" style="font-size:13px;">Send money to complete your order</p>
                    </div>
                </div>
                <!-- Amount Badge -->
                <div class="mt-3 p-3 rounded-3" style="background:rgba(255,255,255,0.18); backdrop-filter:blur(8px);">
                    <p class="mb-0 text-white opacity-75" style="font-size:12px; letter-spacing:1px; text-transform:uppercase;">Amount to Send</p>
                    <p class="mb-0 text-white fw-bold" style="font-size:28px;" id="gcashAmountDisplay">₱0.00</p>
                </div>
            </div>

            <div class="modal-body p-4">
                <!-- Step 1: Send to number -->
                <div class="p-3 rounded-3 mb-3" style="background:#EFF6FF; border:1.5px solid #BFDBFE;">
                    <p class="mb-1 fw-bold" style="font-size:13px; color:#1D4ED8;"><i class="bi bi-phone-fill me-1"></i> Step 1: Send GCash to</p>
                    <div class="d-flex align-items-center justify-content-between">
                        <span style="font-size:22px; font-weight:800; letter-spacing:2px; color:#0070E0;">0917-123-4567</span>
                        <button class="btn btn-sm" style="background:#DBEAFE; color:#1D4ED8; border-radius:8px; font-size:12px; font-weight:600;" onclick="copyGcashNumber()">
                            <i class="bi bi-copy me-1"></i>Copy
                        </button>
                    </div>
                    <p class="mb-0 mt-1" style="font-size:11px; color:#64748B;">Account name: <strong>ShopEasy PH</strong></p>
                </div>

                <!-- Step 2: Enter reference -->
                <p class="fw-bold mb-2" style="font-size:13px; color:#374151;"><i class="bi bi-receipt me-1 text-primary"></i> Step 2: Enter GCash Reference Number</p>
                <div class="input-group mb-1">
                    <span class="input-group-text" style="background:#F0F9FF; border-color:#BFDBFE;">
                        <i class="bi bi-hash text-primary"></i>
                    </span>
                    <input type="text" id="gcashRefInput" class="form-control" 
                           style="border-color:#BFDBFE; font-family:monospace; letter-spacing:1px;"
                           placeholder="e.g. 1234567890123" maxlength="13"
                           oninput="this.value=this.value.replace(/\D/g,''); validateGcashRef()">
                </div>
                <p class="text-muted mb-3" style="font-size:11px;"><i class="bi bi-info-circle me-1"></i>Find this in your GCash app → Transaction History</p>

                <div id="gcashRefError" class="alert alert-danger py-2 mb-3" style="font-size:12px; display:none;">
                    <i class="bi bi-exclamation-circle me-1"></i> Please enter a valid 13-digit reference number.
                </div>

                <div class="d-flex gap-2">
                    <button class="btn btn-outline-secondary flex-shrink-0" style="border-radius:10px;" data-bs-dismiss="modal">
                        Cancel
                    </button>
                    <button class="btn w-100 text-white fw-bold" id="gcashConfirmBtn"
                            style="background:linear-gradient(135deg,#0070E0,#00C2FF); border-radius:10px; border:none;"
                            onclick="confirmGcashPayment()">
                        <i class="bi bi-check-circle me-1"></i> I've Paid — Confirm Order
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- CREDIT/DEBIT CARD MODAL -->
<div class="modal fade" id="cardModal" tabindex="-1" data-bs-backdrop="static">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow-lg overflow-hidden">
            <!-- Card Header -->
            <div style="background: linear-gradient(135deg, #1a1a2e 0%, #16213e 60%, #0f3460 100%); padding: 28px 24px;">
                <!-- Mock Card Visual -->
                <div class="rounded-3 p-3 mb-3" style="background:linear-gradient(135deg,#667eea,#764ba2); min-height:110px; position:relative; box-shadow:0 8px 24px rgba(0,0,0,0.3);">
                    <div class="d-flex justify-content-between align-items-start">
                        <div>
                            <div style="width:36px; height:24px; background:#FFD700; border-radius:4px; opacity:0.9;"></div>
                        </div>
                        <div class="d-flex gap-1 align-items-center">
                            <div style="width:22px; height:22px; background:#EB001B; border-radius:50%; opacity:0.9;"></div>
                            <div style="width:22px; height:22px; background:#F79E1B; border-radius:50%; opacity:0.9; margin-left:-8px;"></div>
                        </div>
                    </div>
                    <p class="mb-0 mt-2 text-white" id="cardPreviewNumber" style="font-size:15px; letter-spacing:3px; font-family:monospace; opacity:0.9;">•••• •••• •••• ••••</p>
                    <div class="d-flex justify-content-between mt-1">
                        <p class="mb-0 text-white" id="cardPreviewName" style="font-size:11px; opacity:0.7; text-transform:uppercase;">YOUR NAME</p>
                        <p class="mb-0 text-white" id="cardPreviewExpiry" style="font-size:11px; opacity:0.7;">MM/YY</p>
                    </div>
                </div>
                <div>
                    <p class="mb-0 text-white fw-bold fs-5">Card Payment</p>
                    <p class="mb-0 text-white opacity-75" style="font-size:13px;">Total: <span id="cardAmountDisplay" class="fw-bold">₱0.00</span></p>
                </div>
            </div>

            <div class="modal-body p-4">
                <!-- Card Number -->
                <div class="mb-3">
                    <label class="form-label fw-bold" style="font-size:13px;">Card Number</label>
                    <input type="text" id="cardNumberInput" class="form-control fw-bold" 
                           style="font-family:monospace; letter-spacing:2px; font-size:15px;"
                           placeholder="0000 0000 0000 0000" maxlength="19"
                           oninput="formatCardNumber(this)">
                </div>
                <!-- Name -->
                <div class="mb-3">
                    <label class="form-label fw-bold" style="font-size:13px;">Name on Card</label>
                    <input type="text" id="cardNameInput" class="form-control text-uppercase" 
                           placeholder="JUAN DELA CRUZ"
                           oninput="document.getElementById('cardPreviewName').textContent = this.value.toUpperCase() || 'YOUR NAME'">
                </div>
                <!-- Expiry + CVV -->
                <div class="row g-3 mb-3">
                    <div class="col-6">
                        <label class="form-label fw-bold" style="font-size:13px;">Expiry Date</label>
                        <input type="text" id="cardExpiryInput" class="form-control" 
                               placeholder="MM/YY" maxlength="5"
                               oninput="formatExpiry(this)">
                    </div>
                    <div class="col-6">
                        <label class="form-label fw-bold" style="font-size:13px;">CVV</label>
                        <div class="input-group">
                            <input type="password" id="cardCvvInput" class="form-control" 
                                   placeholder="•••" maxlength="4"
                                   oninput="this.value=this.value.replace(/\D/g,'')">
                            <span class="input-group-text"><i class="bi bi-shield-lock text-muted"></i></span>
                        </div>
                    </div>
                </div>

                <div id="cardError" class="alert alert-danger py-2 mb-3" style="font-size:12px; display:none;">
                    <i class="bi bi-exclamation-circle me-1"></i> <span id="cardErrorMsg">Please fill in all card details.</span>
                </div>

                <!-- Accepted cards -->
                <div class="d-flex gap-2 align-items-center mb-3">
                    <span style="font-size:11px; color:#94A3B8;">Accepted:</span>
                    <div style="background:#1434CB; color:white; font-size:10px; font-weight:800; padding:2px 8px; border-radius:4px;">VISA</div>
                    <div style="font-size:10px; font-weight:800; padding:2px 8px; border-radius:4px; border:1px solid #ddd;">
                        <span style="color:#EB001B;">Master</span><span style="color:#F79E1B;">card</span>
                    </div>
                </div>

                <div class="d-flex gap-2">
                    <button class="btn btn-outline-secondary flex-shrink-0" style="border-radius:10px;" data-bs-dismiss="modal">
                        Cancel
                    </button>
                    <button class="btn w-100 text-white fw-bold" 
                            style="background:linear-gradient(135deg,#1a1a2e,#0f3460); border-radius:10px; border:none;"
                            onclick="confirmCardPayment()">
                        <i class="bi bi-lock-fill me-1"></i> Pay <span id="cardPayBtnAmt">₱0.00</span>
                    </button>
                </div>
                <p class="text-center mt-2 mb-0 text-muted" style="font-size:11px;"><i class="bi bi-shield-check me-1"></i>256-bit SSL encrypted. Your card info is safe.</p>
            </div>
        </div>
    </div>
</div>

<!-- PROCESSING ORDER OVERLAY -->
<div id="processingOverlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.95); z-index:9999; flex-direction:column; align-items:center; justify-content:center;">
    <div class="spinner-border text-primary mb-3" style="width:3.5rem; height:3.5rem;" role="status"></div>
    <p class="fw-bold text-primary fs-5">Processing Order...</p>
    <p class="text-muted" style="font-size:13px;">Please wait, do not close this page.</p>
</div>




<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
let selectedPayment = 'COD';
let usingNewAddress = <%= savedAddresses.isEmpty() ? "true" : "false" %>;
let shippingFee = <%= cartTotal >= 500 ? 0 : 38 %>;
let voucherDiscount = 0;
let voucherCode = '';
let freeShipApplied = false;
let freeShipCode = '';

const cartTotal = <%= cartTotal %>;
const orderTotal = cartTotal + shippingFee;

    function showToast(msg, color = '#198754') {
        const existing = document.getElementById('checkoutToast');
        if (existing) existing.remove();
        const t = document.createElement('div');
        t.id = 'checkoutToast';
        t.style.cssText = 'position:fixed; bottom:24px; right:24px; z-index:99999; background:' + color + '; color:white; padding:12px 20px; border-radius:12px; font-size:14px; box-shadow:0 4px 16px rgba(0,0,0,0.15); animation:fadeIn 0.2s ease;';
        t.innerText = msg;
        document.body.appendChild(t);
        setTimeout(() => t.remove(), 3000);
    }
    
    function selectPayment(el, method) {
        document.querySelectorAll('.payment-option').forEach(o => o.classList.remove('selected'));
        document.querySelectorAll('[id^="check_"]').forEach(i => i.className = 'bi bi-circle text-muted ms-auto');
        el.classList.add('selected');
        document.getElementById('check_' + method).className = 'bi bi-check-circle-fill text-primary ms-auto';
        selectedPayment = method;
        document.getElementById('selectedPayment').value = method;

        const walletBal = parseFloat(document.getElementById('walletBalance').value) || 0;
        const discountRow = document.getElementById('walletDiscountRow');
        const finalDisplay = document.getElementById('finalTotalDisplay');

        if (method === 'Wallet') {
            const deduct = Math.min(walletBal, cartTotal);
            const finalAmt = Math.max(0, cartTotal - deduct);
            discountRow.style.cssText = 'display:flex; font-size:13px;';
            document.getElementById('walletDiscountAmt').innerText = '-₱' + deduct.toFixed(2);
            finalDisplay.innerText = '₱' + finalAmt.toFixed(2);
        } else {
            discountRow.style.cssText = 'display:none; font-size:13px;';
            finalDisplay.innerText = '₱' + orderTotal.toFixed(2);
        }
    }
    function openVoucherModal(filterType) {
    	fetch('VoucherServlet?action=listAll&cartTotal=<%= cartTotal %>&filterType=' + (filterType || 'platform'))
            .then(r => r.json())
            .then(d => {
                const list = document.getElementById('voucherListContainer');
                list.innerHTML = '';
                if (!d.vouchers || d.vouchers.length === 0) {
                    list.innerHTML = '<div class="text-center text-muted py-4"><i class="bi bi-ticket-perforated" style="font-size:32px;display:block;margin-bottom:8px;"></i>No available vouchers.</div>';
                
                } else {
                    var filtered = filterType === 'freeshipping' 
                        ? d.vouchers.filter(function(v) { return v.type === 'freeshipping'; })
                        : d.vouchers.filter(function(v) { return v.type !== 'freeshipping'; });
                    if (filtered.length === 0) {
                        list.innerHTML = '<div class="text-center text-muted py-4"><i class="bi bi-ticket-perforated" style="font-size:32px;display:block;margin-bottom:8px;"></i>No available vouchers.</div>';
                    } else {
                	filtered.forEach(function(v) {
                        var eligible = v.eligible;
                        var onclickAttr = eligible ? "selectVoucher('" + v.code + "', '" + v.description + "', " + v.discount + ")" : "";
                        var borderClass = eligible ? 'border-primary' : 'border-secondary opacity-50';
                        var cursorStyle = eligible ? 'pointer' : 'default';
                        var minOrderHtml = v.min_order > 0 ? '<div style="font-size:11px; color:#94a3b8;">Min. order: ₱' + v.min_order + '</div>' : '';
                        var expiryHtml = v.expiry ? '<div style="font-size:11px; color:#94a3b8;">Expires: ' + v.expiry + '</div>' : '';
                        var reasonHtml = !eligible ? '<div style="font-size:11px; color:#ef4444;" class="mt-1">' + (v.reason || 'Not eligible') + '</div>' : '';
                        var badgeClass = eligible ? 'bg-primary' : 'bg-secondary';
                        var badgeText = v.type === 'fixed' ? '₱' + v.value + ' OFF' : v.value + '% OFF';

                        list.innerHTML += '<div class="p-3 mb-2 rounded-3 border ' + borderClass + '" style="cursor:' + cursorStyle + ';" onclick="' + onclickAttr + '">'
                            + '<div class="d-flex justify-content-between align-items-center">'
                            + '<div>'
                            + '<strong class="text-primary">' + v.code + '</strong>'
                            + '<div style="font-size:12px; color:#64748b;">' + v.description + '</div>'
                            + minOrderHtml + expiryHtml
                            + '</div>'
                            + '<div class="text-end">'
                            + '<span class="badge ' + badgeClass + '">' + badgeText + '</span>'
                            + reasonHtml
                            + '</div>'
                            + '</div>'
                            + '</div>';
                	});
                    } // close filtered else
                }
                // store filterType for selectVoucher
                document.getElementById('voucherPickerModal').dataset.filterType = filterType;
                new bootstrap.Modal(document.getElementById('voucherPickerModal')).show();
            })
            .catch(() => {
                document.getElementById('voucherMsg').innerHTML = '<span class="text-danger">Error loading vouchers.</span>';
            });
    }

    function selectVoucher(code, desc, discount, isFreeShip) {
        var filterType = document.getElementById('voucherPickerModal').dataset.filterType;
        if (filterType === 'freeshipping' || isFreeShip) {
            freeShipApplied = true;
            freeShipCode = code;
            shippingFee = 0;
            document.getElementById('freeShipSelectedCode').textContent = code;
            document.getElementById('freeShipSelectedBox').classList.remove('d-none');
            document.getElementById('openFreeShipBtn').innerHTML = '<i class="bi bi-truck me-1"></i> Change Free Shipping Voucher';
        } else {
            voucherDiscount = discount;
            voucherCode = code;
            document.getElementById('voucherSelectedCode').textContent = code;
            document.getElementById('voucherSelectedDesc').textContent = desc;
            document.getElementById('voucherSelectedBox').classList.remove('d-none');
            document.getElementById('openVoucherBtn').innerHTML = '<i class="bi bi-ticket-perforated me-1"></i> Change Voucher';
            document.getElementById('voucherDiscountRow').style.display = 'flex';
            document.getElementById('voucherDiscountAmt').textContent = '-₱' + voucherDiscount.toFixed(2);
            document.getElementById('voucherMsg').innerHTML = '';
        }
        bootstrap.Modal.getInstance(document.getElementById('voucherPickerModal')).hide();
        updateTotal();
        // Always call apply so session flags are set (including appliedVoucherFreeShipping)
        fetch('VoucherServlet?action=apply&code=' + encodeURIComponent(code) + '&cartTotal=<%= cartTotal %>').then(r => r.json());
    }

    
    function applyManualVoucher() {
        const code = document.getElementById('manualVoucherCode').value.trim().toUpperCase();
        const msg = document.getElementById('manualVoucherMsg');
        if (!code) { msg.innerHTML = '<span class="text-danger">Please enter a voucher code.</span>'; return; }

        fetch('VoucherServlet?action=apply&code=' + encodeURIComponent(code) + '&cartTotal=<%= cartTotal %>')
            .then(r => r.json())
            .then(d => {
                if (d.success) {
                    selectVoucher(code, d.message, d.discount);
                    msg.innerHTML = '';
                } else {
                    msg.innerHTML = '<span class="text-danger"><i class="bi bi-x-circle"></i> ' + d.message + '</span>';
                }
            });
    }
    function removeFreeShip() {
        freeShipApplied = false;
        freeShipCode = '';
        shippingFee = <%= cartTotal >= 500 ? 0 : 38 %>;
        document.getElementById('freeShipSelectedBox').classList.add('d-none');
        document.getElementById('openFreeShipBtn').innerHTML = '<i class="bi bi-truck me-1"></i> Select Free Shipping Voucher';
        fetch('VoucherServlet?action=removeFreeShip').catch(() => {});
        updateTotal();
    }
    function removeVoucher() {
        voucherDiscount = 0;
        voucherCode = '';
        document.getElementById('voucherSelectedBox').classList.add('d-none');
        document.getElementById('openVoucherBtn').innerHTML = '<i class="bi bi-ticket-perforated me-1"></i> Select Voucher';
        document.getElementById('voucherDiscountRow').style.display = 'none';
        document.getElementById('voucherDiscountAmt').textContent = '-₱0.00';
        fetch('VoucherServlet?action=removeVoucher').catch(() => {});
        updateTotal();
    }

    function updateTotal() {
        const walletAmt = parseFloat(document.getElementById('walletDiscountAmt').textContent.replace('-₱','')) || 0;
        const currentShipping = freeShipApplied ? 0 : shippingFee;
        const newTotal = Math.max(0, cartTotal + currentShipping - voucherDiscount - walletAmt);
        document.getElementById('finalTotalDisplay').textContent = '₱' + newTotal.toFixed(2);

        // Update You save
        const baseSavings = <%= ckSavings %>;
        const shippingSaved = freeShipApplied ? 38 : 0;
        const totalSaved = baseSavings + voucherDiscount + shippingSaved;
        const youSaveRow = document.getElementById('youSaveRow');
        const youSaveAmt = document.getElementById('youSaveAmt');
        if (totalSaved > 0) {
            youSaveRow.style.display = 'flex';
            youSaveAmt.textContent = '-₱' + totalSaved.toFixed(2);
        } else {
            youSaveRow.style.display = 'none';
        }

        // Update shipping display
        const shipDisplay = document.getElementById('shippingDisplay');
        const shipHint = document.getElementById('freeShipHint');
        if (freeShipApplied) {
            shipDisplay.innerHTML = '<i class="bi bi-truck text-success"></i> <span class="text-success fw-bold">Free 🎉</span>';
            if (shipHint) shipHint.style.display = 'none';
        } else {
            shipDisplay.innerHTML = shippingFee === 0 ? '<i class="bi bi-truck text-success"></i> <span class="text-success fw-bold">Free</span>' : '<span class="text-danger fw-bold">₱38.00</span>';
            if (shipHint && shippingFee > 0) shipHint.style.display = 'block';
        }
    }
    async function placeOrder() {
        const name = document.getElementById('shipName').value.trim();
        const address = document.getElementById('shipAddress').value.trim();
        const phone = document.getElementById('shipPhone').value.trim();

        // Debug: if fields empty but saved address selected, re-populate
        if (!name || !address || !phone) {
            const selected = document.querySelector('.saved-addr-card.addr-selected');
            if (selected) {
                selected.click();
                setTimeout(placeOrder, 100);
                return;
            }
        }

        if (!name) {
            showToast('Please enter your full name!', '#dc3545');
            document.getElementById('shipName').focus();
            return;
        }
        if (!address) {
            showToast('Please enter your delivery address!', '#dc3545');
            document.getElementById('shipAddress').focus();
            return;
        }
        if (!phone) {
            showToast('Please enter your phone number!', '#dc3545');
            document.getElementById('shipPhone').focus();
            return;
        }
        const cleanPhone = phone.replace(/[\s\-\(\)]/g, '').replace(/^\+?63/, '').replace(/\D/g, '');
        if (!/^\d{10}$/.test(cleanPhone)) {
            showToast('Phone number must be exactly 10 digits! (e.g. 9171234567)', '#dc3545');
            document.getElementById('shipPhone').focus();
            return;
        }

        // Intercept GCash / Card — show payment modal first
        const currentTotal = parseFloat(document.getElementById('finalTotalDisplay').textContent.replace('₱','')) || 0;
        if (selectedPayment === 'GCash') {
            document.getElementById('gcashAmountDisplay').textContent = '₱' + currentTotal.toFixed(2);
            new bootstrap.Modal(document.getElementById('gcashModal')).show();
            return;
        }
        if (selectedPayment === 'Card') {
            document.getElementById('cardAmountDisplay').textContent = '₱' + currentTotal.toFixed(2);
            document.getElementById('cardPayBtnAmt').textContent = '₱' + currentTotal.toFixed(2);
            new bootstrap.Modal(document.getElementById('cardModal')).show();
            return;
        }

        const btn = document.querySelector('.place-order-btn');
        btn.disabled = true;
        btn.innerHTML = '<i class="bi bi-hourglass-split"></i> Placing Order...';
        const overlay = document.getElementById('processingOverlay');
        overlay.style.display = 'flex';

        // COD / Wallet — submit directly
        submitOrder();
    }
    
    function selectAddress(name, phone, address, el) {
        usingNewAddress = false;
        document.getElementById('newAddressForm').style.display = 'none';
        document.querySelector('[onclick*="toggleNewAddress"]').innerHTML = '<i class="bi bi-plus-circle"></i> Use a Different Address';
        document.querySelectorAll('.saved-addr-card').forEach(c => {
            c.style.borderColor = '';
            c.style.background = '';
            c.classList.remove('addr-selected');
        });
        el.style.borderColor = '#0d6efd';
        el.style.background = '#f0f4ff';
        el.classList.add('addr-selected');
        document.getElementById('shipName').value = name;
        document.getElementById('shipPhone').value = phone;
        document.getElementById('shipAddress').value = address;
    }

    // Auto-select default address on load
    window.addEventListener('load', function() {
        const defaultCard = document.querySelector('.saved-addr-card');
        if (defaultCard) defaultCard.click();
    });

    // ── GCash helpers ──────────────────────────────────────────────
    function copyGcashNumber() {
        navigator.clipboard.writeText('09171234567').then(() => showToast('GCash number copied!'));
    }
    function validateGcashRef() {
        const v = document.getElementById('gcashRefInput').value;
        document.getElementById('gcashRefError').style.display = v.length > 0 && v.length < 13 ? 'block' : 'none';
    }
    function confirmGcashPayment() {
        const ref = document.getElementById('gcashRefInput').value.trim();
        if (ref.length !== 13) {
            document.getElementById('gcashRefError').style.display = 'block';
            return;
        }
        bootstrap.Modal.getInstance(document.getElementById('gcashModal')).hide();
        submitOrder();
    }

    // ── Card helpers ───────────────────────────────────────────────
    function formatCardNumber(input) {
        let v = input.value.replace(/\D/g,'').substring(0,16);
        input.value = v.replace(/(.{4})/g,'$1 ').trim();
        const masked = v.length > 0 
            ? v.substring(0,4).padEnd(4,'•') + ' ' + (v.length > 4 ? v.substring(4,8) : '••••') + ' •••• ' + (v.length > 12 ? v.substring(12) : '••••')
            : '•••• •••• •••• ••••';
        document.getElementById('cardPreviewNumber').textContent = masked;
    }
    function formatExpiry(input) {
        let v = input.value.replace(/\D/g,'').substring(0,4);
        if (v.length >= 3) v = v.substring(0,2) + '/' + v.substring(2);
        input.value = v;
        document.getElementById('cardPreviewExpiry').textContent = v || 'MM/YY';
    }
    function confirmCardPayment() {
        const num = document.getElementById('cardNumberInput').value.replace(/\s/g,'');
        const name = document.getElementById('cardNameInput').value.trim();
        const expiry = document.getElementById('cardExpiryInput').value;
        const cvv = document.getElementById('cardCvvInput').value;
        const errEl = document.getElementById('cardError');
        const errMsg = document.getElementById('cardErrorMsg');

        if (num.length < 16) { errMsg.textContent = 'Card number must be 16 digits.'; errEl.style.display='block'; return; }
        if (!name) { errMsg.textContent = 'Please enter the name on your card.'; errEl.style.display='block'; return; }
        if (!/^\d{2}\/\d{2}$/.test(expiry)) { errMsg.textContent = 'Invalid expiry date format (MM/YY).'; errEl.style.display='block'; return; }
        if (cvv.length < 3) { errMsg.textContent = 'CVV must be 3–4 digits.'; errEl.style.display='block'; return; }
        errEl.style.display = 'none';

        bootstrap.Modal.getInstance(document.getElementById('cardModal')).hide();
        submitOrder();
    }

    // ── Shared actual order submission ─────────────────────────────
    async function submitOrder() {
        const btn = document.querySelector('.place-order-btn');
        btn.disabled = true;
        btn.innerHTML = '<i class="bi bi-hourglass-split"></i> Placing Order...';
        const overlay = document.getElementById('processingOverlay');
        overlay.style.display = 'flex';

        const name = document.getElementById('shipName').value.trim();
        const address = document.getElementById('shipAddress').value.trim();
        const phone = document.getElementById('shipPhone').value.trim();
        const cleanPhone = phone.replace(/[\s\-\(\)]/g,'').replace(/^\+?63/,'').replace(/\D/g,'');

        try {
            if (voucherCode) await fetch('VoucherServlet?action=apply&code=' + encodeURIComponent(voucherCode) + '&cartTotal=<%= cartTotal %>');
            if (freeShipCode) {
                await fetch('VoucherServlet?action=apply&code=' + encodeURIComponent(freeShipCode) + '&cartTotal=<%= cartTotal %>');
                await new Promise(r => setTimeout(r, 300));
            }
        } catch(e) {}

        await new Promise(r => setTimeout(r, 200));
        fetch('CheckoutServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'shipName=' + encodeURIComponent(name) +
                  '&voucherCode=' + encodeURIComponent(voucherCode) +
                  '&freeShipCode=' + encodeURIComponent(freeShipCode) +
                  '&shipAddress=' + encodeURIComponent(address) +
                  '&shipPhone=' + encodeURIComponent(cleanPhone) +
                  '&paymentMethod=' + encodeURIComponent(selectedPayment) +
                  '&useWallet=' + (selectedPayment === 'Wallet' ? 'true' : 'false') +
                  '&walletDeduct=' + (selectedPayment === 'Wallet' ? Math.min(parseFloat(document.getElementById('walletBalance').value)||0, cartTotal).toFixed(2) : '0') +
                  '&isBuyNow=<%= isBuyNow ? "true" : "false" %>'
        }).then(res => res.json())
          .then(data => {
              if (data.success) {
                  setTimeout(function() {
                      let orderIdsParam = data.orderIds ? data.orderIds.join(',') : data.orderId;
                      window.location.href = 'order_success.jsp?orderId=' + data.orderId + '&orderIds=' + orderIdsParam;
                  }, 2500);
              } else {
                  overlay.style.display = 'none';
                  btn.disabled = false;
                  btn.innerHTML = '<i class="bi bi-bag-check"></i> Place Order';
                  showToast('Error: ' + data.message, '#dc3545');
              }
          }).catch(err => {
              overlay.style.display = 'none';
              btn.disabled = false;
              btn.innerHTML = '<i class="bi bi-bag-check"></i> Place Order';
              showToast('Connection error. Please try again.', '#dc3545');
          });
    }

    function toggleNewAddress() {
        const form = document.getElementById('newAddressForm');
        usingNewAddress = !usingNewAddress;
        if (usingNewAddress) {
            form.style.display = 'flex';
            form.style.flexWrap = 'wrap';
            form.style.gap = '12px';
            // Deselect all saved address cards
            document.querySelectorAll('.saved-addr-card').forEach(c => {
                c.style.borderColor = '';
                c.style.background = '';
            });
            // Clear fields for fresh input
            document.getElementById('shipName').value = '';
            document.getElementById('shipAddress').value = '';
            document.getElementById('shipPhone').value = '';
            document.querySelector('[onclick*="toggleNewAddress"]').innerHTML = '<i class="bi bi-x-circle"></i> Cancel';
        } else {
            form.style.display = 'none';
            usingNewAddress = false;
            document.querySelector('[onclick*="toggleNewAddress"]').innerHTML = '<i class="bi bi-plus-circle"></i> Use a Different Address';
            // Re-select default saved address
            const defaultCard = document.querySelector('.saved-addr-card');
            if (defaultCard) defaultCard.click();
        }
    }

</script>
</body>
</html>