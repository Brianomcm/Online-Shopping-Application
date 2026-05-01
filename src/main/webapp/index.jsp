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
            prod.put("description", prodRs.getString("description"));
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

<!-- TOP BAR -- >
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
<nav class="navbar navbar-light bg-white shadow-sm py-3">
    <div class="container-fluid px-4">
        
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
                <p class="card-text text-danger fw-bold mb-0">₱<%= String.format("%.2f", prod.get("price")) %></p>
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
</div>

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
    
    </script>
    
    
    
    
    




<%
    String isLoggedInFlag = (loggedUser != null && "customer".equals(loggedRole)) ? "true" : "false";
%>
<input type="hidden" id="isLoggedInFlag" value="<%= isLoggedInFlag %>">
</body>
</html>