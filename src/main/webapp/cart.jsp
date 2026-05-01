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
    List<Map<String, Object>> cartItems = (List<Map<String, Object>>) request.getAttribute("cartItems");
    Double cartTotal = (Double) request.getAttribute("cartTotal");
    if (cartItems == null) cartItems = new ArrayList<>();
    if (cartTotal == null) cartTotal = 0.0;
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Cart - ShopEasy</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css">
    <style>
        body { background: #f8f9fa; font-family: 'Segoe UI', sans-serif; }
        .navbar-brand { font-weight: 800; color: #0d6efd !important; font-size: 22px; }
        .cart-card { background: white; border-radius: 16px; box-shadow: 0 2px 12px rgba(0,0,0,0.07); padding: 20px; margin-bottom: 16px; }
        .product-img { width: 80px; height: 80px; object-fit: cover; border-radius: 10px; border: 1px solid #eee; }
        .product-img-placeholder { width: 80px; height: 80px; background: #f0f0f0; border-radius: 10px; display: flex; align-items: center; justify-content: center; color: #aaa; font-size: 28px; }
        .qty-btn { width: 32px; height: 32px; border-radius: 50%; border: 1px solid #dee2e6; background: white; font-size: 16px; display: flex; align-items: center; justify-content: center; cursor: pointer; }
        .qty-btn:hover { background: #0d6efd; color: white; border-color: #0d6efd; }
        .qty-display { width: 40px; text-align: center; font-weight: 700; font-size: 15px; }
        .summary-card { background: white; border-radius: 16px; box-shadow: 0 2px 12px rgba(0,0,0,0.07); padding: 20px; position: sticky; top: 80px; }
        .remove-btn { color: #dc3545; background: none; border: none; font-size: 18px; cursor: pointer; padding: 4px 8px; border-radius: 8px; }
        .remove-btn:hover { background: #fff0f0; }
        .empty-cart { text-align: center; padding: 60px 20px; color: #aaa; }
        .checkout-btn { background: linear-gradient(135deg, #0d6efd, #6610f2); border: none; border-radius: 12px; padding: 14px; font-size: 16px; font-weight: 700; }
        .checkout-btn:hover { opacity: 0.9; }
        .avatar-circle { width: 36px; height: 36px; border-radius: 50%; background: #0d6efd; color: white; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 14px; overflow: hidden; }
        .toast-container { position: fixed; bottom: 24px; right: 24px; z-index: 9999; }
        .toast-msg { background: #198754; color: white; padding: 12px 20px; border-radius: 12px; font-size: 14px; box-shadow: 0 4px 16px rgba(0,0,0,0.15); margin-top: 8px; }
    </style>
</head>
<body>

<!-- NAVBAR -->
<nav class="navbar navbar-light bg-white shadow-sm sticky-top px-3">
    <a class="navbar-brand" href="index.jsp"><i class="bi bi-bag-heart-fill text-primary"></i> ShopEasy</a>
    <div class="d-flex align-items-center gap-3">
        <a href="index.jsp" class="btn btn-outline-primary btn-sm"><i class="bi bi-shop"></i> Shop</a>
        <a href="ProfileServlet" class="d-flex align-items-center gap-2 text-decoration-none text-dark">
            <div class="avatar-circle">
                <% if (userAvatar != null && !userAvatar.isEmpty()) { %>
                    <img src="<%= userAvatar %>" style="width:100%;height:100%;object-fit:cover;">
                <% } else { %>
                    <%= userName != null && !userName.isEmpty() ? String.valueOf(userName.charAt(0)).toUpperCase() : "U" %>
                <% } %>
            </div>
        </a>
    </div>
</nav>

<div class="container py-4">
    <h5 class="fw-bold mb-4"><i class="bi bi-cart3 text-primary"></i> My Cart
        <span class="badge bg-primary ms-2"><%= cartItems.size() %></span>
    </h5>

    <% if (cartItems.isEmpty()) { %>
    <div class="empty-cart">
        <i class="bi bi-cart-x" style="font-size: 64px; opacity: 0.2;"></i>
        <p class="mt-3 fs-5">Your cart is empty</p>
        <a href="index.jsp" class="btn btn-primary mt-2"><i class="bi bi-shop"></i> Continue Shopping</a>
    </div>
    <% } else { %>
    <div class="row g-4">
        <!-- Cart Items -->
        <div class="col-lg-8">
            <% for (Map<String, Object> item : cartItems) { %>
            <div class="cart-card" id="cartItem_<%= item.get("cartitemId") %>">
                <div class="d-flex gap-3 align-items-center">
                    <!-- Product Image -->
                    <% if (item.get("image") != null) { %>
                        <img src="<%= item.get("image") %>" class="product-img" alt="<%= item.get("name") %>">
                    <% } else { %>
                        <div class="product-img-placeholder"><i class="bi bi-image"></i></div>
                    <% } %>

                    <!-- Product Info -->
                    <div class="flex-grow-1">
                        <h6 class="mb-1 fw-bold"><%= item.get("name") %></h6>
                        <p class="text-danger fw-bold mb-1">₱<%= String.format("%.2f", item.get("price")) %></p>
                        <p class="text-muted mb-0" style="font-size:11px;">Stock: <%= item.get("stock") %></p>
                    </div>

                    <!-- Quantity + Remove -->
                    <div class="d-flex flex-column align-items-end gap-2">
                        <button class="remove-btn" onclick="removeItem(<%= item.get("cartitemId") %>)">
                            <i class="bi bi-trash"></i>
                        </button>
                        <div class="d-flex align-items-center gap-1">
                            <button class="qty-btn" onclick="changeQty(<%= item.get("cartitemId") %>, -1, <%= item.get("stock") %>)">−</button>
                            <span class="qty-display" id="qty_<%= item.get("cartitemId") %>"><%= item.get("quantity") %></span>
                            <button class="qty-btn" onclick="changeQty(<%= item.get("cartitemId") %>, 1, <%= item.get("stock") %>)">+</button>
                        </div>
                        <span class="text-muted fw-bold" style="font-size:13px;" id="sub_<%= item.get("cartitemId") %>">
                            ₱<%= String.format("%.2f", item.get("subtotal")) %>
                        </span>
                    </div>
                </div>
            </div>
            <% } %>
        </div>

        <!-- Order Summary -->
        <div class="col-lg-4">
            <div class="summary-card">
                <h6 class="fw-bold mb-3">Order Summary</h6>
                <div class="d-flex justify-content-between mb-2">
                    <span class="text-muted">Items (<%= cartItems.size() %>)</span>
                    <span id="summaryTotal">₱<%= String.format("%.2f", cartTotal) %></span>
                </div>
                <div class="d-flex justify-content-between mb-2">
                    <span class="text-muted">Shipping</span>
                    <span class="text-success">Free</span>
                </div>
                <hr>
                <div class="d-flex justify-content-between fw-bold fs-5 mb-4">
                    <span>Total</span>
                    <span class="text-primary" id="grandTotal">₱<%= String.format("%.2f", cartTotal) %></span>
                </div>
                <button class="btn btn-primary checkout-btn w-100 text-white" onclick="checkout()">
                    <i class="bi bi-bag-check"></i> Proceed to Checkout
                </button>
                <a href="index.jsp" class="btn btn-outline-secondary w-100 mt-2">
                    <i class="bi bi-arrow-left"></i> Continue Shopping
                </a>
            </div>
        </div>
    </div>
    <% } %>
</div>

<!-- Toast -->
<div class="toast-container" id="toastContainer"></div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
    const prices = {};
    <% for (Map<String, Object> item : cartItems) { %>
        prices[<%= item.get("cartitemId") %>] = <%= item.get("price") %>;
    <% } %>

    function showToast(msg, color = '#198754') {
        const t = document.createElement('div');
        t.className = 'toast-msg';
        t.style.background = color;
        t.innerText = msg;
        document.getElementById('toastContainer').appendChild(t);
        setTimeout(() => t.remove(), 3000);
    }

    function changeQty(itemId, delta, stock) {
        const qtyEl = document.getElementById('qty_' + itemId);
        let qty = parseInt(qtyEl.innerText) + delta;
        if (qty < 1) { removeItem(itemId); return; }
        if (qty > stock) { showToast('Not enough stock!', '#dc3545'); return; }
        qtyEl.innerText = qty;

        // Update subtotal
        const sub = prices[itemId] * qty;
        document.getElementById('sub_' + itemId).innerText = '₱' + sub.toFixed(2);
        updateTotal();

        // Save to server
        fetch('UpdateCartServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'cartitemId=' + itemId + '&quantity=' + qty
        });
    }

    function removeItem(itemId) {
        if (!confirm('Remove this item from cart?')) return;
        fetch('RemoveCartServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'cartitemId=' + itemId
        }).then(() => {
            document.getElementById('cartItem_' + itemId).remove();
            delete prices[itemId];
            updateTotal();
            showToast('Item removed from cart');
        });
    }

    function updateTotal() {
        let total = 0;
        document.querySelectorAll('[id^="sub_"]').forEach(el => {
            total += parseFloat(el.innerText.replace('₱',''));
        });
        document.getElementById('summaryTotal').innerText = '₱' + total.toFixed(2);
        document.getElementById('grandTotal').innerText = '₱' + total.toFixed(2);
    }

    function checkout() {
        fetch('PrepareCheckoutServlet', {
            method: 'POST'
        }).then(res => res.json())
          .then(data => {
              if (data.success) {
                  window.location.href = 'checkout.jsp';
              } else {
                  showToast(data.message, '#dc3545');
              }
          });
    }
</script>
</body>
</html>