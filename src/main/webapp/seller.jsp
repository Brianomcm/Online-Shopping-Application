<%@ page session="true" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    if(session.getAttribute("userId") == null || !"seller".equals(session.getAttribute("userRole"))) {
        response.sendRedirect("index.jsp");
        return;
    }
    String sellerName = (String) session.getAttribute("userName");
    String sellerEmail = (String) session.getAttribute("userEmail");
    String sellerPhone = (String) session.getAttribute("userPhone");
    String sellerUsername = (String) session.getAttribute("userUsername");
    String sellerBusinessName = (String) session.getAttribute("userBusinessName");
    String sellerBusinessType = (String) session.getAttribute("userBusinessType");
    String sellerPicture = (String) session.getAttribute("userProfilePicture");
    String sellerBanner = (String) session.getAttribute("userBannerPicture");
    

    if(sellerName == null) sellerName = "";
    if(sellerEmail == null) sellerEmail = "";
    if(sellerPhone == null) sellerPhone = "";
    if(sellerUsername == null) sellerUsername = "";
    if(sellerBusinessName == null) sellerBusinessName = "";
    if(sellerBusinessType == null) sellerBusinessType = "";
    if(sellerBanner == null) sellerBanner = "";
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Seller Profile - ShopEasy</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css">
    <style>
        body { background: #f4f6fb; }
        .sidebar {
            background: white;
            border-radius: 16px;
            box-shadow: 0 2px 12px rgba(0,0,0,0.07);
            padding: 24px 0;
            position: sticky;
            top: 20px;
        }
        .sidebar-avatar {
            width: 80px; height: 80px;
            border-radius: 50%;
            object-fit: cover;
            border: 3px solid #198754;
        }
        .sidebar-nav a {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px 24px;
            color: #555;
            text-decoration: none;
            font-size: 14px;
            transition: 0.2s;
            border-left: 3px solid transparent;
        }
        .sidebar-nav a:hover, .sidebar-nav a.active {
            background: #e8f5e9;
            color: #198754;
            border-left-color: #198754;
            font-weight: 600;
        }
        .sidebar-nav a i { font-size: 16px; width: 20px; }
        .card-section {
            background: white;
            border-radius: 16px;
            box-shadow: 0 2px 12px rgba(0,0,0,0.07);
            padding: 24px;
            margin-bottom: 20px;
        }
        .section-title {
            font-size: 16px;
            font-weight: 700;
            color: #1a1a2e;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #e8f5e9;
        }
        .avatar-upload {
            position: relative;
            width: 100px;
            height: 100px;
            margin: 0 auto 16px;
        }
        .avatar-upload img {
            width: 100px; height: 100px;
            border-radius: 50%;
            object-fit: cover;
            border: 3px solid #198754;
        }
        .avatar-upload .upload-btn {
            position: absolute;
            bottom: 0; right: 0;
            background: #198754;
            color: white;
            border: none;
            border-radius: 50%;
            width: 28px; height: 28px;
            font-size: 12px;
            cursor: pointer;
        }
        .stat-box {
            background: #f0fff4;
            border-radius: 12px;
            padding: 14px;
            text-align: center;
        }
        .stat-box .stat-num { font-size: 24px; font-weight: 700; color: #198754; }
        .stat-box .stat-label { font-size: 12px; color: #666; }
        .product-row {
            border: 1px solid #e8f5e9;
            border-radius: 12px;
            padding: 14px;
            margin-bottom: 12px;
            transition: 0.2s;
        }
        .product-row:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.08); }
        .product-img {
            width: 60px; height: 60px;
            border-radius: 8px;
            object-fit: cover;
        }
        .stock-badge { font-size: 11px; padding: 3px 8px; border-radius: 20px; }
        .tab-content-section { display: none; }
        .tab-content-section.active { display: block; }
        .navbar-shopeasy { background: white; box-shadow: 0 2px 8px rgba(0,0,0,0.08); }
        .rating-star { color: #ffc107; font-size: 13px; }
        .password-strength { height: 4px; border-radius: 2px; margin-top: 6px; transition: 0.3s; }
 .shop-banner {
    width: 100%;
    height: 180px;
    border-radius: 12px;
    position: relative;
    overflow: hidden;
    margin-bottom: 16px;
    background-size: cover !important;
    background-position: center !important;
}
        .shop-banner-text {
            position: absolute;
            bottom: 12px; left: 16px;
            color: white;
        }
        .edit-banner-btn {
    position: absolute;
    top: 10px; right: 10px;
    background: rgba(0,0,0,0.6);
    color: white;
    border: 1px solid rgba(255,255,255,0.5);
    border-radius: 8px;
    padding: 4px 10px;
    font-size: 12px;
    cursor: pointer;
    backdrop-filter: blur(4px);
}
.edit-banner-btn:hover {
    background: rgba(0,0,0,0.8);
}
        .crop-modal-overlay {
    display: none;
    position: fixed;
    top: 0; left: 0;
    width: 100%; height: 100%;
    background: rgba(0,0,0,0.8);
    z-index: 99999;
    flex-direction: column;
    align-items: center;
    justify-content: center;
}
.crop-container {
    background: white;
    border-radius: 16px;
    padding: 20px;
    width: 90%;
    max-width: 500px;
}
.crop-canvas-wrapper {
    position: relative;
    overflow: hidden;
    width: 100%;
    background: #f0f0f0;
    cursor: crosshair;
}
#cropCanvas { 
    display: block; 
    width: 300px; 
    height: 300px;
    cursor: grab;
    border-radius: 4px;
}
#bannerCropCanvas {
    display: block;
    width: 100%;
    cursor: grab;
}
#bannerCropCanvas:active { cursor: grabbing; }
#productCropCanvas {
    display: block;
    width: 300px;
    height: 300px;
    cursor: grab;
}
#productCropCanvas:active { cursor: grabbing; }
    </style>
</head>
<body>

<!-- GREEN BAR NOTIFICATION -->
<div id="successBar" style="display:none; position:fixed; top:0; left:0; width:100%; background:#198754; color:white; padding:12px 20px; z-index:9999; text-align:center; font-size:14px; font-weight:600; box-shadow:0 2px 8px rgba(0,0,0,0.15);">
    <i class="bi bi-check-circle-fill me-2"></i><span id="successBarMsg">Saved successfully ✅</span>
</div>

<!-- NAVBAR -->
<nav class="navbar navbar-light navbar-shopeasy py-2 mb-4">
    <div class="container-fluid px-3">
        <a class="navbar-brand fw-bold text-success" href="index.jsp">
            <i class="bi bi-bag-heart-fill"></i> ShopEasy
        </a>
        <div class="d-flex align-items-center gap-3">
            <a href="index.jsp" class="text-decoration-none fw-bold text-success" style="font-size:14px;">
    <i class="bi bi-house-fill"></i> Home
</a>
            <a href="#" onclick="doLogout()" class="btn btn-outline-danger btn-sm">
    <i class="bi bi-box-arrow-right"></i> Logout
</a>
        </div>
    </div>
</nav>

<div class="container pb-5">
    <div class="row g-4">

        <!-- SIDEBAR -->
        <div class="col-md-3">
            <div class="sidebar">
                <div class="text-center px-3 mb-3">
                    <% if(sellerPicture != null && !sellerPicture.isEmpty()) { %>
                        <img src="<%= sellerPicture %>" class="sidebar-avatar mb-2" alt="Avatar" id="sidebarAvatar">
                    <% } else { %>
                        <img src="https://ui-avatars.com/api/?name=<%= sellerName.replace(" ", "+") %>&background=198754&color=fff&size=80" class="sidebar-avatar mb-2" alt="Avatar" id="sidebarAvatar">
                    <% } %>
                    <p class="fw-bold mb-0" style="font-size:15px;"><%= sellerBusinessName.isEmpty() ? sellerName : sellerBusinessName %></p>
                    <p class="text-muted mb-0" style="font-size:12px;"><%= sellerEmail %></p>
                    <span class="badge bg-success mt-1" style="font-size:10px;">Seller</span>
                </div>
                <hr class="mx-3">
                <div class="sidebar-nav">
                  <a href="#" class="<%= request.getParameter("tab") == null ? "active" : "" %>" onclick="showTab('home', this)">
    <i class="bi bi-shop"></i> Shop Settings
</a>

                    <a href="#" onclick="showTab('products', this)">
                        <i class="bi bi-grid"></i> My Products
                    </a>
                    <a href="seller.jsp?tab=orders&orderTab=All"
   class="<%= "orders".equals(request.getParameter("tab")) ? "active" : "" %>">
    <i class="bi bi-bag"></i> Orders Received
</a>
                    <a href="#" onclick="showTab('sales', this)">
                        <i class="bi bi-graph-up"></i> Sales & Analytics
                    </a>
                    <a href="#" onclick="showTab('reviews', this)">
                        <i class="bi bi-star"></i> Reviews
                    </a>
                    <a href="#" onclick="showTab('security', this)">
                        <i class="bi bi-shield-lock"></i> Security
                    </a>
                    <a href="#" onclick="showTab('notifications', this)">
                        <i class="bi bi-bell"></i> Notifications
                    </a>
                </div>
            </div>
        </div>

        <!-- MAIN CONTENT -->
