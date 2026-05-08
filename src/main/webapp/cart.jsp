<%@ page session="true" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%
String cartRole = (String) session.getAttribute("userRole");
if(session.getAttribute("userId") == null || cartRole == null || 
   (!cartRole.equals("customer") && !cartRole.equals("both"))) {
        response.sendRedirect("index.jsp");
        return;
    }
    String userName = (String) session.getAttribute("userName");
    String userAvatar = (String) session.getAttribute("userAvatar");
    List<Map<String, Object>> cartItems = (List<Map<String, Object>>) request.getAttribute("cartItems");
    Double cartTotal = (Double) request.getAttribute("cartTotal");
    if (cartItems == null) { response.sendRedirect("CartServlet"); return; }
    if (cartTotal == null) cartTotal = 0.0;
 
 // Track breadcrumb
   String prevCrumb = (String) session.getAttribute("breadcrumb");
if ("product".equals(prevCrumb) || "seller".equals(prevCrumb)) {
    session.setAttribute("breadcrumb", "product-cart");
} else if (!"product-cart".equals(prevCrumb)) {
    session.setAttribute("breadcrumb", "cart");
    session.removeAttribute("lastProductId");
    session.removeAttribute("lastProduct");
}
    // if already "product-cart", keep it — para hindi mawala ang history
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
        .empty-cart { text-align: center; padding: 80px 20px; }
        .empty-cart-icon { font-size: 90px; background: linear-gradient(135deg, #e0e7ff, #f0f4ff); border-radius: 50%; width: 160px; height: 160px; display: flex; align-items: center; justify-content: center; margin: 0 auto 24px; }
        .empty-cart h4 { font-weight: 700; color: #222; margin-bottom: 8px; }
        .empty-cart p { color: #999; font-size: 14px; margin-bottom: 24px; }
        .btn-shop-now { background: linear-gradient(135deg, #0d6efd, #6610f2); color: white; border: none; border-radius: 50px; padding: 12px 32px; font-weight: 600; font-size: 15px; text-decoration: none; display: inline-flex; align-items: center; gap: 8px; transition: 0.2s; }
        .btn-shop-now:hover { opacity: 0.88; color: white; transform: translateY(-1px); }
        .checkout-btn { background: linear-gradient(135deg, #0d6efd, #6610f2); border: none; border-radius: 12px; padding: 14px; font-size: 16px; font-weight: 700; }
        .checkout-btn:hover { opacity: 0.9; }
        .avatar-circle { width: 36px; height: 36px; border-radius: 50%; background: #0d6efd; color: white; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 14px; overflow: hidden; }
        .toast-container { position: fixed; bottom: 24px; right: 24px; z-index: 9999; }
        .toast-msg { background: #198754; color: white; padding: 12px 20px; border-radius: 12px; font-size: 14px; box-shadow: 0 4px 16px rgba(0,0,0,0.15); margin-top: 8px; }
    </style>
</head>
<body>

<!-- NAVBAR -->
<!-- NAVBAR -->
<%
    int cartNavCount = 0;
    try {
        Integer cartNavCustId = (Integer) session.getAttribute("customerId");
        if (cartNavCustId == null) cartNavCustId = (Integer) session.getAttribute("userId");
        if (cartNavCustId != null) {
            java.sql.Connection cartNavConn = com.shopeasy.DBConnection.getConnection();
            java.sql.PreparedStatement cartNavPs = cartNavConn.prepareStatement(
                "SELECT SUM(ci.quantity) FROM cart c JOIN cartitem ci ON c.cart_id = ci.cart_id WHERE c.customer_id = ? AND ci.quantity > 0");
            cartNavPs.setInt(1, cartNavCustId);
            java.sql.ResultSet cartNavRs = cartNavPs.executeQuery();
            if (cartNavRs.next()) cartNavCount = cartNavRs.getInt(1);
            cartNavRs.close(); cartNavPs.close(); cartNavConn.close();
        }
    } catch (Exception ex) { ex.printStackTrace(); }
    request.setAttribute("navType", "simple");
    request.setAttribute("navBackUrl", "index.jsp");
    request.setAttribute("navBackLabel", "Home");
    request.setAttribute("navCartCount", cartNavCount);
%>
<%@ include file="navbar.jsp" %>
<!-- BREADCRUMB -->
<div class="bg-white border-bottom px-4 py-2">
    <nav aria-label="breadcrumb">
        <ol class="breadcrumb mb-0" style="font-size:13px;">
            <li class="breadcrumb-item"><a href="index.jsp" class="text-decoration-none text-primary">Home</a></li>
            <%
                String cartCrumb = (String) session.getAttribute("breadcrumb");
                Integer lpId = (Integer) session.getAttribute("lastProductId");
                String lpName = (String) session.getAttribute("lastProduct");
                if ("product-cart".equals(cartCrumb) && lpId != null && lpName != null) {
            %>
                <li class="breadcrumb-item">
                    <a href="product.jsp?id=<%= lpId %>" class="text-decoration-none text-primary"><%= lpName %></a>
                </li>
            <% } %>
            <li class="breadcrumb-item active text-muted">Cart</li>
        </ol>
    </nav>
</div>
<div class="container py-4">
    <h5 class="fw-bold mb-4 d-flex align-items-center gap-2">
    <span><i class="bi bi-cart3 text-primary"></i> My Cart
        <%
int badgeCount = 0;
for (Map<String, Object> ci : cartItems) {
    if ((int)ci.get("quantity") > 0) badgeCount++;
}
%>
<span class="badge bg-primary ms-2"><%= badgeCount %></span>
    </span>
    <% if (badgeCount > 0) { %>
    <button class="btn btn-outline-danger btn-sm ms-auto" onclick="removeAll()">
        <i class="bi bi-trash3"></i> Remove All
    </button>
    <% } %>
</h5>

    <%
boolean allZero = true;
for (Map<String, Object> ci : cartItems) {
    if ((int)ci.get("quantity") > 0) { allZero = false; break; }
}
if (cartItems.isEmpty()) { %>
    <div class="empty-cart">
        <div class="empty-cart-icon">
            <i class="bi bi-cart-x" style="font-size: 52px; color: #6610f2; opacity: 0.5;"></i>
        </div>
        <h4>Your cart is empty</h4>
        <p>Looks like you haven't added anything yet.<br>Browse our products and find something you like!</p>
        <a href="index.jsp" class="btn-shop-now">
            <i class="bi bi-bag-heart-fill"></i> Start Shopping
        </a>
    </div>
    <% } else { %>
    <div class="row g-4">
        <!-- Cart Items -->
       <div class="col-lg-8">
<%
// Group items by seller
java.util.LinkedHashMap<Integer, java.util.List<java.util.Map<String, Object>>> shopGroups = new java.util.LinkedHashMap<>();
for (java.util.Map<String, Object> item : cartItems) {
    int sid = (int) item.get("sellerId");
    if (!shopGroups.containsKey(sid)) shopGroups.put(sid, new java.util.ArrayList<>());
    shopGroups.get(sid).add(item);
}
for (java.util.Map.Entry<Integer, java.util.List<java.util.Map<String, Object>>> entry : shopGroups.entrySet()) {
    int groupSellerId = entry.getKey();
    java.util.List<java.util.Map<String, Object>> groupItems = entry.getValue();
    String groupShopName = (String) groupItems.get(0).get("businessName");
%>
<!-- Shop Group -->
<div class="cart-card mb-3 p-0 overflow-hidden" style="border:1px solid #e8f0fe;">
    <!-- Shop Header with checkbox -->
    <div class="d-flex align-items-center gap-2 px-3 py-2" style="background:#f0f4ff; border-bottom:1px solid #e8f0fe;">
        <input type="checkbox" class="shop-checkbox form-check-input mt-0" 
               id="shopCheck_<%= groupSellerId %>"
               data-seller="<%= groupSellerId %>"
               onchange="toggleShop(<%= groupSellerId %>, this.checked)"
            <%= groupItems.stream().anyMatch(i -> (int)i.get("quantity") > 0) ? "checked" : "" %> style="width:18px; height:18px; cursor:pointer;">
        <label for="shopCheck_<%= groupSellerId %>" class="fw-bold mb-0" style="font-size:14px; cursor:pointer;">
            <i class="bi bi-shop text-primary me-1"></i> <%= groupShopName %>
        </label>
    </div>
    <!-- Shop Items -->
    <div class="px-3 pt-2 pb-1">
    <% for (java.util.Map<String, Object> item : groupItems) { %>
    <div class="d-flex gap-3 align-items-center py-3 cart-item-row" 
         id="cartItem_<%= item.get("cartitemId") %>"
         data-seller="<%= groupSellerId %>"
         style="border-bottom:1px solid #f5f5f5; <%= (int)item.get("quantity") == 0 ? "opacity:0.4; filter:grayscale(1);" : "" %>">
        <input type="checkbox" class="item-checkbox form-check-input mt-0"
               id="itemCheck_<%= item.get("cartitemId") %>"
               data-itemid="<%= item.get("cartitemId") %>"
               data-seller="<%= groupSellerId %>"
  data-qty="<%= item.get("quantity") %>"
              onchange="toggleItem(this)"
               <%= (int)item.get("quantity") > 0 ? "checked" : "" %> style="width:16px; height:16px; cursor:pointer; flex-shrink:0;">
        <!-- Product Image -->
        <% if (item.get("image") != null) { %>
            <img src="<%= item.get("image") %>" class="product-img" alt="<%= item.get("name") %>">
        <% } else { %>
            <div class="product-img-placeholder"><i class="bi bi-image"></i></div>
        <% } %>
        <!-- Product Info -->
        <div class="flex-grow-1">
            <h6 class="mb-1 fw-bold" style="font-size:13px;"><%= item.get("name") %></h6>
<%
    double cartRealPrice = item.get("price") != null ? (Double) item.get("price") : 0;
    double cartDiscPrice = item.get("originalPrice") != null ? (Double) item.get("originalPrice") : 0;
    int cartDiscPct = 0;
    double cartDisplayPrice = cartRealPrice;
    if (cartDiscPrice > 0 && cartDiscPrice < cartRealPrice) {
        cartDiscPct = (int) Math.round((cartRealPrice - cartDiscPrice) / cartRealPrice * 100);
        cartDisplayPrice = cartDiscPrice;
    }
%>
<% if (cartDiscPct > 0) { %>
    <div class="d-flex align-items-center gap-2 mb-1">
        <span class="text-muted text-decoration-line-through" style="font-size:11px;">₱<%= String.format("%.2f", cartRealPrice) %></span>
        <span class="badge bg-danger" style="font-size:10px;">-<%= cartDiscPct %>% OFF</span>
    </div>
    <p class="text-danger fw-bold mb-1" style="font-size:13px;">₱<%= String.format("%.2f", cartDisplayPrice) %></p>
<% } else { %>
    <p class="text-danger fw-bold mb-1" style="font-size:13px;">₱<%= String.format("%.2f", cartRealPrice) %></p>
<% } %>
<% if (item.get("variationType") != null) { %>
<p class="mb-1">
    <span class="badge bg-light text-dark border" style="font-size:11px;">
        <i class="bi bi-tag"></i> <%= item.get("variationType") %>: <%= item.get("variationValue") %>
    </span>
</p>
<% } %>
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
    <% } %>
    </div>
</div>
<% } %>
        </div>

        <!-- Order Summary -->
        <div class="col-lg-4">
            <div class="summary-card">
                <h6 class="fw-bold mb-3">Order Summary</h6>
                <div class="d-flex justify-content-between mb-2">
                    <%
int activeItemCount = 0;
for (Map<String, Object> ci : cartItems) {
    if ((int)ci.get("quantity") > 0) activeItemCount++;
}
%>
<span class="text-muted" id="itemsLabel">Items (<%= activeItemCount %>)</span>
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

<!-- Age Block Modal -->
<div class="modal fade" id="ageBlockModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-body text-center p-4">
                <%
                String _ageStatus = (String) session.getAttribute("userAgeStatus");
                if ("no_birthday".equals(_ageStatus) || _ageStatus == null) { %>
                    <div class="mb-3" style="font-size:3rem;">🎂</div>
                    <h5 class="fw-bold mb-2">Birthday Required</h5>
                    <p class="text-muted mb-4" style="font-size:14px;">Please fill in your birthday in your profile before checking out.</p>
                    <a href="ProfileServlet" class="btn btn-primary rounded-pill px-4">
                        <i class="bi bi-person-fill me-1"></i> Go to My Profile
                    </a>
                    <button type="button" class="btn btn-outline-secondary rounded-pill px-4 ms-2" data-bs-dismiss="modal">Cancel</button>
                <% } else { %>
                    <div class="mb-3" style="font-size:3rem;">🚫</div>
                    <h5 class="fw-bold mb-2">Age Restriction</h5>
                    <p class="text-muted mb-4" style="font-size:14px;">Sorry, you must be at least 13 years old to checkout.</p>
                    <button type="button" class="btn btn-primary rounded-pill px-4" data-bs-dismiss="modal">Okay</button>
                <% } %>
            </div>
        </div>
    </div>
</div>
<!-- Toast -->
<div class="toast-container" id="toastContainer"></div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
const prices = {};
<% for (Map<String, Object> item : cartItems) { 
    double jsPrice = item.get("price") != null ? (Double)item.get("price") : 0;
    double jsOrigPrice = item.get("originalPrice") != null ? (Double)item.get("originalPrice") : 0;
    double jsFinalPrice = (jsOrigPrice > 0 && jsOrigPrice < jsPrice) ? jsOrigPrice : jsPrice;
%>
    prices[<%= item.get("cartitemId") %>] = <%= jsFinalPrice %>;
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
        if (qty < 0) return;
        if (qty > stock) { showToast('Not enough stock!', '#dc3545'); return; }
        qtyEl.innerText = qty;

        // Update subtotal
        const sub = prices[itemId] * qty;
        document.getElementById('sub_' + itemId).innerText = '₱' + sub.toFixed(2);

        // Grey out if zero
        const card = document.getElementById('cartItem_' + itemId);
        if (qty === 0) {
            card.style.opacity = '0.4';
            card.style.filter = 'grayscale(1)';
            // Auto-uncheck item
            const cb = document.getElementById('itemCheck_' + itemId);
            if (cb) cb.checked = false;
            // Check if all items of shop are now 0 → auto-uncheck shop
            const sellerId = card.dataset.seller;
            const allItemCbs = document.querySelectorAll('.item-checkbox[data-seller="' + sellerId + '"]');
            const allUnchecked = Array.from(allItemCbs).every(c => !c.checked);
            const shopCb = document.getElementById('shopCheck_' + sellerId);
            if (shopCb && allUnchecked) shopCb.checked = false;
        } else {
            card.style.opacity = '1';
            card.style.filter = 'none';
            // Auto-check item kapag nag-+ mula 0
            const cb = document.getElementById('itemCheck_' + itemId);
            if (cb) cb.checked = true;
            // Check kung lahat ng items ng shop ay naka-check na → auto-check shop
            const sellerId = card.dataset.seller;
            const allItemCbs = document.querySelectorAll('.item-checkbox[data-seller="' + sellerId + '"]');
            const allChecked = Array.from(allItemCbs).every(c => c.checked);
            const shopCb = document.getElementById('shopCheck_' + sellerId);
            if (shopCb) shopCb.checked = allChecked;
        }

        updateTotal();
     // Update badge and items count
        let activeCount = 0;
        document.querySelectorAll('[id^="qty_"]').forEach(el => {
            if (parseInt(el.innerText) > 0) activeCount++;
        });
        const badge = document.querySelector('.badge.bg-primary');
        if (badge) badge.innerText = activeCount;
        const itemsLabel = document.getElementById('itemsLabel');
        if (itemsLabel) itemsLabel.innerText = 'Items (' + activeCount + ')';
        
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
        }).then(response => {
            if (response.ok) {
             
                window.location.reload(); 
            } else {
                showToast('Failed to remove item', '#dc3545');
            }
        }).catch(err => {
            console.error(err);
            showToast('Error connecting to server', '#dc3545');
        });
    }
    function toggleShop(sellerId, checked) {
        document.querySelectorAll('.item-checkbox[data-seller="' + sellerId + '"]').forEach(cb => {
            cb.checked = checked;
            toggleItem(cb, true); // true = skip updateTotal muna
        });
        const shopCard = document.getElementById('shopCheck_' + sellerId)
            ?.closest('.cart-card');
        if (shopCard) {
            shopCard.style.opacity = checked ? '1' : '0.7';
        }
        updateTotal();
    }
 // On load: grey out unchecked items
    document.addEventListener('DOMContentLoaded', function() {
        document.querySelectorAll('.item-checkbox').forEach(cb => {
            if (!cb.checked) {
                const itemId = cb.dataset.itemid;
                const row = document.getElementById('cartItem_' + itemId);
                if (row) {
                    row.style.opacity = '0.4';
                    row.style.filter = 'grayscale(1)';
                }
            }
        });
        updateTotal();
    });
    function toggleItem(cb, skipTotal = false) {
        const itemId = cb.dataset.itemid;
        const checked = cb.checked;
        const row = document.getElementById('cartItem_' + itemId);
        if (row) {
            row.style.opacity = checked ? '1' : '0.4';
            row.style.filter = checked ? 'none' : 'grayscale(1)';
        }
        // Set qty in DB
        let newQty;
        if (!checked) {
            // Save current qty to data-qty before zeroing
            const qtyEl = document.getElementById('qty_' + itemId);
            if (qtyEl && parseInt(qtyEl.innerText) > 0) {
                cb.dataset.qty = qtyEl.innerText; // save last qty
            }
            newQty = 0;
            if (qtyEl) qtyEl.innerText = 0;
            const sub = document.getElementById('sub_' + itemId);
            if (sub) sub.innerText = '₱0.00';
        } else {
            // Restore last qty (min 1)
            const lastQty = parseInt(cb.dataset.qty) || 1;
            newQty = lastQty;
            const qtyEl = document.getElementById('qty_' + itemId);
            if (qtyEl) qtyEl.innerText = lastQty;
            const sub = document.getElementById('sub_' + itemId);
            if (sub) sub.innerText = '₱' + (prices[itemId] * lastQty).toFixed(2);
        }
        // Save to DB
        fetch('UpdateCartServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'cartitemId=' + itemId + '&quantity=' + newQty
        });
        if (!skipTotal) updateTotal();
    }
    
    function updateTotal() {
        let total = 0;
        let checkedCount = 0;
        document.querySelectorAll('[id^="qty_"]').forEach(el => {
            const itemId = el.id.replace('qty_', '');
            const cb = document.getElementById('itemCheck_' + itemId);
            if (cb && !cb.checked) return; // skip unchecked
            const qty = parseInt(el.innerText);
            if (qty > 0) {
                total += prices[itemId] * qty;
                checkedCount++;
            }
        });
        document.getElementById('summaryTotal').innerText = '₱' + total.toFixed(2);
        document.getElementById('grandTotal').innerText = '₱' + total.toFixed(2);
     // Update items count
        const itemsLabel = document.getElementById('itemsLabel');
        if (itemsLabel) itemsLabel.innerText = 'Items (' + checkedCount + ')';
        // Update My Cart badge
        const cartBadge = document.querySelector('h5 .badge.bg-primary');
        if (cartBadge) cartBadge.innerText = checkedCount;
    }
    function checkout() {
        // Check if all items are zero
        let hasItems = false;
        document.querySelectorAll('[id^="qty_"]').forEach(el => {
            if (parseInt(el.innerText) > 0) hasItems = true;
        });
        if (!hasItems) {
            showToast('Please add at least 1 item to checkout!', '#dc3545');
            return;
        }
     // Age check
        const ageStatus = '<%= session.getAttribute("userAgeStatus") != null ? session.getAttribute("userAgeStatus") : "unknown" %>';
        if (ageStatus !== 'ok') {
        	new bootstrap.Modal(document.getElementById('ageBlockModal')).show();
            return;
        }
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
    function removeAll() {
        if (!confirm('Remove all items from cart? This cannot be undone.')) return;
        fetch('RemoveAllCartServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'}
        }).then(() => {
            location.reload();
        });
    }
</script>
</body>
</html>