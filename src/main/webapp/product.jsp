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
    String name = "", loggedUser = "", description = "", image = "", sellerName = "", sellerPfp = "";
    StringBuilder galleryJson = new StringBuilder("[]");
    double price = 0, originalPrice = 0;
    int stock = 0, sellerId = 0;
    double storeAvg = 0;
    int storeRevs = 0;
    double topAvgRating = 0;
    int topTotalReviews = 0;
    int totalSold = 0;

    try {
        Connection conn = com.shopeasy.DBConnection.getConnection();
        PreparedStatement ps = conn.prepareStatement(
        	    "SELECT p.*, s.business_name, s.seller_id, COALESCE(s.profile_picture, s.shop_logo) as profile_picture, " +
        	    "COALESCE((SELECT AVG(r.rating) FROM review r WHERE r.product_id = p.product_id), 0) AS avg_rating, " +
        	    "COALESCE((SELECT COUNT(r.review_id) FROM review r WHERE r.product_id = p.product_id), 0) AS review_count, " +
        	    "COALESCE((SELECT SUM(oi.quantity) FROM order_items oi JOIN orders o ON oi.order_id = o.order_id WHERE oi.product_id = p.product_id AND o.status='Completed'), 0) AS total_sold " +
        	    "FROM product p JOIN seller s ON p.seller_id = s.seller_id " +
        	    "WHERE p.product_id = ?");
        ps.setInt(1, productId);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
        	
        	
            name = rs.getString("name");
            description = rs.getString("description");
         // Prefer thumbnail > gallery image > variation image
            String thumbnail = rs.getString("thumbnail");
            image = rs.getString("image");
            if (thumbnail != null && !thumbnail.isEmpty()) image = thumbnail;
         // If no image at all, use first variation image
         if (image == null || image.isEmpty()) {
             try {
                 java.sql.Connection imgFallConn = com.shopeasy.DBConnection.getConnection();
                 java.sql.PreparedStatement imgFallPs = imgFallConn.prepareStatement(
                		 "SELECT image FROM product_variation WHERE product_id=? AND image IS NOT NULL ORDER BY price ASC LIMIT 1");
                 imgFallPs.setInt(1, productId);
                 java.sql.ResultSet imgFallRs = imgFallPs.executeQuery();
                 if (imgFallRs.next()) image = imgFallRs.getString("image");
                 imgFallRs.close(); imgFallPs.close(); imgFallConn.close();
             } catch (Exception ignored) {}
         }
            price = rs.getDouble("price");
            originalPrice = rs.getDouble("original_price");
            stock = rs.getInt("stock");
            topAvgRating = rs.getDouble("avg_rating");
            topTotalReviews = rs.getInt("review_count");
            totalSold = rs.getInt("total_sold");
         // If stock is 0 but has variations, get total stock from variations
         if (stock == 0) {
             try {
                 java.sql.Connection stockConn = com.shopeasy.DBConnection.getConnection();
                 java.sql.PreparedStatement stockPs = stockConn.prepareStatement(
                     "SELECT COALESCE(SUM(stock), 0) FROM product_variation WHERE product_id = ?");
                 stockPs.setInt(1, productId);
                 java.sql.ResultSet stockRs = stockPs.executeQuery();
                 if (stockRs.next()) stock = stockRs.getInt(1);
                 stockRs.close(); stockPs.close(); stockConn.close();
             } catch (Exception ignored) {}
         }
            sellerName = rs.getString("business_name");
            sellerId = rs.getInt("seller_id");
            sellerPfp = rs.getString("profile_picture");
        } else {
            response.sendRedirect("index.jsp");
            return;
        }
        rs.close(); ps.close();

     // Get store average rating
     PreparedStatement storeRatPs = conn.prepareStatement(
    "SELECT COALESCE(AVG(r.rating), 0) AS store_avg, COUNT(r.review_id) AS store_revs " +
    "FROM review r JOIN product p ON r.product_id = p.product_id " +
    "WHERE p.seller_id = ?");
