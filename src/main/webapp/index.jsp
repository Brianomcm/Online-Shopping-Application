<%@ page session="true" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String searchParam = request.getParameter("search");
    java.util.List<java.util.Map<String, Object>> products = new java.util.ArrayList<>();
    try {
        java.sql.Connection prodConn = com.shopeasy.DBConnection.getConnection();

        String catParam = request.getParameter("category");
        String minPriceParam = request.getParameter("minPrice");
        String maxPriceParam = request.getParameter("maxPrice");
        String minRatingParam = request.getParameter("minRating");
        String sortParam = request.getParameter("sort");

        String catFilter = (catParam != null && !catParam.isEmpty() && !catParam.equals("0")) ? "AND p.category_id = " + Integer.parseInt(catParam) + " " : "";
        String searchFilter = (searchParam != null && !searchParam.trim().isEmpty()) ? "AND (p.name LIKE ? OR p.description LIKE ?) " : "";
        String minPriceFilter = (minPriceParam != null && !minPriceParam.isEmpty()) ? "AND p.price >= " + Double.parseDouble(minPriceParam) + " " : "";
        String maxPriceFilter = (maxPriceParam != null && !maxPriceParam.isEmpty()) ? "AND p.price <= " + Double.parseDouble(maxPriceParam) + " " : "";
        String ratingFilter = (minRatingParam != null && !minRatingParam.isEmpty() && !minRatingParam.equals("0")) ? "HAVING avg_rating >= " + Double.parseDouble(minRatingParam) + " " : "";

        String orderBy = "ORDER BY RAND()";
        if ("price_asc".equals(sortParam)) orderBy = "ORDER BY p.price ASC";
        else if ("price_desc".equals(sortParam)) orderBy = "ORDER BY p.price DESC";
        else if ("rating".equals(sortParam)) orderBy = "ORDER BY avg_rating DESC";
        else if ("newest".equals(sortParam)) orderBy = "ORDER BY p.product_id DESC";
        else if ("best_seller".equals(sortParam)) orderBy = "ORDER BY total_sold DESC";

        java.sql.PreparedStatement prodPs = prodConn.prepareStatement(
        "SELECT p.*, s.business_name, " +
        "COALESCE((SELECT AVG(r.rating) FROM review r WHERE r.product_id = p.product_id), 0) AS avg_rating, " +
        "COALESCE((SELECT COUNT(*) FROM review r WHERE r.product_id = p.product_id), 0) AS review_count, " +
        "COALESCE((SELECT SUM(oi.quantity) FROM order_items oi JOIN orders o ON oi.order_id = o.order_id WHERE oi.product_id = p.product_id AND o.status='Completed'), 0) AS total_sold " +
        "FROM product p JOIN seller s ON p.seller_id = s.seller_id " +
        "WHERE p.status='active' AND p.stock > 0 " + catFilter + searchFilter + minPriceFilter + maxPriceFilter + ratingFilter + orderBy);
        if (searchParam != null && !searchParam.trim().isEmpty()) {
            String like = "%" + searchParam.trim() + "%";
            prodPs.setString(1, like);
            prodPs.setString(2, like);
        }


        java.sql.ResultSet prodRs = prodPs.executeQuery();
        while (prodRs.next()) {
            java.util.Map<String, Object> prod = new java.util.HashMap<>();
            prod.put("id", prodRs.getInt("product_id"));
            prod.put("name", prodRs.getString("name"));
            prod.put("price", prodRs.getDouble("price"));
            prod.put("image", prodRs.getString("image"));
            prod.put("stock", prodRs.getInt("stock"));
            prod.put("seller", prodRs.getString("business_name"));
prod.put("description", prodRs.getString("description"));
prod.put("categoryId", prodRs.getInt("category_id"));
prod.put("avgRating", prodRs.getDouble("avg_rating"));
prod.put("reviewCount", prodRs.getInt("review_count"));
prod.put("totalSold", prodRs.getInt("total_sold"));
prod.put("originalPrice", prodRs.getDouble("original_price"));
            products.add(prod);
        }
        prodRs.close();
        prodPs.close();
      prodConn.close();
    } catch (Exception ex) {
        ex.printStackTrace();
    }

    // Get cart count
    int cartCount = 0;
    try {
        String sessionRole = (String) session.getAttribute("userRole");
        Integer sessionUserId = (Integer) session.getAttribute("userId");
        if (sessionUserId != null && "customer".equals(sessionRole)) {
            java.sql.Connection cartConn = com.shopeasy.DBConnection.getConnection();
            java.sql.PreparedStatement cartPs = cartConn.prepareStatement(
                "SELECT SUM(ci.quantity) FROM cart c JOIN cartitem ci ON c.cart_id = ci.cart_id WHERE c.customer_id = ?");
            cartPs.setInt(1, sessionUserId);
            java.sql.ResultSet cartRs = cartPs.executeQuery();
            if (cartRs.next()) cartCount = cartRs.getInt(1);
            cartRs.close();
            cartPs.close();
            cartConn.close();
        }
    } catch (Exception ex) {
        ex.printStackTrace();
    }
%>

<%
    // Reset breadcrumb when user goes home
    session.removeAttribute("breadcrumb");
    session.removeAttribute("lastProductId");
    session.removeAttribute("lastProduct");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ShopEasy - Home</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css">
    
    <style>
    /* SKELETON LOADER */
.skeleton-box {
    background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
    background-size: 200% 100%;
    animation: shimmer 1.4s infinite;
}
@keyframes shimmer {
    0% { background-position: 200% 0; }
    100% { background-position: -200% 0; }
}

    input[type="password"]::-ms-reveal,
input[type="password"]::-ms-clear {
    display: none;
}
    
    
    input::-ms-reveal,
