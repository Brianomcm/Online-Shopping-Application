<%@ page session="true" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%
    Map<String, String> seller = (Map<String, String>) request.getAttribute("seller");
    List<Map<String, Object>> products = (List<Map<String, Object>>) request.getAttribute("products");
    if (seller == null) { response.sendRedirect("index.jsp"); return; }

    String loggedUser = (String) session.getAttribute("userName");
    String loggedRole = (String) session.getAttribute("userRole");
    String userAvatar = (String) session.getAttribute("userAvatar");
    // Check if logged-in user is the owner of this shop
    boolean isOwnShop = false;
    try {
        Integer sessionUserId = (Integer) session.getAttribute("userId");
        String shopSellerUserId = seller.get("user_id");
        if (sessionUserId != null && shopSellerUserId != null) {
            isOwnShop = sessionUserId.equals(Integer.parseInt(shopSellerUserId));
        }
    } catch (Exception ignored) {}

    String businessName = seller.get("business_name");
    if (businessName == null || businessName.isEmpty()) businessName = seller.get("name");
    String bannerPic = seller.get("banner_picture");
    String profilePic = (seller.get("shop_logo") != null && !seller.get("shop_logo").isEmpty())
            ? seller.get("shop_logo")
            : seller.get("profile_picture");
    String shopDesc = seller.get("shop_description");
    String address = seller.get("address");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= businessName %> - ShopEasy</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css">
    <style>
        body { background: #f8f9fa; font-family: 'Segoe UI', sans-serif; }
        .navbar-brand { font-weight: 800; color: #0d6efd !important; }
        .shop-banner {
    width: 100%;
    height: 250px;
    object-fit: cover;
    object-position: center;
    display: block;
}
   .shop-logo {
        width: 90px; height: 90px;
        border-radius: 50%;
        border: 3px solid white;
        box-shadow: 0 4px 12px rgba(25,135,84,0.3);
        object-fit: cover;
        margin-top: -45px;
        background: white;
    }
        .shop-logo-placeholder {
        width: 90px; height: 90px;
        border-radius: 50%;
        border: 3px solid white;
        box-shadow: 0 4px 12px rgba(25,135,84,0.3);
        background: #198754;
            color: white;
            font-size: 32px;
            font-weight: 700;
            display: flex; align-items: center; justify-content: center;
            margin-top: -45px;
        }
        .product-card { transition: 0.3s; border-radius: 12px; overflow: hidden; cursor: pointer; }
        .product-card:hover { box-shadow: 0 6px 20px rgba(0,0,0,0.15); transform: translateY(-4px); }
        .product-card img { height: 200px; object-fit: contain; width: 100%; background: #f8f9fa; padding: 8px; }
        .toast-msg { position: fixed; top: 20px; left: 50%; transform: translateX(-50%); background: #198754; color: white; padding: 12px 28px; border-radius: 12px; font-size: 14px; font-weight: 600; z-index: 9999; display: none; }
      .avatar-circle { width: 36px; height: 36px; border-radius: 50%; background: #0d6efd; color: white; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 14px; overflow: hidden; }

   @media (max-width: 576px) {
            .shop-banner { height: 140px !important; }
            .shop-logo { width: 70px !important; height: 70px !important; margin-top: -35px !important; }
            .shop-logo-placeholder { width: 70px !important; height: 70px !important; margin-top: -35px !important; font-size: 24px !important; }
            .product-card img { height: 100px !important; }
            .card-title { font-size: 12px !important; line-height: 1.3; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
            .card-body { padding: 6px 8px !important; }
            .card-body .text-muted { font-size: 10px !important; }
            .card-body .badge { font-size: 9px !important; }
            .card-body p { margin-bottom: 2px !important; font-size: 12px; }
            .card-body .btn { font-size: 11px !important; padding: 5px 8px !important; }
        }
        .shop-banner-wrap { height: 140px !important; }
            .shop-banner-wrap img,
            .shop-banner-wrap div { height: 140px !important; }
    </style>
</head>
<body>

<!-- TOAST -->
<div id="cartToast" class="toast-msg"><i class="bi bi-cart-check-fill me-2"></i> Item added to cart! 🛒</div>

<!-- NAVBAR -->
<%
    int spCartCount = 0;
    try {
        Integer spUserId = (Integer) session.getAttribute("userId");
        String spRole = (String) session.getAttribute("userRole");
        if (spUserId != null && ("customer".equals(spRole) || "both".equals(spRole))) {
            java.sql.Connection spCartConn = com.shopeasy.DBConnection.getConnection();
            java.sql.PreparedStatement spCartPs = spCartConn.prepareStatement(
                "SELECT SUM(ci.quantity) FROM cart c JOIN cartitem ci ON c.cart_id = ci.cart_id WHERE c.customer_id = ? AND ci.quantity > 0");
            Integer spCustId = (Integer) session.getAttribute("customerId");
            if (spCustId == null) spCustId = spUserId;
            spCartPs.setInt(1, spCustId);
            java.sql.ResultSet spCartRs = spCartPs.executeQuery();
            if (spCartRs.next()) spCartCount = spCartRs.getInt(1);
            spCartRs.close(); spCartPs.close(); spCartConn.close();
        }
    } catch (Exception spEx) { spEx.printStackTrace(); }
    request.setAttribute("navType", "full");
    request.setAttribute("navCartCount", spCartCount);
%>
<%@ include file="navbar.jsp" %>

<!-- BREADCRUMB -->
<div class="bg-white border-bottom px-4 py-2">
  <nav aria-label="breadcrumb" class="d-none d-md-block">
        <ol class="breadcrumb mb-0" style="font-size:13px;">
            <li class="breadcrumb-item"><a href="index.jsp" class="text-decoration-none text-primary">Home</a></li>
            <%
                String sellerCrumb = (String) session.getAttribute("breadcrumb");
                Integer lpId3 = (Integer) session.getAttribute("lastProductId");
                String lpName3 = (String) session.getAttribute("lastProduct");
                if ("product".equals(sellerCrumb) && lpId3 != null && lpName3 != null) {
            %>
                <li class="breadcrumb-item">
                    <a href="product.jsp?id=<%= lpId3 %>" class="text-decoration-none text-primary"><%= lpName3 %></a>
                </li>
            <%
                }
                session.setAttribute("breadcrumb", "seller");
            %>
            <li class="breadcrumb-item active text-muted"><%= businessName %></li>
        </ol>
    </nav>
</div>

<!-- SHOP BANNER -->
<div style="max-width:1100px; margin:0 auto; height:220px; overflow:hidden; border-radius:12px; margin-bottom:0;" class="shop-banner-wrap">
<% if (bannerPic != null && !bannerPic.isEmpty()) { %>
    <img src="<%= bannerPic %>" style="width:100%; height:220px; object-fit:cover; object-position:center; display:block; border-radius:12px;">
<% } else { %>
    <div style="width:100%; height:220px; background:linear-gradient(135deg,#198754,#20c997); border-radius:12px;"></div>
<% } %>
</div>

<!-- SHOP INFO -->
<div class="container" style="max-width:1100px;">
    <div class="d-flex align-items-end gap-3 mb-2">
        <% if (profilePic != null && !profilePic.isEmpty()) { %>
            <img src="<%= profilePic %>" class="shop-logo">
        <% } else { %>
            <div class="shop-logo-placeholder"><%= businessName.substring(0,1).toUpperCase() %></div>
        <% } %>
        <div class="pb-2">
    <h4 class="fw-bold mb-0"><%= businessName %></h4>
    <% if (address != null && !address.isEmpty()) { %>
        <p class="text-muted mb-0" style="font-size:13px;"><i class="bi bi-geo-alt"></i> <%= address %></p>
    <% } %>
    <%
    String storeAvgStr = seller.get("storeAvgRating");
    String storeRevStr = seller.get("storeReviewCount");
    double storeAvg = storeAvgStr != null ? Double.parseDouble(storeAvgStr) : 0.0;
    int storeRevs = storeRevStr != null ? Integer.parseInt(storeRevStr) : 0;
    %>
    <div class="d-flex align-items-center gap-1 mt-1">
        <% for (int s = 1; s <= 5; s++) { %>
            <i class="bi bi-star-fill" style="color:<%= s <= Math.round(storeAvg) ? "#ffc107" : "#ddd" %>; font-size:13px;"></i>
        <% } %>
        <span class="fw-bold ms-1" style="font-size:13px;"><%= String.format("%.1f", storeAvg) %></span>
        <span class="text-muted" style="font-size:12px;">· <%= storeRevs %> review<%= storeRevs != 1 ? "s" : "" %></span>
    </div>
</div>
    </div>
    <% if (shopDesc != null && !shopDesc.isEmpty()) { %>
        <p class="text-muted mb-3" style="font-size:14px;"><%= shopDesc %></p>
    <% } %>
    <hr>

    <!-- PRODUCTS -->
   <h5 class="fw-bold mb-3"><i class="bi bi-grid text-primary"></i> <%= isOwnShop ? "Your Products" : "Products" %> (<%= products != null ? products.size() : 0 %>)</h5>
    <div class="row g-3 mb-5">
        <% if (products == null || products.isEmpty()) { %>
            <div class="col-12 text-center py-5 text-muted">
                <i class="bi bi-box-seam fs-1 opacity-25"></i>
                <p class="mt-2">No products available yet.</p>
            </div>
        <% } else { %>
            <% for (Map<String, Object> prod : products) { %>
            <div class="col-6 col-md-4 col-lg-3">
                <div class="card h-100 product-card" onclick="window.location.href='product.jsp?id=<%= prod.get("product_id") %>'">
                    <% if (prod.get("image") != null && !prod.get("image").toString().isEmpty()) { %>
                        <img src="<%= prod.get("image") %>" class="card-img-top" alt="<%= prod.get("name") %>">
                    <% } else { %>
                        <div style="height:180px; background:#f8f9fa; display:flex; align-items:center; justify-content:center; color:#aaa; font-size:40px;"><i class="bi bi-image"></i></div>
                    <% } %>
                    <div class="card-body">
    <h6 class="card-title fw-bold"><%= prod.get("name") %></h6>
    <div class="d-flex align-items-center gap-1 mb-1">
        <%
        double spRating = prod.get("avgRating") != null ? (Double) prod.get("avgRating") : 0.0;
        int spReviews = prod.get("reviewCount") != null ? (Integer) prod.get("reviewCount") : 0;
        int spSold = prod.get("totalSold") != null ? (Integer) prod.get("totalSold") : 0;
        for (int s = 1; s <= 5; s++) { %>
            <i class="bi bi-star-fill" style="color:<%= s <= Math.round(spRating) ? "#ffc107" : "#ddd" %>; font-size:11px;"></i>
        <% } %>
        <span class="text-muted" style="font-size:10px;">(<%= spReviews %>)</span>
        <span class="text-muted" style="font-size:10px;">· <%= spSold %> sold</span>
    </div>
    <%
    double spDiscPrice = prod.get("originalPrice") != null ? (Double) prod.get("originalPrice") : 0;
    double spRealPrice = prod.get("price") != null ? (Double) prod.get("price") : 0;
    int spDiscPct = 0;
    if (spDiscPrice > 0 && spDiscPrice < spRealPrice) {
        spDiscPct = (int) Math.round((spRealPrice - spDiscPrice) / spRealPrice * 100);
    }
%>
<% if (spDiscPct > 0) { %>
    <div class="d-flex align-items-center gap-2 mb-0">
        <span class="text-muted text-decoration-line-through" style="font-size:11px;">₱<%= String.format("%.2f", spRealPrice) %></span>
        <span class="badge bg-danger" style="font-size:10px;">-<%= spDiscPct %>% OFF</span>
    </div>
    <p class="text-danger fw-bold mb-1">₱<%= String.format("%.2f", spDiscPrice) %></p>
<% } else { %>
    <p class="text-danger fw-bold mb-1">₱<%= String.format("%.2f", spRealPrice) %></p>
<% } %>
<p class="text-muted mb-2" style="font-size:11px;">Stock: <%= prod.get("stock") %></p>

                        <div onclick="event.stopPropagation();">
                          <% if (isOwnShop) { %>
                                <button class="btn btn-secondary btn-sm w-100" disabled style="cursor:not-allowed; opacity:0.7;">
                                    <i class="bi bi-slash-circle"></i> Your Product
                                </button>
                           <% } else if (loggedUser != null && ("customer".equals(loggedRole) || "both".equals(loggedRole))) { %>
                                <button class="btn btn-primary btn-sm w-100" onclick="addToCart(<%= prod.get("product_id") %>)">
                                    <i class="bi bi-cart-plus"></i> Add to Cart
                                </button>
                            <% } else if (isOwnShop) { %>
                                <a href="seller.jsp?tab=products" class="btn btn-outline-success btn-sm w-100">
                                    <i class="bi bi-pencil"></i> Edit in Shop
                                </a>
                            <% } else { %>
                                <button class="btn btn-primary btn-sm w-100" data-bs-toggle="modal" data-bs-target="#loginModal">
                                    <i class="bi bi-cart-plus"></i> Add to Cart
                                </button>
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>
            <% } %>
        <% } %>
    </div>
</div>



<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
function addToCart(productId) {
    fetch('AddToCartServlet', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'productId=' + productId
    })
    .then(res => res.json())
    .then(data => {
        if (data.success) {
            const toast = document.getElementById('cartToast');
            toast.style.display = 'block';
            setTimeout(() => toast.style.display = 'none', 2500);
            const badge = document.getElementById('cartBadge');
            if (badge) badge.textContent = data.newCount;
        } else {
            const toast = document.getElementById('cartToast');
            toast.style.background = '#dc3545';
            toast.innerHTML = '<i class="bi bi-exclamation-circle-fill me-2"></i>' + (data.message || 'Error adding to cart.');
            toast.style.display = 'block';
            setTimeout(() => {
                toast.style.display = 'none';
                toast.style.background = '#198754';
                toast.innerHTML = '<i class="bi bi-cart-check-fill me-2"></i> Item added to cart! 🛒';
            }, 2500);
        }
    })
    .catch(() => {
        const toast = document.getElementById('cartToast');
        toast.style.background = '#dc3545';
        toast.innerHTML = '<i class="bi bi-exclamation-circle-fill me-2"></i> Server error. Please try again.';
        toast.style.display = 'block';
        setTimeout(() => {
            toast.style.display = 'none';
            toast.style.background = '#198754';
            toast.innerHTML = '<i class="bi bi-cart-check-fill me-2"></i> Item added to cart! 🛒';
        }, 2500);
    });
}
</script>
<div id="logoutOverlay" style="display:none; position:fixed; inset:0; background:rgba(255,255,255,0.95); z-index:9999; flex-direction:column; align-items:center; justify-content:center;">
    <div class="spinner-border text-primary"></div>
    <p class="mt-2 fw-bold text-primary">Logging out...</p>
</div>
<%@ include file="modals.jsp" %>
</body>
</html>