storeRatPs.setInt(1, sellerId);
ResultSet storeRatRs = storeRatPs.executeQuery();
if (storeRatRs.next()) {
    storeAvg = storeRatRs.getDouble("store_avg");
    storeRevs = storeRatRs.getInt("store_revs");
}
storeRatRs.close(); storeRatPs.close(); conn.close();
//Load gallery images OUTSIDE the rs.next() block
java.util.List<String> galleryImageList = new java.util.ArrayList<>();
galleryJson = new StringBuilder("[");
try {
    java.sql.Connection galConn = com.shopeasy.DBConnection.getConnection();
    java.sql.PreparedStatement galStmt = galConn.prepareStatement(
        "SELECT image FROM product_gallery WHERE product_id = ? ORDER BY sort_order ASC");
    galStmt.setInt(1, productId);
    java.sql.ResultSet galRs = galStmt.executeQuery();
    boolean firstGal = true;
    while (galRs.next()) {
        String gImg = galRs.getString("image");
        if (gImg != null && !gImg.isEmpty()) {
            galleryImageList.add(gImg);
            if (!firstGal) galleryJson.append(",");
            galleryJson.append("\"").append(gImg.replace("\"", "\\\"")).append("\"");
            firstGal = false;
        }
    }
    galRs.close(); galStmt.close(); galConn.close();
} catch (Exception ignored) {}
galleryJson.append("]");

    } catch (Exception e) { e.printStackTrace(); }
    
 // Fetch variations for this product
 java.util.List<java.util.Map<String, Object>> variations = new java.util.ArrayList<>();
 try {
     Connection varConn = com.shopeasy.DBConnection.getConnection();
     PreparedStatement varPs = varConn.prepareStatement(
    		 "SELECT variation_id, variation_type, variation_value, price, original_price, stock, image FROM product_variation WHERE product_id = ? ORDER BY variation_id ASC");
     varPs.setInt(1, productId);
     ResultSet varRs = varPs.executeQuery();
     while (varRs.next()) {
         java.util.Map<String, Object> v = new java.util.HashMap<>();
         v.put("id", varRs.getInt("variation_id"));
         v.put("type", varRs.getString("variation_type"));
         v.put("value", varRs.getString("variation_value"));
         v.put("price", varRs.getObject("price"));
         v.put("originalPrice", varRs.getObject("original_price"));
         v.put("stock", varRs.getObject("stock"));
         v.put("image", varRs.getString("image"));
         variations.add(v);
     }
     varRs.close(); varPs.close(); varConn.close();
 } catch (Exception e) { e.printStackTrace(); }
 
 loggedUser = (String) session.getAttribute("userName");
 String loggedRole = (String) session.getAttribute("userRole");
 String userAvatar = (String) session.getAttribute("userAvatar");