input::-ms-clear,
input::-webkit-credentials-auto-fill-button,
input::-webkit-contacts-auto-fill-button {
    display: none !important;
    visibility: hidden;
    pointer-events: none;
}
        * { box-sizing: border-box; }
        
        .category-card {
            transition: 0.3s;
            cursor: pointer;
            border-radius: 12px;
        }
        .category-card:hover {
            background-color: #0d6efd;
            color: white;
            transform: translateY(-3px);
        }
       .category-card:hover i,
        .category-card:hover small {
            color: white !important;
        }
        .category-card.active {
            background-color: #0d6efd !important;
            border-color: #0d6efd !important;
            color: white !important;
        }
        .category-card.active i,
        .category-card.active small {
            color: white !important;
        }
        .product-card {
            transition: 0.3s;
            border-radius: 12px;
            overflow: hidden;
        }
        .product-card:hover {
            box-shadow: 0 6px 20px rgba(0,0,0,0.15);
            transform: translateY(-4px);
        }
       .product-card img {
    height: 200px;
    object-fit: contain;
    width: 100%;
    background: #f8f9fa;
    padding: 8px;
}
        @media (max-width: 576px) {
            .product-card img { height: 120px; }
            .card-title { font-size: 13px; }
            .card-body { padding: 8px; }
        }
        .hero-section {
            background: linear-gradient(135deg, #0d6efd, #0056b3);
            padding: 60px 0;
        }
        @media (max-width: 576px) {
            .hero-section { padding: 30px 0; }
            .hero-section h1 { font-size: 24px; }
            .hero-section p { font-size: 14px; }
        }
        .top-bar {
            font-size: 12px;
            background-color: #0056b3;
        }
        .navbar-brand {
            font-size: 1.5rem;
            
        }
        
        .navbar.sticky-top {
  		  top: 0;
   		z-index: 1030;
		}

        @media (max-width: 576px) {
            .navbar-brand { font-size: 1.2rem; }
        }
        .badge-sale {
            position: absolute;
            top: 8px;
            left: 8px;
            background-color: red;
            color: white;
            font-size: 10px;
            padding: 3px 6px;
            border-radius: 4px;
        }
        .product-wrapper { position: relative; }
        footer a { color: #adb5bd; text-decoration: none; }
        footer a:hover { color: white; }
        #pageLoader {
            display: none;
            position: fixed;
            top: 0; left: 0;
            width: 100%; height: 100%;
            background: rgba(255,255,255,0.7);
            z-index: 9999;
            align-items: center;
            justify-content: center;
            flex-direction: column;
            gap: 12px;
        }
        .spinner-ring {
            width: 48px; height: 48px;
            border: 5px solid #e0e0e0;
            border-top-color: #0d6efd;
            border-radius: 50%;
            animation: spin 0.7s linear infinite;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
    </style>
</head>
<body>

<!-- PAGE LOADER -->
<div id="pageLoader">
    <div class="spinner-ring"></div>
    <span class="text-primary fw-bold">Loading...</span>
</div>


<!-- SUCCESS MESSAGE -->

<div id="successMsg" class="alert alert-success text-center mb-0 py-2" style="display:none; border-radius:0;">
    <i class="bi bi-check-circle-fill"></i> Registration successful! Please login to continue.
</div>
<!-- ERROR MESSAGE -->
<div id="errorMsg" class="alert alert-danger text-center mb-0 py-2" style="display:none; border-radius:0;">
    <i class="bi bi-x-circle-fill"></i> <span id="errorText">Account not found. Please check your email or password.</span>
</div>
<!-- NAVIGATION BAR -->
<nav class="navbar navbar-light bg-white shadow-sm py-3 sticky-top">
    <div class="container-fluid px-4">
        
        <!-- Logo -->
        <a class="navbar-brand fw-bold text-primary" href="index.jsp">
            <i class="bi bi-bag-heart-fill"></i> ShopEasy
        </a>

        <!-- Desktop Search Bar -->
        <form id="desktopSearch" class="d-none d-md-flex mx-3 flex-grow-1" action="index.jsp" method="get" onsubmit="return false;">
            <div class="input-group">
                <input type="text" class="form-control" name="search" placeholder="Search products..." value="<%= searchParam != null ? searchParam : "" %>">
                <button class="btn btn-primary px-3" type="submit">
                    <i class="bi bi-search"></i>
                </button>
            </div>
        </form>

        <!-- Nav Buttons -->
        <div class="d-flex gap-2 align-items-center">
        <%
            String loggedUser = (String) session.getAttribute("userName");
            String loggedRole = (String) session.getAttribute("userRole");
            if (loggedUser != null) {
        %>
        <% if ("customer".equals(loggedRole)) { %>
<a href="CartServlet" class="btn btn-outline-secondary position-relative">
    <i class="bi bi-cart3 fs-5"></i>
    <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" style="font-size:9px;"><%= cartCount > 0 ? cartCount : "0" %></span>
</a>
<% } %>
<div class="dropdown">
            <div class="dropdown">
                <a href="#" class="d-flex align-items-center gap-2 text-decoration-none" data-bs-toggle="dropdown">
                    <%
    String loggedRole2 = (String) session.getAttribute("userRole");
String navAvatar = "seller".equals(loggedRole2) ? 
    (String) session.getAttribute("userProfilePicture") : 
    (String) session.getAttribute("userAvatar");
%>
<% if (navAvatar != null && !navAvatar.isEmpty()) { %>
    <img src="<%= navAvatar %>" style="width:34px; height:34px; border-radius:50%; object-fit:cover; border:2px solid #0d6efd;" alt="Avatar">
<% } else { %>
    <div style="width:34px; height:34px; background:#0d6efd; border-radius:50%; display:flex; align-items:center; justify-content:center; color:white; font-weight:bold; font-size:14px;">
        <%= loggedUser.substring(0, 1).toUpperCase() %>
    </div>
<% } %>
                    <%
    String displayName = loggedUser;
    String businessName = (String) session.getAttribute("userBusinessName");
    if ("seller".equals(loggedRole) && businessName != null && !businessName.isEmpty()) {
        displayName = businessName;
    }
%>
<span class="d-none d-md-inline fw-bold text-dark" style="font-size:14px; max-width:100px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;"><%= displayName %></span>
                    <i class="bi bi-chevron-down text-muted" style="font-size:11px;"></i>
                </a>
                <ul class="dropdown-menu dropdown-menu-end shadow">
                    <li><h6 class="dropdown-header"><%= displayName %></h6></li>
                    <li><hr class="dropdown-divider"></li>
                    <% if ("customer".equals(loggedRole)) { %>
                    <li><a class="dropdown-item" href="customer.jsp"><i class="bi bi-person me-2"></i> My Profile</a></li>
                    <li><a class="dropdown-item" href="customer.jsp?tab=orders"><i class="bi bi-bag me-2"></i> My Orders</a></li>
                    <% } else if ("seller".equals(loggedRole)) { %>
                    <li><a class="dropdown-item" href="seller.jsp"><i class="bi bi-shop me-2"></i> Seller Dashboard</a></li>
                    <% } %>
                    <li><hr class="dropdown-divider"></li>
                    <li><a class="dropdown-item text-danger" href="#" onclick="doLogout()"><i class="bi bi-box-arrow-right me-2"></i> Logout</a></li>
                </ul>
            </div>
        <% } else { %>
    <a href="#" class="btn btn-outline-secondary position-relative" data-bs-toggle="modal" data-bs-target="#loginModal">
        <i class="bi bi-cart3 fs-5"></i>
        <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" style="font-size:9px;">0</span>
    </a>
    <a href="#" class="btn btn-outline-primary" data-bs-toggle="modal" data-bs-target="#loginModal">
        <i class="bi bi-person"></i>
        <span class="d-none d-md-inline"> Login</span>
    </a>
    <a href="#" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#registerModal">
        <i class="bi bi-person-plus"></i>
        <span class="d-none d-md-inline"> Register</span>
    </a>
<% } %>
        </div>
    </div>

 <!-- Mobile Search Bar -->
    <form id="mobileSearch" class="container-fluid px-3 d-md-none mt-2" action="index.jsp" method="get" onsubmit="return false;">
        <div class="input-group">
            <input type="text" class="form-control" name="search" placeholder="Search products..." value="<%= searchParam != null ? searchParam : "" %>">
            <button class="btn btn-primary" type="submit">
                <i class="bi bi-search"></i>
            </button>
        </div>
    </form>
</nav>

<!-- HERO CAROUSEL -->
<div id="heroCarousel" class="carousel slide" data-bs-ride="carousel" data-bs-interval="4000">
    <div class="carousel-indicators">
        <button type="button" data-bs-target="#heroCarousel" data-bs-slide-to="0" class="active"></button>
        <button type="button" data-bs-target="#heroCarousel" data-bs-slide-to="1"></button>
        <button type="button" data-bs-target="#heroCarousel" data-bs-slide-to="2"></button>
    </div>
    <div class="carousel-inner">
        <!-- SLIDE 1 -->
        <div class="carousel-item active">
            <div style="background:linear-gradient(135deg,#0d6efd 0%,#0056b3 100%); min-height:280px; display:flex; align-items:center; justify-content:center; flex-direction:column; color:white; text-align:center; padding:40px 20px;">
                <div style="font-size:13px; font-weight:600; letter-spacing:3px; opacity:0.85; margin-bottom:8px;">⚡ LIMITED TIME OFFER</div>
                <div style="font-size:52px; font-weight:900; line-height:1; text-shadow:0 2px 8px rgba(0,0,0,0.2);">BIG SALE</div>
                <div style="font-size:22px; font-weight:700; margin:8px 0; opacity:0.95;">Up to 50% Off Storewide!</div>
                <a href="#products" class="btn btn-warning btn-lg fw-bold mt-3 px-5" style="border-radius:30px;">
                    <i class="bi bi-shop"></i> Shop Now →
                </a>
            </div>
        </div>
        <!-- SLIDE 2 -->
        <div class="carousel-item">
            <div style="background:linear-gradient(135deg,#fd7e14 0%,#dc3545 100%); min-height:280px; display:flex; align-items:center; justify-content:center; flex-direction:column; color:white; text-align:center; padding:40px 20px;">
                <div style="font-size:13px; font-weight:600; letter-spacing:3px; opacity:0.85; margin-bottom:8px;">🚚 NATIONWIDE DELIVERY</div>
                <div style="font-size:52px; font-weight:900; line-height:1; text-shadow:0 2px 8px rgba(0,0,0,0.2);">FREE SHIPPING</div>
                <div style="font-size:22px; font-weight:700; margin:8px 0; opacity:0.95;">On All Orders Over ₱500!</div>
                <a href="#products" class="btn btn-light btn-lg fw-bold mt-3 px-5 text-danger" style="border-radius:30px;">
                    <i class="bi bi-cart3"></i> Order Now →
                </a>
            </div>
        </div>
        <!-- SLIDE 3 -->
        <div class="carousel-item">
            <div style="background:linear-gradient(135deg,#198754 0%,#0f5132 100%); min-height:280px; display:flex; align-items:center; justify-content:center; flex-direction:column; color:white; text-align:center; padding:40px 20px;">
                <div style="font-size:13px; font-weight:600; letter-spacing:3px; opacity:0.85; margin-bottom:8px;">🌟 JUST DROPPED</div>
                <div style="font-size:52px; font-weight:900; line-height:1; text-shadow:0 2px 8px rgba(0,0,0,0.2);">NEW ARRIVALS</div>
                <div style="font-size:22px; font-weight:700; margin:8px 0; opacity:0.95;">Fresh Finds This Week!</div>
                <a href="index.jsp?sort=newest" class="btn btn-warning btn-lg fw-bold mt-3 px-5" style="border-radius:30px;">
                    <i class="bi bi-stars"></i> See New Items →
                </a>
            </div>
        </div>
    </div>
    <button class="carousel-control-prev" type="button" data-bs-target="#heroCarousel" data-bs-slide="prev">
        <span class="carousel-control-prev-icon"></span>
    </button>
    <button class="carousel-control-next" type="button" data-bs-target="#heroCarousel" data-bs-slide="next">
        <span class="carousel-control-next-icon"></span>
    </button>
</div>
<!-- CATEGORIES -->
<%
String cp = request.getParameter("category");
boolean isAll = (cp == null || cp.isEmpty() || cp.equals("0"));
%>
<div class="container mt-4 mb-2">
<h5 class="mb-3 fw-bold">Browse by Category</h5>
<div class="row g-2 text-center flex-nowrap overflow-auto">
        <div class="col" onclick="filterCategory(0)" style="cursor:pointer; min-width:100px;">
            <div class="card category-card py-3 border h-100 <%= isAll ? "active" : "" %>" id="cat-0">
                <i class="bi bi-grid-fill fs-3 <%= isAll ? "" : "text-primary" %>"></i>
                <small class="mt-1 fw-bold">All</small>
            </div>
        </div>
        <div class="col" onclick="filterCategory(1)" style="cursor:pointer; min-width:100px;">
            <div class="card category-card py-3 border h-100 <%= "1".equals(cp) ? "active" : "" %>" id="cat-1">
                <i class="bi bi-phone fs-3 <%= "1".equals(cp) ? "" : "text-primary" %>"></i>
                <small class="mt-1 fw-bold">Electronics</small>
            </div>
        </div>
        <div class="col" onclick="filterCategory(2)" style="cursor:pointer; min-width:100px;">
            <div class="card category-card py-3 border h-100 <%= "2".equals(cp) ? "active" : "" %>" id="cat-2">
                <i class="bi bi-bag fs-3 <%= "2".equals(cp) ? "" : "text-primary" %>"></i>
                <small class="mt-1 fw-bold">Fashion</small>
            </div>
        </div>
        <div class="col" onclick="filterCategory(3)" style="cursor:pointer; min-width:100px;">
            <div class="card category-card py-3 border h-100 <%= "3".equals(cp) ? "active" : "" %>" id="cat-3">
                <i class="bi bi-house fs-3 <%= "3".equals(cp) ? "" : "text-primary" %>"></i>
                <small class="mt-1 fw-bold">Home</small>
            </div>
        </div>
        <div class="col" onclick="filterCategory(4)" style="cursor:pointer; min-width:100px;">
            <div class="card category-card py-3 border h-100 <%= "4".equals(cp) ? "active" : "" %>" id="cat-4">
                <i class="bi bi-controller fs-3 <%= "4".equals(cp) ? "" : "text-primary" %>"></i>
                <small class="mt-1 fw-bold">Gaming</small>
            </div>
        </div>
        <div class="col" onclick="filterCategory(5)" style="cursor:pointer; min-width:100px;">
            <div class="card category-card py-3 border h-100 <%= "5".equals(cp) ? "active" : "" %>" id="cat-5">
                <i class="bi bi-heart-pulse fs-3 <%= "5".equals(cp) ? "" : "text-primary" %>"></i>
                <small class="mt-1 fw-bold">Health</small>
            </div>
        </div>
        <div class="col" onclick="filterCategory(6)" style="cursor:pointer; min-width:100px;">
            <div class="card category-card py-3 border h-100 <%= "6".equals(cp) ? "active" : "" %>" id="cat-6">
                <i class="bi bi-box fs-3 <%= "6".equals(cp) ? "" : "text-primary" %>"></i>
                <small class="mt-1 fw-bold">Others</small>
            </div>
        </div>
    </div>
</div>


<!-- FEATURED PRODUCTS -->
<div class="container mt-4" id="products">
<%
String fMin = request.getParameter("minPrice") != null ? request.getParameter("minPrice") : "";
String fMax = request.getParameter("maxPrice") != null ? request.getParameter("maxPrice") : "";
String fRating = request.getParameter("minRating") != null ? request.getParameter("minRating") : "0";
String fSort = request.getParameter("sort") != null ? request.getParameter("sort") : "";
String fCat = request.getParameter("category") != null ? request.getParameter("category") : "0";
String fSearch = request.getParameter("search") != null ? request.getParameter("search") : "";
%>
<!-- COLLAPSIBLE FILTER BAR -->
<div class="mb-3">
    <button class="btn btn-outline-primary btn-sm fw-bold" type="button" data-bs-toggle="collapse" data-bs-target="#filterPanel">
        <i class="bi bi-funnel-fill"></i> Filters
        <% if (!fMin.isEmpty() || !fMax.isEmpty() || !fRating.equals("0") || !fSort.isEmpty()) { %>
        <span class="badge bg-primary ms-1">Active</span>
        <% } %>
    </button>
    <a href="index.jsp?category=<%= fCat %>&search=<%= fSearch %>" class="btn btn-outline-secondary btn-sm ms-2">
        <i class="bi bi-x-lg"></i> Clear
    </a>
    <div class="collapse <%= (!fMin.isEmpty() || !fMax.isEmpty() || !fRating.equals("0") || !fSort.isEmpty()) ? "show" : "" %>" id="filterPanel">
        <div class="card border-0 shadow-sm p-3 mt-2" style="border-radius:12px;">
            <form id="filterForm" action="index.jsp" method="get">
                <input type="hidden" name="category" value="<%= fCat %>">
                <input type="hidden" name="search" value="<%= fSearch %>">
                <div class="row g-2 align-items-end">
                    <div class="col-6 col-md-2">
                        <label class="form-label fw-bold mb-1" style="font-size:12px;">Min Price (₱)</label>
                        <input type="number" name="minPrice" class="form-control form-control-sm" placeholder="0" value="<%= fMin %>" min="0">
                    </div>
                    <div class="col-6 col-md-2">
                        <label class="form-label fw-bold mb-1" style="font-size:12px;">Max Price (₱)</label>
                        <input type="number" name="maxPrice" class="form-control form-control-sm" placeholder="Any" value="<%= fMax %>" min="0">
                    </div>
                    <div class="col-6 col-md-3">
                        <label class="form-label fw-bold mb-1" style="font-size:12px;">Min Rating</label>
                        <select name="minRating" class="form-select form-select-sm">
                            <option value="0" <%= "0".equals(fRating) ? "selected" : "" %>>Any Rating</option>
                            <option value="1" <%= "1".equals(fRating) ? "selected" : "" %>>⭐ 1 & up</option>
                            <option value="2" <%= "2".equals(fRating) ? "selected" : "" %>>⭐⭐ 2 & up</option>
                            <option value="3" <%= "3".equals(fRating) ? "selected" : "" %>>⭐⭐⭐ 3 & up</option>
                            <option value="4" <%= "4".equals(fRating) ? "selected" : "" %>>⭐⭐⭐⭐ 4 & up</option>
                            <option value="5" <%= "5".equals(fRating) ? "selected" : "" %>>⭐⭐⭐⭐⭐ 5 only</option>
                        </select>
                    </div>
                    <div class="col-6 col-md-3">
                        <label class="form-label fw-bold mb-1" style="font-size:12px;">Sort By</label>
                        <select name="sort" class="form-select form-select-sm">
                            <option value="" <%= "".equals(fSort) ? "selected" : "" %>>Default</option>
                            <option value="price_asc" <%= "price_asc".equals(fSort) ? "selected" : "" %>>Price: Low to High</option>
                            <option value="price_desc" <%= "price_desc".equals(fSort) ? "selected" : "" %>>Price: High to Low</option>
                            <option value="rating" <%= "rating".equals(fSort) ? "selected" : "" %>>Highest Rated</option>
                            <option value="newest" <%= "newest".equals(fSort) ? "selected" : "" %>>Newest</option>
                            <option value="best_seller" <%= "best_seller".equals(fSort) ? "selected" : "" %>>Best Seller</option>
                        </select>
                    </div>
                    <div class="col-12 col-md-2">
                        <button type="submit" class="btn btn-primary btn-sm w-100">
                            <i class="bi bi-funnel-fill"></i> Apply
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>
<!-- PRODUCTS COLUMN -->
<div class="col-12">
   <%
String[] catNames = {"Featured Products","Electronics","Fashion","Home","Gaming","Health","Others"};
String catParamTitle = request.getParameter("category");
String sectionTitle = (catParamTitle != null && !catParamTitle.isEmpty() && !catParamTitle.equals("0")) ? catNames[Integer.parseInt(catParamTitle)] : "Featured Products";
String searchTitle = (searchParam != null && !searchParam.trim().isEmpty()) ? "Search results for \"" + searchParam + "\"" : sectionTitle;
%>
    <div class="d-flex align-items-center justify-content-between mb-3">
        <h5 class="fw-bold mb-0"><%= searchTitle %></h5>
        <span class="text-muted" style="font-size:13px;"><%= products.size() %> product<%= products.size() != 1 ? "s" : "" %> found</span>
    </div>
    <!-- SKELETON LOADER -->
    <div id="skeletonGrid" class="row g-3">
        <% for (int sk = 0; sk < 8; sk++) { %>
        <div class="col-6 col-md-4 col-lg-3">
            <div class="card h-100 border-0 shadow-sm">
                <div class="skeleton-box" style="height:200px; border-radius:8px 8px 0 0;"></div>
                <div class="card-body">
                    <div class="skeleton-box mb-2" style="height:14px; width:80%; border-radius:4px;"></div>
                    <div class="skeleton-box mb-2" style="height:12px; width:50%; border-radius:4px;"></div>
                    <div class="skeleton-box mb-2" style="height:12px; width:60%; border-radius:4px;"></div>
                    <div class="skeleton-box" style="height:30px; border-radius:6px;"></div>
                </div>
            </div>
        </div>
        <% } %>
    </div>
    <!-- ACTUAL PRODUCTS -->
    <div id="actualGrid" class="row g-3" style="display:none;">
    
<% if (products.isEmpty()) { %>
    <div class="col-12 text-center py-5 text-muted">
        <i class="bi bi-box-seam fs-1 opacity-25"></i>
        <p class="mt-2">No products available yet.</p>
    </div>
<% } else { %>
    <% for (java.util.Map<String, Object> prod : products) { %>
   <div class="col-6 col-md-4 col-lg-3 product-item" data-category="<%= prod.get("categoryId") %>">
<div class="card h-100 product-card" onclick="window.location.href='product.jsp?id=<%= prod.get("id") %>'" style="cursor:pointer;">  
            <div class="product-wrapper">
                <% if (prod.get("image") != null) { %>
                    <img src="<%= prod.get("image") %>" class="card-img-top" alt="<%= prod.get("name") %>">
                <% } else { %>
                    <div style="height:200px; background:#f8f9fa; display:flex; align-items:center; justify-content:center; color:#aaa; font-size:40px;"><i class="bi bi-image"></i></div>
                <% } %>
            </div>
            <div class="card-body d-flex flex-column">
              <h6 class="card-title"><%= prod.get("name") %></h6>
<p class="text-muted mb-1" style="font-size:11px;"><i class="bi bi-shop"></i> <%= prod.get("seller") %></p>
<div class="d-flex align-items-center gap-1 mb-1">
    <% double pRating = (Double) prod.get("avgRating");
       int pReviews = (Integer) prod.get("reviewCount");
       for (int s = 1; s <= 5; s++) { %>
        <i class="bi bi-star-fill" style="color:<%= s <= Math.round(pRating) ? "#ffc107" : "#ddd" %>; font-size:11px;"></i>
    <% } %>
    <span class="text-muted" style="font-size:10px;">(<%= pReviews %>)</span>
    <span class="text-muted" style="font-size:10px;">· <%= prod.get("totalSold") %> sold</span>
</div>
<%
    double idxDiscPrice = (Double) prod.get("originalPrice");
    double idxRealPrice = (Double) prod.get("price");
    int idxDiscPct = 0;
    if (idxDiscPrice > 0 && idxDiscPrice < idxRealPrice) {
        idxDiscPct = (int) Math.round((idxRealPrice - idxDiscPrice) / idxRealPrice * 100);
    }
%>
<% if (idxDiscPct > 0) { %>
    <div class="d-flex align-items-center gap-2 mb-0">
        <span class="text-muted text-decoration-line-through" style="font-size:11px;">₱<%= String.format("%.2f", idxRealPrice) %></span>
        <span class="badge bg-danger" style="font-size:10px;">-<%= idxDiscPct %>% OFF</span>
    </div>
    <p class="card-text text-danger fw-bold mb-0">₱<%= String.format("%.2f", idxDiscPrice) %></p>
<% } else { %>
    <p class="card-text text-danger fw-bold mb-0">₱<%= String.format("%.2f", idxRealPrice) %></p>
<% } %>
<p class="text-muted mb-2" style="font-size:11px;">Stock: <%= prod.get("stock") %></p>
                <div class="mt-auto" onclick="event.stopPropagation();">
                    <% if (loggedUser != null && "customer".equals(loggedRole)) { %>
                        <button type="button" class="btn btn-primary btn-sm w-100" onclick="addToCart(<%= prod.get("id") %>)">
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
<!-- LOAD MORE -->
<div class="col-12 text-center mt-4" id="loadMoreSection" style="display:none;">
    <button class="btn btn-outline-primary px-5 py-2 fw-bold" onclick="loadMore()" id="loadMoreBtn">
        <i class="bi bi-arrow-down-circle"></i> Load More Products
    </button>
    <p class="text-muted mt-2" style="font-size:12px;" id="loadMoreCount"></p>
</div>
</div>
</div>
</div>
</div>

<!-- PRODUCT DETAILS MODAL -->

<!-- PRODUCT DETAILS MODAL -->
<div class="modal fade" id="productModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content rounded-4">
            <div class="modal-header border-0 pb-0">
                <h5 class="modal-title fw-bold" id="modalProductName"></h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body px-4 pb-4">
                <div class="row g-3">
                    <div class="col-md-5 text-center">
                        <img id="modalProductImg" src="" style="width:100%; max-height:280px; object-fit:contain; border-radius:12px; background:#f8f9fa; padding:12px;">
                    </div>
                    <div class="col-md-7">
                        <p class="text-muted mb-1" style="font-size:13px;"><i class="bi bi-shop"></i> <span id="modalSeller"></span></p>
                        <h3 class="text-danger fw-bold mb-2" id="modalPrice"></h3>
                        <p class="text-muted mb-3" style="font-size:13px;">Stock: <span id="modalStock"></span></p>
                        <hr>
                        <p class="fw-bold mb-1">Description</p>
                        <p class="text-muted" id="modalDescription" style="font-size:14px;"></p>
                        <div id="modalCartSection" class="mt-3"></div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>




<!-- FOOTER -->
<footer style="background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%); color:white; margin-top:60px; padding:60px 0 0 0;">
    <div class="container">
        <div class="row g-4 pb-5">

            <!-- Brand -->
            <div class="col-lg-4 col-md-6">
                <div class="d-flex align-items-center gap-2 mb-3">
                    <div style="background:linear-gradient(135deg,#22c55e,#16a34a); border-radius:10px; width:38px; height:38px; display:flex; align-items:center; justify-content:center;">
                        <i class="bi bi-bag-heart-fill text-white" style="font-size:18px;"></i>
                    </div>
                    <span style="font-size:22px; font-weight:800; letter-spacing:-0.5px;">ShopEasy</span>
                </div>
                <p style="font-size:13px; color:#94a3b8; line-height:1.7;">
                    Your one-stop marketplace for everything you need — from gadgets to fashion, delivered fast and easy across the Philippines.
                </p>
                <div class="d-flex gap-2 mt-3">
                    <div style="background:#1e3a5f; border-radius:8px; width:34px; height:34px; display:flex; align-items:center; justify-content:center; cursor:pointer;">
                        <i class="bi bi-facebook" style="color:#60a5fa; font-size:15px;"></i>
                    </div>
                    <div style="background:#2d1b4e; border-radius:8px; width:34px; height:34px; display:flex; align-items:center; justify-content:center; cursor:pointer;">
                        <i class="bi bi-instagram" style="color:#e879f9; font-size:15px;"></i>
                    </div>
                    <div style="background:#1a3a2a; border-radius:8px; width:34px; height:34px; display:flex; align-items:center; justify-content:center; cursor:pointer;">
                        <i class="bi bi-twitter-x" style="color:#4ade80; font-size:15px;"></i>
                    </div>
                    <div style="background:#3b1f1f; border-radius:8px; width:34px; height:34px; display:flex; align-items:center; justify-content:center; cursor:pointer;">
                        <i class="bi bi-youtube" style="color:#f87171; font-size:15px;"></i>
                    </div>
                </div>
            </div>

            <!-- Quick Links -->
            <div class="col-lg-2 col-md-6 col-6">
                <p style="font-size:12px; font-weight:700; color:#22c55e; letter-spacing:1.5px; text-transform:uppercase; margin-bottom:16px;">Navigate</p>
                <ul class="list-unstyled" style="font-size:13px;">
                    <li class="mb-2"><a href="index.jsp" style="color:#cbd5e1; text-decoration:none;" onmouseover="this.style.color='#22c55e'" onmouseout="this.style.color='#cbd5e1'"><i class="bi bi-chevron-right me-1" style="font-size:10px;"></i>Home</a></li>
                    <li class="mb-2"><a href="index.jsp?category=1" style="color:#cbd5e1; text-decoration:none;" onmouseover="this.style.color='#22c55e'" onmouseout="this.style.color='#cbd5e1'"><i class="bi bi-chevron-right me-1" style="font-size:10px;"></i>Electronics</a></li>
                    <li class="mb-2"><a href="index.jsp?category=2" style="color:#cbd5e1; text-decoration:none;" onmouseover="this.style.color='#22c55e'" onmouseout="this.style.color='#cbd5e1'"><i class="bi bi-chevron-right me-1" style="font-size:10px;"></i>Fashion</a></li>
                    <li class="mb-2"><a href="index.jsp?category=4" style="color:#cbd5e1; text-decoration:none;" onmouseover="this.style.color='#22c55e'" onmouseout="this.style.color='#cbd5e1'"><i class="bi bi-chevron-right me-1" style="font-size:10px;"></i>Gaming</a></li>
                    <li class="mb-2"><a href="index.jsp?category=3" style="color:#cbd5e1; text-decoration:none;" onmouseover="this.style.color='#22c55e'" onmouseout="this.style.color='#cbd5e1'"><i class="bi bi-chevron-right me-1" style="font-size:10px;"></i>Home & Living</a></li>
                </ul>
            </div>

            <!-- Support -->
            <div class="col-lg-2 col-md-6 col-6">
                <p style="font-size:12px; font-weight:700; color:#22c55e; letter-spacing:1.5px; text-transform:uppercase; margin-bottom:16px;">Support</p>
                <ul class="list-unstyled" style="font-size:13px;">
                    <li class="mb-2"><a href="#" style="color:#cbd5e1; text-decoration:none;" onmouseover="this.style.color='#22c55e'" onmouseout="this.style.color='#cbd5e1'"><i class="bi bi-chevron-right me-1" style="font-size:10px;"></i>Help Center</a></li>
                    <li class="mb-2"><a href="#" style="color:#cbd5e1; text-decoration:none;" onmouseover="this.style.color='#22c55e'" onmouseout="this.style.color='#cbd5e1'"><i class="bi bi-chevron-right me-1" style="font-size:10px;"></i>Track Order</a></li>
                    <li class="mb-2"><a href="#" style="color:#cbd5e1; text-decoration:none;" onmouseover="this.style.color='#22c55e'" onmouseout="this.style.color='#cbd5e1'"><i class="bi bi-chevron-right me-1" style="font-size:10px;"></i>Returns</a></li>
                    <li class="mb-2"><a href="#" style="color:#cbd5e1; text-decoration:none;" onmouseover="this.style.color='#22c55e'" onmouseout="this.style.color='#cbd5e1'"><i class="bi bi-chevron-right me-1" style="font-size:10px;"></i>Privacy Policy</a></li>
                    <li class="mb-2"><a href="#" style="color:#cbd5e1; text-decoration:none;" onmouseover="this.style.color='#22c55e'" onmouseout="this.style.color='#cbd5e1'"><i class="bi bi-chevron-right me-1" style="font-size:10px;"></i>Terms of Use</a></li>
                </ul>
            </div>

            <!-- Contact -->
            <div class="col-lg-4 col-md-6">
                <p style="font-size:12px; font-weight:700; color:#22c55e; letter-spacing:1.5px; text-transform:uppercase; margin-bottom:16px;">Get In Touch</p>
                <div class="d-flex align-items-start gap-3 mb-3">
                    <div style="background:#1a3a2a; border-radius:8px; width:36px; height:36px; flex-shrink:0; display:flex; align-items:center; justify-content:center;">
                        <i class="bi bi-geo-alt-fill" style="color:#22c55e; font-size:15px;"></i>
                    </div>
                    <div>
                        <p style="font-size:12px; font-weight:600; color:#e2e8f0; margin:0;">Head Office</p>
                        <p style="font-size:12px; color:#94a3b8; margin:0;">123 Ayala Ave, Makati City, Metro Manila, Philippines</p>
                    </div>
                </div>
                <div class="d-flex align-items-start gap-3 mb-3">
                    <div style="background:#1e3a5f; border-radius:8px; width:36px; height:36px; flex-shrink:0; display:flex; align-items:center; justify-content:center;">
                        <i class="bi bi-envelope-fill" style="color:#60a5fa; font-size:15px;"></i>
                    </div>
                    <div>
                        <p style="font-size:12px; font-weight:600; color:#e2e8f0; margin:0;">Email Us</p>
                        <p style="font-size:12px; color:#94a3b8; margin:0;">support@shopeasy.com</p>
                    </div>
                </div>
                <div class="d-flex align-items-start gap-3">
                    <div style="background:#3b1f1f; border-radius:8px; width:36px; height:36px; flex-shrink:0; display:flex; align-items:center; justify-content:center;">
                        <i class="bi bi-telephone-fill" style="color:#f87171; font-size:15px;"></i>
                    </div>
                    <div>
                        <p style="font-size:12px; font-weight:600; color:#e2e8f0; margin:0;">Call Us</p>
                        <p style="font-size:12px; color:#94a3b8; margin:0;">+63 912 345 6789 &nbsp;|&nbsp; Mon–Sat 8AM–6PM</p>
                    </div>
                </div>
            </div>

        </div>

        <!-- Stats bar -->
        <div style="border-top:1px solid #1e293b; padding:20px 0;" class="d-none d-md-block">
            <div class="row text-center">
                <div class="col-3">
                    <p style="font-size:22px; font-weight:800; color:#22c55e; margin:0;">10K+</p>
                    <p style="font-size:11px; color:#64748b; margin:0;">Products Listed</p>
                </div>
                <div class="col-3">
                    <p style="font-size:22px; font-weight:800; color:#60a5fa; margin:0;">5K+</p>
                    <p style="font-size:11px; color:#64748b; margin:0;">Happy Customers</p>
                </div>
                <div class="col-3">
                    <p style="font-size:22px; font-weight:800; color:#e879f9; margin:0;">500+</p>
                    <p style="font-size:11px; color:#64748b; margin:0;">Verified Sellers</p>
                </div>
                <div class="col-3">
                    <p style="font-size:22px; font-weight:800; color:#f87171; margin:0;">4.8★</p>
                    <p style="font-size:11px; color:#64748b; margin:0;">Average Rating</p>
                </div>
            </div>
        </div>

        <!-- Bottom bar -->
        <div style="border-top:1px solid #1e293b; padding:16px 0;">
            <div class="d-flex flex-column flex-md-row justify-content-between align-items-center gap-2">
                <p style="font-size:12px; color:#475569; margin:0;">© 2026 ShopEasy Philippines. All rights reserved.</p>
                <div class="d-flex gap-3">
                    <img src="https://img.icons8.com/color/32/visa.png" style="height:22px; opacity:0.8;" alt="Visa">
<img src="https://img.icons8.com/color/32/mastercard-logo.png" style="height:22px; opacity:0.8;" alt="Mastercard">
<span style="background:#007bff; color:white; font-size:10px; font-weight:800; padding:3px 7px; border-radius:5px; letter-spacing:0.5px; opacity:0.85;">GCash</span>
<img src="https://img.icons8.com/color/32/paypal.png" style="height:22px; opacity:0.8;" alt="PayPal">
                </div>
            </div>
        </div>

    </div>
</footer>
<%@ include file="modals.jsp" %>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

<script>
function showProduct(id, name, price, stock, seller, image, description) {
    document.getElementById('modalProductName').innerText = name;
    document.getElementById('modalPrice').innerText = '₱' + parseFloat(price).toFixed(2);
    document.getElementById('modalStock').innerText = stock;
    document.getElementById('modalSeller').innerText = seller;
    document.getElementById('modalDescription').innerText = description;

    const img = document.getElementById('modalProductImg');
    if (image && image !== 'null' && image !== '') {
        img.src = image;
        img.style.display = 'block';
    } else {
        img.style.display = 'none';
    }

    const cartSection = document.getElementById('modalCartSection');
    const isLoggedIn = <%= (loggedUser != null && "customer".equals(loggedRole)) ? "true" : "false" %>;
    if (isLoggedIn) {
    	cartSection.innerHTML = `
    	    <button type="button" class="btn btn-primary w-100 fw-bold py-2" onclick="addToCart(${id})">
    	        <i class="bi bi-cart-plus"></i> Add to Cart
    	    </button>`;
    } else {
        cartSection.innerHTML = `
            <button class="btn btn-primary w-100 fw-bold py-2" onclick="bootstrap.Modal.getInstance(document.getElementById('productModal')).hide(); setTimeout(()=>new bootstrap.Modal(document.getElementById('loginModal')).show(),300)">
                <i class="bi bi-cart-plus"></i> Login to Add to Cart
            </button>`;
    }

    new bootstrap.Modal(document.getElementById('productModal')).show();
}
</script>

<script>
    


    function doLogout() {
        if (confirm('Are you sure you want to logout?')) {
            document.getElementById('logoutOverlay').style.display = 'flex';
            setTimeout(() => { window.location.href = 'LogoutServlet'; }, 1500);
        }
    }

    function showCenterToast(msg) {
        const toast = document.getElementById('centerToast');
        document.getElementById('centerToastMsg').textContent = msg;
        toast.style.display = 'flex';
        setTimeout(() => toast.style.display = 'none', 3000);
    }

    document.getElementById('registerForm').addEventListener('submit', function(e) {
        const password = document.getElementById('regPassword').value;
        const confirm = document.getElementById('confirmPassword').value;
        if (password !== confirm) {
            e.preventDefault();
            alert('Passwords do not match!');
            return false;
        }
        if (password.length < 6) {
            e.preventDefault();
            alert('Password must be at least 6 characters!');
            return false;
        }
        // Don't prevent default — let form submit normally
        // Just show the overlay as visual feedback
        var modal = bootstrap.Modal.getInstance(document.getElementById('registerModal'));
        if (modal) modal.hide();
        document.getElementById('registerLoadingOverlay').style.display = 'flex';
    });

    window.addEventListener('load', function() {
        initProducts();
        const urlParams = new URLSearchParams(window.location.search);

        if (urlParams.get('registered') === 'true') {
            document.getElementById('successMsg').style.display = 'block';
            document.getElementById('successMsg').innerHTML = '<i class="bi bi-check-circle-fill"></i> Registration successful! Please login to continue.';
            setTimeout(() => document.getElementById('successMsg').style.display = 'none', 4000);
        }

        if (urlParams.get('loggedin') === 'true') {
            showCenterToast('Welcome! You are now logged in. 👋');
        }

        if (urlParams.get('error') === 'login') {
            var loginModal = new bootstrap.Modal(document.getElementById('loginModal'));
            loginModal.show();
            setTimeout(() => {
                document.getElementById('loginError').style.display = 'block';
                document.getElementById('loginErrorText').textContent = 'Account not found. Please check your email or password.';
                document.getElementById('loginPassword').value = '';
            }, 500);
        }
    });
    
    
 
    
    
    </script>

<!-- WELCOME TOAST -->
<div id="centerToast" style="display:none; position:fixed; top:20px; left:50%; transform:translateX(-50%); background:#0d6efd; color:white; padding:14px 32px; border-radius:12px; font-size:15px; font-weight:600; z-index:9999; box-shadow:0 4px 16px rgba(0,0,0,0.2); align-items:center; gap:10px;">
    <i class="bi bi-person-check-fill me-2"></i><span id="centerToastMsg"></span>
</div>
    <!-- ADD TO CART TOAST -->
    <div id="cartToast" style="display:none; position:fixed; top:20px; left:50%; transform:translateX(-50%); background:#198754; color:white; padding:12px 28px; border-radius:12px; font-size:14px; font-weight:600; z-index:9999; box-shadow:0 4px 16px rgba(0,0,0,0.2);">
        <i class="bi bi-cart-check-fill me-2"></i> Item added to cart! 🛒
    </div>


    <script>
    function addToCart(productId) {
        fetch('AddToCartServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'productId=' + productId
        })
        .then(res => res.json())
        .then(data => {
    console.log('Response:', data);
    if (data.success) {
                const toast = document.getElementById('cartToast');
                toast.style.display = 'block';
                setTimeout(() => toast.style.display = 'none', 2500);
                const badge = document.querySelector('.badge.bg-danger');
                if (badge) {
                    badge.textContent = parseInt(badge.textContent || 0) + 1;
                }
                const modal = bootstrap.Modal.getInstance(document.getElementById('productModal'));
                if (modal) modal.hide();
            }
        })
        .catch(err => console.error(err));
    }
    
    const pageSize = 20;
    let shown = 0;
    let allCards = [];

    function initProducts() {
        allCards = Array.from(document.querySelectorAll('.product-item'));
        if (allCards.length === 0) return;
        allCards.forEach(c => c.style.display = 'none');
        shown = 0;
        showNextBatch();
    }

    function showNextBatch() {
        const next = allCards.slice(shown, shown + pageSize);
        next.forEach(c => c.style.display = 'block');
        shown += next.length;
        updateLoadMore();
    }

    function loadMore() {
        showNextBatch();
    }

    function updateLoadMore() {
        const total = allCards.length;
        const section = document.getElementById('loadMoreSection');
        const countEl = document.getElementById('loadMoreCount');
        if (total <= pageSize) {
            section.style.display = 'none';
            return;
        }
        section.style.display = 'block';
        if (shown >= total) {
            document.getElementById('loadMoreBtn').style.display = 'none';
            countEl.textContent = 'Showing all ' + total + ' products';
        } else {
            document.getElementById('loadMoreBtn').style.display = 'inline-block';
            countEl.textContent = 'Showing ' + shown + ' of ' + total + ' products';
        }
    }
    
    function filterCategory(categoryId) {
        window.location.href = 'index.jsp?category=' + categoryId;
    }
    function showSearchLoader(formId) {
        var loader = document.getElementById('pageLoader');
        loader.style.display = 'flex';
        loader.style.alignItems = 'center';
        loader.style.justifyContent = 'center';
        setTimeout(() => { document.getElementById(formId).submit(); }, 500);
    }

    document.addEventListener('DOMContentLoaded', function() {
        ['desktopSearch', 'mobileSearch'].forEach(function(id) {
            var form = document.getElementById(id);
            if (!form) return;
            form.querySelector('button[type=submit]').addEventListener('click', function() {
                showSearchLoader(id);
            });
            form.addEventListener('keydown', function(e) {
                if (e.key === 'Enter') showSearchLoader(id);
            });
        });
    });
 // Show skeleton first, then reveal actual products after short delay
    document.addEventListener('DOMContentLoaded', function() {
        setTimeout(function() {
            document.getElementById('skeletonGrid').style.display = 'none';
            document.getElementById('actualGrid').style.display = 'flex';
            document.getElementById('actualGrid').style.flexWrap = 'wrap';
        }, 800);
    });
    </script>
    

    
   
<%
    String isLoggedInFlag = (loggedUser != null && "customer".equals(loggedRole)) ? "true" : "false";
%>
<input type="hidden" id="isLoggedInFlag" value="<%= isLoggedInFlag %>">


</body>
</html>