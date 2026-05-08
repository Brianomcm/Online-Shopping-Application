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
    </style>
</head>
<body>

<!-- NAVBAR -->
<% request.setAttribute("navType", "checkout"); %>
<%@ include file="navbar.jsp" %>

<!-- BREADCRUMB -->
<div class="bg-white border-bottom px-4 py-2">
    <nav aria-label="breadcrumb">
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
        <div class="col-lg-8">

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
                        <input type="text" class="form-control" id="shipName" value="<%= userName != null ? userName : "" %>">
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-bold" style="font-size:13px;">Delivery Address</label>
                        <textarea class="form-control" rows="2" id="shipAddress" placeholder="Enter your full delivery address"><%= userAddress %></textarea>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold" style="font-size:13px;">Phone Number</label>
                        <div class="input-group">
                            <span class="input-group-text">+63</span>
                            <input type="tel" class="form-control" id="shipPhone" value="<%= session.getAttribute("userPhone") != null ? session.getAttribute("userPhone") : "" %>">
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
                <input type="hidden" id="selectedPayment" value="COD">
            </div>

            <!-- ORDER ITEMS -->
            <div class="card-section">
                <p class="section-title"><span class="step-badge">3</span> Order Items (<%= cartItems.size() %>)</p>
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
        <div class="col-lg-4">
            <div class="summary-card">
                <h6 class="fw-bold mb-3">Order Summary</h6>
                <div class="d-flex justify-content-between mb-2">
                    <span class="text-muted">Items (<%= cartItems.size() %>)</span>
                    <span>₱<%= String.format("%.2f", cartTotal) %></span>
                </div>
                <div class="d-flex justify-content-between mb-2">
                    <span class="text-muted">Shipping</span>
                    <span class="text-success">Free</span>
                </div>
                <hr>
                <div class="d-flex justify-content-between fw-bold fs-5 mb-4">
                    <span>Total</span>
                    <span class="text-primary">₱<%= String.format("%.2f", cartTotal) %></span>
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

<!-- PROCESSING ORDER OVERLAY -->
<div id="processingOverlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.95); z-index:9999; flex-direction:column; align-items:center; justify-content:center;">
    <div class="spinner-border text-primary mb-3" style="width:3.5rem; height:3.5rem;" role="status"></div>
    <p class="fw-bold text-primary fs-5">Processing Order...</p>
    <p class="text-muted" style="font-size:13px;">Please wait, do not close this page.</p>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
    let selectedPayment = 'COD';

    function selectPayment(el, method) {
        document.querySelectorAll('.payment-option').forEach(o => {
            o.classList.remove('selected');
        });
        document.querySelectorAll('[id^="check_"]').forEach(i => {
            i.className = 'bi bi-circle text-muted ms-auto';
        });
        el.classList.add('selected');
        document.getElementById('check_' + method).className = 'bi bi-check-circle-fill text-primary ms-auto';
        selectedPayment = method;
        document.getElementById('selectedPayment').value = method;
    }

    function placeOrder() {
        const name = document.getElementById('shipName').value.trim();
        const address = document.getElementById('shipAddress').value.trim();
        const phone = document.getElementById('shipPhone').value.trim();

        if (!name || !address || !phone) {
            alert('Please fill in all shipping details!');
            return;
        }

        const btn = document.querySelector('.place-order-btn');
        btn.disabled = true;
        btn.innerHTML = '<i class="bi bi-hourglass-split"></i> Placing Order...';

        const overlay = document.getElementById('processingOverlay');
        overlay.style.display = 'flex';

        fetch('CheckoutServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'shipName=' + encodeURIComponent(name) +
                  '&shipAddress=' + encodeURIComponent(address) +
                  '&shipPhone=' + encodeURIComponent(phone) +
                  '&paymentMethod=' + encodeURIComponent(selectedPayment) +
                  '&isBuyNow=<%= isBuyNow ? "true" : "false" %>'
        }).then(res => res.json())
          .then(data => {
    if (data.success) {
        setTimeout(function() {
            window.location.href = 'order_success.jsp?orderId=' + data.orderId;
        }, 2500);
    } else {
                  alert('Error: ' + data.message);
                  btn.disabled = false;
                  btn.innerHTML = '<i class="bi bi-bag-check"></i> Place Order';
              }
          });
    }
    
    function selectAddress(name, phone, address, el) {
        usingNewAddress = false;
        document.getElementById('newAddressForm').style.display = 'none';
        document.querySelector('[onclick*="toggleNewAddress"]').innerHTML = '<i class="bi bi-plus-circle"></i> Use a Different Address';
        document.querySelectorAll('.saved-addr-card').forEach(c => {
            c.style.borderColor = '';
            c.style.background = '';
        });
        el.style.borderColor = '#0d6efd';
        el.style.background = '#f0f4ff';
        document.getElementById('shipName').value = name;
        document.getElementById('shipPhone').value = phone;
        document.getElementById('shipAddress').value = address;
    }

    // Auto-select default address on load
    window.addEventListener('load', function() {
        const defaultCard = document.querySelector('.saved-addr-card');
        if (defaultCard) defaultCard.click();
    });
    
    let usingNewAddress = <%= savedAddresses.isEmpty() ? "true" : "false" %>;

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