<%@ page session="true" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    java.util.List<java.util.Map<String, Object>> products = new java.util.ArrayList<>();
    try {
        java.sql.Connection prodConn = com.shopeasy.DBConnection.getConnection();
        java.sql.PreparedStatement prodPs = prodConn.prepareStatement(
            "SELECT p.*, s.business_name FROM product p JOIN seller s ON p.seller_id = s.seller_id WHERE p.status='active' ORDER BY p.product_id DESC LIMIT 8");
        java.sql.ResultSet prodRs = prodPs.executeQuery();
        while (prodRs.next()) {
            java.util.Map<String, Object> prod = new java.util.HashMap<>();
            prod.put("id", prodRs.getInt("product_id"));
            prod.put("name", prodRs.getString("name"));
            prod.put("price", prodRs.getDouble("price"));
            prod.put("image", prodRs.getString("image"));
            prod.put("stock", prodRs.getInt("stock"));
            prod.put("seller", prodRs.getString("business_name"));
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
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ShopEasy - Home</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css">
    <style>
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
    </style>
</head>
<body>

<!-- TOP BAR -->
<div class="top-bar text-white py-1 text-center">
    🎉 Free shipping on orders over ₱500! Limited time only!
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
<nav class="navbar navbar-light bg-white shadow-sm py-2">
    <div class="container-fluid px-3">
        
        <!-- Logo -->
        <a class="navbar-brand fw-bold text-primary" href="index.jsp">
            <i class="bi bi-bag-heart-fill"></i> ShopEasy
        </a>

        <!-- Desktop Search Bar -->
        <div class="d-none d-md-flex mx-3 flex-grow-1">
            <div class="input-group">
                <input type="text" class="form-control" placeholder="Search products...">
                <button class="btn btn-primary px-3">
                    <i class="bi bi-search"></i>
                </button>
            </div>
        </div>

        <!-- Nav Buttons -->
        <div class="d-flex gap-2 align-items-center">
        <%
            String loggedUser = (String) session.getAttribute("userName");
            String loggedRole = (String) session.getAttribute("userRole");
            if (loggedUser != null) {
        %>
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
                    <li><a class="dropdown-item" href="#"><i class="bi bi-bag me-2"></i> My Orders</a></li>
                    <% } else if ("seller".equals(loggedRole)) { %>
                    <li><a class="dropdown-item" href="seller.jsp"><i class="bi bi-shop me-2"></i> Seller Dashboard</a></li>
                    <% } %>
                    <li><hr class="dropdown-divider"></li>
                    <li><a class="dropdown-item text-danger" href="#" onclick="doLogout()"><i class="bi bi-box-arrow-right me-2"></i> Logout</a></li>
                </ul>
            </div>
        <% } else { %>
            <a href="#" class="btn btn-outline-primary btn-sm" data-bs-toggle="modal" data-bs-target="#loginModal">
                <i class="bi bi-person"></i>
                <span class="d-none d-md-inline"> Login</span>
            </a>
            <a href="#" class="btn btn-primary btn-sm" data-bs-toggle="modal" data-bs-target="#registerModal">
                <i class="bi bi-person-plus"></i>
                <span class="d-none d-md-inline"> Register</span>
            </a>
        <% } %>
            <% if (loggedUser == null) { %>
                <a href="#" class="btn btn-outline-secondary btn-sm position-relative" data-bs-toggle="modal" data-bs-target="#loginModal">
            <% } else { %>
                <a href="CartServlet" class="btn btn-outline-secondary btn-sm position-relative">
            <% } %>
                <i class="bi bi-cart3"></i>
               <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" style="font-size:9px;"><%= cartCount > 0 ? cartCount : "0" %></span>
            </a>
        </div>
    </div>

    <!-- Mobile Search Bar -->
    <div class="container-fluid px-3 d-md-none mt-2">
        <div class="input-group">
            <input type="text" class="form-control" placeholder="Search products...">
            <button class="btn btn-primary">
                <i class="bi bi-search"></i>
            </button>
        </div>
    </div>
</nav>

<!-- HERO SECTION -->
<div class="hero-section text-white text-center">
    <div class="container">
        <h1 class="fw-bold">Welcome to ShopEasy</h1>
        <p class="lead mb-4">Browse thousands of products at the best prices!</p>
        <a href="#products" class="btn btn-warning btn-lg fw-bold px-5">
            <i class="bi bi-shop"></i> Shop Now
        </a>
    </div>
</div>

<!-- CATEGORIES -->
<div class="container mt-4 mb-2">
    <h5 class="mb-3 fw-bold">Browse by Category</h5>
    <div class="row g-2 text-center">
        <div class="col-4 col-md-2">
            <div class="card category-card py-3 border h-100">
                <i class="bi bi-phone fs-3 text-primary"></i>
                <small class="mt-1 fw-bold">Electronics</small>
            </div>
        </div>
        <div class="col-4 col-md-2">
            <div class="card category-card py-3 border h-100">
                <i class="bi bi-bag fs-3 text-primary"></i>
                <small class="mt-1 fw-bold">Fashion</small>
            </div>
        </div>
        <div class="col-4 col-md-2">
            <div class="card category-card py-3 border h-100">
                <i class="bi bi-house fs-3 text-primary"></i>
                <small class="mt-1 fw-bold">Home</small>
            </div>
        </div>
        <div class="col-4 col-md-2">
            <div class="card category-card py-3 border h-100">
                <i class="bi bi-controller fs-3 text-primary"></i>
                <small class="mt-1 fw-bold">Gaming</small>
            </div>
        </div>
        <div class="col-4 col-md-2">
            <div class="card category-card py-3 border h-100">
                <i class="bi bi-heart-pulse fs-3 text-primary"></i>
                <small class="mt-1 fw-bold">Health</small>
            </div>
        </div>
        <div class="col-4 col-md-2">
            <div class="card category-card py-3 border h-100">
                <i class="bi bi-grid fs-3 text-primary"></i>
                <small class="mt-1 fw-bold">More</small>
            </div>
        </div>
    </div>
</div>

<!-- FEATURED PRODUCTS -->
<div class="container mt-4" id="products">
    <h5 class="mb-3 fw-bold">Featured Products</h5>
    <div class="row g-3">
<% if (products.isEmpty()) { %>
    <div class="col-12 text-center py-5 text-muted">
        <i class="bi bi-box-seam fs-1 opacity-25"></i>
        <p class="mt-2">No products available yet.</p>
    </div>
<% } else { %>
    <% for (java.util.Map<String, Object> prod : products) { %>
        <div class="col-6 col-md-4 col-lg-3">
            <div class="card h-100 product-card">
                <div class="product-wrapper">
                    <% if (prod.get("image") != null) { %>
                        <img src="<%= prod.get("image") %>" class="card-img-top" alt="<%= prod.get("name") %>">
                    <% } else { %>
                        <img src="https://via.placeholder.com/300x200" class="card-img-top" alt="<%= prod.get("name") %>">
                    <% } %>
                </div>
                <div class="card-body d-flex flex-column">
                    <h6 class="card-title"><%= prod.get("name") %></h6>
                    <p class="text-muted mb-1" style="font-size:11px;"><i class="bi bi-shop"></i> <%= prod.get("seller") %></p>
                    <p class="card-text text-danger fw-bold mb-0">₱<%= String.format("%.2f", prod.get("price")) %></p>
                    <p class="text-muted mb-2" style="font-size:11px;">Stock: <%= prod.get("stock") %></p>
                    <div class="mt-auto">
                        <% if (loggedUser != null && "customer".equals(loggedRole)) { %>
    <form action="AddToCartServlet" method="post">
        <input type="hidden" name="productId" value="<%= prod.get("id") %>">
        <button type="submit" class="btn btn-primary btn-sm w-100">
            <i class="bi bi-cart-plus"></i> Add to Cart
        </button>
    </form>
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
    <div class="modal-dialog modal-dialog-centered" style="max-width:420px; margin:auto;">
        <div class="modal-content rounded-4">
            <div class="modal-header border-0 pb-0">
                <h5 class="modal-title fw-bold">
                    <i class="bi bi-bag-heart-fill text-primary"></i> Login to ShopEasy
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body px-4 pb-4">

                <!-- SOCIAL LOGIN -->
                <p class="text-center fw-bold mb-2" style="font-size:13px;">Log in with</p>
                <div class="row g-2 mb-3">
                    <div class="col-6">
                        <button class="btn btn-outline-danger w-100 d-flex align-items-center justify-content-center gap-2" type="button" style="transition:0.3s;" onmouseover="this.style.background='#EA4335'; this.style.color='white';" onmouseout="this.style.background='white'; this.style.color='#EA4335';">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 48 48">
                                <path fill="#EA4335" d="M24 9.5c3.1 0 5.6 1.1 7.6 2.9l5.6-5.6C33.5 3.5 29 1.5 24 1.5 14.9 1.5 7.2 7.2 4.1 15.1l6.6 5.1C12.3 13.7 17.7 9.5 24 9.5z"/>
                                <path fill="#4285F4" d="M46.5 24.5c0-1.6-.1-3.1-.4-4.5H24v8.5h12.7c-.6 3-2.3 5.5-4.8 7.2l7.4 5.7c4.3-4 6.8-9.9 6.8-16.9z"/>
                                <path fill="#FBBC05" d="M10.7 28.8A14.6 14.6 0 0 1 9.5 24c0-1.7.3-3.3.8-4.8L3.7 14c-1.4 2.9-2.2 6.1-2.2 9.5s.8 6.6 2.2 9.5l7-5.2z"/>
                                <path fill="#34A853" d="M24 46.5c5 0 9.2-1.7 12.3-4.5l-7.4-5.7c-1.7 1.1-3.8 1.8-4.9 1.8-6.3 0-11.7-4.2-13.6-10l-6.6 5.1C7.2 40.8 14.9 46.5 24 46.5z"/>
                            </svg>
                            Google
                        </button>
                    </div>
                    <div class="col-6">
                        <button class="btn w-100 d-flex align-items-center justify-content-center gap-2" type="button" style="background:#1877F2; color:white; border:none; transition:0.3s;" onmouseover="this.style.background='#1558b0'" onmouseout="this.style.background='#1877F2'">
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="white" viewBox="0 0 16 16">
        <path d="M16 8.049c0-4.446-3.582-8.05-8-8.05C3.58 0-.002 3.603-.002 8.05c0 4.017 2.926 7.347 6.75 7.951v-5.625h-2.03V8.05H6.75V6.275c0-2.017 1.195-3.131 3.022-3.131.876 0 1.791.157 1.791.157v1.98h-1.009c-.993 0-1.303.621-1.303 1.258v1.51h2.218l-.354 2.326H9.25V16c3.824-.604 6.75-3.934 6.75-7.951z"/>
    </svg>
    Facebook
</button>
                    </div>
                </div>

                <!-- DIVIDER -->
                <div class="d-flex align-items-center mb-3">
                    <hr class="flex-grow-1">
                    <span class="px-2 text-muted" style="font-size:12px;">or login with email</span>
                    <hr class="flex-grow-1">
                </div>

                <!-- LOGIN FORM -->
                <form action="LoginServlet" method="post" autocomplete="off" id="loginForm" onsubmit="return handleLoginSubmit(event, this)">
                    <div class="mb-3">
                        <label class="form-label fw-bold">Email or Username</label>
                        <div class="input-group">
                            <span class="input-group-text bg-light"><i class="bi bi-person"></i></span>
                            <input type="text" name="email" id="loginEmail" class="form-control" placeholder="Enter email or username" required autocomplete="off" onfocus="this.removeAttribute('readonly')" readonly>
                        </div>
                    </div>
                    <div class="mb-2">
                        <label class="form-label fw-bold">Password</label>
                        <div class="input-group">
                            <span class="input-group-text bg-light"><i class="bi bi-lock"></i></span>
                            <input type="password" name="password" id="loginPassword" class="form-control" placeholder="Enter your password" required autocomplete="off">
                            
                            <button class="btn btn-outline-secondary" type="button" onclick="togglePassword('loginPassword', this)">
                                <i class="bi bi-eye"></i>
                            </button>
                        </div>
                    </div>
                    <div class="d-flex justify-content-between mb-3">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" id="rememberMe">
                            <label class="form-check-label" style="font-size:13px;" for="rememberMe">Remember me</label>
                        </div>
                        <a href="#" class="text-primary" style="font-size:13px;">Forgot password?</a>
                    </div>
                    <div id="loginError" class="alert alert-danger py-2 mb-3" style="display:none; font-size:13px;">
                        <i class="bi bi-x-circle-fill"></i> <span id="loginErrorText">Invalid email or password.</span>
                    </div>
                    <button type="submit" class="btn btn-primary w-100 fw-bold py-2">
                        <i class="bi bi-box-arrow-in-right"></i> Login
                    </button>
                </form>

                <p class="text-center mt-3 mb-0" style="font-size:14px;">
                    Don't have an account?
                    <a href="#" class="fw-bold text-primary" data-bs-dismiss="modal" data-bs-toggle="modal" data-bs-target="#registerModal">Register here</a>
                </p>
            </div>
        </div>
    </div>
</div>


<!-- REGISTER MODAL -->
<div class="modal fade" id="registerModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content rounded-4">
            <div class="modal-header border-0 pb-0">
                <h5 class="modal-title fw-bold">
                    <i class="bi bi-bag-heart-fill text-primary"></i> Create a ShopEasy Account
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body px-4 pb-4">

                <!-- LOADING OVERLAY -->
                <div id="loadingOverlay" style="display:none; position:absolute; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.85); z-index:999; border-radius:16px; flex-direction:column; align-items:center; justify-content:center;">
                    <div class="spinner-border text-primary mb-2" role="status" style="width:3rem; height:3rem;">
                        <span class="visually-hidden">Loading...</span>
                    </div>
                    <p class="fw-bold text-primary mb-0" id="loadingText">Loading...</p>
                </div>

                <form action="RegisterServlet" method="post" id="registerForm">
                <!-- ACCOUNT TYPE SELECTOR -->
                <p class="fw-bold mb-2">Select Account Type:</p>
                <div class="row g-2 mb-3">
                    <div class="col-6">
                        <div class="account-type-card border rounded-3 p-3 text-center" id="customerCard" onclick="selectTypeWithMessage('customer', 'Setting up Customer account...')" style="cursor:pointer; border-color:#0d6efd !important; background:#e8f0fe;">
                            <i class="bi bi-person-fill fs-3 text-primary"></i>
                            <p class="mb-0 fw-bold mt-1">Customer</p>
                            <small class="text-muted">I want to shop</small>
                        </div>
                    </div>
                    <div class="col-6">
                        <div class="account-type-card border rounded-3 p-3 text-center" id="sellerCard" onclick="selectTypeWithMessage('seller', 'Setting up Business account...')" style="cursor:pointer;">
                            <i class="bi bi-shop fs-3 text-secondary"></i>
                            <p class="mb-0 fw-bold mt-1">Business / Seller</p>
                            <small class="text-muted">I want to sell</small>
                        </div>
                    </div>
                </div>

                <!-- SHARED FIELDS -->
                <div class="row g-2">
                    <div class="col-md-6">
                        <label class="form-label fw-bold">Full Name</label>
                        <input type="text" name="fullname" class="form-control" placeholder="Enter your full name" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold">Username</label>
                        <input type="text" name="username" class="form-control" placeholder="Choose a username" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold">Email</label>
                        <input type="email" name="email" class="form-control" placeholder="Enter your email" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold">Phone Number</label>
                        <div class="input-group">
                            <span class="input-group-text">+63</span>
                            <input type="tel" name="phone" class="form-control" placeholder="9XX XXX XXXX" required>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold">Password</label>
                        <div class="input-group">
    <input type="password" name="password" id="regPassword" class="form-control" placeholder="Create a password" required>
    <button class="btn btn-outline-secondary" type="button" onclick="togglePassword('regPassword', this)">
        <i class="bi bi-eye"></i>
    </button>
</div>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold">Confirm Password</label>
                        <div class="input-group">
    <input type="password" id="confirmPassword" class="form-control" placeholder="Repeat your password">
    <button class="btn btn-outline-secondary" type="button" onclick="togglePassword('confirmPassword', this)">
        <i class="bi bi-eye"></i>
    </button>
</div>
                    </div>
                </div>

                <!-- SELLER EXTRA FIELDS -->
                <div id="sellerFields" style="display:none;">
                    <hr>
                    <p class="fw-bold mb-2"><i class="bi bi-shop text-primary"></i> Business Information</p>
                    <div class="row g-2">
                        <div class="col-md-6">
                            <label class="form-label fw-bold">Business Name</label>
                            <input type="text" name="businessName" class="form-control" placeholder="Enter your business name">
                        </div>
                        <div class="col-md-6">
                            <label class="form-label fw-bold">Business Type</label>
                            <select name="businessType" class="form-select">
                                <option value="">Select type</option>
                                <option>Retail</option>
                                <option>Wholesale</option>
                                <option>Food & Beverage</option>
                                <option>Fashion & Apparel</option>
                                <option>Electronics</option>
                                <option>Others</option>
                            </select>
                        </div>
                        <div class="col-12">
                            <label class="form-label fw-bold">Business Address</label>
                            <input type="text" name="businessAddress" class="form-control" placeholder="Enter your business address">
                        </div>
                    </div>
                </div>

                <div class="mt-3">
                    <div class="form-check mb-3">
                        <input class="form-check-input" type="checkbox" id="agreeTerms" required>
                        <label class="form-check-label" for="agreeTerms" style="font-size:13px;">
                            I agree to the <a href="#" class="text-primary">Terms and Conditions</a> and <a href="#" class="text-primary">Privacy Policy</a>
                        </label>
                    </div>
                    <input type="hidden" name="accountType" id="accountTypeInput" value="customer">
                    <button type="submit" class="btn btn-primary w-100 fw-bold py-2">
                        <i class="bi bi-person-check"></i> Create Account
                    </button>
                </div>
                </form>

                <hr>
                <p class="text-center fw-bold mb-2" style="font-size:13px;">Or sign up with</p>
                <div class="row g-2">
                    <div class="col-6">
                        <button class="btn btn-outline-danger w-100" type="button">
                            <i class="bi bi-google"></i> Google
                        </button>
                    </div>
                    <div class="col-6">
                        <button class="btn w-100 d-flex align-items-center justify-content-center gap-2" type="button" style="background:#1877F2; color:white; border:none; transition:0.3s;" onmouseover="this.style.background='#1558b0'" onmouseout="this.style.background='#1877F2'">
                            <i class="bi bi-facebook"></i> Facebook
                        </button>
                    </div>
                </div>

                <p class="text-center mt-3 mb-0" style="font-size:14px;">
                    Already have an account? 
                    <a href="#" class="fw-bold text-primary" data-bs-dismiss="modal" data-bs-toggle="modal" data-bs-target="#loginModal">Login here</a>
                </p>
            </div>
        </div>
    </div>
</div>

<!-- FOOTER -->
<footer class="bg-dark text-white mt-5 py-4">
    <div class="container">
        <div class="row text-center text-md-start">
            <div class="col-md-4 mb-3">
                <h6 class="fw-bold"><i class="bi bi-bag-heart-fill"></i> ShopEasy</h6>
                <p style="font-size:13px;" class="text-muted">Your one stop shop for everything you need.</p>
            </div>
            <div class="col-md-4 mb-3">
                <h6 class="fw-bold">Quick Links</h6>
                <ul class="list-unstyled" style="font-size:13px;">
                    <li><a href="#">Home</a></li>
                    <li><a href="#">Products</a></li>
                    <li><a href="#">Register</a></li>
                </ul>
            </div>
            <div class="col-md-4 mb-3">
                <h6 class="fw-bold">Contact Us</h6>
                <p style="font-size:13px;" class="text-muted mb-1"><i class="bi bi-envelope"></i> support@shopeasy.com</p>
                <p style="font-size:13px;" class="text-muted"><i class="bi bi-telephone"></i> +63 912 345 6789</p>
            </div>
        </div>
        <hr class="border-secondary">
        <p class="text-center text-muted mb-0" style="font-size:12px;">2026 ShopEasy. All rights reserved.</p>
    </div>
</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

<script>
    function togglePassword(fieldId, btn) {
        const field = document.getElementById(fieldId);
        const icon = btn.querySelector('i');
        if (field.type === 'password') {
            field.type = 'text';
            icon.className = 'bi bi-eye-slash';
        } else {
            field.type = 'password';
            icon.className = 'bi bi-eye';
        }
    }

    function selectTypeWithMessage(type, message) {
        const customerCard = document.getElementById('customerCard');
        const sellerCard = document.getElementById('sellerCard');
        const sellerFields = document.getElementById('sellerFields');
        const overlay = document.getElementById('loadingOverlay');
        const loadingText = document.getElementById('loadingText');

        loadingText.textContent = message;
        overlay.style.display = 'flex';

        setTimeout(() => {
            if (type === 'customer') {
                customerCard.style.background = '#e8f0fe';
                customerCard.style.borderColor = '#0d6efd';
                customerCard.querySelector('i').className = 'bi bi-person-fill fs-3 text-primary';
                sellerCard.style.background = 'white';
                sellerCard.style.borderColor = '#dee2e6';
                sellerCard.querySelector('i').className = 'bi bi-shop fs-3 text-secondary';
                sellerFields.style.display = 'none';
                document.getElementById('accountTypeInput').value = 'customer';
            } else {
                sellerCard.style.background = '#e8f0fe';
                sellerCard.style.borderColor = '#0d6efd';
                sellerCard.querySelector('i').className = 'bi bi-shop fs-3 text-primary';
                customerCard.style.background = 'white';
                customerCard.style.borderColor = '#dee2e6';
                customerCard.querySelector('i').className = 'bi bi-person-fill fs-3 text-secondary';
                sellerFields.style.display = 'block';
                document.getElementById('accountTypeInput').value = 'seller';
            }
            overlay.style.display = 'none';
        }, 800);
    }

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
</script>
<!-- LOGIN LOADING OVERLAY -->
<div id="loginLoadingOverlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.95); z-index:9999; flex-direction:column; align-items:center; justify-content:center;">
    <div class="spinner-border text-primary mb-3" style="width:3.5rem; height:3.5rem;" role="status"></div>
    <p class="fw-bold text-primary fs-5">Logging in...</p>
    <p class="text-muted" style="font-size:13px;">Please wait a moment</p>
</div>

<!-- REGISTER LOADING OVERLAY -->
<div id="registerLoadingOverlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.95); z-index:9999; flex-direction:column; align-items:center; justify-content:center;">
    <div class="spinner-border text-primary mb-3" style="width:3.5rem; height:3.5rem;" role="status"></div>
    <p class="fw-bold text-primary fs-5">Creating Account...</p>
    <p class="text-muted" style="font-size:13px;">Please wait a moment</p>
</div>

<div id="centerToast" style="display:none; position:fixed; top:50%; left:50%; transform:translate(-50%,-50%); background:#0d6efd; color:white; padding:20px 40px; border-radius:16px; font-size:16px; font-weight:600; z-index:9999; box-shadow:0 8px 30px rgba(0,0,0,0.3); text-align:center; align-items:center; gap:10px;">
    <i class="bi bi-check-circle-fill" style="font-size:20px;"></i>
    <span id="centerToastMsg"></span>
</div>

<!-- LOGOUT OVERLAY -->
<div id="logoutOverlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.9); z-index:9999; flex-direction:column; align-items:center; justify-content:center;">
    <div class="spinner-border text-primary mb-3" style="width:3rem; height:3rem;" role="status"></div>
    <p class="fw-bold text-primary fs-5">Logging out...</p>
</div>

</body>
</html>