<div class="col-md-9">

    <!-- STATS ROW -->
    <%
    int sellerStatProducts = 0, sellerStatOrders = 0;
    double sellerStatRevenue = 0;
    try {
        int sId = (int) session.getAttribute("userId");
        java.sql.Connection sStatConn = com.shopeasy.DBConnection.getConnection();

        // Product count
        java.sql.PreparedStatement sStatPs1 = sStatConn.prepareStatement(
            "SELECT COUNT(*) FROM product WHERE seller_id=? AND status='active'");
        sStatPs1.setInt(1, sId);
        java.sql.ResultSet sStatRs1 = sStatPs1.executeQuery();
        if (sStatRs1.next()) sellerStatProducts = sStatRs1.getInt(1);
        sStatRs1.close(); sStatPs1.close();

        // Order count
        java.sql.PreparedStatement sStatPs2 = sStatConn.prepareStatement(
            "SELECT COUNT(DISTINCT o.order_id) FROM orders o JOIN order_items oi ON o.order_id=oi.order_id WHERE oi.seller_id=?");
        sStatPs2.setInt(1, sId);
        java.sql.ResultSet sStatRs2 = sStatPs2.executeQuery();
        if (sStatRs2.next()) sellerStatOrders = sStatRs2.getInt(1);
        sStatRs2.close(); sStatPs2.close();

        // Revenue
        java.sql.PreparedStatement sStatPs3 = sStatConn.prepareStatement(
            "SELECT SUM(oi.subtotal) FROM order_items oi JOIN orders o ON oi.order_id=o.order_id WHERE oi.seller_id=? AND o.status='Completed'");
        sStatPs3.setInt(1, sId);
        java.sql.ResultSet sStatRs3 = sStatPs3.executeQuery();
        if (sStatRs3.next()) sellerStatRevenue = sStatRs3.getDouble(1);
        sStatRs3.close(); sStatPs3.close();

        sStatConn.close();
    } catch (Exception ex) { ex.printStackTrace(); }
%>
    <div class="row g-3 mb-4">
        <div class="col-6 col-md-3">
            <div class="stat-box">
                <div class="stat-num"><%= sellerStatProducts %></div>
                <div class="stat-label">Products</div>
            </div>
        </div>
        <div class="col-6 col-md-3">
            <div class="stat-box">
                <div class="stat-num"><%= sellerStatOrders %></div>
                <div class="stat-label">Orders</div>
            </div>
        </div>
        <div class="col-6 col-md-3">
            <div class="stat-box">
                <div class="stat-num">₱<%= String.format("%.0f", sellerStatRevenue) %></div>
                <div class="stat-label">Revenue</div>
            </div>
        </div>
        <div class="col-6 col-md-3">
            <div class="stat-box">
                <%
