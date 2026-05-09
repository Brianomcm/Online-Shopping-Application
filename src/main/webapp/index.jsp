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
        String searchFilter = "";
        String[] searchWords = new String[0];
        if (searchParam != null && !searchParam.trim().isEmpty()) {
            searchWords = searchParam.trim().split("\\s+");
            StringBuilder sf = new StringBuilder("AND (");
            for (int i = 0; i < searchWords.length; i++) {
                if (i > 0) sf.append(" OR ");
                sf.append("p.name LIKE ? OR p.description LIKE ?");
            }
            sf.append(") ");
            searchFilter = sf.toString();
        }
        double minPriceVal = 0, maxPriceVal = 0, minRatingVal = 0;
        try { if (minPriceParam != null && !minPriceParam.isEmpty()) minPriceVal = Double.parseDouble(minPriceParam); } catch (NumberFormatException e) { minPriceParam = ""; }
        try { if (maxPriceParam != null && !maxPriceParam.isEmpty()) maxPriceVal = Double.parseDouble(maxPriceParam); } catch (NumberFormatException e) { maxPriceParam = ""; }
        try { if (minRatingParam != null && !minRatingParam.isEmpty()) minRatingVal = Double.parseDouble(minRatingParam); } catch (NumberFormatException e) { minRatingParam = ""; }

        String minPriceFilter = (minPriceParam != null && !minPriceParam.isEmpty()) ?
            "AND COALESCE(NULLIF(p.original_price, 0), p.price) >= " + minPriceVal + " " : "";
        String maxPriceFilter = (maxPriceParam != null && !maxPriceParam.isEmpty()) ?
            "AND COALESCE(NULLIF(p.original_price, 0), p.price) <= " + maxPriceVal + " " : "";
        String ratingFilter = (minRatingParam != null && !minRatingParam.isEmpty() && !minRatingParam.equals("0")) ?
            "AND COALESCE((SELECT AVG(r.rating) FROM review r WHERE r.product_id = p.product_id), 0) >= " + minRatingVal + " " : "";
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
        		"COALESCE((SELECT SUM(oi.quantity) FROM order_items oi JOIN orders o ON oi.order_id = o.order_id WHERE oi.product_id = p.product_id AND o.status='Completed'), 0) AS total_sold, " +
        		"s.user_id AS seller_user_id " +
        "FROM product p JOIN seller s ON p.seller_id = s.seller_id " +
        "WHERE p.status='active' AND p.stock > 0 " + catFilter + searchFilter + minPriceFilter + maxPriceFilter + ratingFilter + orderBy);
        if (searchWords.length > 0) {
            int idx = 1;
            for (String word : searchWords) {
                String like = "%" + word + "%";
                prodPs.setString(idx++, like);
                prodPs.setString(idx++, like);
            }
        }


        java.sql.ResultSet prodRs = prodPs.executeQuery();
        while (prodRs.next()) {
            java.util.Map<String, Object> prod = new java.util.HashMap<>();
            prod.put("id", prodRs.getInt("product_id"));
            prod.put("name", prodRs.getString("name"));
            prod.put("price", prodRs.getDouble("price"));
            String prodImg = prodRs.getString("thumbnail");
            if (prodImg == null || prodImg.isEmpty()) prodImg = prodRs.getString("image");
            prod.put("image", prodImg);
            prod.put("productIdForVar", prodRs.getInt("product_id"));
            prod.put("stock", prodRs.getInt("stock"));
            prod.put("seller", prodRs.getString("business_name"));
prod.put("description", prodRs.getString("description"));
prod.put("categoryId", prodRs.getInt("category_id"));
prod.put("avgRating", prodRs.getDouble("avg_rating"));
prod.put("reviewCount", prodRs.getInt("review_count"));
prod.put("totalSold", prodRs.getInt("total_sold"));
prod.put("originalPrice", prodRs.getDouble("original_price"));
prod.put("sellerUserId", prodRs.getInt("seller_user_id"));

         products.add(prod);
        }
        prodRs.close();
        prodPs.close();
      prodConn.close();
      
   // Batch-load variation flags (1 query instead of N)
      java.util.Set<Integer> productsWithVariations = new java.util.HashSet<>();
      if (!products.isEmpty()) {
    	  java.sql.Connection pvConn = com.shopeasy.DBConnection.getConnection();
          java.sql.PreparedStatement pvPs = pvConn.prepareStatement(
              "SELECT DISTINCT product_id FROM product_variation");
          java.sql.ResultSet pvRs = pvPs.executeQuery();
          while (pvRs.next()) productsWithVariations.add(pvRs.getInt("product_id"));
          pvRs.close(); pvPs.close();

          // Fallback: load first variation image for products with no image
          for (java.util.Map<String, Object> p : products) {
              p.put("hasVariations", productsWithVariations.contains((Integer) p.get("id")));
              String pImg = (String) p.get("image");
              if ((pImg == null || pImg.isEmpty()) && productsWithVariations.contains((Integer) p.get("id"))) {
                  java.sql.PreparedStatement varImgPs = pvConn.prepareStatement(
                		  "SELECT image FROM product_variation WHERE product_id=? AND image IS NOT NULL ORDER BY price ASC LIMIT 1");
                  varImgPs.setInt(1, (Integer) p.get("id"));
                  java.sql.ResultSet varImgRs = varImgPs.executeQuery();
                  if (varImgRs.next()) p.put("image", varImgRs.getString("image"));
                  varImgRs.close(); varImgPs.close();
              }
          }
          pvConn.close();
      }
      
    } catch (Exception ex) {
        ex.printStackTrace();
    }

    // Get cart count
    int cartCount = 0;
    try {
        String sessionRole = (String) session.getAttribute("userRole");
        Integer sessionUserId = (Integer) session.getAttribute("userId");
        if (sessionUserId != null && ("customer".equals(sessionRole) || "both".equals(sessionRole))) {
            java.sql.Connection cartConn = com.shopeasy.DBConnection.getConnection();
            java.sql.PreparedStatement cartPs = cartConn.prepareStatement(
                    "SELECT SUM(ci.quantity) FROM cart c JOIN cartitem ci ON c.cart_id = ci.cart_id WHERE c.customer_id = ? AND ci.quantity > 0");
            Integer cartCustId = (Integer) session.getAttribute("customerId");
            if (cartCustId == null) {
                try {
                    java.sql.Connection cidConn2 = com.shopeasy.DBConnection.getConnection();
                    java.sql.PreparedStatement cidPs2 = cidConn2.prepareStatement(
                        "SELECT customer_id FROM customer WHERE user_id=?");
                    cidPs2.setInt(1, sessionUserId);
                    java.sql.ResultSet cidRs2 = cidPs2.executeQuery();
                    if (cidRs2.next()) cartCustId = cidRs2.getInt("customer_id");
                    cidRs2.close(); cidPs2.close(); cidConn2.close();
                } catch (Exception ignored) {}
            }
            if (cartCustId == null) cartCustId = sessionUserId;
            cartPs.setInt(1, cartCustId);
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
<nav class="navbar navbar-light bg-white shadow-sm py-2 sticky-top">
    <div class="container-fluid px-4">

        <!-- Logo -->
        <a class="navbar-brand fw-bold text-primary" href="index.jsp">
            <i class="bi bi-bag-heart-fill"></i> ShopEasy
        </a>

        <!-- Desktop Search Bar -->
       <form id="desktopSearch" class="d-none d-md-flex mx-3 flex-grow-1" action="index.jsp" method="get">
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
            String loggedEmail = (String) session.getAttribute("userEmail");
            if (loggedUser != null) {
        %>
            <!-- Cart (customer only) -->
     <% if ("customer".equals(loggedRole) || "both".equals(loggedRole)) { %>
        <a href="CartServlet" class="btn btn-outline-secondary position-relative">
    <i class="bi bi-cart3 fs-5"></i>
    <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" id="cartBadge" style="font-size:9px;"><%= cartCount > 0 ? cartCount : "0" %></span>
</a>
            <% } %>

            <!-- Profile Dropdown -->
            <div class="dropdown">
                <button class="btn btn-light border d-flex align-items-center gap-2 px-2 py-1 rounded-pill"
                        type="button" data-bs-toggle="dropdown" aria-expanded="false" style="font-size:13px;">
                    <%
                        String navAvatar2 = "seller".equals(loggedRole) ?
                            (String) session.getAttribute("userProfilePicture") :
                            (String) session.getAttribute("userAvatar");
                    %>
                    <% if (navAvatar2 != null && !navAvatar2.isEmpty()) { %>
                        <img src="<%= navAvatar2 %>" style="width:28px; height:28px; border-radius:50%; object-fit:cover;">
                    <% } else { %>
                        <div style="width:28px; height:28px; border-radius:50%; background:#0d6efd; color:white; font-size:12px; font-weight:700; display:flex; align-items:center; justify-content:center;">
                            <%= loggedUser.substring(0, 1).toUpperCase() %>
                        </div>
                    <% } %>
                    <%
                        String displayName = loggedUser;
                        String bizName = (String) session.getAttribute("userBusinessName");
                        if ("seller".equals(loggedRole) && bizName != null && !bizName.isEmpty()) {
                            displayName = bizName;
                        }
                    %>
                    <span class="d-none d-sm-inline fw-semibold"><%= displayName.split(" ")[0] %></span>
                    <i class="bi bi-chevron-down" style="font-size:10px;"></i>
                </button>
                <ul class="dropdown-menu dropdown-menu-end shadow border-0" style="min-width:200px; border-radius:12px; margin-top:6px;">
                   <li class="px-3 py-2 border-bottom">
                        <div class="d-flex align-items-center gap-2">
                            <%
                            String idxAvatar = (String) session.getAttribute("userAvatar");
                            if (idxAvatar == null || idxAvatar.isEmpty())
                                idxAvatar = (String) session.getAttribute("userProfilePicture");
                            String idxInitial = (displayName != null && !displayName.isEmpty()) ? String.valueOf(displayName.charAt(0)).toUpperCase() : "?";
                            %>
                            <% if (idxAvatar != null && !idxAvatar.isEmpty()) { %>
                                <img src="<%= idxAvatar %>" style="width:38px; height:38px; border-radius:50%; object-fit:cover; flex-shrink:0;">
                            <% } else { %>
                                <div style="width:38px; height:38px; border-radius:50%; background:#0d6efd; color:white; font-size:14px; font-weight:700; display:flex; align-items:center; justify-content:center; flex-shrink:0;"><%= idxInitial %></div>
                            <% } %>
                            <div>
                                <p class="mb-0 fw-bold" style="font-size:13px;"><%= displayName %></p>
                                <p class="mb-0 text-muted" style="font-size:11px;"><%= loggedEmail != null ? loggedEmail : "" %></p>
                            </div>
                        </div>
                    </li>
                    <% if ("customer".equals(loggedRole) || "both".equals(loggedRole)) { %>
                    <li><a class="dropdown-item py-2" href="customer.jsp" style="font-size:13px;"><i class="bi bi-person me-2 text-primary"></i>My Profile</a></li>
                    <li><a class="dropdown-item py-2" href="customer.jsp?tab=orders" style="font-size:13px;"><i class="bi bi-bag me-2 text-primary"></i>My Orders</a></li>
                    <% } %>
                    <% if ("seller".equals(loggedRole)) { %>
                    <li><a class="dropdown-item py-2" href="seller.jsp" style="font-size:13px;"><i class="bi bi-shop me-2 text-warning"></i>Seller Dashboard</a></li>
                    <% } %>
                    <% if ("both".equals(loggedRole) || "seller".equals(loggedRole)) { %>
                    <li><hr class="dropdown-divider my-1"></li>
                    <li>
                       <a class="dropdown-item py-2 text-success fw-semibold" href="#" onclick="goToSellerCenter()" style="font-size:13px;">
                            <i class="bi bi-shop me-2"></i>Seller Center
                        </a>
                    </li>
                    <% } else if ("customer".equals(loggedRole)) { %>
                    <li><hr class="dropdown-divider my-1"></li>
                    <li>
                       <a class="dropdown-item py-2 text-success fw-semibold" href="#" onclick="goToBecomeSeller()" style="font-size:13px;">
    <i class="bi bi-shop-window me-2"></i>Become a Seller
                        </a>
                    </li>
                    <% } %>
                    <li><hr class="dropdown-divider my-1"></li>
                    <li>
                        <a class="dropdown-item py-2 text-danger" href="#" onclick="doLogout()" style="font-size:13px;">
                            <i class="bi bi-box-arrow-right me-2"></i>Logout
                        </a>
                    </li>
                </ul>
            </div>

        <% } else { %>
            <!-- Not logged in -->
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
  <form id="mobileSearch" class="container-fluid px-3 d-md-none mt-2" action="index.jsp" method="get">
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
        <button type="button" data-bs-target="#heroCarousel" data-bs-slide-to="3"></button>
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
<!-- SLIDE 4 - BECOME A SELLER -->
        <div class="carousel-item">
            <div style="background:linear-gradient(135deg,#6610f2 0%,#0d6efd 100%); min-height:280px; display:flex; align-items:center; justify-content:center; flex-direction:column; color:white; text-align:center; padding:40px 20px;">
                <div style="font-size:13px; font-weight:600; letter-spacing:3px; opacity:0.85; margin-bottom:8px;">🏪 START YOUR BUSINESS</div>
                <div style="font-size:52px; font-weight:900; line-height:1; text-shadow:0 2px 8px rgba(0,0,0,0.2);">SELL HERE</div>
                <div style="font-size:22px; font-weight:700; margin:8px 0; opacity:0.95;">Turn Your Products Into Profit!</div>
<% if ("seller".equals(loggedRole) || "both".equals(loggedRole)) { %>
<button onclick="showAlreadySellerModal()" class="btn btn-warning btn-lg fw-bold mt-3 px-5" style="border-radius:30px;">
    <i class="bi bi-shop-window"></i> Become a Seller →
</button>
<% } else if (loggedUser != null) { %>
<button onclick="goToBecomeSeller()" class="btn btn-warning btn-lg fw-bold mt-3 px-5" style="border-radius:30px;">
    <i class="bi bi-shop-window"></i> Become a Seller →
</button>
<% } else { %>
<button onclick="showSellerLoginPrompt()" class="btn btn-warning btn-lg fw-bold mt-3 px-5" style="border-radius:30px;">
    <i class="bi bi-shop-window"></i> Become a Seller →
</button>
<% } %>
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
       <% if (prod.get("image") != null && !prod.get("image").toString().isEmpty()) { %>
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
               <%
    Integer sessionUid = (Integer) session.getAttribute("userId");
    boolean isOwn = sessionUid != null && prod.get("sellerUserId") != null 
                    && sessionUid.equals(prod.get("sellerUserId"));
%>
<% if (isOwn) { %>
    <button class="btn btn-secondary btn-sm w-100" disabled style="cursor:not-allowed; opacity:0.7;">
        <i class="bi bi-slash-circle"></i> Your Product
    </button>
<% } else if (loggedUser != null && ("customer".equals(loggedRole) || "both".equals(loggedRole))) { %>
   <%
    Object spv = prod.get("hasVariations");
    boolean hasVar = spv != null && (boolean) spv;
%>
<button type="button" class="btn btn-primary btn-sm w-100" onclick="addToCart(<%= prod.get("id") %>, <%= hasVar %>)">
    <i class="bi bi-cart-plus"></i> <%= hasVar ? "Select Options" : "Add to Cart" %>
</button>
<% } else { 
    Object spv2 = prod.get("hasVariations");
    boolean hasVar2 = spv2 != null && (boolean) spv2;
%>
    <button class="btn btn-primary btn-sm w-100" data-bs-toggle="modal" data-bs-target="#loginModal">
        <i class="bi bi-cart-plus"></i> <%= hasVar2 ? "Select Options" : "Add to Cart" %>
    </button>
<% } %>       </div>
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

//Auto-show seller blocked modal
(function() {
    const params = new URLSearchParams(window.location.search);
    if (params.get('sellerBlocked') === 'age') {
        var el = document.getElementById('sellerBlockedModal');
        if (el) new bootstrap.Modal(el).show();
    }
})();


</script>

<script>
    


function doLogout() {
    new bootstrap.Modal(document.getElementById('logoutConfirmModal')).show();
}

function confirmLogout() {
    bootstrap.Modal.getInstance(document.getElementById('logoutConfirmModal')).hide();
    document.getElementById('logoutOverlay').style.display = 'flex';
    setTimeout(() => { window.location.href = 'LogoutServlet'; }, 1500);
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
        const regErr = document.getElementById('regValidationError');
        if (password !== confirm) {
            e.preventDefault();
            regErr.textContent = 'Passwords do not match!';
            regErr.style.display = 'block';
            return false;
        }
        if (password.length < 6) {
            e.preventDefault();
            regErr.textContent = 'Password must be at least 6 characters!';
            regErr.style.display = 'block';
            return false;
        }
        regErr.style.display = 'none';
        e.preventDefault();
        var modal = bootstrap.Modal.getInstance(document.getElementById('registerModal'));
        if (modal) modal.hide();
        document.getElementById('registerLoadingOverlay').style.display = 'flex';
        setTimeout(() => {
            document.getElementById('registerForm').submit();
        }, 2500);
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
    function addToCart(productId, hasVariations) {
        if (hasVariations) {
            window.location.href = 'product.jsp?id=' + productId;
            return;
        }
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
                showCenterToast(data.message || 'Failed to add item to cart.');
            }
        })
        .catch(() => showCenterToast('Failed to add item to cart. Please try again.'));
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
   

<!-- Seller Welcome Toast -->
<div id="sellerWelcomeToast" style="display:none; position:fixed; bottom:30px; left:50%; transform:translateX(-50%); z-index:9999;
     background:#fff; border-radius:16px; box-shadow:0 8px 32px rgba(0,0,0,0.15); padding:20px 28px;
     display:none; align-items:center; gap:16px; min-width:340px; border-left:5px solid #198754;">
    <div style="width:48px; height:48px; border-radius:50%; background:#d1f2e1; display:flex; align-items:center; justify-content:center; flex-shrink:0;">
        <i class="bi bi-shop-window" style="font-size:22px; color:#198754;"></i>
    </div>
    <div style="flex:1;">
        <p style="margin:0; font-weight:700; font-size:14px; color:#198754;">🎉 You're now a seller!</p>
        <p style="margin:4px 0 0; font-size:12px; color:#555;">Go to your profile → dropdown → <strong>Seller Center</strong> to start selling.</p>
    </div>
    <button onclick="document.getElementById('sellerWelcomeToast').style.display='none'"
            style="background:none; border:none; font-size:18px; color:#aaa; cursor:pointer; flex-shrink:0;">✕</button>
</div>

<script>
// Show seller welcome toast if redirected from seller application
(function() {
    const params = new URLSearchParams(window.location.search);
    if (params.get('sellerWelcome') === 'true') {
        const toast = document.getElementById('sellerWelcomeToast');
        toast.style.display = 'flex';
        // Auto hide after 8 seconds
        setTimeout(function() {
            toast.style.display = 'none';
        }, 8000);
        // Clean URL
        window.history.replaceState({}, '', 'index.jsp');
    }
})();
</script>


<!-- Seller Center Loading Overlay -->
<div id="sellerCenterOverlay" style="display:none; position:fixed; inset:0; background:rgba(255,255,255,0.95);
     z-index:9999; flex-direction:column; align-items:center; justify-content:center; gap:16px;">
    <div style="width:56px; height:56px; border:5px solid #e9ecef; border-top-color:#198754;
         border-radius:50%; animation:scSpin 0.8s linear infinite;"></div>
    <p style="font-size:16px; font-weight:600; color:#198754; margin:0;">
        <i class="bi bi-shop me-2"></i>Opening Seller Center…
    </p>
    <small style="color:#888; font-size:13px;">Please wait…</small>
</div>
<style>
@keyframes scSpin { to { transform: rotate(360deg); } }
</style>
<script>
function goToSellerCenter() {
    document.getElementById('sellerCenterOverlay').style.display = 'flex';
    setTimeout(function() {
        window.location.href = 'seller.jsp';
    }, 1500);
}

function goToBecomeSeller() {
	const birthday = '<%= session.getAttribute("userBirthday") != null ? session.getAttribute("userBirthday") : "" %>';
    if (!birthday || birthday.trim() === '') {
        new bootstrap.Modal(document.getElementById('sellerBlockedModal')).show();
        return;
    }
    const birthDate = new Date(birthday);
    const today = new Date();
    let age = today.getFullYear() - birthDate.getFullYear();
    const m = today.getMonth() - birthDate.getMonth();
    if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) age--;
    if (age < 18) {
        new bootstrap.Modal(document.getElementById('sellerBlockedModal')).show();
        return;
    }
    document.getElementById('sellerCenterOverlay').style.display = 'flex';
    document.querySelector('#sellerCenterOverlay p').innerHTML = '<i class="bi bi-shop-window me-2"></i>Opening Seller Application...';
    setTimeout(function() {
        window.location.href = 'seller-apply.jsp';
    }, 1500);
}
function showSellerLoginPrompt() {
    new bootstrap.Modal(document.getElementById('sellerLoginPromptModal')).show();
}
function showAlreadySellerModal() {
    new bootstrap.Modal(document.getElementById('alreadySellerModal')).show();
}
</script>
<!-- SELLER LOGIN PROMPT MODAL -->
<div class="modal fade" id="sellerLoginPromptModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-body text-center p-5">
                <div style="width:70px; height:70px; background:linear-gradient(135deg,#6610f2,#0d6efd); border-radius:50%; display:flex; align-items:center; justify-content:center; margin:0 auto 20px;">
                    <i class="bi bi-shop-window" style="font-size:30px; color:white;"></i>
                </div>
                <h5 class="fw-bold mb-2">Become a Seller</h5>
                <p class="text-muted mb-1" style="font-size:14px;">You need to <strong>log in</strong> first and must be <strong>18 years or older</strong> to become a seller.</p>
                <div class="d-flex gap-2 justify-content-center mt-4">
                    <button class="btn btn-outline-secondary" data-bs-dismiss="modal">Maybe Later</button>
                    <button class="btn btn-primary px-4" onclick="bootstrap.Modal.getInstance(document.getElementById('sellerLoginPromptModal')).hide(); setTimeout(()=>new bootstrap.Modal(document.getElementById('loginModal')).show(),300)">
                        <i class="bi bi-person me-1"></i> Login Now
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- ALREADY SELLER MODAL -->
<div class="modal fade" id="alreadySellerModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-body text-center p-5">
                <div style="width:70px; height:70px; background:linear-gradient(135deg,#198754,#20c997); border-radius:50%; display:flex; align-items:center; justify-content:center; margin:0 auto 20px;">
                    <i class="bi bi-patch-check-fill" style="font-size:30px; color:white;"></i>
                </div>
                <h5 class="fw-bold mb-2">You're Already a Seller! 🎉</h5>
                <p class="text-muted mb-1" style="font-size:14px;">You already have an active seller account. Go to your <strong>Seller Center</strong> to manage your shop.</p>
                <div class="d-flex gap-2 justify-content-center mt-4">
                    <button class="btn btn-outline-secondary" data-bs-dismiss="modal">Close</button>
                    <button class="btn btn-success px-4" onclick="bootstrap.Modal.getInstance(document.getElementById('alreadySellerModal')).hide(); goToSellerCenter()">
                        <i class="bi bi-shop me-1"></i> Go to Seller Center
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>


<!-- LOGOUT CONFIRM MODAL -->
<div class="modal fade" id="logoutConfirmModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-body text-center p-5">
                <div style="width:70px; height:70px; background:linear-gradient(135deg,#dc3545,#c0392b); border-radius:50%; display:flex; align-items:center; justify-content:center; margin:0 auto 20px;">
                    <i class="bi bi-box-arrow-right" style="font-size:30px; color:white;"></i>
                </div>
                <h5 class="fw-bold mb-2">Log Out?</h5>
                <p class="text-muted mb-1" style="font-size:14px;">Are you sure you want to logout?</p>
                <div class="d-flex gap-2 justify-content-center mt-4">
                    <button class="btn btn-outline-secondary px-4" data-bs-dismiss="modal">Cancel</button>
                    <button class="btn btn-danger px-4" onclick="confirmLogout()">
                        <i class="bi bi-box-arrow-right me-1"></i> Logout
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>
</body>
</html>