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

<!-- TOAST -->
<div id="cartToast" class="toast-msg">
    <i class="bi bi-cart-check-fill me-2"></i> Item added to cart! 🛒
</div>

<!-- NAVBAR -->
<nav class="navbar navbar-light bg-white shadow-sm py-2">
    <div class="container-fluid px-3">
        <a class="navbar-brand fw-bold text-primary" href="index.jsp">
            <i class="bi bi-bag-heart-fill"></i> ShopEasy
        </a>
        <div class="d-flex align-items-center gap-3">
            <a href="index.jsp" class="btn btn-outline-primary btn-sm">
                <i class="bi bi-arrow-left"></i> Back to Shop
            </a>
            <% if (loggedUser != null && "customer".equals(loggedRole)) { %>
            <a href="CartServlet" class="btn btn-outline-secondary btn-sm position-relative">
                <i class="bi bi-cart3"></i>
                <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" style="font-size:9px;"><%= cartCount > 0 ? cartCount : "0" %></span>
            </a>
            <% } %>
            <div class="avatar-circle">
                <% if (userAvatar != null && !userAvatar.isEmpty()) { %>
                    <img src="<%= userAvatar %>" style="width:100%;height:100%;object-fit:cover;">
                <% } else if (loggedUser != null) { %>
                    <%= loggedUser.substring(0, 1).toUpperCase() %>
                <% } else { %>
                    <i class="bi bi-person"></i>
                <% } %>
            </div>
        </div>
    </div>
</nav>

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

                <!-- ADD TO CART -->
                <div class="mt-4">
                    <% if (loggedUser != null && "customer".equals(loggedRole)) { %>
                        <% if (stock > 0) { %>
                            <button class="btn btn-primary add-cart-btn w-100 text-white" onclick="addToCart(<%= productId %>)">
                                <i class="bi bi-cart-plus"></i> Add to Cart
                            </button>
                        <% } else { %>
                            <button class="btn btn-secondary w-100" disabled>
                                <i class="bi bi-x-circle"></i> Out of Stock
                            </button>
                        <% } %>
                    <% } else { %>
                        <a href="index.jsp" class="btn btn-primary add-cart-btn w-100 text-white">
                            <i class="bi bi-box-arrow-in-right"></i> Login to Add to Cart
                        </a>
                    <% } %>
                </div>
            </div>
        </div>
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
            const badge = document.querySelector('.badge.bg-danger');
            if (badge) badge.textContent = parseInt(badge.textContent || 0) + 1;
        }
    })
    .catch(err => console.error(err));
}
</script>
</body>
</html>