double sellerAvgRating = 0.0;
try {
    java.sql.Connection ratingConn = com.shopeasy.DBConnection.getConnection();
    java.sql.PreparedStatement ratingPs = ratingConn.prepareStatement(
        "SELECT AVG(r.rating) FROM review r " +
        "JOIN product p ON r.product_id = p.product_id " +
        "WHERE p.seller_id = ?");
    ratingPs.setInt(1, (int) session.getAttribute("userId"));
    java.sql.ResultSet ratingRs = ratingPs.executeQuery();
    if (ratingRs.next()) sellerAvgRating = ratingRs.getDouble(1);
    ratingRs.close(); ratingPs.close(); ratingConn.close();
} catch (Exception ex) { ex.printStackTrace(); }
%>
<div class="stat-num"><%= String.format("%.1f", sellerAvgRating) %></div>
<div class="stat-label">Rating</div>
            </div>
        </div>
    </div>

    <!-- SHOP SETTINGS -->
    <div class="card-section mb-4" id="section-shop">
    <p class="section-title"><i class="bi bi-shop-window text-success"></i> Shop Settings</p>
        <form action="UpdateSellerServlet" method="post">
            <input type="hidden" name="action" value="shop">
            
            <div class="shop-banner" id="shopBannerDiv" style="<%= !sellerBanner.isEmpty() ? "background:url('" + sellerBanner + "') center/cover no-repeat;" : "background:linear-gradient(135deg, #198754, #20c997);" %>">
               <button type="button" class="edit-banner-btn" id="editBannerBtn" onclick="document.getElementById('bannerInput').click()">
    <i class="bi bi-camera"></i> Edit Banner
</button>
<button type="button" class="edit-banner-btn" id="removeBannerBtn" style="right:110px; <%= sellerBanner.isEmpty() ? "display:none;" : "" %>" onclick="removeBanner()">
    <i class="bi bi-trash"></i> Remove
</button>
                <div class="shop-banner-text">
                    <p class="mb-0 fw-bold fs-5"><%= sellerBusinessName.isEmpty() ? sellerName : sellerBusinessName %></p>
                    <p class="mb-0" style="font-size:12px;">Quality products at great prices</p>
                </div>
            </div>
            
            

            <div class="row g-3">
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">Shop / Business Name</label>
                    <input type="text" class="form-control" name="businessName" id="shopBusinessName" value="<%= sellerBusinessName %>" disabled>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">Business Type</label>
                    <select class="form-select" name="businessType" id="shopBusinessType" disabled>
                        <option value="Retail" <%= "Retail".equals(sellerBusinessType) ? "selected" : "" %>>Retail</option>
                        <option value="Wholesale" <%= "Wholesale".equals(sellerBusinessType) ? "selected" : "" %>>Wholesale</option>
                        <option value="Food & Beverage" <%= "Food & Beverage".equals(sellerBusinessType) ? "selected" : "" %>>Food & Beverage</option>
                        <option value="Fashion & Apparel" <%= "Fashion & Apparel".equals(sellerBusinessType) ? "selected" : "" %>>Fashion & Apparel</option>
                        <option value="Electronics" <%= "Electronics".equals(sellerBusinessType) ? "selected" : "" %>>Electronics</option>
                        <option value="Others" <%= "Others".equals(sellerBusinessType) ? "selected" : "" %>>Others</option>
                    </select>
                </div>
                <div class="col-12">
                    <label class="form-label fw-bold" style="font-size:13px;">Shop Description</label>
                    <textarea class="form-control" rows="3" name="shopDescription" id="shopDescription" disabled><%= session.getAttribute("userShopDescription") != null ? session.getAttribute("userShopDescription") : "" %></textarea>
                </div>
                <div class="col-12">
                    <label class="form-label fw-bold" style="font-size:13px;">Business Address</label>
                    <input type="text" class="form-control" name="address" id="shopAddress" value="<%= session.getAttribute("userAddress") != null ? session.getAttribute("userAddress") : "" %>" disabled>
                </div>
                <div class="col-12 text-end">
                    <button type="button" class="btn btn-outline-success px-4" id="editShopBtn" onclick="enableShopEdit()">
                        <i class="bi bi-pencil"></i> Edit Settings
                    </button>
                    <button type="submit" class="btn btn-success px-4" id="saveShopBtn" style="display:none;">
                        <i class="bi bi-check2"></i> Save Changes
                    </button>
                    <button type="button" class="btn btn-outline-secondary px-4" id="cancelShopBtn" style="display:none;" onclick="cancelShopEdit()">
                        <i class="bi bi-x"></i> Cancel
                    </button>
                </div>
            </div>
        </form>
    </div>
    <form id="avatarForm" action="UpdateSellerServlet" method="post" style="display:none;">
    <input type="hidden" name="action" value="avatar">
    <input type="hidden" id="avatarData" name="profilePicture" value="">
</form>
<form id="bannerForm" action="UpdateSellerServlet" method="post" style="display:none;">
    <input type="hidden" name="action" value="banner">
    <input type="hidden" id="bannerData" name="bannerPicture" value="">
    <input type="hidden" id="removeBannerFlag" name="removeBanner" value="false">
</form>
    <!-- PERSONAL INFORMATION -->
   <div class="card-section mb-4" id="section-profile">
    <p class="section-title"><i class="bi bi-person-fill text-success"></i> Personal Information</p>
        <form id="profileForm" action="UpdateSellerServlet" method="post">
            <input type="hidden" name="action" value="profile">
            <input type="hidden" name="profilePicture" id="profilePictureInput">
            <div class="text-center mb-4">
                <div class="avatar-upload">
                    <img src="<%= (sellerPicture != null && !sellerPicture.isEmpty()) ? sellerPicture : "https://ui-avatars.com/api/?name=" + sellerName.replace(" ", "+") + "&background=198754&color=fff&size=100" %>"
                         alt="Avatar" id="avatarPreview">
                    <button type="button" class="upload-btn" id="avatarUploadBtn" onclick="document.getElementById('avatarInput').click()">
                        <i class="bi bi-camera"></i>
                    </button>
                    <input type="file" id="avatarInput" style="display:none" accept="image/*" onchange="previewAvatar(this)">
                </div>
                <p class="text-muted" style="font-size:12px;">Click the camera icon to change profile picture</p>
            </div>
            <div class="row g-3">
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">Full Name</label>
                    <input type="text" class="form-control" name="fullname" id="profFullname" value="<%= sellerName %>" disabled>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">Username</label>
                    <input type="text" class="form-control" name="username" id="profUsername" value="<%= sellerUsername %>" disabled>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">Email</label>
                    <input type="email" class="form-control" name="email" id="profEmail" value="<%= sellerEmail %>" disabled>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">Phone Number</label>
                    <div class="input-group">
                        <span class="input-group-text">+63</span>
                        <input type="tel" class="form-control" name="phone" id="profPhone" value="<%= sellerPhone %>" disabled>
                    </div>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">Birthday</label>
                    <input type="date" class="form-control" name="birthday" id="profBirthday" value="<%= session.getAttribute("userBirthday") != null ? session.getAttribute("userBirthday") : "" %>" disabled>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">Gender</label>
                    <select class="form-select" name="gender" id="profGender" disabled>
                        <option value="">Select Gender</option>
                        <option value="Male" <%= "Male".equals(session.getAttribute("userGender")) ? "selected" : "" %>>Male</option>
                        <option value="Female" <%= "Female".equals(session.getAttribute("userGender")) ? "selected" : "" %>>Female</option>
                        <option value="Other" <%= "Other".equals(session.getAttribute("userGender")) ? "selected" : "" %>>Other</option>
                        <option value="Prefer not to say" <%= "Prefer not to say".equals(session.getAttribute("userGender")) ? "selected" : "" %>>Prefer not to say</option>
                    </select>
                </div>
                <div class="col-12 text-end">
                    <button type="button" class="btn btn-outline-success px-4" id="editProfileBtn" onclick="enableProfileEdit()">
                        <i class="bi bi-pencil"></i> Edit Profile
                    </button>
                    <button type="submit" class="btn btn-success px-4" id="saveProfileBtn" style="display:none;">
                        <i class="bi bi-check2"></i> Save Changes
                    </button>
                    <button type="button" class="btn btn-outline-secondary px-4" id="cancelProfileBtn" style="display:none;" onclick="cancelProfileEdit()">
                        <i class="bi bi-x"></i> Cancel
                    </button>
                </div>
            </div>
        </form>
    </div>

    <!-- OTHER TABS (keep these hidden for sidebar nav) -->
    <div id="tab-products" class="tab-content-section" style="display:none;">
    <div class="card-section">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <p class="section-title mb-0"><i class="bi bi-grid-fill text-success"></i> My Products</p>
            <button class="btn btn-success btn-sm" onclick="showAddProduct()">
                <i class="bi bi-plus"></i> Add Product
            </button>
        </div>

        <!-- ADD PRODUCT FORM -->
        <div id="addProductForm" style="display:none;" class="mb-4 p-3 border rounded-3 bg-light">
            <p class="fw-bold mb-3" style="font-size:14px;">
                <i class="bi bi-plus-circle text-success"></i> Add New Product
            </p>
            <form action="AddProductServlet" method="post" id="productForm">
                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label fw-bold" style="font-size:13px;">Product Name</label>
                        <input type="text" name="productName" class="form-control" placeholder="Enter product name" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold" style="font-size:13px;">Category</label>
                        <select name="categoryId" class="form-select" required>
                            <option value="">Select category</option>
                            <option value="1">Electronics</option>
                            <option value="2">Fashion</option>
                            <option value="3">Home</option>
                            <option value="4">Gaming</option>
                            <option value="5">Health</option>
                            <option value="6">Others</option>
                        </select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold" style="font-size:13px;">Price (₱)</label>
                        <input type="number" name="price" class="form-control" placeholder="0.00" step="0.01" min="0" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold" style="font-size:13px;">Stock Quantity</label>
                        <input type="number" name="stock" class="form-control" placeholder="0" min="0" required>
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-bold" style="font-size:13px;">Description</label>
                        <textarea name="description" class="form-control" rows="3" placeholder="Describe your product..."></textarea>
                    </div>
                    <div class="col-12">
    <label class="form-label fw-bold" style="font-size:13px;">Product Image</label>
    <input type="file" id="productImageInput" class="form-control" accept="image/*" onchange="openProductCropModal(this)">
    <input type="hidden" name="productImage" id="productImageData">
    <div id="productImagePreview" class="mt-2" style="display:none;">
        <img id="productImgPreview" src="" style="width:120px; height:120px; object-fit:cover; border-radius:8px; border:2px solid #198754;">
        <p class="text-muted mt-1" style="font-size:11px;">Click the file input again to change photo</p>
    </div>
</div>
                    <div class="col-12 d-flex gap-2 justify-content-end">
                        <button type="button" class="btn btn-outline-secondary btn-sm" onclick="hideAddProduct()">
                            <i class="bi bi-x"></i> Cancel
                        </button>
                        <button type="submit" class="btn btn-success btn-sm px-4">
                            <i class="bi bi-check2"></i> Save Product
                        </button>
                    </div>
                </div>
            </form>
        </div>

        <%
    java.util.List<java.util.Map<String, String>> products = 
        (java.util.List<java.util.Map<String, String>>) session.getAttribute("sellerProducts");
    if (products != null && !products.isEmpty()) {
%>
    <div id="productList">
    <% for (java.util.Map<String, String> product : products) { %>
        <div class="product-row">
            <div class="d-flex gap-3 align-items-center">
                <% if (product.get("image") != null && !product.get("image").isEmpty()) { %>
                    <img src="<%= product.get("image") %>" class="product-img" alt="Product">
                <% } else { %>
                    <div class="product-img d-flex align-items-center justify-content-center bg-light rounded">
                        <i class="bi bi-image text-muted"></i>
                    </div>
                <% } %>
                <div class="flex-grow-1">
                    <p class="mb-0 fw-bold" style="font-size:14px;"><%= product.get("name") %></p>
                    <p class="mb-0 text-muted" style="font-size:12px;">
                        <%= product.get("category_name") != null ? product.get("category_name") : "Uncategorized" %> 
                        &nbsp;|&nbsp; Stock: <%= product.get("stock") %>
                    </p>
                </div>
                <div class="text-end">
                    <p class="mb-1 fw-bold text-success">₱<%= product.get("price") %></p>
                    <% int stock = Integer.parseInt(product.get("stock") != null ? product.get("stock") : "0");
                       if (stock > 5) { %>
                        <span class="badge bg-success stock-badge">In Stock</span>
                    <% } else if (stock > 0) { %>
                        <span class="badge bg-warning text-dark stock-badge">Low Stock</span>
                    <% } else { %>
                        <span class="badge bg-danger stock-badge">Out of Stock</span>
                    <% } %>
                </div>
                <div class="d-flex flex-column gap-1">
    <button class="btn btn-outline-primary btn-sm" 
        onclick="editProduct('<%= product.get("product_id") %>', '<%= product.get("name") %>', '<%= product.get("price") %>', '<%= product.get("stock") %>', '<%= product.get("description") != null ? product.get("description").replace("'", "\\'") : "" %>', '<%= product.get("category_name") %>')">
        <i class="bi bi-pencil"></i>
    </button>
    <button class="btn btn-outline-danger btn-sm"
        onclick="deleteProduct('<%= product.get("product_id") %>', '<%= product.get("name") %>')">
        <i class="bi bi-trash"></i>
    </button>
</div>
            </div>
        </div>
    <% } %>
    </div>
<% } else { %>
    <div class="text-center text-muted py-4" id="noProductsMsg">
        <i class="bi bi-box-seam fs-1 opacity-50"></i>
        <p class="mt-2" style="font-size:13px;">No products yet. Click Add Product to start!</p>
    </div>
<% } %>
    </div>
</div>




<div id="tab-orders" class="tab-content-section" style="display:none;">
    <%-- Fetch orders with items --%>
    <%
        String orderTabFilter = request.getParameter("orderTab");
        if (orderTabFilter == null) orderTabFilter = "All";

        java.util.List<java.util.Map<String, Object>> sellerOrders = new java.util.ArrayList<>();
        try {
            int sOrdSellerId = (int) session.getAttribute("userId");
            java.sql.Connection sOrdConn = com.shopeasy.DBConnection.getConnection();

            String sOrdSql = "SELECT DISTINCT o.order_id, o.status, o.order_date, o.total_amount AS total_price, " +
            	    "o.payment_method, c.name AS buyer_name, c.email AS buyer_email, " +
            	    "o.shipping_address AS address, NULL AS addr_name, NULL AS phone " +
            	    "FROM orders o " +
            	    "JOIN order_items oi ON o.order_id = oi.order_id " +
            	    "JOIN customer c ON o.customer_id = c.customer_id " +
            	    "WHERE oi.seller_id = ? ";
            if (!"All".equals(orderTabFilter)) {
                sOrdSql += "AND o.status = ? ";
            }
            sOrdSql += "ORDER BY o.order_id DESC";

            java.sql.PreparedStatement sOrdPs = sOrdConn.prepareStatement(sOrdSql);
            sOrdPs.setInt(1, sOrdSellerId);
            if (!"All".equals(orderTabFilter)) sOrdPs.setString(2, orderTabFilter);
            java.sql.ResultSet sOrdRs = sOrdPs.executeQuery();

            while (sOrdRs.next()) {
                java.util.Map<String, Object> ord = new java.util.HashMap<>();
                ord.put("id", sOrdRs.getInt("order_id"));
                ord.put("status", sOrdRs.getString("status"));
                ord.put("date", sOrdRs.getString("order_date"));
                ord.put("total", sOrdRs.getDouble("total_price"));
                ord.put("payment", sOrdRs.getString("payment_method"));
                ord.put("buyer_name", sOrdRs.getString("buyer_name"));
                ord.put("buyer_email", sOrdRs.getString("buyer_email"));
                ord.put("addr_name", sOrdRs.getString("addr_name"));
                ord.put("phone", sOrdRs.getString("phone"));
                ord.put("address", sOrdRs.getString("address"));

                // Fetch items for this order belonging to this seller
                java.util.List<java.util.Map<String, Object>> itemList = new java.util.ArrayList<>();
                java.sql.PreparedStatement itemPs = sOrdConn.prepareStatement(
                		"SELECT oi.quantity, oi.subtotal, p.name AS pname, p.image AS image_url " +
                    "FROM order_items oi JOIN product p ON oi.product_id = p.product_id " +
                    "WHERE oi.order_id = ? AND oi.seller_id = ?");
                itemPs.setInt(1, sOrdRs.getInt("order_id"));
                itemPs.setInt(2, sOrdSellerId);
                java.sql.ResultSet itemRs = itemPs.executeQuery();
                while (itemRs.next()) {
                    java.util.Map<String, Object> item = new java.util.HashMap<>();
                    item.put("qty", itemRs.getInt("quantity"));
                    item.put("subtotal", itemRs.getDouble("subtotal"));
                    item.put("pname", itemRs.getString("pname"));
                    item.put("image", itemRs.getString("image_url"));
                    itemList.add(item);
                }
                itemRs.close(); itemPs.close();
                ord.put("items", itemList);
                sellerOrders.add(ord);
            }
            sOrdRs.close(); sOrdPs.close(); sOrdConn.close();
        } catch (Exception ex) { ex.printStackTrace(); }
    %>

    <%-- Order Tab Nav --%>
    <div class="d-flex align-items-center justify-content-between mb-3 flex-wrap gap-2">
        <h5 class="mb-0 fw-bold"><i class="bi bi-bag-check me-2"></i>Orders Received</h5>
    </div>

    <%-- Status Filter Tabs --%>
    <ul class="nav nav-tabs mb-4" id="orderStatusTabs">
        <% String[] sOrderStatuses = {"All","Pending","Processing","Shipped","Completed","Cancelled"};
           for (String st : sOrderStatuses) { %>
            <li class="nav-item">
                <a class="nav-link <%= st.equals(orderTabFilter) ? "active fw-semibold" : "" %>"
                   href="seller.jsp?tab=orders&orderTab=<%= st %>">
                    <%= st %>
                </a>
            </li>
        <% } %>
    </ul>

    <%-- Orders List --%>
    <% if (sellerOrders.isEmpty()) { %>
        <div class="text-center py-5 text-muted">
            <i class="bi bi-inbox" style="font-size:3rem;"></i>
            <p class="mt-3">No <%= "All".equals(orderTabFilter) ? "" : orderTabFilter %> orders yet.</p>
        </div>
    <% } else {
        for (java.util.Map<String, Object> ord : sellerOrders) {
            String sStatus = (String) ord.get("status");
            String badgeClass = "secondary";
            if ("Pending".equals(sStatus)) badgeClass = "warning text-dark";
            else if ("Processing".equals(sStatus)) badgeClass = "primary";
            else if ("Shipped".equals(sStatus)) badgeClass = "info text-dark";
            else if ("Completed".equals(sStatus)) badgeClass = "success";
            else if ("Cancelled".equals(sStatus)) badgeClass = "danger";
            @SuppressWarnings("unchecked")
            java.util.List<java.util.Map<String, Object>> ordItems =
                (java.util.List<java.util.Map<String, Object>>) ord.get("items");
    %>
    <div class="card mb-3 shadow-sm border-0" style="border-radius:12px; overflow:hidden;">
        <%-- Card Header --%>
        <div class="card-header bg-white d-flex justify-content-between align-items-center py-2 px-3"
             style="border-bottom: 1px solid #f0f0f0;">
            <span class="fw-semibold text-muted" style="font-size:13px;">
                <i class="bi bi-hash"></i>Order #SE-<%= ord.get("id") %>
                <span class="ms-2 text-secondary" style="font-weight:400; font-size:12px;">
                    <%= ord.get("date") != null ? ord.get("date") : "Date not available" %>
                </span>
            </span>
            <span class="badge bg-<%= badgeClass %> px-3 py-1" style="font-size:12px;">
                <%= sStatus %>
            </span>
        </div>

        <div class="card-body px-3 py-3">
            <div class="row g-3">

                <%-- LEFT: Customer Info --%>
                <div class="col-md-4 border-end">
                    <p class="mb-1 fw-semibold" style="font-size:13px; color:#555;">
                        <i class="bi bi-person-circle me-1"></i>Customer
                    </p>
                    <p class="mb-0 fw-bold" style="font-size:14px;"><%= ord.get("buyer_name") %></p>
                    <p class="mb-0 text-muted" style="font-size:12px;"><%= ord.get("buyer_email") %></p>
                    <hr class="my-2">
                    <p class="mb-1 fw-semibold" style="font-size:13px; color:#555;">
                        <i class="bi bi-geo-alt me-1"></i>Delivery Address
                    </p>
                    <% if (ord.get("addr_name") != null) { %>
                        <p class="mb-0" style="font-size:12px;"><%= ord.get("addr_name") %> | <%= ord.get("phone") %></p>
                        <p class="mb-0 text-muted" style="font-size:12px;"><%= ord.get("address") %></p>
                    <% } else { %>
                        <p class="mb-0 text-muted" style="font-size:12px;">No address on file</p>
                    <% } %>
                    <hr class="my-2">
                    <p class="mb-0" style="font-size:12px;">
                        <i class="bi bi-wallet2 me-1"></i>
                        <span class="fw-semibold">Payment:</span> <%= ord.get("payment") %>
                    </p>
                </div>

                <%-- RIGHT: Products + Actions --%>
                <div class="col-md-8">
                    <p class="mb-2 fw-semibold" style="font-size:13px; color:#555;">
                        <i class="bi bi-box-seam me-1"></i>Items Ordered
                    </p>

                    <%-- Product list --%>
                    <% for (java.util.Map<String, Object> itm : ordItems) {
                        String imgUrl = (String) itm.get("image");
                        if (imgUrl == null || imgUrl.isEmpty()) imgUrl = "images/no-image.png";
                    %>
                    <div class="d-flex align-items-center gap-2 mb-2 p-2 rounded"
                         style="background:#f8f9fa;">
                        <img src="<%= imgUrl %>" alt="product"
                             style="width:52px; height:52px; object-fit:cover; border-radius:8px; border:1px solid #e0e0e0;">
                        <div class="flex-grow-1">
                            <p class="mb-0 fw-semibold" style="font-size:13px;"><%= itm.get("pname") %></p>
                            <p class="mb-0 text-muted" style="font-size:12px;">
                                Qty: <%= itm.get("qty") %> &nbsp;|&nbsp;
                                ₱<%= String.format("%.2f", itm.get("subtotal")) %>
                            </p>
                        </div>
                    </div>
                    <% } %>

                    <%-- Total + Actions --%>
                    <div class="d-flex justify-content-between align-items-center mt-3 flex-wrap gap-2">
                        <span class="fw-bold text-success" style="font-size:15px;">
                            Total: ₱<%= String.format("%.2f", ord.get("total")) %>
                        </span>
                        <div class="d-flex gap-2 flex-wrap" id="actions_<%= ord.get("id") %>">
                            <% if ("Pending".equals(sStatus)) { %>
                                <button class="btn btn-primary btn-sm"
                                    onclick="updateOrderStatus(<%= ord.get("id") %>, 'Processing')">
                                    <i class="bi bi-check-circle"></i> Confirm Order
                                </button>
                                <button class="btn btn-outline-danger btn-sm"
                                    onclick="updateOrderStatus(<%= ord.get("id") %>, 'Cancelled')">
                                    <i class="bi bi-x-circle"></i> Cancel
                                </button>
                            <% } else if ("Processing".equals(sStatus)) { %>
                                <button class="btn btn-info btn-sm text-white"
                                    onclick="updateOrderStatus(<%= ord.get("id") %>, 'Shipped')">
                                    <i class="bi bi-truck"></i> Ship Order
                                </button>
                            <% } else if ("Shipped".equals(sStatus)) { %>
                                <button class="btn btn-success btn-sm"
                                    onclick="updateOrderStatus(<%= ord.get("id") %>, 'Completed')">
                                    <i class="bi bi-bag-check"></i> Mark Completed
                                </button>
                            <% } else { %>
                                <span class="text-muted" style="font-size:12px;">
                                    <i class="bi bi-check2-all"></i> <%= sStatus %>
                                </span>
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <% } } %>
</div>

    <div id="tab-sales" class="tab-content-section" style="display:none;">
        <div class="card-section">
            <p class="section-title"><i class="bi bi-graph-up-arrow text-success"></i> Sales & Analytics</p>
            <div class="text-center text-muted py-4">
                <i class="bi bi-bar-chart fs-1 opacity-50"></i>
                <p class="mt-2" style="font-size:13px;">No sales data yet.</p>
            </div>
        </div>
    </div>

    <div id="tab-reviews" class="tab-content-section" style="display:none;">
    <div class="card-section">
        <p class="section-title"><i class="bi bi-star-fill text-success"></i> Customer Reviews</p>
        <%
        boolean hasSellerReviews = false;
        try {
            java.sql.Connection srConn = com.shopeasy.DBConnection.getConnection();
            java.sql.PreparedStatement srPs = srConn.prepareStatement(
                "SELECT r.rating, r.comment, r.photo, p.name AS pname, p.image AS pimage, " +
                "c.name AS cname " +
                "FROM review r " +
                "JOIN product p ON r.product_id = p.product_id " +
                "JOIN customer c ON r.customer_id = c.customer_id " +
                "WHERE p.seller_id = ? ORDER BY r.review_id DESC");
            srPs.setInt(1, (int) session.getAttribute("userId"));
            java.sql.ResultSet srRs = srPs.executeQuery();
            while (srRs.next()) {
                hasSellerReviews = true;
        %>
        <div class="d-flex gap-3 p-3 mb-3 border rounded-3">
            <% if (srRs.getString("pimage") != null && !srRs.getString("pimage").isEmpty()) { %>
                <img src="<%= srRs.getString("pimage") %>"
                     style="width:60px; height:60px; object-fit:cover; border-radius:8px;">
            <% } else { %>
                <div style="width:60px; height:60px; background:#f0f0f0; border-radius:8px;
                     display:flex; align-items:center; justify-content:center;">
                    <i class="bi bi-image text-muted"></i>
                </div>
            <% } %>
            <div class="flex-grow-1">
                <p class="mb-0 fw-bold" style="font-size:14px;"><%= srRs.getString("pname") %></p>
                <p class="mb-0 text-muted" style="font-size:12px;">
                    <i class="bi bi-person-circle"></i> <%= srRs.getString("cname") %>
                </p>
                <div class="my-1">
                    <% for (int s = 1; s <= 5; s++) { %>
                        <i class="bi bi-star-fill"
                           style="color:<%= s <= srRs.getInt("rating") ? "#ffc107" : "#ddd" %>;
                                  font-size:13px;"></i>
                    <% } %>
                </div>
                <p class="mb-1 text-muted" style="font-size:13px;"><%= srRs.getString("comment") %></p>
                <% if (srRs.getString("photo") != null && !srRs.getString("photo").isEmpty()) { %>
                    <img src="<%= srRs.getString("photo") %>"
                         style="width:80px; height:80px; object-fit:cover;
                                border-radius:8px; border:2px solid #eee; margin-top:4px;">
                <% } %>
            </div>
        </div>
        <%
            }
            srRs.close(); srPs.close(); srConn.close();
            if (!hasSellerReviews) {
        %>
        <div class="text-center text-muted py-4">
            <i class="bi bi-star fs-1 opacity-50"></i>
            <p class="mt-2" style="font-size:13px;">No reviews yet.</p>
        </div>
        <% } } catch (Exception ex) { ex.printStackTrace(); } %>
    </div>
</div>

    <div id="tab-security" class="tab-content-section" style="display:none;">
        <div class="card-section">
            <p class="section-title"><i class="bi bi-shield-lock-fill text-success"></i> Security Settings</p>
            <div class="row g-3">
                <div class="col-12">
                    <label class="form-label fw-bold" style="font-size:13px;">Current Password</label>
                    <div class="input-group">
                        <span class="input-group-text"><i class="bi bi-lock"></i></span>
                        <input type="password" id="currentPw" class="form-control" placeholder="Enter current password">
                        <button type="button" class="btn btn-outline-secondary" onclick="togglePassword('currentPw', this)"><i class="bi bi-eye"></i></button>
                    </div>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">New Password</label>
                    <div class="input-group">
                        <span class="input-group-text"><i class="bi bi-lock"></i></span>
                        <input type="password" id="newPw" class="form-control" placeholder="Enter new password" oninput="checkStrength(this.value)">
                        <button type="button" class="btn btn-outline-secondary" onclick="togglePassword('newPw', this)"><i class="bi bi-eye"></i></button>
                    </div>
                    <div id="strengthBar" class="password-strength bg-secondary" style="width:0%"></div>
                    <small id="strengthText" class="text-muted"></small>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">Confirm New Password</label>
                    <div class="input-group">
                        <span class="input-group-text"><i class="bi bi-lock"></i></span>
                        <input type="password" id="confirmPw" class="form-control" placeholder="Confirm new password">
                        <button type="button" class="btn btn-outline-secondary" onclick="togglePassword('confirmPw', this)"><i class="bi bi-eye"></i></button>
                    </div>
                </div>
                <div class="col-12">
                    <button type="button" class="btn btn-success px-4">
                        <i class="bi bi-shield-check"></i> Update Password
                    </button>
                </div>
            </div>
        </div>
    </div>

    <div id="tab-notifications" class="tab-content-section" style="display:none;">
        <div class="card-section">
            <p class="section-title"><i class="bi bi-bell-fill text-success"></i> Notification Settings</p>
            <div class="d-flex flex-column gap-3">
                <div class="d-flex justify-content-between align-items-center p-3 border rounded-3">
                    <div>
                        <p class="mb-0 fw-bold" style="font-size:14px;">New Orders</p>
                        <p class="mb-0 text-muted" style="font-size:12px;">Get notified when you receive a new order</p>
                    </div>
                    <div class="form-check form-switch mb-0">
                        <input class="form-check-input" type="checkbox" checked style="width:40px; height:20px;">
                    </div>
                </div>
                <div class="d-flex justify-content-between align-items-center p-3 border rounded-3">
                    <div>
                        <p class="mb-0 fw-bold" style="font-size:14px;">New Reviews</p>
                        <p class="mb-0 text-muted" style="font-size:12px;">Get notified when a customer leaves a review</p>
                    </div>
                    <div class="form-check form-switch mb-0">
                        <input class="form-check-input" type="checkbox" checked style="width:40px; height:20px;">
                    </div>
                </div>
            </div>
        </div>
    </div>

</div>
    </div>


<!-- TOAST -->
<div id="toast" style="display:none; position:fixed; bottom:24px; right:24px; background:#198754; color:white; padding:12px 20px; border-radius:10px; font-size:14px; z-index:9999; box-shadow:0 4px 12px rgba(0,0,0,0.2);">
    <i class="bi bi-check-circle me-2"></i><span id="toastMsg"></span>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
    // SIDEBAR NAV — hide shop+profile sections, show selected tab
    function showTab(tab, el) {
        // Hide shop and profile sections
        document.getElementById('section-shop').style.display = 'none';
        document.getElementById('section-profile').style.display = 'none';
        // Hide all other tabs
        document.querySelectorAll('.tab-content-section').forEach(t => t.style.display = 'none');
        document.querySelectorAll('.sidebar-nav a').forEach(a => a.classList.remove('active'));

        const otherTab = document.getElementById('tab-' + tab);
        if (otherTab) {
            otherTab.style.display = 'block';
        } else {
            // If no tab found, show shop+profile (home view)
            document.getElementById('section-shop').style.display = 'block';
            document.getElementById('section-profile').style.display = 'block';
        }
        el.classList.add('active');
        event.preventDefault();
    }

    // SHOP EDIT
    function enableShopEdit() {
    document.querySelectorAll('#section-shop input, #section-shop select, #section-shop textarea').forEach(el => el.disabled = false);
    document.getElementById('editShopBtn').style.display = 'none';
    document.getElementById('saveShopBtn').style.display = 'inline-block';
    document.getElementById('cancelShopBtn').style.display = 'inline-block';
    document.getElementById('editBannerBtn').style.display = 'block';
    document.getElementById('removeBannerBtn').style.display = 'block';
}
    function cancelShopEdit() {
        document.querySelectorAll('#section-shop input, #section-shop select, #section-shop textarea').forEach(el => el.disabled = true);
        document.getElementById('editShopBtn').style.display = 'inline-block';
        document.getElementById('saveShopBtn').style.display = 'none';
        document.getElementById('cancelShopBtn').style.display = 'none';
        document.getElementById('editBannerBtn').style.display = 'none';
        // Revert banner preview if not saved
        document.getElementById('bannerData').value = '';
        document.getElementById('removeBannerBtn').style.display = 'none';
        document.getElementById('removeBannerFlag').value = 'false';
    }

    // PROFILE EDIT
    function enableProfileEdit() {
        document.querySelectorAll('#section-profile input, #section-profile select').forEach(el => el.disabled = false);
        document.getElementById('avatarUploadBtn').disabled = false;
        document.getElementById('avatarUploadBtn').style.opacity = '1';
        document.getElementById('editProfileBtn').style.display = 'none';
        document.getElementById('saveProfileBtn').style.display = 'inline-block';
        document.getElementById('cancelProfileBtn').style.display = 'inline-block';
    }
    function cancelProfileEdit() {
        document.querySelectorAll('#section-profile input, #section-profile select').forEach(el => el.disabled = true);
        document.getElementById('avatarUploadBtn').disabled = true;
        document.getElementById('avatarUploadBtn').style.opacity = '0.5';
        document.getElementById('editProfileBtn').style.display = 'inline-block';
        document.getElementById('saveProfileBtn').style.display = 'none';
        document.getElementById('cancelProfileBtn').style.display = 'none';
    }



    function openBannerCrop(input) {
        if (input.files && input.files[0]) {
            const reader = new FileReader();
            reader.onload = function(e) {
                cropTarget = 'banner';
                openBannerCropModal(e.target.result);
            };
            reader.readAsDataURL(input.files[0]);
        }
    }

 // AVATAR CROP - Complete Rewrite
    let cropImg = new Image();
    let cropOffX = 0, cropOffY = 0;
    let cropIsDragging = false;
    let cropStartX, cropStartY;
    let cropScale = 1;
    let cropSize = 300;

    function previewAvatar(input) {
        if (input.files && input.files[0]) {
            const reader = new FileReader();
            reader.onload = function(e) {
                openCropModal(e.target.result);
            };
            reader.readAsDataURL(input.files[0]);
        }
    }

    function openCropModal(src) {
        document.getElementById('cropModal').style.display = 'flex';
        cropScale = 1;
        document.getElementById('cropZoom').value = 1;

        cropImg = new Image();
        cropImg.onload = function() {
            // Auto-fit image to fill the crop circle
            const fitScale = Math.max(cropSize / cropImg.width, cropSize / cropImg.height);
            cropScale = fitScale;
            document.getElementById('cropZoom').min = fitScale;
            document.getElementById('cropZoom').value = fitScale;
            // Center the image
            cropOffX = (cropSize - cropImg.width * cropScale) / 2;
            cropOffY = (cropSize - cropImg.height * cropScale) / 2;
            drawCropCanvas();
        };
        cropImg.src = src;

        const canvas = document.getElementById('cropCanvas');
        canvas.width = cropSize;
        canvas.height = cropSize;

        // Remove old listeners by replacing element
        const newCanvas = canvas.cloneNode(true);
        canvas.parentNode.replaceChild(newCanvas, canvas);
        const c = document.getElementById('cropCanvas');

        c.addEventListener('mousedown', (e) => {
            cropIsDragging = true;
            cropStartX = e.clientX - cropOffX;
            cropStartY = e.clientY - cropOffY;
        });
        c.addEventListener('mousemove', (e) => {
            if (!cropIsDragging) return;
            cropOffX = e.clientX - cropStartX;
            cropOffY = e.clientY - cropStartY;
            clampCrop();
            drawCropCanvas();
        });
        c.addEventListener('mouseup', () => cropIsDragging = false);
        c.addEventListener('mouseleave', () => cropIsDragging = false);

        // Touch support
        c.addEventListener('touchstart', (e) => {
            cropIsDragging = true;
            cropStartX = e.touches[0].clientX - cropOffX;
            cropStartY = e.touches[0].clientY - cropOffY;
        }, {passive:true});
        c.addEventListener('touchmove', (e) => {
            if (!cropIsDragging) return;
            cropOffX = e.touches[0].clientX - cropStartX;
            cropOffY = e.touches[0].clientY - cropStartY;
            clampCrop();
            drawCropCanvas();
        }, {passive:true});
        c.addEventListener('touchend', () => cropIsDragging = false);

        document.getElementById('cropZoom').oninput = function() {
            const oldScale = cropScale;
            cropScale = parseFloat(this.value);
            // Zoom toward center
            cropOffX = cropSize/2 - (cropSize/2 - cropOffX) * (cropScale / oldScale);
            cropOffY = cropSize/2 - (cropSize/2 - cropOffY) * (cropScale / oldScale);
            clampCrop();
            drawCropCanvas();
        };
    }

    function clampCrop() {
        const w = cropImg.width * cropScale;
        const h = cropImg.height * cropScale;
        // Don't let image go past circle edges
        if (cropOffX > 0) cropOffX = 0;
        if (cropOffY > 0) cropOffY = 0;
        if (cropOffX + w < cropSize) cropOffX = cropSize - w;
        if (cropOffY + h < cropSize) cropOffY = cropSize - h;
    }

    function drawCropCanvas() {
        const canvas = document.getElementById('cropCanvas');
        const ctx = canvas.getContext('2d');
        canvas.width = cropSize;
        canvas.height = cropSize;

        // White background
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(0, 0, cropSize, cropSize);

        // Draw image
        ctx.drawImage(cropImg, cropOffX, cropOffY, cropImg.width * cropScale, cropImg.height * cropScale);

        // Draw circle overlay - darken outside
        ctx.save();
        ctx.fillStyle = 'rgba(0,0,0,0.5)';
        ctx.fillRect(0, 0, cropSize, cropSize);
        ctx.globalCompositeOperation = 'destination-out';
        ctx.beginPath();
        ctx.arc(cropSize/2, cropSize/2, cropSize/2 - 2, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();

        // Circle border
        ctx.strokeStyle = '#198754';
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.arc(cropSize/2, cropSize/2, cropSize/2 - 2, 0, Math.PI * 2);
        ctx.stroke();
    }

    function applyCrop() {
        const output = document.createElement('canvas');
        output.width = 300;
        output.height = 300;
        const ctx = output.getContext('2d');

        ctx.beginPath();
        ctx.arc(150, 150, 150, 0, Math.PI * 2);
        ctx.clip();
        ctx.drawImage(cropImg, cropOffX, cropOffY, cropImg.width * cropScale, cropImg.height * cropScale);

        const result = output.toDataURL('image/png');
        document.getElementById('avatarPreview').src = result;
        document.getElementById('sidebarAvatar').src = result;
        document.getElementById('avatarData').value = result;
        closeCropModal();

        document.getElementById('savingOverlay').style.display = 'flex';
        setTimeout(() => {
            document.getElementById('avatarForm').submit();
        }, 1500);
    }
    function closeCropModal() {
        document.getElementById('cropModal').style.display = 'none';
        cropIsDragging = false;
    }

 // BANNER CROP - Fixed
    let bannerImg = new Image();
    let bannerOffX = 0, bannerOffY = 0;
    let bannerIsDragging = false;
    let bannerStartX, bannerStartY;
    let bannerScale = 1;
    const BANNER_W = 1200, BANNER_H = 300;

    function openBannerCrop(input) {
        if (input.files && input.files[0]) {
            const reader = new FileReader();
            reader.onload = function(e) {
                openBannerCropModal(e.target.result);
            };
            reader.readAsDataURL(input.files[0]);
        }
    }

    function openBannerCropModal(src) {
        document.getElementById('bannerCropModal').style.display = 'flex';
        bannerOffX = 0; bannerOffY = 0; bannerScale = 1;

        bannerImg = new Image();
        bannerImg.onload = function() {
            setTimeout(() => {
                const wrapper = document.getElementById('bannerCropWrapper');
                const displayW = wrapper.clientWidth;
                const displayH = Math.round(displayW * (BANNER_H / BANNER_W));

                const canvas = document.getElementById('bannerCropCanvas');
                canvas.width = displayW;
                canvas.height = displayH;
                document.getElementById('bannerCropWrapper').style.height = displayH + 'px';

                const fitScale = Math.max(displayW / bannerImg.width, displayH / bannerImg.height);
                bannerScale = fitScale;
                document.getElementById('bannerCropZoom').min = fitScale;
                document.getElementById('bannerCropZoom').max = fitScale * 3;
                document.getElementById('bannerCropZoom').value = fitScale;

                bannerOffX = (displayW - bannerImg.width * bannerScale) / 2;
                bannerOffY = (displayH - bannerImg.height * bannerScale) / 2;
                clampBanner();
                drawBannerCrop();
            }, 150);
        };
        bannerImg.src = src;

        const canvas = document.getElementById('bannerCropCanvas');
        const newCanvas = canvas.cloneNode(true);
        canvas.parentNode.replaceChild(newCanvas, canvas);
        const c = document.getElementById('bannerCropCanvas');

        c.addEventListener('mousedown', (e) => {
            bannerIsDragging = true;
            bannerStartX = e.clientX - bannerOffX;
            bannerStartY = e.clientY - bannerOffY;
            c.style.cursor = 'grabbing';
        });
        c.addEventListener('mousemove', (e) => {
            if (!bannerIsDragging) return;
            bannerOffX = e.clientX - bannerStartX;
            bannerOffY = e.clientY - bannerStartY;
            clampBanner();
            drawBannerCrop();
        });
        c.addEventListener('mouseup', () => { bannerIsDragging = false; c.style.cursor = 'grab'; });
        c.addEventListener('mouseleave', () => { bannerIsDragging = false; });

        // Touch support for banner
        c.addEventListener('touchstart', (e) => {
            e.preventDefault();
            bannerIsDragging = true;
            bannerStartX = e.touches[0].clientX - bannerOffX;
            bannerStartY = e.touches[0].clientY - bannerOffY;
        }, {passive: false});
        c.addEventListener('touchmove', (e) => {
            e.preventDefault();
            if (!bannerIsDragging) return;
            bannerOffX = e.touches[0].clientX - bannerStartX;
            bannerOffY = e.touches[0].clientY - bannerStartY;
            clampBanner();
            drawBannerCrop();
        }, {passive: false});
        c.addEventListener('touchend', () => bannerIsDragging = false);

        document.getElementById('bannerCropZoom').oninput = function() {
            const oldScale = bannerScale;
            bannerScale = parseFloat(this.value);
            const c2 = document.getElementById('bannerCropCanvas');
            const dW = c2.width;
            const dH = c2.height;
            bannerOffX = dW/2 - (dW/2 - bannerOffX) * (bannerScale / oldScale);
            bannerOffY = dH/2 - (dH/2 - bannerOffY) * (bannerScale / oldScale);
            clampBanner();
            drawBannerCrop();
        };
    }

    function clampBanner() {
        const canvas = document.getElementById('bannerCropCanvas');
        const displayW = canvas.width;
        const displayH = canvas.height;
        const w = bannerImg.width * bannerScale;
        const h = bannerImg.height * bannerScale;
        if (bannerOffX > 0) bannerOffX = 0;
        if (bannerOffY > 0) bannerOffY = 0;
        if (bannerOffX + w < displayW) bannerOffX = displayW - w;
        if (bannerOffY + h < displayH) bannerOffY = displayH - h;
    }

    function drawBannerCrop() {
        const canvas = document.getElementById('bannerCropCanvas');
        const ctx = canvas.getContext('2d');
        const displayW = canvas.width;
        const displayH = canvas.height;

        ctx.fillStyle = '#f0f0f0';
        ctx.fillRect(0, 0, displayW, displayH);
        ctx.drawImage(bannerImg, bannerOffX, bannerOffY,
            bannerImg.width * bannerScale, bannerImg.height * bannerScale);

        ctx.strokeStyle = 'rgba(255,255,255,0.9)';
        ctx.lineWidth = 2;
        ctx.setLineDash([8, 4]);
        ctx.strokeRect(2, 2, displayW - 4, displayH - 4);
        ctx.setLineDash([]);
    }
    

    function applyBannerCrop() {
        const canvas = document.getElementById('bannerCropCanvas');
        const output = document.createElement('canvas');
        output.width = BANNER_W;
        output.height = BANNER_H;
        const ctx = output.getContext('2d');

        const scaleX = BANNER_W / canvas.width;
        const scaleY = BANNER_H / canvas.height;

        ctx.drawImage(bannerImg,
            -bannerOffX / bannerScale,
            -bannerOffY / bannerScale,
            bannerImg.width,
            bannerImg.height,
            0, 0,
            bannerImg.width * bannerScale * scaleX,
            bannerImg.height * bannerScale * scaleY
        );

        const result = output.toDataURL('image/png');
        document.getElementById('bannerData').value = result;
        document.getElementById('editBannerBtn').style.display = 'block';
        document.getElementById('removeBannerBtn').style.display = 'block';
        closeBannerCropModal();

        document.getElementById('savingOverlay').style.display = 'flex';
        setTimeout(() => {
            document.getElementById('bannerForm').submit();
        }, 1500);
    }
    function closeBannerCropModal() {
        document.getElementById('bannerCropModal').style.display = 'none';
        bannerIsDragging = false;
    }


    // PASSWORD TOGGLE
    function togglePassword(fieldId, btn) {
        const field = document.getElementById(fieldId);
        const icon = btn.querySelector('i');
        if (field.type === 'password') { field.type = 'text'; icon.className = 'bi bi-eye-slash'; }
        else { field.type = 'password'; icon.className = 'bi bi-eye'; }
    }

    // PASSWORD STRENGTH
    function checkStrength(val) {
        const bar = document.getElementById('strengthBar');
        const text = document.getElementById('strengthText');
        if (val.length === 0) { bar.style.width = '0%'; text.textContent = ''; return; }
        if (val.length < 6) { bar.style.width = '25%'; bar.className = 'password-strength bg-danger'; text.textContent = 'Weak'; text.className = 'text-danger'; }
        else if (val.length < 10) { bar.style.width = '60%'; bar.className = 'password-strength bg-warning'; text.textContent = 'Medium'; text.className = 'text-warning'; }
        else { bar.style.width = '100%'; bar.className = 'password-strength bg-success'; text.textContent = 'Strong'; text.className = 'text-success'; }
    }

    // GREEN BAR on page load
window.addEventListener('load', function() {
    const params = new URLSearchParams(window.location.search);
    
    if (params.get('updated') === 'true') {
        const msg = params.get('msg');
        document.getElementById('successBarMsg').textContent = 
            msg === 'banner' ? 'Banner updated successfully! ✅' :
            msg === 'profile' ? 'Profile saved successfully! ✅' :
            msg === 'avatar' ? 'Profile picture updated! ✅' :
            msg === 'product' ? 'Product saved successfully! ✅' :
            msg === 'deleted' ? 'Product deleted! ✅' :
            'Saved successfully! ✅';
        document.getElementById('successBar').style.display = 'block';
        setTimeout(() => { document.getElementById('successBar').style.display = 'none'; }, 3000);
        window.history.replaceState({}, '', 'seller.jsp');
    }

    const tab = params.get('tab');
    if (tab === 'orders') {
        document.getElementById('section-shop').style.display = 'none';
        document.getElementById('section-profile').style.display = 'none';
        const ordersTab = document.getElementById('tab-orders');
        if (ordersTab) ordersTab.style.display = 'block';
    } else if (tab) {
        setTimeout(() => {
            const link = document.querySelector('.sidebar-nav a[onclick*="' + tab + '"]');
            if (link) link.click();
        }, 100);
    }
});
    function doLogout() {
        if (!confirm('Are you sure you want to logout?')) return;
        document.getElementById('logoutOverlay').style.display = 'flex';
        setTimeout(() => { window.location.href = 'LogoutServlet'; }, 1500);
    }
    
    document.getElementById('profileForm').addEventListener('submit', function(e) {
        e.preventDefault();
        document.getElementById('savingOverlay').style.display = 'flex';
        setTimeout(() => { this.submit(); }, 1500);
    });

    document.querySelector('form[action="UpdateSellerServlet"]').addEventListener('submit', function(e) {
        e.preventDefault();
        document.getElementById('savingOverlay').style.display = 'flex';
        setTimeout(() => { this.submit(); }, 1500);
    });

    document.getElementById('productForm').addEventListener('submit', function(e) {
        document.getElementById('savingOverlay').style.display = 'flex';
    });
    
    function removeBanner() {
        if (!confirm('Remove banner photo?')) return;
        document.getElementById('bannerData').value = '';
        document.getElementById('removeBannerFlag').value = 'true';
        document.getElementById('removeBannerBtn').style.display = 'none';
        document.getElementById('savingOverlay').style.display = 'flex';
        setTimeout(() => {
            document.getElementById('bannerForm').submit();
        }, 1500);
    }
    
    function showAddProduct() {
        document.getElementById('addProductForm').style.display = 'block';
        document.getElementById('noProductsMsg').style.display = 'none';
    }
    function hideAddProduct() {
        document.getElementById('addProductForm').style.display = 'none';
        document.getElementById('noProductsMsg').style.display = 'block';
    }
    let productCropImg = new Image();
    let productCropOffX = 0, productCropOffY = 0;
    let productCropIsDragging = false;
    let productCropStartX, productCropStartY;
    let productCropScale = 1;
    const PRODUCT_SIZE = 600;

    function openProductCropModal(input) {
        if (input.files && input.files[0]) {
            const reader = new FileReader();
            reader.onload = function(e) {
                document.getElementById('productCropModal').style.display = 'flex';
                productCropScale = 1;
                document.getElementById('productCropZoom').value = 1;

                productCropImg = new Image();
                productCropImg.onload = function() {
                    const fitScale = Math.max(PRODUCT_SIZE / productCropImg.width, PRODUCT_SIZE / productCropImg.height);
                    productCropScale = fitScale;
                    document.getElementById('productCropZoom').min = fitScale;
                    document.getElementById('productCropZoom').value = fitScale;
                    productCropOffX = (PRODUCT_SIZE - productCropImg.width * productCropScale) / 2;
                    productCropOffY = (PRODUCT_SIZE - productCropImg.height * productCropScale) / 2;
                    drawProductCropCanvas();
                };
                productCropImg.src = e.target.result;

                const canvas = document.getElementById('productCropCanvas');
                canvas.width = PRODUCT_SIZE;
                canvas.height = PRODUCT_SIZE;

                const newCanvas = canvas.cloneNode(true);
                canvas.parentNode.replaceChild(newCanvas, canvas);
                const c = document.getElementById('productCropCanvas');

                c.addEventListener('mousedown', (e) => {
                    productCropIsDragging = true;
                    productCropStartX = e.clientX - productCropOffX;
                    productCropStartY = e.clientY - productCropOffY;
                });
                c.addEventListener('mousemove', (e) => {
                    if (!productCropIsDragging) return;
                    productCropOffX = e.clientX - productCropStartX;
                    productCropOffY = e.clientY - productCropStartY;
                    clampProductCrop();
                    drawProductCropCanvas();
                });
                c.addEventListener('mouseup', () => productCropIsDragging = false);
                c.addEventListener('mouseleave', () => productCropIsDragging = false);
                c.addEventListener('touchstart', (e) => {
                    productCropIsDragging = true;
                    productCropStartX = e.touches[0].clientX - productCropOffX;
                    productCropStartY = e.touches[0].clientY - productCropOffY;
                }, {passive: true});
                c.addEventListener('touchmove', (e) => {
                    if (!productCropIsDragging) return;
                    productCropOffX = e.touches[0].clientX - productCropStartX;
                    productCropOffY = e.touches[0].clientY - productCropStartY;
                    clampProductCrop();
                    drawProductCropCanvas();
                }, {passive: true});
                c.addEventListener('touchend', () => productCropIsDragging = false);

                document.getElementById('productCropZoom').oninput = function() {
                    const oldScale = productCropScale;
                    productCropScale = parseFloat(this.value);
                    productCropOffX = PRODUCT_SIZE/2 - (PRODUCT_SIZE/2 - productCropOffX) * (productCropScale / oldScale);
                    productCropOffY = PRODUCT_SIZE/2 - (PRODUCT_SIZE/2 - productCropOffY) * (productCropScale / oldScale);
                    clampProductCrop();
                    drawProductCropCanvas();
                };
            };
            reader.readAsDataURL(input.files[0]);
        }
    }

    function clampProductCrop() {
        const w = productCropImg.width * productCropScale;
        const h = productCropImg.height * productCropScale;
        if (productCropOffX > 0) productCropOffX = 0;
        if (productCropOffY > 0) productCropOffY = 0;
        if (productCropOffX + w < PRODUCT_SIZE) productCropOffX = PRODUCT_SIZE - w;
        if (productCropOffY + h < PRODUCT_SIZE) productCropOffY = PRODUCT_SIZE - h;
    }

    function drawProductCropCanvas() {
        const canvas = document.getElementById('productCropCanvas');
        const ctx = canvas.getContext('2d');
        canvas.width = PRODUCT_SIZE;
        canvas.height = PRODUCT_SIZE;
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(0, 0, PRODUCT_SIZE, PRODUCT_SIZE);
        ctx.drawImage(productCropImg, productCropOffX, productCropOffY,
            productCropImg.width * productCropScale, productCropImg.height * productCropScale);
        ctx.strokeStyle = '#198754';
        ctx.lineWidth = 3;
        ctx.setLineDash([8, 4]);
        ctx.strokeRect(2, 2, PRODUCT_SIZE - 4, PRODUCT_SIZE - 4);
        ctx.setLineDash([]);
    }

    function applyProductCrop() {
        const canvas = document.getElementById('productCropCanvas');
        const output = document.createElement('canvas');
        output.width = PRODUCT_SIZE;
        output.height = PRODUCT_SIZE;
        const ctx = output.getContext('2d');
        ctx.drawImage(productCropImg, productCropOffX, productCropOffY,
            productCropImg.width * productCropScale, productCropImg.height * productCropScale);
        const result = output.toDataURL('image/jpeg', 0.85);
        document.getElementById('productImgPreview').src = result;
        document.getElementById('productImagePreview').style.display = 'block';
        document.getElementById('productImageData').value = result;
        closeProductCropModal();
    }

    function closeProductCropModal() {
        document.getElementById('productCropModal').style.display = 'none';
        productCropIsDragging = false;
    }
    
    
    function deleteProduct(id, name) {
        if (!confirm('Delete "' + name + '"?')) return;
        document.getElementById('savingOverlay').style.display = 'flex';
        window.location.href = 'DeleteProductServlet?productId=' + id + '&tab=products&msg=deleted';
    }

    function editProduct(id, name, price, stock, description, category) {
        document.getElementById('editProductId').value = id;
        document.getElementById('editProductName').value = name;
        document.getElementById('editProductPrice').value = price;
        document.getElementById('editProductStock').value = stock;
        document.getElementById('editProductDesc').value = description;
        document.getElementById('editProductModal').style.display = 'flex';
    }
    function closeEditModal() {
        document.getElementById('editProductModal').style.display = 'none';
    }
    function updateOrderStatus(orderId, newStatus) {
        const actionLabels = {
            'Processing': 'Confirm this order?',
            'Shipped': 'Mark this order as Shipped?',
            'Completed': 'Mark this order as Completed?',
            'Cancelled': 'Cancel this order?'
        };
        if (!confirm(actionLabels[newStatus] || 'Update order status?')) return;

        fetch('UpdateOrderServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'orderId=' + orderId + '&status=' + encodeURIComponent(newStatus)
        })
        .then(res => res.text())
        .then(() => {
            // Show success bar
            document.getElementById('successBarMsg').textContent = 'Order status updated to ' + newStatus + '! ✅';
            document.getElementById('successBar').style.display = 'block';
            setTimeout(() => {
                document.getElementById('successBar').style.display = 'none';
                location.reload();
            }, 1500);
        })
        .catch(err => alert('Error updating order: ' + err));
    }
</script>

<!-- LOGOUT OVERLAY -->
<div id="logoutOverlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.9); z-index:9999; flex-direction:column; align-items:center; justify-content:center;">
    <div class="spinner-border text-success mb-3" style="width:3rem; height:3rem;" role="status"></div>
    <p class="fw-bold text-success fs-5">Logging out...</p>
</div>

<!-- CROP MODAL FOR AVATAR -->
<div class="crop-modal-overlay" id="cropModal">
    <div class="crop-container">
        <p class="fw-bold mb-3 text-center" style="font-size:15px;"><i class="bi bi-crop text-success"></i> Crop Profile Photo</p>
        
        <div class="crop-canvas-wrapper" id="cropWrapper" style="width:300px; height:300px; margin:0 auto; overflow:hidden; border-radius:8px;">
    <canvas id="cropCanvas"></canvas>
    <div class="crop-preview-circle" id="cropCircle" style="display:none;"></div>
</div>
        <div class="mt-3 d-flex justify-content-between align-items-center">
            <div>
                <label style="font-size:12px;" class="text-muted">Zoom</label>
                <input type="range" id="cropZoom" min="0.5" max="3" step="0.01" value="1" style="width:120px;">
            </div>
            <div class="d-flex gap-2">
                <button class="btn btn-outline-secondary btn-sm" onclick="closeCropModal()">
                    <i class="bi bi-x"></i> Cancel
                </button>
                <button class="btn btn-success btn-sm" onclick="applyCrop()">
                    <i class="bi bi-check2"></i> Apply
                </button>
            </div>
        </div>
    </div>
</div>

<!-- CROP MODAL FOR BANNER -->
<div class="crop-modal-overlay" id="bannerCropModal">
    <div class="crop-container" style="max-width:700px; width:95%;">
        <p class="fw-bold mb-3 text-center" style="font-size:15px;"><i class="bi bi-crop text-success"></i> Crop Banner Photo</p>
        <div class="crop-canvas-wrapper" id="bannerCropWrapper" style="width:100%; background:#f0f0f0; overflow:hidden;">
    <canvas id="bannerCropCanvas" style="display:block; width:100%;"></canvas>
</div>
        <div class="mt-3 d-flex justify-content-between align-items-center">
            <div>
                <label style="font-size:12px;" class="text-muted">Zoom</label>
                <input type="range" id="bannerCropZoom" min="0.5" max="3" step="0.01" value="1" style="width:120px;">
            </div>
            <div class="d-flex gap-2">
                <button class="btn btn-outline-secondary btn-sm" onclick="closeBannerCropModal()">
                    <i class="bi bi-x"></i> Cancel
                </button>
                <button class="btn btn-success btn-sm" onclick="applyBannerCrop()">
                    <i class="bi bi-check2"></i> Apply
                </button>
            </div>
        </div>
    </div>
</div>

<!-- HIDDEN FILE INPUTS -->
<input type="file" id="bannerInput" style="display:none" accept="image/*" onchange="openBannerCrop(this)">


<!-- SAVING OVERLAY -->
<div id="savingOverlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.9); z-index:9998; flex-direction:column; align-items:center; justify-content:center;">
    <div class="spinner-border text-success mb-3" style="width:3rem; height:3rem;" role="status"></div>
    <p class="fw-bold text-success fs-5">Saving...</p>
</div>

<!-- CROP MODAL FOR PRODUCT IMAGE -->
<div class="crop-modal-overlay" id="productCropModal">
    <div class="crop-container">
        <p class="fw-bold mb-3 text-center" style="font-size:15px;"><i class="bi bi-crop text-success"></i> Crop Product Image</p>
        <div class="crop-canvas-wrapper" id="productCropWrapper" style="width:300px; height:300px; margin:0 auto; overflow:hidden; border-radius:8px;">
            <canvas id="productCropCanvas"></canvas>
        </div>
        <div class="mt-3 d-flex justify-content-between align-items-center">
            <div>
                <label style="font-size:12px;" class="text-muted">Zoom</label>
                <input type="range" id="productCropZoom" min="0.5" max="3" step="0.01" value="1" style="width:120px;">
            </div>
            <div class="d-flex gap-2">
                <button class="btn btn-outline-secondary btn-sm" onclick="closeProductCropModal()">
                    <i class="bi bi-x"></i> Cancel
                </button>
                <button class="btn btn-success btn-sm" onclick="applyProductCrop()">
                    <i class="bi bi-check2"></i> Apply
                </button>
            </div>
        </div>
    </div>
</div>
<!-- EDIT PRODUCT MODAL -->
<div id="editProductModal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.5); z-index:9999; align-items:center; justify-content:center;">
    <div style="background:white; border-radius:16px; padding:24px; width:90%; max-width:500px;">
        <p class="fw-bold mb-3"><i class="bi bi-pencil-fill text-success"></i> Edit Product</p>
        <form action="EditProductServlet" method="post">
            <input type="hidden" name="productId" id="editProductId">
            <div class="row g-3">
                <div class="col-12">
                    <label class="form-label fw-bold" style="font-size:13px;">Product Name</label>
                    <input type="text" name="productName" id="editProductName" class="form-control" required>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">Price (₱)</label>
                    <input type="number" name="price" id="editProductPrice" class="form-control" step="0.01" min="0" required>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">Stock</label>
                    <input type="number" name="stock" id="editProductStock" class="form-control" min="0" required>
                </div>
                <div class="col-12">
                    <label class="form-label fw-bold" style="font-size:13px;">Description</label>
                    <textarea name="description" id="editProductDesc" class="form-control" rows="3"></textarea>
                </div>
                <div class="col-12 d-flex gap-2 justify-content-end">
                    <button type="button" class="btn btn-outline-secondary" onclick="closeEditModal()">Cancel</button>
                    <button type="submit" class="btn btn-success px-4">Save Changes</button>
                </div>
            </div>
        </form>
    </div>
</div>

</body>
</html>