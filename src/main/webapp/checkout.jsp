<%@ page session="true" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%
    if(session.getAttribute("userId") == null || !"customer".equals(session.getAttribute("userRole"))) {
        response.sendRedirect("index.jsp");
        return;
    }
    String userName = (String) session.getAttribute("userName");
    String userAvatar = (String) session.getAttribute("userAvatar");
    String userAddress = (String) session.getAttribute("userAddress");
    List<Map<String, Object>> cartItems = (List<Map<String, Object>>) session.getAttribute("checkoutItems");
    Double cartTotal = (Double) session.getAttribute("checkoutTotal");
    if (cartItems == null) { response.sendRedirect("CartServlet"); return; }
    if (cartTotal == null) cartTotal = 0.0;
    if (userAddress == null) userAddress = "";
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
        .card-section { background: white; border-radius: 16px; box-shadow: 0 2px 12px rgba(0,0,0,0.07); padding: 24px; margin-bottom: 20px; }
        .section-title { font-size: 15px; font-weight: 700; color: #1a1a2e; margin-bottom: 16px; padding-bottom: 10px; border-bottom: 2px solid #e8f0fe; }
        .product-img { width: 60px; height: 60px; object-fit: cover; border-radius: 8px; border: 1px solid #eee; }
        .product-img-placeholder { width: 60px; height: 60px; background: #f0f0f0; border-radius: 8px; display: flex; align-items: center; justify-content: center; color: #aaa; font-size: 22px; }
        .payment-option { border: 2px solid #dee2e6; border-radius: 12px; padding: 14px; cursor: pointer; transition: 0.2s; margin-bottom: 10px; }
        .payment-option:hover { border-color: #0d6efd; background: #f0f4ff; }
        .payment-option.selected { border-color: #0d6efd; background: #f0f4ff; }
        .summary-card { background: white; border-radius: 16px; box-shadow: 0 2px 12px rgba(0,0,0,0.07); padding: 24px; position: sticky; top: 80px; }
        .place-order-btn { background: linear-gradient(135deg, #0d6efd, #6610f2); border: none; border-radius: 12px; padding: 14px; font-size: 16px; font-weight: 700; }
        .avatar-circle { width: 36px; height: 36px; border-radius: 50%; background: #0d6efd; color: white; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 14px; overflow: hidden; }
        .step-badge { background: #0d6efd; color: white; border-radius: 50%; width: 28px; height: 28px; display: inline-flex; align-items: center; justify-content: center; font-weight: 700; font-size: 13px; margin-right: 8px; }
    </style>
</head>
<body>

<!-- NAVBAR -->
<nav class="navbar navbar-light bg-white shadow-sm sticky-top px-3">
    <a class="navbar-brand" href="index.jsp"><i class="bi bi-bag-heart-fill text-primary"></i> ShopEasy</a>
    <div class="d-flex align-items-center gap-3">
        <a href="CartServlet" class="btn btn-outline-primary btn-sm"><i class="bi bi-cart3"></i> Back to Cart</a>
        <div class="avatar-circle">
            <% if (userAvatar != null && !userAvatar.isEmpty()) { %>
                <img src="<%= userAvatar %>" style="width:100%;height:100%;object-fit:cover;">
            <% } else { %>
                <%= userName != null ? String.valueOf(userName.charAt(0)).toUpperCase() : "U" %>
            <% } %>
        </div>
    </div>
</nav>

<div class="container py-4">
    <h5 class="fw-bold mb-4"><i class="bi bi-bag-check text-primary"></i> Checkout</h5>

    <div class="row g-4">
        <div class="col-lg-8">

            <!-- SHIPPING ADDRESS -->
            <div class="card-section">
                <p class="section-title"><span class="step-badge">1</span> Shipping Address</p>
                <div class="row g-3">
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
                <a href="CartServlet" class="btn btn-outline-secondary w-100 mt-2">
                    <i class="bi bi-arrow-left"></i> Back to Cart
                </a>
            </div>
        </div>
    </div>
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

        fetch('CheckoutServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'shipName=' + encodeURIComponent(name) +
                  '&shipAddress=' + encodeURIComponent(address) +
                  '&shipPhone=' + encodeURIComponent(phone) +
                  '&paymentMethod=' + encodeURIComponent(selectedPayment)
        }).then(res => res.json())
          .then(data => {
              if (data.success) {
                  window.location.href = 'order_success.jsp?orderId=' + data.orderId;
              } else {
                  alert('Error: ' + data.message);
                  btn.disabled = false;
                  btn.innerHTML = '<i class="bi bi-bag-check"></i> Place Order';
              }
          });
    }
</script>
</body>
</html>