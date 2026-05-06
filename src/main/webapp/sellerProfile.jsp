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
    int cartCount = 0;
    try {
        Integer sessionUserId = (Integer) session.getAttribute("userId");
        if (sessionUserId != null && "customer".equals(loggedRole)) {
            java.sql.Connection cartConn = com.shopeasy.DBConnection.getConnection();
            java.sql.PreparedStatement cartPs = cartConn.prepareStatement(
                "SELECT SUM(ci.quantity) FROM cart c JOIN cartitem ci ON c.cart_id = ci.cart_id WHERE c.customer_id = ?");
            cartPs.setInt(1, sessionUserId);
            java.sql.ResultSet cartRs = cartPs.executeQuery();
            if (cartRs.next()) cartCount = cartRs.getInt(1);
            cartRs.close(); cartPs.close(); cartConn.close();
        }
    } catch (Exception e) { e.printStackTrace(); }

    String businessName = seller.get("business_name");
    if (businessName == null || businessName.isEmpty()) businessName = seller.get("name");
    String bannerPic = seller.get("banner_picture");
    String profilePic = seller.get("profile_picture");
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
            border: 4px solid white;
            object-fit: cover;
            margin-top: -45px;
            background: white;
        }
        .shop-logo-placeholder {
            width: 90px; height: 90px;
            border-radius: 50%;
            border: 4px solid white;
            background: #0d6efd;
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
    </style>
</head>
<body>

<!-- TOAST -->
<div id="cartToast" class="toast-msg"><i class="bi bi-cart-check-fill me-2"></i> Item added to cart! 🛒</div>

<!-- NAVBAR -->
<nav class="navbar navbar-light bg-white shadow-sm py-3 sticky-top">
    <div class="container-fluid px-4">
        <a class="navbar-brand fw-bold text-primary fs-4" href="index.jsp">
            <i class="bi bi-bag-heart-fill"></i> ShopEasy
        </a>
        <form class="d-flex flex-grow-1 mx-3" action="index.jsp" method="get">
            <div class="input-group">
                <input type="text" class="form-control" name="search" placeholder="Search products..." style="border-radius:8px 0 0 8px;">
                <button class="btn btn-primary" type="submit" style="border-radius:0 8px 8px 0;"><i class="bi bi-search"></i></button>
            </div>
        </form>
        <div class="d-flex align-items-center gap-2">
            <% if (loggedUser != null && "customer".equals(loggedRole)) { %>
                <a href="CartServlet" class="btn btn-outline-secondary position-relative">
                    <i class="bi bi-cart3 fs-5"></i>
                    <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" style="font-size:9px;"><%= cartCount > 0 ? cartCount : "0" %></span>
                </a>
                <div class="avatar-circle">
                    <% if (userAvatar != null && !userAvatar.isEmpty()) { %>
                        <img src="<%= userAvatar %>" style="width:100%;height:100%;object-fit:cover;">
                    <% } else { %>
                        <%= loggedUser.substring(0, 1).toUpperCase() %>
                    <% } %>
                </div>
            <% } else { %>
                <a href="CartServlet" class="btn btn-outline-secondary position-relative">
                    <i class="bi bi-cart3 fs-5"></i>
                    <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" style="font-size:9px;">0</span>
                </a>
                <a href="index.jsp" class="btn btn-outline-primary" data-bs-toggle="modal" data-bs-target="#loginModal"><i class="bi bi-box-arrow-in-right"></i> Login</a>
                <a href="index.jsp" class="btn btn-primary"><i class="bi bi-person-plus"></i> Register</a>
            <% } %>
        </div>
    </div>
</nav>

<!-- BREADCRUMB -->
<div class="bg-white border-bottom px-4 py-2">
    <nav aria-label="breadcrumb">
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
<div style="max-width:1100px; margin:0 auto; height:220px; overflow:hidden; border-radius:12px; margin-bottom:0;">
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
    <h5 class="fw-bold mb-3"><i class="bi bi-grid text-primary"></i> Products (<%= products != null ? products.size() : 0 %>)</h5>
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
                            <% if (loggedUser != null && "customer".equals(loggedRole)) { %>
                                <button class="btn btn-primary btn-sm w-100" onclick="addToCart(<%= prod.get("product_id") %>)">
                                    <i class="bi bi-cart-plus"></i> Add to Cart
                                </button>
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
<!-- LOGIN MODAL -->
<div class="modal fade" id="loginModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered" style="max-width:420px;">
        <div class="modal-content rounded-4">
            <div class="modal-header border-0 pb-0">
                <h5 class="modal-title fw-bold">
                    <i class="bi bi-bag-heart-fill text-primary"></i> Login to ShopEasy
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body px-4 pb-4">
                <form action="LoginServlet" method="post" onsubmit="return handleLoginSubmit(event, this)">
                    <div class="mb-3">
                        <label class="form-label fw-bold">Email</label>
                        <input type="text" name="email" class="form-control" placeholder="Enter email" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-bold">Password</label>
                        <input type="password" name="password" class="form-control" placeholder="Enter password" required>
                    </div>
                    <button type="submit" class="btn btn-primary w-100 fw-bold py-2">
                        <i class="bi bi-box-arrow-in-right"></i> Login
                    </button>
                </form>
            </div>
        </div>
    </div>
</div>

<!-- LOGIN LOADING OVERLAY -->
<div id="loginLoadingOverlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.95); z-index:9999; flex-direction:column; align-items:center; justify-content:center;">
    <div class="spinner-border text-primary mb-3" style="width:3.5rem; height:3.5rem;" role="status"></div>
    <p class="fw-bold text-primary fs-5">Logging in...</p>
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
            const badge = document.querySelector('.badge.bg-danger');
            if (badge) badge.textContent = parseInt(badge.textContent || 0) + 1;
        }
    })
    .catch(err => console.error(err));
}
</script>
</body>
</html>