//Check if logged-in user is the seller of this product
boolean isOwnProduct = false;
try {
   Integer sessionUserId2 = (Integer) session.getAttribute("userId");
   if (sessionUserId2 != null && sellerId > 0) {
       java.sql.Connection ownConn = com.shopeasy.DBConnection.getConnection();
       java.sql.PreparedStatement ownPs = ownConn.prepareStatement(
           "SELECT COUNT(*) FROM seller WHERE seller_id=? AND user_id=?");
       ownPs.setInt(1, sellerId);
       ownPs.setInt(2, sessionUserId2);
       java.sql.ResultSet ownRs = ownPs.executeQuery();
       if (ownRs.next() && ownRs.getInt(1) > 0) isOwnProduct = true;
       ownRs.close(); ownPs.close(); ownConn.close();
   }
} catch (Exception ignored) {}
    int cartCount = 0;
    try {
        Integer sessionUserId = (Integer) session.getAttribute("userId");
        if (sessionUserId != null && (("customer".equals(loggedRole) || "both".equals(loggedRole)))) {
            Connection cartConn = com.shopeasy.DBConnection.getConnection();
            PreparedStatement cartPs = cartConn.prepareStatement(
                "SELECT SUM(ci.quantity) FROM cart c JOIN cartitem ci ON c.cart_id = ci.cart_id WHERE c.customer_id = ?");
            Integer cartCustId = (Integer) session.getAttribute("customerId");
            if (cartCustId == null) cartCustId = sessionUserId;
            cartPs.setInt(1, cartCustId);
            ResultSet cartRs = cartPs.executeQuery();
            if (cartRs.next()) cartCount = cartRs.getInt(1);
            cartRs.close(); cartPs.close(); cartConn.close();
        }
    } catch (Exception e) { e.printStackTrace(); }
    
 // Track breadcrumb
    session.setAttribute("lastProduct", name);
    session.setAttribute("lastProductId", productId);
    session.setAttribute("breadcrumb", "product");
    
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
  body { background: #f0f2f5; font-family: 'Segoe UI', sans-serif; }
.navbar-brand { font-weight: 800; color: #0d6efd !important; }
.product-img { width: 100%; max-height: 440px; object-fit: contain; background: white; border-radius: 20px; padding: 24px; box-shadow: 0 4px 24px rgba(0,0,0,0.08); transition: transform 0.3s; }
.product-img:hover { transform: scale(1.02); }
.gallery-thumb { width: 60px; height: 60px; object-fit: cover; border-radius: 8px; border: 2px solid #dee2e6; cursor: pointer; transition: 0.2s; opacity: 0.7; }
.gallery-thumb:hover, .gallery-thumb.active { border-color: #0d6efd; opacity: 1; }
.gallery-dot { width: 8px; height: 8px; border-radius: 50%; background: #dee2e6; cursor: pointer; transition: 0.2s; border: none; padding: 0; }
.gallery-dot.active { background: #0d6efd; }
.product-card { background: white; border-radius: 20px; box-shadow: 0 4px 24px rgba(0,0,0,0.08); padding: 32px; }
.price-tag { font-size: 34px; font-weight: 900; color: #dc3545; letter-spacing: -0.5px; }
.stock-badge { font-size: 12px; padding: 5px 14px; border-radius: 20px; font-weight: 600; }
.add-cart-btn { background: #3d7edd; border: none; border-radius: 8px; padding: 13px; font-size: 15px; font-weight: 600; transition: background 0.2s; }
.add-cart-btn:hover { background: #2d6ec8; }
.btn-success { background: #3a9e6e !important; border-color: #3a9e6e !important; border-radius: 8px !important; padding: 13px !important; font-size: 15px !important; font-weight: 600 !important; transition: background 0.2s !important; }
.btn-success:hover { background: #2e8a5c !important; border-color: #2e8a5c !important; }
#wishlistBtn { border-radius: 8px !important; padding: 13px !important; font-size: 15px !important; font-weight: 600 !important; transition: background 0.2s, color 0.2s !important; }
.seller-card { background: linear-gradient(135deg, #f0f4ff, #e8f5e9); border-radius: 14px; padding: 16px; margin-top: 16px; border: 1px solid #e0e8ff; transition: box-shadow 0.2s; }
.seller-card:hover { box-shadow: 0 4px 16px rgba(13,110,253,0.1); }
.avatar-circle { width: 36px; height: 36px; border-radius: 50%; background: #0d6efd; color: white; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 14px; overflow: hidden; }
.toast-msg { position: fixed; top: 20px; left: 50%; transform: translateX(-50%); background: #198754; color: white; padding: 14px 32px; border-radius: 14px; font-size: 14px; font-weight: 600; z-index: 9999; box-shadow: 0 6px 20px rgba(0,0,0,0.2); display: none; }
.variation-btn { transition: all 0.15s; }
.variation-btn:hover { transform: translateY(-1px); }
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
<% request.setAttribute("navType", "full"); %>
<% request.setAttribute("navCartCount", cartCount); %>
<%@ include file="navbar.jsp" %>

<!-- BREADCRUMB -->
<div class="bg-white border-bottom px-4 py-2">
    <nav aria-label="breadcrumb">
        <ol class="breadcrumb mb-0" style="font-size:13px;">
            <li class="breadcrumb-item"><a href="index.jsp" class="text-decoration-none text-primary">Home</a></li>
            <li class="breadcrumb-item active text-muted"><%= name %></li>
        </ol>
    </nav>
</div>

<div class="container py-4">
    <div class="row g-4">
        <!-- PRODUCT IMAGE -->
      <div class="col-md-5">
            <div style="background:white; border-radius:20px; padding:20px; box-shadow:0 4px 24px rgba(0,0,0,0.08);">
                <!-- Main Image -->
                <div style="position:relative; overflow:hidden; border-radius:12px; background:#f8f9fa; height:380px; display:flex; align-items:center; justify-content:center;">
                    <% if (image != null && !image.isEmpty()) { %>
                        <img src="<%= image %>" id="mainProductImg" style="max-width:100%; max-height:340px; object-fit:contain; transition:opacity 0.3s;">
                    <% } else { %>
                        <img src="" id="mainProductImg" style="max-width:100%; max-height:340px; object-fit:contain; display:none;">
                        <div id="noImagePlaceholder"><i class="bi bi-image" style="font-size:80px; opacity:0.2; color:#aaa;"></i></div>
                    <% } %>
                    <!-- Slide arrows — shown only when >1 gallery image -->
                    <button id="prevSlide" onclick="slideGallery(-1)" style="display:none; position:absolute; left:8px; top:50%; transform:translateY(-50%); background:rgba(0,0,0,0.35); border:none; border-radius:50%; width:36px; height:36px; color:white; font-size:16px; cursor:pointer; z-index:2;">‹</button>
                    <button id="nextSlide" onclick="slideGallery(1)" style="display:none; position:absolute; right:8px; top:50%; transform:translateY(-50%); background:rgba(0,0,0,0.35); border:none; border-radius:50%; width:36px; height:36px; color:white; font-size:16px; cursor:pointer; z-index:2;">›</button>
                </div>
                <!-- Thumbnails -->
                <div id="galleryThumbs" class="d-flex gap-2 mt-2 flex-wrap" style="display:none!important;"></div>
                <!-- Dots -->
                <div id="galleryDots" class="d-flex gap-1 justify-content-center mt-2"></div>
            </div>
        </div>

        <!-- PRODUCT DETAILS -->
        <div class="col-md-7">
            <div class="product-card">
                <h2 class="fw-bold mb-2"><%= name %></h2>


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

<%
    int prodDiscPct = 0;
    if (originalPrice > 0 && originalPrice < price) {
        prodDiscPct = (int) Math.round((price - originalPrice) / price * 100);
    }
%>
<div id="priceDisplay">
<% if (prodDiscPct > 0) { %>
    <div class="d-flex align-items-center gap-2 mb-1">
        <span class="text-muted text-decoration-line-through" style="font-size:15px;">₱<%= String.format("%.2f", price) %></span>
        <span class="badge bg-danger" style="font-size:12px;">-<%= prodDiscPct %>% OFF</span>
    </div>
    <div class="price-tag mb-2">₱<%= String.format("%.2f", originalPrice) %></div>
<% } else { %>
    <div class="price-tag mb-2">₱<%= String.format("%.2f", price) %></div>
<% } %>
</div>

<div id="stockDisplay">
<% if (stock > 10) { %>
    <span class="badge bg-success stock-badge mb-3"><i class="bi bi-check-circle"></i> In Stock (<%= stock %> available)</span>
<% } else if (stock > 0) { %>
    <span class="badge bg-warning text-dark stock-badge mb-3"><i class="bi bi-exclamation-circle"></i> Low Stock (<%= stock %> left)</span>
<% } else { %>
    <span class="badge bg-danger stock-badge mb-3"><i class="bi bi-x-circle"></i> Out of Stock</span>
<% } %>
</div>

                <hr>
                <p class="fw-bold mb-1">Description</p>
                <p class="text-muted" style="font-size:15px; line-height:1.7;"><%= description != null ? description : "No description available." %></p>

                <!-- SELLER INFO -->
                <div class="seller-card">
    <a href="SellerPageServlet?id=<%= sellerId %>" class="text-decoration-none d-flex align-items-center gap-2">
        <% if (sellerPfp != null && !sellerPfp.isEmpty()) { %>
        <img src="<%= sellerPfp %>" style="width:36px; height:36px; border-radius:50%; object-fit:cover; border:2px solid #198754;">
        <% } else { %>
            <div style="width:36px; height:36px; border-radius:50%; background:#0d6efd; color:white; display:flex; align-items:center; justify-content:center; font-weight:700; font-size:14px;">
                <%= sellerName.substring(0,1).toUpperCase() %>
            </div>
        <% } %>
        <div>
    <p class="mb-0 fw-bold text-primary" style="font-size:13px;"><%= sellerName %></p>
    <div class="d-flex align-items-center gap-1">
    <% if (storeRevs > 0) { %>
        <i class="bi bi-star-fill" style="color:#ffc107; font-size:10px;"></i>
    <% } else { %>
        <i class="bi bi-star" style="color:#ddd; font-size:10px;"></i>
    <% } %>
    <span class="text-muted" style="font-size:10px;"><%= storeRevs > 0 ? String.format("%.1f", storeAvg) + " · " + storeRevs + " review" + (storeRevs != 1 ? "s" : "") : "No reviews yet" %></span>
</div>
    <p class="mb-0 text-muted" style="font-size:11px;">View Shop →</p>
</div>
    </a>
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
   data-price="<%= v.get("price") != null ? v.get("price") : "" %>"
    data-originalprice="<%= v.get("originalPrice") != null ? v.get("originalPrice") : "" %>"
    data-stock="<%= v.get("stock") != null ? v.get("stock") : "" %>"
    data-image="<%= v.get("image") != null ? v.get("image") : "" %>"
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
<% if (isOwnProduct) { %>
    <button class="btn btn-secondary w-100 mt-2" disabled style="cursor:not-allowed; opacity:0.7;">
        <i class="bi bi-slash-circle"></i> You cannot buy your own product
    </button>
<% } else if (loggedUser != null && ("customer".equals(loggedRole) || "both".equals(loggedRole))) { %>
    <% if (stock > 0 || !variations.isEmpty()) { %>
            <!-- QUANTITY SELECTOR -->
            <div class="d-flex align-items-center gap-3 mb-3">
                <label class="fw-bold mb-0" style="font-size:13px;">Quantity:</label>
                <div class="d-flex align-items-center border rounded-3 overflow-hidden">
                    <button type="button" class="btn btn-light px-3 py-2" onclick="changeQty(-1)" style="border-radius:0; border:none;">
                        <i class="bi bi-dash-lg"></i>
                    </button>
                    <input type="number" id="qtyInput" value="1" min="1" max="<%= stock %>"
                        class="form-control text-center border-0 fw-bold"
                        style="width:60px; border-radius:0; box-shadow:none;">
                    <button type="button" class="btn btn-light px-3 py-2" onclick="changeQty(1)" style="border-radius:0; border:none;">
                        <i class="bi bi-plus-lg"></i>
                    </button>
                </div>
               <span class="text-muted" style="font-size:12px;" id="availableText"><%= !variations.isEmpty() ? "Select a size first" : "/ " + stock + " available" %></span>
            </div>
            <div class="d-flex gap-2 mb-2">
    <button class="btn btn-primary add-cart-btn w-100 text-white" onclick="addToCart(<%= productId %>, <%= !variations.isEmpty() %>)"> 
        <i class="bi bi-cart-plus"></i> Add to Cart
    </button>
    <button class="btn btn-success w-100 fw-bold" onclick="buyNow(<%= productId %>, <%= !variations.isEmpty() %>)">
        <i class="bi bi-lightning-fill"></i> Buy Now
    </button>
</div>
<button class="btn w-100" id="wishlistBtn" onclick="toggleWishlist(<%= productId %>)"
    style="font-size:16px; font-weight:700; border:2px solid #dc3545; color:#dc3545; background:white; padding:14px; border-radius:10px; transition:all 0.25s ease;">
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


<!-- REVIEWS SECTION -->
<div class="container pb-5">
    <div class="bg-white rounded-4 shadow-sm p-4 mt-2">
        <h5 class="fw-bold mb-4"><i class="bi bi-star-fill text-warning"></i> Customer Reviews</h5>
        <%
        int totalReviews = topTotalReviews;
        double avgRating = topAvgRating;
        try {
            Connection revConn = com.shopeasy.DBConnection.getConnection();
            PreparedStatement revPs = revConn.prepareStatement(
                "SELECT r.rating, r.comment, r.review_date, r.photo, c.name AS cname, c.profile_picture AS cavatar " +
                "FROM review r JOIN customer c ON r.customer_id = c.customer_id " +
                "WHERE r.product_id = ? ORDER BY r.review_id DESC");
            revPs.setInt(1, productId);
            ResultSet revRs = revPs.executeQuery();
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
                    String cname = revRs.getString("cname");
                 // Mask name: each word → first letter + asterisks
                 String maskedName = "";
                 if (cname != null && !cname.isEmpty()) {
                     String[] nameParts = cname.split(" ");
                     StringBuilder sb = new StringBuilder();
                     for (String part : nameParts) {
                         if (part.isEmpty()) continue;
                         if (sb.length() > 0) sb.append(" ");
                         if (part.length() == 1) {
                             sb.append(part); // single char like "M." — keep as is
                         } else {
                             sb.append(part.charAt(0));
                             for (int ni = 1; ni < part.length(); ni++) sb.append("*");
                         }
                     }
                     maskedName = sb.toString();
                 } else {
                     maskedName = "Anonymous";
                 }
                 %>
                    <% if (cavatar != null && !cavatar.isEmpty()) { %>
                        <img src="<%= cavatar %>" style="width:100%;height:100%;object-fit:cover;">
                    <% } else { %>
                      <%= maskedName.charAt(0) %>
                    <% } %>
                </div>
                <!-- Review Content -->
                <div class="flex-grow-1">
                    <div class="d-flex justify-content-between align-items-start">
                  <p class="fw-bold mb-0" style="font-size:14px;"><%= maskedName %></p>
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
const basePrice = <%= price %>;
const baseOriginalPrice = <%= originalPrice %>;
const baseStock = <%= stock %>;

//GALLERY SLIDESHOW
let galleryImages = [];
let galleryIndex = 0;
let galleryLocked = false;

function initGallery() {
    const seen = new Set();
    galleryImages = [];

    // Load DB gallery images
    const dbGallery = <%= galleryJson.toString() %>;
    dbGallery.forEach(src => {
        if (src && !seen.has(src)) { seen.add(src); galleryImages.push(src); }
    });

    // Fallback: variation images if no DB gallery
    if (galleryImages.length === 0) {
        const btns = document.querySelectorAll('.variation-btn');
        btns.forEach(btn => {
            const img = btn.dataset.image;
            if (img && img !== '' && !seen.has(img)) { seen.add(img); galleryImages.push(img); }
        });
        const mainSrc = '<%= image != null ? image.replace("'", "\\'") : "" %>';
        if (mainSrc && !seen.has(mainSrc)) galleryImages.unshift(mainSrc);
    }

    const dotsEl = document.getElementById('galleryDots');
    dotsEl.innerHTML = '';
    if (galleryImages.length > 1) {
        document.getElementById('prevSlide').style.display = 'block';
        document.getElementById('nextSlide').style.display = 'block';
        galleryImages.forEach((img, i) => {
            const dot = document.createElement('button');
            dot.className = 'gallery-dot' + (i === 0 ? ' active' : '');
            dot.onclick = () => setGalleryImage(i);
            dotsEl.appendChild(dot);
        });
    }
    if (galleryImages.length > 0) setGalleryImage(0);
}

function setGalleryImage(idx) {
    if (galleryLocked) return;
    galleryIndex = (idx + galleryImages.length) % galleryImages.length;
    const mainImg = document.getElementById('mainProductImg');
    mainImg.style.opacity = '0';
    setTimeout(() => {
        mainImg.src = galleryImages[galleryIndex];
        mainImg.style.display = 'block';
        mainImg.style.opacity = '1';
        const placeholder = document.getElementById('noImagePlaceholder');
        if (placeholder) placeholder.style.display = 'none';
    }, 150);
    document.querySelectorAll('.gallery-dot').forEach((d, i) => {
        d.classList.toggle('active', i === galleryIndex);
    });
}

function slideGallery(dir) {
    if (galleryLocked) return;
    setGalleryImage(galleryIndex + dir);
}

function lockGallery(imgSrc) {
    galleryLocked = true;
    const mainImg = document.getElementById('mainProductImg');
    mainImg.style.opacity = '0';
    setTimeout(() => {
        mainImg.src = imgSrc;
        mainImg.style.display = 'block';
        mainImg.style.opacity = '1';
    }, 150);
    document.getElementById('prevSlide').style.display = 'none';
    document.getElementById('nextSlide').style.display = 'none';
    document.getElementById('galleryDots').innerHTML = '';
}

function unlockGallery() {
    galleryLocked = false;
    initGallery();
}

// Auto-select cheapest variation on load
window.addEventListener('DOMContentLoaded', function() {
    initGallery();
    // Find cheapest variation button (lowest price), not necessarily first
    const allBtns = document.querySelectorAll('.variation-btn');
    let cheapestBtn = null;
    let lowestPrice = Infinity;
    allBtns.forEach(btn => {
        const p = parseFloat(btn.dataset.price);
        if (p < lowestPrice) { lowestPrice = p; cheapestBtn = btn; }
    });

    const firstBtn = cheapestBtn; // use cheapest for default display
    if (firstBtn) {
        // Show cheapest variation image
        const varImage = firstBtn.dataset.image;
        const mainImg = document.getElementById('mainProductImg');
        if (mainImg && varImage && varImage !== '') mainImg.src = varImage;

        // Update priceDisplay with cheapest variation price + discount
        const price = parseFloat(firstBtn.dataset.price);
        const original = firstBtn.dataset.originalprice ? parseFloat(firstBtn.dataset.originalprice) : 0;
        let priceHtml = '';
        if (original > 0 && original < price) {
            const pct = Math.round((price - original) / price * 100);
            priceHtml = '<div class="d-flex align-items-center gap-2 mb-1">' +
                '<span class="text-muted text-decoration-line-through" style="font-size:15px;">₱' + price.toFixed(2) + '</span>' +
                '<span class="badge bg-danger" style="font-size:12px;">-' + pct + '% OFF</span>' +
                '</div><div class="price-tag mb-2">₱' + original.toFixed(2) + '</div>';
        } else {
            priceHtml = '<div class="price-tag mb-2">₱' + price.toFixed(2) + '</div>';
        }
        document.getElementById('priceDisplay').innerHTML = priceHtml;
    }
});
function selectVariation(btn, type) {
    document.querySelectorAll('#varGroup_' + type + ' .variation-btn').forEach(b => {
        b.classList.remove('btn-dark');
        b.classList.add('btn-outline-secondary');
    });
    btn.classList.remove('btn-outline-secondary');
    btn.classList.add('btn-dark');
    document.getElementById('selectedVariationId').value = btn.dataset.id;

 // Update price display
    const varBasePrice = btn.dataset.price ? parseFloat(btn.dataset.price) : null;
    const varSalePrice = btn.dataset.originalprice ? parseFloat(btn.dataset.originalprice) : null;
    const rawStock = btn.dataset.stock;
    const varStock = (rawStock !== undefined && rawStock !== '' && rawStock !== 'null') ? parseInt(rawStock) : null;
    const safeStock = (varStock !== null && !isNaN(varStock) && varStock >= 0) ? varStock : null;

 // Update main image if variation has its own image
const varImage = btn.dataset.image;
if (varImage && varImage !== '') {
    lockGallery(varImage);
} else {
    unlockGallery();
}
 const mainImg = document.getElementById('mainProductImg');
 if (mainImg) {
     if (varImage && varImage !== '') {
         mainImg.src = varImage;
     } else {
         mainImg.src = '<%= image != null ? image : "" %>';
     }
 }
//Determine effective display price for this variant
 // varBasePrice = original/crossed-out price, varSalePrice = sale/discounted price
 let displayPrice, displayOriginalPrice, discountPct;
 if (varBasePrice !== null) {
     // Variant has its own pricing
     displayOriginalPrice = varBasePrice;
     displayPrice = varSalePrice !== null ? varSalePrice : varBasePrice;
     discountPct = (varSalePrice !== null && varBasePrice > varSalePrice)
         ? Math.round((varBasePrice - varSalePrice) / varBasePrice * 100) : 0;
 } else {
     // Fall back to base product pricing
     displayOriginalPrice = basePrice;
     displayPrice = baseOriginalPrice > 0 ? baseOriginalPrice : basePrice;
     discountPct = (baseOriginalPrice > 0 && baseOriginalPrice < basePrice)
         ? Math.round((basePrice - baseOriginalPrice) / basePrice * 100) : 0;
 }
 const displayStock = safeStock !== null ? safeStock : baseStock;

 let priceHtml = '';
 if (discountPct > 0) {
     priceHtml = '<div class="d-flex align-items-center gap-2 mb-1">' +
         '<span class="text-muted text-decoration-line-through" style="font-size:15px;">₱' + displayOriginalPrice.toFixed(2) + '</span>' +
         '<span class="badge bg-danger" style="font-size:12px;">-' + discountPct + '% OFF</span>' +
         '</div>' +
         '<div class="price-tag mb-2">₱' + displayPrice.toFixed(2) + '</div>';
 } else {
     priceHtml = '<div class="price-tag mb-2">₱' + displayPrice.toFixed(2) + '</div>';
 }
 document.getElementById('priceDisplay').innerHTML = priceHtml;

    // Update stock badge
    let stockHtml = '';
    if (safeStock === null) {
        // Variation has no stock info — keep showing base stock display, don't override
    } else if (displayStock > 10) {
        stockHtml = '<span class="badge bg-success stock-badge mb-3"><i class="bi bi-check-circle"></i> In Stock (' + displayStock + ' available)</span>';
        document.getElementById('stockDisplay').innerHTML = stockHtml;
    } else if (displayStock > 0) {
        stockHtml = '<span class="badge bg-warning text-dark stock-badge mb-3"><i class="bi bi-exclamation-circle"></i> Low Stock (' + displayStock + ' left)</span>';
        document.getElementById('stockDisplay').innerHTML = stockHtml;
    } else {
        stockHtml = '<span class="badge bg-danger stock-badge mb-3"><i class="bi bi-x-circle"></i> Out of Stock</span>';
        document.getElementById('stockDisplay').innerHTML = stockHtml;
    }
    document.getElementById('qtyInput').max = safeStock !== null ? displayStock : baseStock;
    document.getElementById('availableText').textContent = '/ ' + (safeStock !== null ? displayStock : baseStock) + ' available';
}

function changeQty(delta) {
    const input = document.getElementById('qtyInput');
    const max = parseInt(input.max);
    let val = parseInt(input.value) + delta;
    if (val < 1) val = 1;
    if (val > max) val = max;
    input.value = val;
}

function buyNow(productId, hasVariation) {
    // Birthday check
    const ageStatus = '<%=  session.getAttribute("userAgeStatus") != null ? session.getAttribute("userAgeStatus") : "unknown" %>';
    if (ageStatus !== 'ok') {
    	new bootstrap.Modal(document.getElementById('ageBlockModal')).show();
        return;
    }
    if (hasVariation) {
        const selectedId = document.getElementById('selectedVariationId').value;
        if (!selectedId) {
        	showProductToast('Please select your preferred options first!', 'error');
        	return;
           
        }
    }
    const varId = hasVariation ? document.getElementById('selectedVariationId').value : '';
    const qty = document.getElementById('qtyInput') ? document.getElementById('qtyInput').value : '1';
    
    // First remove existing buyNow item if any, then add fresh
    fetch('BuyNowServlet', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'productId=' + productId + (varId ? '&variationId=' + varId : '') + '&quantity=' + qty
    })
    .then(res => res.json())
    .then(data => {
        if (data.success) {
            window.location.href = 'checkout.jsp?buyNow=true';
        } else {
        	showProductToast(data.message || 'Could not process Buy Now.', 'error');
        }
    })
    .catch(() => showProductToast('Server error. Please try again.', 'error'));
}

function addToCart(productId, hasVariation) {
    const variationId = document.getElementById('selectedVariationId') 
                        ? document.getElementById('selectedVariationId').value 
                        : '';

                        if (hasVariation && !variationId) {
                            showProductToast('Please select a variation first!', 'error');
                            return;
                        }

    const qty = document.getElementById('qtyInput') ? document.getElementById('qtyInput').value : '1';
    let body = 'productId=' + productId + '&quantity=' + qty;
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
            
            // Gamitin ang newCount na galing sa database
            const badge = document.getElementById('cartBadge');
            if (badge) {
                badge.textContent = data.newCount;
            }
        } else {
        	showProductToast(data.message || 'Error adding to cart.', 'error');
        }
    })
    .catch(() => showProductToast('Server error. Please try again.', 'error'));
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
            const wb = document.getElementById('wishlistBtn');
            if (data.action === 'added') {
                icon.className = 'bi bi-heart-fill';
                text.textContent = 'Wishlisted';
                wb.style.background = '#dc3545';
                wb.style.color = 'white';
            } else {
                icon.className = 'bi bi-heart';
                text.textContent = 'Add to Wishlist';
                wb.style.background = 'white';
                wb.style.color = '#dc3545';
            }
        }
    })
    .catch(() => showProductToast('Could not update wishlist. Please try again.', 'error'));
}

// Check if already wishlisted on load
window.addEventListener('load', function() {
    fetch('WishlistServlet?check=<%= productId %>')
    .then(res => res.json())
    .then(data => {
        if (data.wishlisted) {
            document.getElementById('wishlistIcon').className = 'bi bi-heart-fill';
            document.getElementById('wishlistText').textContent = 'Wishlisted';
            const wbLoad = document.getElementById('wishlistBtn');
            wbLoad.style.background = '#dc3545';
            wbLoad.style.color = 'white';
        }
    })
    .catch(() => {});
});

window.addEventListener('pageshow', function(e) {
    if (e.persisted) {
        // Page was loaded from cache (back button)
        const qtyInput = document.getElementById('qtyInput');
        if (qtyInput) qtyInput.value = 1;
    }
});

function showProductToast(msg, type) {
    const toast = document.getElementById('cartToast');
    toast.style.background = (type === 'error') ? '#dc3545' : '#198754';
    toast.innerHTML = (type === 'error')
        ? '<i class="bi bi-exclamation-circle-fill me-2"></i>' + msg
        : '<i class="bi bi-cart-check-fill me-2"></i>' + msg;
    toast.style.display = 'block';
    setTimeout(() => {
        toast.style.display = 'none';
        toast.style.background = '#198754';
        toast.innerHTML = '<i class="bi bi-cart-check-fill me-2"></i> Item added to cart! 🛒';
    }, 2500);
}

</script>

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
</body>
</html>