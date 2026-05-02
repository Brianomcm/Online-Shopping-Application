<%@ page session="true" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    String productIdParam = request.getParameter("id");
    if (productIdParam == null || productIdParam.trim().isEmpty()) {
        response.sendRedirect("index.jsp");
        return;
    }

    int productId = Integer.parseInt(productIdParam.trim());
    String name = "", description = "", image = "", sellerName = "";
    double price = 0;
    int stock = 0, sellerId = 0;

    try {
        Connection conn = com.shopeasy.DBConnection.getConnection();
        PreparedStatement ps = conn.prepareStatement(
            "SELECT p.*, s.business_name, s.seller_id FROM product p " +
            "JOIN seller s ON p.seller_id = s.seller_id " +
            "WHERE p.product_id = ? AND p.status = 'active'");
        ps.setInt(1, productId);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            name = rs.getString("name");
            description = rs.getString("description");
            image = rs.getString("image");
            price = rs.getDouble("price");
            stock = rs.getInt("stock");
            sellerName = rs.getString("business_name");
            sellerId = rs.getInt("seller_id");
        } else {
            response.sendRedirect("index.jsp");
            return;
        }
        rs.close(); ps.close(); conn.close();
    } catch (Exception e) {
        e.printStackTrace();
    }
    
    
 // Fetch variations for this product
 java.util.List<java.util.Map<String, Object>> variations = new java.util.ArrayList<>();
 try {
     Connection varConn = com.shopeasy.DBConnection.getConnection();
     PreparedStatement varPs = varConn.prepareStatement(
         "SELECT variation_id, variation_type, variation_value FROM product_variation WHERE product_id = ? ORDER BY variation_type");
     varPs.setInt(1, productId);
     ResultSet varRs = varPs.executeQuery();
     while (varRs.next()) {
         java.util.Map<String, Object> v = new java.util.HashMap<>();
         v.put("id", varRs.getInt("variation_id"));
         v.put("type", varRs.getString("variation_type"));
         v.put("value", varRs.getString("variation_value"));
         variations.add(v);
     }
     varRs.close(); varPs.close(); varConn.close();
 } catch (Exception e) { e.printStackTrace(); }
 

    String loggedUser = (String) session.getAttribute("userName");
    String loggedRole = (String) session.getAttribute("userRole");
    String userAvatar = (String) session.getAttribute("userAvatar");
    int cartCount = 0;
    try {
        Integer sessionUserId = (Integer) session.getAttribute("userId");
        if (sessionUserId != null && "customer".equals(loggedRole)) {
            Connection cartConn = com.shopeasy.DBConnection.getConnection();
            PreparedStatement cartPs = cartConn.prepareStatement(
                "SELECT SUM(ci.quantity) FROM cart c JOIN cartitem ci ON c.cart_id = ci.cart_id WHERE c.customer_id = ?");
            cartPs.setInt(1, sessionUserId);
            ResultSet cartRs = cartPs.executeQuery();
            if (cartRs.next()) cartCount = cartRs.getInt(1);
            cartRs.close(); cartPs.close(); cartConn.close();
        }
    } catch (Exception e) { e.printStackTrace(); }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= name %> - ShopEasy</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css">
    <style>
        body { background: #f8f9fa; font-family: 'Segoe UI', sans-serif; }
        .navbar-brand { font-weight: 800; color: #0d6efd !important; }
        .product-img { width: 100%; max-height: 420px; object-fit: contain; background: white; border-radius: 16px; padding: 20px; box-shadow: 0 2px 12px rgba(0,0,0,0.07); }
        .product-card { background: white; border-radius: 16px; box-shadow: 0 2px 12px rgba(0,0,0,0.07); padding: 28px; }
        .price-tag { font-size: 32px; font-weight: 800; color: #dc3545; }
        .stock-badge { font-size: 13px; padding: 4px 12px; border-radius: 20px; }
        .add-cart-btn { background: linear-gradient(135deg, #0d6efd, #6610f2); border: none; border-radius: 12px; padding: 14px; font-size: 16px; font-weight: 700; }
        .seller-card { background: #f0f4ff; border-radius: 12px; padding: 14px; margin-top: 16px; }
        .avatar-circle { width: 36px; height: 36px; border-radius: 50%; background: #0d6efd; color: white; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 14px; overflow: hidden; }
        .toast-msg { position: fixed; top: 20px; left: 50%; transform: translateX(-50%); background: #198754; color: white; padding: 12px 28px; border-radius: 12px; font-size: 14px; font-weight: 600; z-index: 9999; box-shadow: 0 4px 16px rgba(0,0,0,0.2); display: none; }
    </style>
</head>
<body>

<!-- PAGE LOADER -->
<div id="pageLoader" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.7); z-index:9999; flex-direction:column; gap:12px;">
    <div style="width:48px; height:48px; border:5px solid #e0e0e0; border-top-color:#0d6efd; border-radius:50%; animation:spin 0.7s linear infinite;"></div>
    <span class="text-primary fw-bold">Searching...</span>
</div>

<style>
@keyframes spin { to { transform: rotate(360deg); } }
#pageLoader { display: none; }
#pageLoader.active {
    display: flex !important;
    align-items: center;
    justify-content: center;
}
</style>
<script>
function showLoader() {
    
    var loader = document.getElementById('pageLoader');
    loader.classList.add('active'); 
    var btn = document.getElementById('searchBtn');
    if (btn) btn.innerHTML = '<i class="bi bi-hourglass-split"></i>';
    setTimeout(() => { 
        document.getElementById('productSearch').submit(); 
    }, 500);
}
</script>

<!-- TOAST -->
<div id="cartToast" class="toast-msg">
    <i class="bi bi-cart-check-fill me-2"></i> Item added to cart! 🛒
</div>

<!-- NAVBAR -->
<nav class="navbar navbar-light bg-white shadow-sm py-3 sticky-top">
    <div class="container-fluid px-4">
        <!-- LOGO -->
        <a class="navbar-brand fw-bold text-primary fs-4" href="index.jsp">
            <i class="bi bi-bag-heart-fill"></i> ShopEasy
        </a>

       <!-- SEARCH BAR -->
        <form id="productSearch" class="d-flex flex-grow-1 mx-3" action="index.jsp" method="get" onsubmit="event.preventDefault(); showLoader();">
            <div class="input-group">
                <input type="text" class="form-control" name="search" placeholder="Search products..." style="border-radius:8px 0 0 8px;">
                <button class="btn btn-primary" type="submit" id="searchBtn" style="border-radius:0 8px 8px 0;">
                    <i class="bi bi-search"></i>
                </button>
            </div>
        </form>
       <!-- RIGHT SIDE -->
        <div class="d-flex align-items-center gap-2">
          <% if (loggedUser != null) { %>
            <% if ("customer".equals(loggedRole)) { %>
            <a href="CartServlet" class="btn btn-outline-secondary position-relative">
                <i class="bi bi-cart3 fs-5"></i>
                <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" style="font-size:9px;"><%= cartCount > 0 ? cartCount : "0" %></span>
            </a>
            <% } %>
            <div class="dropdown">
                <a href="#" class="d-flex align-items-center gap-2 text-decoration-none" data-bs-toggle="dropdown">
                    <div class="avatar-circle">
                        <% if (userAvatar != null && !userAvatar.isEmpty()) { %>
                            <img src="<%= userAvatar %>" style="width:100%;height:100%;object-fit:cover;">
                        <% } else { %>
                            <%= loggedUser.substring(0, 1).toUpperCase() %>
                        <% } %>
                    </div>
                    <span class="d-none d-md-inline fw-bold text-dark" style="font-size:14px; max-width:100px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;"><%= loggedUser %></span>
                    <i class="bi bi-chevron-down text-muted" style="font-size:11px;"></i>
                </a>
                <ul class="dropdown-menu dropdown-menu-end shadow">
                    <li><h6 class="dropdown-header"><%= loggedUser %></h6></li>
                    <li><hr class="dropdown-divider"></li>
                    <% if ("customer".equals(loggedRole)) { %>
                    <li><a class="dropdown-item" href="customer.jsp"><i class="bi bi-person me-2"></i> My Profile</a></li>
                    <li><a class="dropdown-item" href="customer.jsp?tab=orders"><i class="bi bi-bag me-2"></i> My Orders</a></li>
                    <% } else if ("seller".equals(loggedRole)) { %>
                    <li><a class="dropdown-item" href="seller.jsp"><i class="bi bi-shop me-2"></i> Seller Dashboard</a></li>
                    <% } %>
                    <li><hr class="dropdown-divider"></li>
                    <li><a class="dropdown-item text-danger" href="LogoutServlet"><i class="bi bi-box-arrow-right me-2"></i> Logout</a></li>
                </ul>
            </div>
          <% } else { %>
            <a href="CartServlet" class="btn btn-outline-secondary position-relative">
                <i class="bi bi-cart3 fs-5"></i>
                <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" style="font-size:9px;">0</span>
            </a>
            <a href="index.jsp" class="btn btn-outline-primary"><i class="bi bi-box-arrow-in-right"></i> Login</a>
            <a href="index.jsp" class="btn btn-primary"><i class="bi bi-person-plus"></i> Register</a>
          <% } %>
        </div>
    </div>
</nav>

<!-- BACK TO SHOP -->
<div class="bg-white border-bottom px-4 py-2">
    <a href="index.jsp" class="text-decoration-none text-muted" style="font-size:13px;">
        <i class="bi bi-arrow-left"></i> Back to Shop
    </a>
</div>

<div class="container py-4">
    <!-- BREADCRUMB -->
    <nav aria-label="breadcrumb" class="mb-3">
        <ol class="breadcrumb">
            <li class="breadcrumb-item"><a href="index.jsp" class="text-decoration-none">Home</a></li>
            <li class="breadcrumb-item active"><%= name %></li>
        </ol>
    </nav>

    <div class="row g-4">
        <!-- PRODUCT IMAGE -->
        <div class="col-md-5">
            <% if (image != null && !image.isEmpty()) { %>
                <img src="<%= image %>" class="product-img" alt="<%= name %>">
            <% } else { %>
                <div class="product-img d-flex align-items-center justify-content-center text-muted" style="height:420px;">
                    <i class="bi bi-image" style="font-size:80px; opacity:0.2;"></i>
                </div>
            <% } %>
        </div>

        <!-- PRODUCT DETAILS -->
        <div class="col-md-7">
            <div class="product-card">
                <h2 class="fw-bold mb-2"><%= name %></h2>
<%
double topAvgRating = 0;
int topTotalReviews = 0;
try {
    Connection topRatConn = com.shopeasy.DBConnection.getConnection();
    PreparedStatement topRatPs = topRatConn.prepareStatement(
        "SELECT COUNT(*), AVG(rating) FROM review WHERE product_id = ?");
    topRatPs.setInt(1, productId);
    ResultSet topRatRs = topRatPs.executeQuery();
    if (topRatRs.next()) {
        topTotalReviews = topRatRs.getInt(1);
        topAvgRating = topRatRs.getDouble(2);
    }
    topRatRs.close(); topRatPs.close(); topRatConn.close();
} catch (Exception e) { e.printStackTrace(); }
%>
<%
int totalSold = 0;
try {
    Connection soldConn = com.shopeasy.DBConnection.getConnection();
    PreparedStatement soldPs = soldConn.prepareStatement(
        "SELECT SUM(oi.quantity) FROM order_items oi " +
        "JOIN orders o ON oi.order_id = o.order_id " +
        "WHERE oi.product_id = ? AND o.status = 'Completed'");
    soldPs.setInt(1, productId);
    ResultSet soldRs = soldPs.executeQuery();
    if (soldRs.next()) totalSold = soldRs.getInt(1);
    soldRs.close(); soldPs.close(); soldConn.close();
} catch (Exception e) { e.printStackTrace(); }
%>
<div class="d-flex align-items-center gap-2 mb-2">
    <% for (int s = 1; s <= 5; s++) { %>
        <i class="bi bi-star-fill" style="color:<%= s <= Math.round(topAvgRating) ? "#ffc107" : "#ddd" %>; font-size:14px;"></i>
    <% } %>
    <% if (topTotalReviews > 0) { %>
        <span class="text-muted" style="font-size:13px;"><%= String.format("%.1f", topAvgRating) %> (<%= topTotalReviews %> review<%= topTotalReviews != 1 ? "s" : "" %>)</span>
    <% } else { %>
        <span class="text-muted" style="font-size:13px;">No reviews yet</span>
    <% } %>
    <span class="text-muted" style="font-size:13px;">|</span>
    <span class="text-muted" style="font-size:13px;"><i class="bi bi-bag-check"></i> <%= totalSold %> sold</span>
</div>

<div class="price-tag mb-2">₱<%= String.format("%.2f", price) %></div>

                <% if (stock > 10) { %>
                    <span class="badge bg-success stock-badge mb-3"><i class="bi bi-check-circle"></i> In Stock (<%= stock %> available)</span>
                <% } else if (stock > 0) { %>
                    <span class="badge bg-warning text-dark stock-badge mb-3"><i class="bi bi-exclamation-circle"></i> Low Stock (<%= stock %> left)</span>
                <% } else { %>
                    <span class="badge bg-danger stock-badge mb-3"><i class="bi bi-x-circle"></i> Out of Stock</span>
                <% } %>

                <hr>
                <p class="fw-bold mb-1">Description</p>
                <p class="text-muted" style="font-size:15px; line-height:1.7;"><%= description != null ? description : "No description available." %></p>

                <!-- SELLER INFO -->
                <div class="seller-card">
                    <p class="mb-0" style="font-size:13px;">
                        <i class="bi bi-shop text-primary"></i>
                        <strong> Sold by:</strong> <%= sellerName %>
                    </p>
                </div>

               
                <!-- VARIATIONS -->
<% if (!variations.isEmpty()) {
    // Group by type
    java.util.Map<String, java.util.List<java.util.Map<String, Object>>> grouped = new java.util.LinkedHashMap<>();
    for (java.util.Map<String, Object> v : variations) {
        String vtype = (String) v.get("type");
        grouped.computeIfAbsent(vtype, k -> new java.util.ArrayList<>()).add(v);
    }
%>
<div class="mb-3">
    <% for (java.util.Map.Entry<String, java.util.List<java.util.Map<String, Object>>> entry : grouped.entrySet()) { %>
    <div class="mb-3">
        <label class="form-label fw-bold" style="font-size:13px;"><%= entry.getKey() %></label>
        <div class="d-flex flex-wrap gap-2" id="varGroup_<%= entry.getKey() %>">
            <% for (java.util.Map<String, Object> v : entry.getValue()) { %>
            <button type="button"
                class="btn btn-outline-secondary btn-sm variation-btn"
                data-type="<%= entry.getKey() %>"
                data-id="<%= v.get("id") %>"
                data-value="<%= v.get("value") %>"
                onclick="selectVariation(this, '<%= entry.getKey() %>')"
                style="border-radius:8px; min-width:52px; font-size:13px;">
                <%= v.get("value") %>
            </button>
            <% } %>
        </div>
    </div>
    <% } %>
</div>
<!-- Hidden field to carry selected variation -->
<input type="hidden" id="selectedVariationId" value="">
<% } %>

<!-- ADD TO CART -->
<div class="mt-4">
    <% if (loggedUser != null && "customer".equals(loggedRole)) { %>
        <% if (stock > 0) { %>
            <button class="btn btn-primary add-cart-btn w-100 text-white" onclick="addToCart(<%= productId %>, <%= !variations.isEmpty() %>)">
                <i class="bi bi-cart-plus"></i> Add to Cart
            </button>
            <button class="btn btn-outline-danger w-100 mt-2" id="wishlistBtn" onclick="toggleWishlist(<%= productId %>)">
                <i class="bi bi-heart" id="wishlistIcon"></i> <span id="wishlistText">Add to Wishlist</span>
            </button>
            
            <% if (!variations.isEmpty()) { %>
            <p class="text-muted mt-2 mb-0" style="font-size:11px;"><i class="bi bi-info-circle"></i> Please select your preferred options above.</p>
            <% } %>
        <% } else { %>
            <button class="btn btn-secondary w-100" disabled>
                <i class="bi bi-x-circle"></i> Out of Stock
            </button>
        <% } %>
    <% } else { %>
        <button class="btn btn-primary add-cart-btn w-100 text-white" data-bs-toggle="modal" data-bs-target="#loginModal">
            <i class="bi bi-box-arrow-in-right"></i> Login to Add to Cart
        </button>
    <% } %>
</div>
            </div>
        </div>
    </div>
</div>


</div>
</div>
</div>

<!-- REVIEWS SECTION -->
<div class="container pb-5">
    <div class="bg-white rounded-4 shadow-sm p-4 mt-2">
        <h5 class="fw-bold mb-4"><i class="bi bi-star-fill text-warning"></i> Customer Reviews</h5>
        <%
        int totalReviews = 0;
        double avgRating = 0;
        try {
            Connection revConn = com.shopeasy.DBConnection.getConnection();
            PreparedStatement revPs = revConn.prepareStatement(
                "SELECT r.rating, r.comment, r.review_date, r.photo, c.name AS cname, c.profile_picture AS cavatar " +
                "FROM review r JOIN customer c ON r.customer_id = c.customer_id " +
                "WHERE r.product_id = ? ORDER BY r.review_id DESC");
            revPs.setInt(1, productId);
            ResultSet revRs = revPs.executeQuery();

            // Get avg rating
            PreparedStatement avgPs = revConn.prepareStatement(
                "SELECT COUNT(*), AVG(rating) FROM review WHERE product_id = ?");
            avgPs.setInt(1, productId);
            ResultSet avgRs = avgPs.executeQuery();
            if (avgRs.next()) {
                totalReviews = avgRs.getInt(1);
                avgRating = avgRs.getDouble(2);
            }
            avgRs.close(); avgPs.close();
        %>

        <!-- Rating Summary -->
        <div class="d-flex align-items-center gap-3 mb-4 p-3 bg-light rounded-3">
            <div class="text-center">
                <div style="font-size:48px; font-weight:800; color:#ffc107; line-height:1;"><%= String.format("%.1f", avgRating) %></div>
                <div class="d-flex gap-1 justify-content-center mt-1">
                    <% for (int s = 1; s <= 5; s++) { %>
                        <i class="bi bi-star-fill" style="color:<%= s <= Math.round(avgRating) ? "#ffc107" : "#ddd" %>; font-size:14px;"></i>
                    <% } %>
                </div>
                <div class="text-muted mt-1" style="font-size:12px;"><%= totalReviews %> review<%= totalReviews != 1 ? "s" : "" %></div>
            </div>
        </div>

        <% if (totalReviews == 0) { %>
            <div class="text-center text-muted py-4">
                <i class="bi bi-star fs-1 opacity-25"></i>
                <p class="mt-2">No reviews yet. Be the first to review!</p>
            </div>
        <% } else { while (revRs.next()) { %>
            <div class="d-flex gap-3 mb-4 pb-4 border-bottom">
                <!-- Avatar -->
                <div style="width:42px; height:42px; border-radius:50%; overflow:hidden; flex-shrink:0; background:#0d6efd; display:flex; align-items:center; justify-content:center; color:white; font-weight:700;">
                    <% String cavatar = revRs.getString("cavatar");
                       String cname = revRs.getString("cname"); %>
                    <% if (cavatar != null && !cavatar.isEmpty()) { %>
                        <img src="<%= cavatar %>" style="width:100%;height:100%;object-fit:cover;">
                    <% } else { %>
                        <%= cname != null && !cname.isEmpty() ? String.valueOf(cname.charAt(0)).toUpperCase() : "U" %>
                    <% } %>
                </div>
                <!-- Review Content -->
                <div class="flex-grow-1">
                    <div class="d-flex justify-content-between align-items-start">
                        <p class="fw-bold mb-0" style="font-size:14px;"><%= cname %></p>
                        <small class="text-muted"><%= revRs.getString("review_date") != null ? revRs.getString("review_date").toString().substring(0,10) : "" %></small>
                    </div>
                    <div class="d-flex gap-1 my-1">
                        <% for (int s = 1; s <= 5; s++) { %>
                            <i class="bi bi-star-fill" style="color:<%= s <= revRs.getInt("rating") ? "#ffc107" : "#ddd" %>; font-size:13px;"></i>
                        <% } %>
                    </div>
                    <p class="text-muted mb-2" style="font-size:14px;"><%= revRs.getString("comment") %></p>
                    <% String rphoto = revRs.getString("photo");
                       if (rphoto != null && !rphoto.isEmpty()) { %>
                        <img src="<%= rphoto %>" style="width:90px; height:90px; object-fit:cover; border-radius:10px; border:2px solid #eee;">
                    <% } %>
                </div>
            </div>
        <% } } %>

        <%
            revRs.close(); revPs.close(); revConn.close();
        %>

        
        <% } catch (Exception e) { e.printStackTrace(); } %>
    </div>
</div>

<%@ include file="modals.jsp" %>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

<script>
document.querySelectorAll('.star-btn').forEach(star => {
    star.addEventListener('mouseover', function() {
        const val = parseInt(this.dataset.val);
        document.querySelectorAll('.star-btn').forEach((s, i) => {
            s.style.color = i < val ? '#ffc107' : '#ddd';
        });
    });
    star.addEventListener('mouseout', function() {
        const selected = parseInt(document.getElementById('ratingInput').value);
        document.querySelectorAll('.star-btn').forEach((s, i) => {
            s.style.color = i < selected ? '#ffc107' : '#ddd';
        });
    });
    star.addEventListener('click', function() {
        const val = parseInt(this.dataset.val);
        document.getElementById('ratingInput').value = val;
        document.querySelectorAll('.star-btn').forEach((s, i) => {
            s.style.color = i < val ? '#ffc107' : '#ddd';
        });
    });
});

</script>
<script>
function selectVariation(btn, type) {
    // Deselect all buttons in this group
    document.querySelectorAll('#varGroup_' + type + ' .variation-btn').forEach(b => {
        b.classList.remove('btn-dark');
        b.classList.add('btn-outline-secondary');
    });
    // Select clicked
    btn.classList.remove('btn-outline-secondary');
    btn.classList.add('btn-dark');
    // Store the last selected variation id
    // We store all selected per type, pick last one for single variation products
    // For multi-type, we just pass the last clicked (you can extend this)
    document.getElementById('selectedVariationId').value = btn.dataset.id;
}

function addToCart(productId, hasVariations) {
    const variationId = document.getElementById('selectedVariationId') 
                        ? document.getElementById('selectedVariationId').value 
                        : '';

    if (hasVariations && !variationId) {
        const toast = document.getElementById('cartToast');
        toast.style.background = '#dc3545';
        toast.innerHTML = '<i class="bi bi-exclamation-circle-fill me-2"></i> Please select a variation first!';
        toast.style.display = 'block';
        setTimeout(() => {
            toast.style.display = 'none';
            toast.style.background = '#198754';
            toast.innerHTML = '<i class="bi bi-cart-check-fill me-2"></i> Item added to cart! 🛒';
        }, 2500);
        return;
    }

    let body = 'productId=' + productId;
    if (variationId) body += '&variationId=' + variationId;

    fetch('AddToCartServlet', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body
    })
    .then(res => res.json())
    .then(data => {
        if (data.success) {
            const toast = document.getElementById('cartToast');
            toast.style.display = 'block';
            setTimeout(() => toast.style.display = 'none', 2500);
            const badge = document.querySelector('.badge.bg-danger');
            if (badge) badge.textContent = parseInt(badge.textContent || 0) + 1;
        }
    })
    .catch(err => console.error(err));
}

function handleLoginSubmit(e, form) {
    e.preventDefault();
    var modal = bootstrap.Modal.getInstance(document.getElementById('loginModal'));
    if (modal) modal.hide();
    setTimeout(() => {
        document.getElementById('loginLoadingOverlay').style.display = 'flex';
        setTimeout(() => { form.submit(); }, 1500);
    }, 300);
    return false;
}
//WISHLIST
function toggleWishlist(productId) {
    fetch('WishlistServlet', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'productId=' + productId
    })
    .then(res => res.json())
    .then(data => {
        if (data.success) {
            const icon = document.getElementById('wishlistIcon');
            const text = document.getElementById('wishlistText');
            if (data.action === 'added') {
                icon.className = 'bi bi-heart-fill';
                text.textContent = 'Wishlisted';
                document.getElementById('wishlistBtn').classList.add('btn-danger');
                document.getElementById('wishlistBtn').classList.remove('btn-outline-danger');
            } else {
                icon.className = 'bi bi-heart';
                text.textContent = 'Add to Wishlist';
                document.getElementById('wishlistBtn').classList.remove('btn-danger');
                document.getElementById('wishlistBtn').classList.add('btn-outline-danger');
            }
        }
    });
}

// Check if already wishlisted on load
window.addEventListener('load', function() {
    fetch('WishlistServlet?check=<%= productId %>')
    .then(res => res.json())
    .then(data => {
        if (data.wishlisted) {
            document.getElementById('wishlistIcon').className = 'bi bi-heart-fill';
            document.getElementById('wishlistText').textContent = 'Wishlisted';
            document.getElementById('wishlistBtn').classList.add('btn-danger');
            document.getElementById('wishlistBtn').classList.remove('btn-outline-danger');
        }
    });
});
</script>
</body>
</html>