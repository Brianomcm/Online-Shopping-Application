<%@ page session="true" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Connection, java.sql.PreparedStatement, java.sql.ResultSet, com.shopeasy.DBConnection" %>
<%
    if(session.getAttribute("userId") == null) {
        response.sendRedirect("index.jsp");
        return;
    }
String sellerUserRole = (String) session.getAttribute("userRole");
if (sellerUserRole == null) sellerUserRole = "customer";
// If session says customer but DB says both/seller, refresh from DB
if ("customer".equals(sellerUserRole)) {
    try {
        java.sql.Connection roleConn = com.shopeasy.DBConnection.getConnection();
        java.sql.PreparedStatement rolePs = roleConn.prepareStatement("SELECT role FROM users WHERE user_id = ?");
        rolePs.setInt(1, (int) session.getAttribute("userId"));
        java.sql.ResultSet roleRs = rolePs.executeQuery();
        if (roleRs.next()) sellerUserRole = roleRs.getString("role");
        roleRs.close(); rolePs.close(); roleConn.close();
        session.setAttribute("userRole", sellerUserRole);
    } catch (Exception ex) { ex.printStackTrace(); }
}
if (!"seller".equals(sellerUserRole) && !"both".equals(sellerUserRole)) {
    response.sendRedirect("customer.jsp");
    return;
}
   
    String sellerName = (String) session.getAttribute("userName");
    String sellerEmail = (String) session.getAttribute("userEmail");
    String sellerPhone = (String) session.getAttribute("userPhone");
    String sellerUsername = (String) session.getAttribute("userUsername");
    String sellerBusinessName = (String) session.getAttribute("userBusinessName");
    if (sellerBusinessName == null) sellerBusinessName = "";
   
    String sellerBizNameEncoded = sellerBusinessName.replace(" ", "+");
    String sellerBusinessType = (String) session.getAttribute("userBusinessType");
    String sellerShopDescription = (String) session.getAttribute("shopDescription");
    String sellerShopAddress = (String) session.getAttribute("shopLocation");

    // Load from DB if session is empty
    if ((sellerShopDescription == null || sellerShopDescription.isEmpty()) ||
        (sellerBusinessType == null || sellerBusinessType.isEmpty())) {
        try {
            java.sql.Connection loadConn = com.shopeasy.DBConnection.getConnection();
            java.sql.PreparedStatement loadPs = loadConn.prepareStatement(
                "SELECT business_type, shop_description, shop_location FROM seller WHERE user_id=?");
            loadPs.setInt(1, (int) session.getAttribute("userId"));
            java.sql.ResultSet loadRs = loadPs.executeQuery();
            if (loadRs.next()) {
                if (sellerBusinessType == null || sellerBusinessType.isEmpty())
                    sellerBusinessType = loadRs.getString("business_type");
                if (sellerShopDescription == null || sellerShopDescription.isEmpty())
                    sellerShopDescription = loadRs.getString("shop_description");
                if (sellerShopAddress == null || sellerShopAddress.isEmpty())
                    sellerShopAddress = loadRs.getString("shop_location");
            }
            loadRs.close(); loadPs.close(); loadConn.close();
        } catch (Exception ex) { ex.printStackTrace(); }
    }
    if (sellerShopDescription == null) sellerShopDescription = "";
    if (sellerShopAddress == null) sellerShopAddress = "";
    if (sellerBusinessType == null) sellerBusinessType = "";
    String sellerPicture = (String) session.getAttribute("userProfilePicture");
    if (sellerPicture == null || sellerPicture.isEmpty()) {
        sellerPicture = (String) session.getAttribute("userAvatar");
    }
    String sellerBanner = (String) session.getAttribute("userBannerPicture");
    String sellerShopLogo = (String) session.getAttribute("userShopLogo");
    if (sellerShopLogo == null) sellerShopLogo = "";
 // Load shop_logo from DB if session is empty
    if (sellerShopLogo.isEmpty()) {
        try {
            java.sql.Connection logoConn = com.shopeasy.DBConnection.getConnection();
            java.sql.PreparedStatement logoPs = logoConn.prepareStatement(
                "SELECT shop_logo FROM seller WHERE user_id=?");
            logoPs.setInt(1, (int) session.getAttribute("userId"));
            java.sql.ResultSet logoRs = logoPs.executeQuery();
            if (logoRs.next() && logoRs.getString("shop_logo") != null) {
                sellerShopLogo = logoRs.getString("shop_logo");
                session.setAttribute("userShopLogo", sellerShopLogo);
            }
            logoRs.close(); logoPs.close(); logoConn.close();
        } catch (Exception ex) { ex.printStackTrace(); }
    }
    

    if(sellerName == null) sellerName = "";
    if(sellerEmail == null) sellerEmail = "";
    if(sellerPhone == null) sellerPhone = "";
    if(sellerUsername == null) sellerUsername = "";
    if(sellerBusinessName == null) sellerBusinessName = "";
    if(sellerBusinessType == null) sellerBusinessType = "";
    if(sellerBanner == null) sellerBanner = "";
%>

 <%
    int sellerUnreadCount = 0;
    java.text.SimpleDateFormat sellerNotifSdf = new java.text.SimpleDateFormat("MMM d, yyyy h:mm a");
    sellerNotifSdf.setTimeZone(java.util.TimeZone.getTimeZone("Asia/Manila"));
    java.util.List<java.util.Map<String, Object>> sellerNotifList = new java.util.ArrayList<>();
    try {
        int sellerNotifId = (int) session.getAttribute("userId");
        java.sql.Connection sellerNotifConn = com.shopeasy.DBConnection.getConnection();
        java.sql.PreparedStatement sellerNotifPs = sellerNotifConn.prepareStatement(
            "SELECT * FROM notifications WHERE user_id=? AND user_type='seller' ORDER BY created_at DESC LIMIT 50");
        sellerNotifPs.setInt(1, sellerNotifId);
        java.sql.ResultSet sellerNotifRs = sellerNotifPs.executeQuery();
        while (sellerNotifRs.next()) {
            java.util.Map<String, Object> n = new java.util.HashMap<>();
            n.put("id", sellerNotifRs.getInt("notif_id"));
            n.put("message", sellerNotifRs.getString("message"));
            n.put("isRead", sellerNotifRs.getInt("is_read") == 1);
            n.put("createdAt", sellerNotifSdf.format(sellerNotifRs.getTimestamp("created_at")));
            sellerNotifList.add(n);
            if (sellerNotifRs.getInt("is_read") == 0) sellerUnreadCount++;
        }
        sellerNotifRs.close(); sellerNotifPs.close(); sellerNotifConn.close();
    } catch (Exception ex) { ex.printStackTrace(); }
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
  
.navbar-shopeasy { z-index: 100 !important; }

        body { background: #eef1f7; }
.sidebar {
    background: white;
    border-radius: 20px;
    box-shadow: 0 4px 24px rgba(0,0,0,0.08);
    padding: 24px 0;
    position: sticky;
    top: 20px;
    overflow: hidden;
}
.sidebar-avatar {
    width: 80px; height: 80px;
    border-radius: 50%;
    object-fit: cover;
    border: 3px solid white;
    box-shadow: 0 4px 12px rgba(25,135,84,0.3);
}
.sidebar-nav a {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 11px 24px;
    color: #555;
    text-decoration: none;
    font-size: 14px;
    transition: 0.2s;
    border-left: 3px solid transparent;
}
.sidebar-nav a:hover, .sidebar-nav a.active {
    background: linear-gradient(90deg, #e8f5e9, #f0fff4);
    color: #198754;
    border-left-color: #198754;
    font-weight: 600;
}
.sidebar-nav a i { font-size: 16px; width: 20px; }
.card-section {
    background: white;
    border-radius: 20px;
    box-shadow: 0 4px 24px rgba(0,0,0,0.07);
    padding: 28px;
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
    border: 3px solid white;
    box-shadow: 0 4px 12px rgba(25,135,84,0.25);
}
.avatar-upload .upload-btn {
    position: absolute;
    bottom: 2px; right: 2px;
    background: #198754;
    color: white;
    border: 2px solid white;
    border-radius: 50%;
    width: 30px; height: 30px;
    font-size: 12px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 2px 8px rgba(0,0,0,0.2);
    transition: 0.2s;
}
.avatar-upload .upload-btn:hover { background: #157347; transform: scale(1.1); }
.stat-box {
    background: linear-gradient(135deg, #f0fff4, #e8f5e9);
    border-radius: 16px;
    padding: 16px;
    text-align: center;
    border: 1px solid #c8e6c9;
    transition: 0.2s;
}
.stat-box:hover { transform: translateY(-2px); box-shadow: 0 4px 16px rgba(25,135,84,0.12); }
.stat-box .stat-num { font-size: 26px; font-weight: 800; color: #198754; }
.stat-box .stat-label { font-size: 12px; color: #666; font-weight: 500; }
       .product-row {
    border: 1px solid #e8f5e9;
    border-radius: 14px;
    padding: 16px;
    margin-bottom: 12px;
    transition: 0.2s;
    background: #fafffe;
}
.product-row:hover { box-shadow: 0 4px 16px rgba(25,135,84,0.1); border-color: #a5d6a7; }
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
<nav class="navbar navbar-light navbar-shopeasy py-2 mb-4 shadow-sm sticky-top bg-white">
    <div class="container-fluid px-4">
        <a class="navbar-brand fw-bold text-success" href="index.jsp" style="font-size:1.5rem;">
            <i class="bi bi-bag-heart-fill"></i> ShopEasy
        </a>
        <div class="d-flex align-items-center gap-3">
      <a href="index.jsp" class="btn btn-outline-secondary d-flex align-items-center gap-1">
    <i class="bi bi-house"></i> Home
</a>
<a href="SellerPageServlet?id=<%= (Integer) session.getAttribute("sellerId") %>" 
   class="btn btn-outline-success d-flex align-items-center gap-1">
    <i class="bi bi-shop"></i> View My Shop
</a>
            <!-- PROFILE DROPDOWN -->
            <div class="dropdown">
                <button class="btn btn-light border d-flex align-items-center gap-2 px-2 py-1 rounded-pill" 
                        type="button" data-bs-toggle="dropdown" aria-expanded="false" style="font-size:13px;">
                    <%
                    String sellerNavAvatar = (sellerPicture != null && !sellerPicture.isEmpty()) ? sellerPicture : (String) session.getAttribute("userAvatar");
                        String sellerNavName = (String) session.getAttribute("userName");
                        String sellerNavInitial = (sellerNavName != null && !sellerNavName.isEmpty()) ? String.valueOf(sellerNavName.charAt(0)).toUpperCase() : "S";
                        if (sellerNavAvatar != null && !sellerNavAvatar.isEmpty()) {
                    %>
                        <img src="<%= sellerNavAvatar %>" style="width:28px; height:28px; border-radius:50%; object-fit:cover;">
                    <% } else { %>
                       <div style="width:28px; height:28px; border-radius:50%; background:#0d6efd; color:white; font-size:12px; font-weight:700; display:flex; align-items:center; justify-content:center;"><%= sellerNavInitial %></div>
                    <% } %>
                 <span class="d-none d-sm-inline fw-semibold"><%= (sellerNavName != null && !sellerNavName.isEmpty()) ? sellerNavName.split(" ")[0] : "Me" %></span>
                    <i class="bi bi-chevron-down" style="font-size:10px;"></i>
                </button>
               <ul class="dropdown-menu dropdown-menu-end shadow border-0" style="min-width:220px; border-radius:12px; margin-top:6px;">
                    <li class="px-3 py-2 border-bottom">
                        <div class="d-flex align-items-center gap-2">
                            <% if (sellerPicture != null && !sellerPicture.isEmpty()) { %>
                                <img src="<%= sellerPicture %>" style="width:38px; height:38px; border-radius:50%; object-fit:cover; flex-shrink:0;">
                            <% } else { %>
                                <div style="width:38px; height:38px; border-radius:50%; background:#0d6efd; color:white; font-size:14px; font-weight:700; display:flex; align-items:center; justify-content:center; flex-shrink:0;">  
                                    <%= sellerName != null && !sellerName.isEmpty() ? String.valueOf(sellerName.charAt(0)).toUpperCase() : "S" %>
                                </div>
                            <% } %>
                            <div>
                                <p class="mb-0 fw-bold" style="font-size:13px;"><%= sellerName %></p>
                                <p class="mb-0 text-muted" style="font-size:11px;"><%= sellerEmail %></p>
                            </div>
                        </div>
                    </li>
                 <li><a class="dropdown-item py-2" href="seller.jsp?tab=sales" style="font-size:13px;"><i class="bi bi-speedometer2 me-2 text-success"></i>Dashboard</a></li>
                    <li><a class="dropdown-item py-2" href="seller.jsp?tab=products" style="font-size:13px;"><i class="bi bi-box me-2 text-success"></i>Manage Products</a></li>
                    <li><a class="dropdown-item py-2" href="seller.jsp?tab=orders" style="font-size:13px;"><i class="bi bi-bag me-2 text-success"></i>Orders</a></li>
                    <li><a class="dropdown-item py-2" href="seller.jsp" style="font-size:13px;"><i class="bi bi-shop-window me-2 text-success"></i>Shop Settings</a></li>
                    <li><hr class="dropdown-divider my-1"></li>
                    <li>
                        <a class="dropdown-item py-2 text-primary fw-semibold" href="index.jsp" style="font-size:13px;">
                            <i class="bi bi-house me-2"></i>Back to Shopping
                        </a>
                    </li>
                    <li><hr class="dropdown-divider my-1"></li>
                    <li>
                        <a class="dropdown-item py-2 text-danger" href="#" onclick="doLogout()" style="font-size:13px;">
                            <i class="bi bi-box-arrow-right me-2"></i>Logout
                        </a>
                    </li>
                </ul>
            </div>
        </div>
    </div>
</nav>

<div class="container pb-5">
    <div class="row g-4">

        <!-- SIDEBAR -->
        <div class="col-md-3">
            <div class="sidebar">
                <div class="text-center px-3 mb-3">
        <div style="display:inline-block;">
    <%
        String sidebarAvatarSrc = !sellerShopLogo.isEmpty() ? sellerShopLogo
            : "https://ui-avatars.com/api/?name=" + sellerBizNameEncoded + "&background=198754&color=fff&size=80";
    %>
    <img src="<%= sidebarAvatarSrc %>" 
         class="sidebar-avatar mb-2" alt="Avatar" id="sidebarAvatar">
</div>
                    <p class="fw-bold mb-0" style="font-size:15px;"><%= sellerBusinessName.isEmpty() ? sellerName : sellerBusinessName %></p>
                    <p class="text-muted mb-0" style="font-size:12px;"><%= sellerEmail %></p>
                    <span class="badge bg-success mt-1" style="font-size:10px;">Seller</span>
                </div>
                <hr class="mx-3">
                <div class="sidebar-nav">
                <a href="#" class="<%= request.getParameter("tab") == null ? "active" : "" %>" onclick="showTab('home', this)">
    <i class="bi bi-shop-window"></i> Shop Settings
</a>

                    <a href="#" onclick="showTab('products', this)">
                        <i class="bi bi-grid"></i> My Products
                    </a>
                    <a href="seller.jsp?tab=orders&orderTab=All"
   class="<%= "orders".equals(request.getParameter("tab")) ? "active" : "" %>">
    <i class="bi bi-bag"></i> Orders Received
</a>
                   <a href="#" onclick="showTab('sales', this)">
                        <i class="bi bi-speedometer2"></i> Dashboard
                    </a>
                    <a href="#" onclick="showTab('reviews', this)">
                        <i class="bi bi-star"></i> Reviews
                    </a>
                  
                 <a href="#" onclick="showTab('notifications', this)">
                        <i class="bi bi-bell"></i> Notifications
                        <% if (sellerUnreadCount > 0) { %>
                        <span class="badge bg-danger ms-auto" style="font-size:10px;"><%= sellerUnreadCount %></span>
                        <% } %>
                    </a>
                    <a href="#" onclick="showTab('payout', this)">
                        <i class="bi bi-wallet2"></i> Payout
                    </a>
                </div>
            </div>
        </div>

        <!-- MAIN CONTENT -->
<div class="col-md-9">

    <!-- STATS ROW -->
    <%
    int sellerStatProducts = 0, sellerStatOrders = 0;
    int sellerStatPending = 0, sellerStatLowStock = 0, sellerStatCompleted = 0;
    double sellerStatRevenue = 0;
    try {
    	int sUserId = (int) session.getAttribute("userId");
    	// Get actual seller_id from DB
    	int sId = sUserId; // fallback
    	java.sql.PreparedStatement sIdPs = com.shopeasy.DBConnection.getConnection().prepareStatement(
    	    "SELECT seller_id FROM seller WHERE user_id=?");
    	sIdPs.setInt(1, sUserId);
    	java.sql.ResultSet sIdRs = sIdPs.executeQuery();
    	if (sIdRs.next()) sId = sIdRs.getInt(1);
    	sIdRs.close(); sIdPs.close();
        java.sql.Connection sStatConn = com.shopeasy.DBConnection.getConnection();

        // Product count
        java.sql.PreparedStatement sStatPs1 = sStatConn.prepareStatement(
            "SELECT COUNT(*) FROM product WHERE seller_id=? AND status='active'");
        sStatPs1.setInt(1, sId);
        java.sql.ResultSet sStatRs1 = sStatPs1.executeQuery();
        if (sStatRs1.next()) sellerStatProducts = sStatRs1.getInt(1);
        sStatRs1.close(); sStatPs1.close();

        // Total Order count
        java.sql.PreparedStatement sStatPs2 = sStatConn.prepareStatement(
            "SELECT COUNT(DISTINCT o.order_id) FROM orders o JOIN order_items oi ON o.order_id=oi.order_id WHERE oi.seller_id=?");
        sStatPs2.setInt(1, sId);
        java.sql.ResultSet sStatRs2 = sStatPs2.executeQuery();
        if (sStatRs2.next()) sellerStatOrders = sStatRs2.getInt(1);
        sStatRs2.close(); sStatPs2.close();

        // Revenue
        java.sql.PreparedStatement sStatPs3 = sStatConn.prepareStatement(
        		"SELECT SUM(oi.subtotal) FROM order_items oi JOIN orders o ON oi.order_id=o.order_id WHERE oi.seller_id=? AND o.status='Completed' AND o.order_id NOT IN (SELECT order_id FROM refund_requests WHERE status='Refunded')");
        sStatPs3.setInt(1, sId);
        java.sql.ResultSet sStatRs3 = sStatPs3.executeQuery();
        if (sStatRs3.next()) sellerStatRevenue = sStatRs3.getDouble(1);
        sStatRs3.close(); sStatPs3.close();

        // Pending orders
        java.sql.PreparedStatement sStatPs4 = sStatConn.prepareStatement(
            "SELECT COUNT(DISTINCT o.order_id) FROM orders o JOIN order_items oi ON o.order_id=oi.order_id WHERE oi.seller_id=? AND o.status='Pending'");
        sStatPs4.setInt(1, sId);
        java.sql.ResultSet sStatRs4 = sStatPs4.executeQuery();
        if (sStatRs4.next()) sellerStatPending = sStatRs4.getInt(1);
        sStatRs4.close(); sStatPs4.close();

        // Low stock (stock <= 5)
        java.sql.PreparedStatement sStatPs5 = sStatConn.prepareStatement(
            "SELECT COUNT(*) FROM product WHERE seller_id=? AND status='active' AND stock <= 5");
        sStatPs5.setInt(1, sId);
        java.sql.ResultSet sStatRs5 = sStatPs5.executeQuery();
        if (sStatRs5.next()) sellerStatLowStock = sStatRs5.getInt(1);
        sStatRs5.close(); sStatPs5.close();

        // Completed orders
        java.sql.PreparedStatement sStatPs6 = sStatConn.prepareStatement(
            "SELECT COUNT(DISTINCT o.order_id) FROM orders o JOIN order_items oi ON o.order_id=oi.order_id WHERE oi.seller_id=? AND o.status='Completed'");
        sStatPs6.setInt(1, sId);
        java.sql.ResultSet sStatRs6 = sStatPs6.executeQuery();
        if (sStatRs6.next()) sellerStatCompleted = sStatRs6.getInt(1);
        sStatRs6.close(); sStatPs6.close();

        sStatConn.close();
    } catch (Exception ex) { ex.printStackTrace(); }
%>
    <div class="row g-3 mb-4">
        <div class="col-6 col-md-2">
            <div class="stat-box">
                <div class="stat-num"><%= sellerStatProducts %></div>
                <div class="stat-label">Products</div>
            </div>
        </div>
        <div class="col-6 col-md-2">
            <div class="stat-box">
                <div class="stat-num"><%= sellerStatOrders %></div>
                <div class="stat-label">Total Orders</div>
            </div>
        </div>
        <div class="col-6 col-md-2">
            <div class="stat-box">
                <div class="stat-num">₱<%= String.format("%.0f", sellerStatRevenue) %></div>
                <div class="stat-label">Revenue</div>
            </div>
        </div>
        <div class="col-6 col-md-2">
            <div class="stat-box" style="border-top: 3px solid #ffc107;">
                <div class="stat-num text-warning"><%= sellerStatPending %></div>
                <div class="stat-label">Pending</div>
            </div>
        </div>
        <div class="col-6 col-md-2">
            <div class="stat-box" style="border-top: 3px solid #198754;">
                <div class="stat-num text-success"><%= sellerStatCompleted %></div>
                <div class="stat-label">Completed</div>
            </div>
        </div>
        <div class="col-6 col-md-2">
            <div class="stat-box" style="border-top: 3px solid #dc3545;">
                <div class="stat-num text-danger"><%= sellerStatLowStock %></div>
                <div class="stat-label">Low Stock</div>
            </div>
        </div>
    </div>
      

    <!-- SHOP SETTINGS -->
    <div class="card-section mb-4" id="section-shop" style="display:none;">

    <!-- Facebook-style: Banner with overlapping logo -->
    <div style="position:relative; margin-bottom:70px;">
        <!-- Banner -->
        <div class="shop-banner" id="shopBannerPreviewDiv" style="height:160px; border-radius:12px; overflow:hidden; <%= !sellerBanner.isEmpty() ? "background:url('" + sellerBanner + "') center/cover no-repeat;" : "background:linear-gradient(135deg, #198754, #20c997);" %>">
        </div>
      <!-- Logo overlapping banner -->
        <div style="position:absolute; bottom:-50px; left:24px; display:flex; align-items:flex-end; gap:16px;">
            <div style="position:relative;">
                <img src="<%= !sellerShopLogo.isEmpty() ? sellerShopLogo : "https://ui-avatars.com/api/?name=" + sellerBizNameEncoded + "&background=198754&color=fff&size=100" %>"
     alt="Shop Logo" id="shopLogoPreview"
                     style="width:90px; height:90px; border-radius:50%; object-fit:cover; border:4px solid #fff; box-shadow:0 2px 8px rgba(0,0,0,0.15); cursor:pointer;"
                     onclick="document.getElementById('shopLogoInput').click()">
                <button type="button" onclick="document.getElementById('shopLogoInput').click()"
                        style="position:absolute; bottom:2px; right:2px; width:28px; height:28px; border-radius:50%; background:#198754; border:2px solid #fff; color:white; font-size:12px; cursor:pointer; display:flex; align-items:center; justify-content:center;">
                    <i class="bi bi-camera"></i>
                </button>
                <input type="file" id="shopLogoInput" style="display:none" accept="image/*" onchange="openShopLogoCrop(this)">
            </div>
            <div style="padding-bottom:4px;">
                <p class="fw-bold mb-0" style="font-size:17px; color:#111;"><%= sellerBusinessName %></p>
                <p class="text-muted mb-0" style="font-size:12px; color:#666;"><%= sellerEmail %></p>
            </div>
        </div>
        <!-- Banner edit buttons top right -->
        <div style="position:absolute; top:10px; right:10px; display:flex; gap:6px;">
            <button type="button" id="editBannerBtn2" onclick="document.getElementById('bannerInput').click()"
                    style="background:rgba(0,0,0,0.5); color:#fff; border:none; border-radius:6px; padding:5px 10px; font-size:12px; cursor:pointer;">
                <i class="bi bi-camera"></i> Edit Banner
            </button>
            <button type="button" id="removeBannerBtn2" onclick="removeBanner()"
                    style="background:rgba(220,53,69,0.8); color:#fff; border:none; border-radius:6px; padding:5px 10px; font-size:12px; cursor:pointer; <%= sellerBanner.isEmpty() ? "display:none;" : "" %>">
                <i class="bi bi-trash"></i>
            </button>
        </div>
    </div>
    <p class="section-title mt-2"><i class="bi bi-shop-window text-success"></i> Shop Settings</p>
        <form action="UpdateSellerServlet" method="post">
            <input type="hidden" name="action" value="shop">
            
            
            

            <div class="row g-3">
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">Shop / Business Name</label>
                    <input type="text" class="form-control" name="businessName" id="shopBusinessName" value="<%= sellerBusinessName %>" disabled>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">Business Type</label>
                   <select class="form-select" name="businessType" id="shopBusinessType" disabled>
                        <option value="Individual Seller" <%= "Individual Seller".equals(sellerBusinessType) ? "selected" : "" %>>🧑 Individual Seller</option>
                        <option value="Small Business" <%= "Small Business".equals(sellerBusinessType) ? "selected" : "" %>>🏪 Small Business</option>
                        <option value="Registered Business" <%= "Registered Business".equals(sellerBusinessType) ? "selected" : "" %>>🏢 Registered Business</option>
                    </select>
                </div>
                <div class="col-12">
                    <label class="form-label fw-bold" style="font-size:13px;">Shop Description</label>
                  <textarea class="form-control" rows="3" name="shopDescription" id="shopDescription" disabled><%= sellerShopDescription %></textarea>
                </div>
                <div class="col-12">
                    <label class="form-label fw-bold" style="font-size:13px;">Business Address</label>
                    <input type="text" class="form-control" name="address" id="shopAddress" value="<%= sellerShopAddress %>" disabled>
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

   <form id="shopLogoForm" action="UpdateSellerServlet" method="post" style="display:none;">
    <input type="hidden" name="action" value="shopLogo">
    <input type="hidden" id="shopLogoData" name="shopLogo" value="">
</form>

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
    <%
        java.sql.Connection catConn = com.shopeasy.DBConnection.getConnection();
        java.sql.PreparedStatement catPs = catConn.prepareStatement("SELECT category_id, name FROM category ORDER BY name");
        java.sql.ResultSet catRs = catPs.executeQuery();
        while (catRs.next()) {
    %>
        <option value="<%= catRs.getInt("category_id") %>"><%= catRs.getString("name") %></option>
    <%
        }
        catRs.close(); catPs.close(); catConn.close();
    %>
</select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold" style="font-size:13px;">Price (₱)</label>
                        <input type="number" name="price" class="form-control" placeholder="0.00" step="0.01" min="0" required>
                    </div>
                    <div class="col-md-6">
<label class="form-label fw-bold" style="font-size:13px;">Discounted Price (₱) <span class="text-muted fw-normal" style="font-size:11px;">optional — leave blank if no discount</span></label>
<input type="number" name="originalPrice" class="form-control" placeholder="e.g. 199.00" step="0.01" min="0">
</div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold" style="font-size:13px;">Stock Quantity</label>
                        <input type="number" name="stock" class="form-control" placeholder="0" min="0" required>
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-bold" style="font-size:13px;">Description</label>
                        <textarea name="description" class="form-control" rows="3" placeholder="Describe your product..."></textarea>
                    </div>
                    
                    <!-- PRODUCT VARIATIONS -->
<div class="col-12">
    <label class="form-label fw-bold" style="font-size:13px;">
        Product Variations 
        <span class="text-muted fw-normal" style="font-size:11px;">(optional — size, color, kilos)</span>
    </label>
    <div id="variationsContainer" class="d-flex flex-column gap-2 mb-2">
        <!-- rows added dynamically -->
    </div>
    <button type="button" class="btn btn-outline-success btn-sm" onclick="addVariationRow()">
        <i class="bi bi-plus"></i> Add Variation
    </button>
    <p class="text-muted mt-1" style="font-size:11px;">
        Each row is one option. Example: Size → XL, Color → Red, Kilos → 5kg
    </p>
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
    java.util.List<java.util.Map<String, String>> products = new java.util.ArrayList<>();
    try {
    	int sellerIdForProducts = 0;
        try {
            java.sql.PreparedStatement sidPsP = com.shopeasy.DBConnection.getConnection().prepareStatement("SELECT seller_id FROM seller WHERE user_id=?");
            sidPsP.setInt(1, (int) session.getAttribute("userId"));
            java.sql.ResultSet sidRsP = sidPsP.executeQuery();
            if (sidRsP.next()) sellerIdForProducts = sidRsP.getInt(1);
            sidRsP.close(); sidPsP.close();
        } catch (Exception ex) { sellerIdForProducts = (int) session.getAttribute("userId"); }
        java.sql.Connection prodConn = com.shopeasy.DBConnection.getConnection();
        java.sql.PreparedStatement prodPs = prodConn.prepareStatement(
            "SELECT p.*, c.name as category_name FROM product p " +
            "LEFT JOIN category c ON p.category_id = c.category_id " +
            "WHERE p.seller_id = ? ORDER BY p.product_id DESC");
        prodPs.setInt(1, sellerIdForProducts);
        java.sql.ResultSet prodRs = prodPs.executeQuery();
        while (prodRs.next()) {
            java.util.Map<String, String> product = new java.util.HashMap<>();
            product.put("product_id", prodRs.getString("product_id"));
            product.put("name", prodRs.getString("name"));
            product.put("description", prodRs.getString("description"));
            product.put("price", prodRs.getString("price"));
            product.put("original_price", prodRs.getString("original_price"));
            product.put("stock", prodRs.getString("stock"));
            product.put("image", prodRs.getString("image"));
            product.put("category_name", prodRs.getString("category_name"));
            product.put("category_id", prodRs.getString("category_id"));
            product.put("status", prodRs.getString("status"));
            products.add(product);
        }
        prodRs.close(); prodPs.close(); prodConn.close();
    } catch (Exception prodEx) { prodEx.printStackTrace(); }
    if (!products.isEmpty()) {
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
    <%
    String discPriceStr = product.get("original_price");
    double discPrice = (discPriceStr != null && !discPriceStr.isEmpty()) ? Double.parseDouble(discPriceStr) : 0;
    double realPrice = Double.parseDouble(product.get("price") != null ? product.get("price") : "0");
    int discPct = 0;
    if (discPrice > 0 && discPrice < realPrice) {
        discPct = (int) Math.round((realPrice - discPrice) / realPrice * 100);
    }
%>
<% if (discPct > 0) { %>
    <span class="badge bg-danger mb-1" style="font-size:10px;">-<%= discPct %>% OFF</span><br>
    <span class="text-muted text-decoration-line-through" style="font-size:11px;">₱<%= product.get("price") %></span><br>
    <p class="mb-1 fw-bold text-success">₱<%= discPriceStr %></p>
<% } else { %>
    <p class="mb-1 fw-bold text-success">₱<%= product.get("price") %></p>
<% } %>
    <%  int stock = Integer.parseInt(product.get("stock") != null ? product.get("stock") : "0");
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
    onclick="editProduct('<%= product.get("product_id") %>', '<%= product.get("name") != null ? product.get("name").replace("'", "\\'") : "" %>', '<%= product.get("price") %>', '<%= product.get("stock") %>', '<%= product.get("description") != null ? product.get("description").replace("'", "\\'").replace("\n", "\\n").replace("\r", "") : "" %>', '<%= product.get("category_name") %>', '<%= product.get("original_price") != null ? product.get("original_price") : "" %>', '<%= product.get("category_id") != null ? product.get("category_id") : "" %>')">
        <i class="bi bi-pencil"></i>
    </button>
    <button class="btn btn-outline-danger btn-sm"
        onclick="deleteProduct('<%= product.get("product_id") %>', '<%= product.get("name") != null ? new String(product.get("name").getBytes("ISO-8859-1"), "UTF-8") : "" %>')">
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

        java.text.SimpleDateFormat sOrdSdf = new java.text.SimpleDateFormat("MMM d, yyyy h:mm a");
        sOrdSdf.setTimeZone(java.util.TimeZone.getTimeZone("Asia/Manila"));
        java.util.List<java.util.Map<String, Object>> sellerOrders = new java.util.ArrayList<>();
        try {
        	int sOrdSellerId = 0;
            try {
                java.sql.PreparedStatement sidPsO = com.shopeasy.DBConnection.getConnection().prepareStatement("SELECT seller_id FROM seller WHERE user_id=?");
                sidPsO.setInt(1, (int) session.getAttribute("userId"));
                java.sql.ResultSet sidRsO = sidPsO.executeQuery();
                if (sidRsO.next()) sOrdSellerId = sidRsO.getInt(1);
                sidRsO.close(); sidPsO.close();
            } catch (Exception ex) { sOrdSellerId = (int) session.getAttribute("userId"); }
            java.sql.Connection sOrdConn = com.shopeasy.DBConnection.getConnection();

            String sOrdSql = "SELECT DISTINCT o.order_id, o.status, o.order_date, o.total_amount AS total_price, " +
            	    "o.payment_method, c.name AS buyer_name, c.email AS buyer_email, " +
            	    		"o.shipping_address AS address, " +
            	    				"o.shipping_address AS addr_name, NULL AS phone " +
            	    "FROM orders o " +
            	    "JOIN order_items oi ON o.order_id = oi.order_id " +
            	    "JOIN customer c ON o.customer_id = c.customer_id " +
            	    "WHERE oi.seller_id = ? ";
            if ("Refund Requests".equals(orderTabFilter)) {
                sOrdSql += "AND o.order_id IN (SELECT order_id FROM refund_requests WHERE status='Pending') ";
            } else if (!"All".equals(orderTabFilter)) {
                sOrdSql += "AND o.status = ? ";
            }
            sOrdSql += "ORDER BY o.order_id DESC";

            java.sql.PreparedStatement sOrdPs = sOrdConn.prepareStatement(sOrdSql);
            sOrdPs.setInt(1, sOrdSellerId);
            if (!"All".equals(orderTabFilter) && !"Refund Requests".equals(orderTabFilter)) sOrdPs.setString(2, orderTabFilter);
            java.sql.ResultSet sOrdRs = sOrdPs.executeQuery();

            while (sOrdRs.next()) {
                java.util.Map<String, Object> ord = new java.util.HashMap<>();
                ord.put("id", sOrdRs.getInt("order_id"));
                ord.put("status", sOrdRs.getString("status"));
                java.sql.Timestamp sOrdTs = sOrdRs.getTimestamp("order_date");
                ord.put("date", sOrdTs != null ? sOrdSdf.format(sOrdTs) : "Date not available");
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
                	    "SELECT oi.quantity, oi.subtotal, p.name AS pname, p.image AS image_url, " +
                	    "pv.variation_type, pv.variation_value " +
                	    "FROM order_items oi " +
                	    "JOIN product p ON oi.product_id = p.product_id " +
                	    "LEFT JOIN product_variation pv ON oi.variation_id = pv.variation_id " +
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
                    item.put("variationType", itemRs.getString("variation_type"));
                    item.put("variationValue", itemRs.getString("variation_value"));
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
        <%String[] sOrderStatuses = {"All","Pending","Processing","Shipped","Completed","Cancelled","Cancellation Requested","Refund Requests"};
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
            else if ("Cancellation Requested".equals(sStatus)) badgeClass = "warning text-dark";
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
    <p class="mb-0 text-muted" style="font-size:12px;"><%= ord.get("addr_name") %></p>
<% } else { %>
    <p class="mb-0 text-muted" style="font-size:12px;">No address on file</p>
<% } %>
                    <hr class="my-2">
                    <p class="mb-0" style="font-size:12px;">
                     <i class="bi bi-wallet2 me-1"></i>
<span class="fw-semibold">Payment:</span> <%= "Wallet".equals(ord.get("payment")) ? "ShopEasy Wallet" : ord.get("payment") %>
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
<% if (itm.get("variationType") != null) { %>
    <span class="badge bg-light text-dark border mb-1" style="font-size:11px;">
        <i class="bi bi-tag"></i> <%= itm.get("variationType") %>: <%= itm.get("variationValue") %>
    </span>
<% } %>
<p class="mb-0 text-muted" style="font-size:12px;">
    Qty: <%= itm.get("qty") %> &nbsp;|&nbsp;
    ₱<%= String.format("%.2f", itm.get("subtotal")) %>
</p>
                        </div>
                    </div>
                    <% } %>

                   <%-- Total + Actions --%>
<div class="d-flex justify-content-between align-items-center mt-2 pt-2 border-top">
    <p class="mb-0 fw-bold text-success" style="font-size:13px;">
        Total: ₱<%= String.format("%.2f", ord.get("total")) %>
    </p>
    <div class="d-flex gap-2 flex-column align-items-end" id="actions_<%= ord.get("id") %>">
        <% if ("Pending".equals(sStatus)) { %>
            <button class="btn btn-primary btn-sm"
                onclick="updateOrderStatus(<%= ord.get("id") %>, 'Processing')">
                <i class="bi bi-check-circle"></i> Confirm Order
            </button>
            <button class="btn btn-outline-danger btn-sm"
    onclick="openSellerCancelModal(<%= ord.get("id") %>)">
    <i class="bi bi-x-circle"></i> Cancel Order
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
        <% } else if ("Cancellation Requested".equals(sStatus)) { %>
            <%
                String cancelReason = "";
                try {
                    java.sql.Connection crConn = com.shopeasy.DBConnection.getConnection();
                    java.sql.PreparedStatement crPs = crConn.prepareStatement(
                        "SELECT cancel_reason FROM orders WHERE order_id=?");
                    crPs.setInt(1, (int) ord.get("id"));
                    java.sql.ResultSet crRs = crPs.executeQuery();
                    if (crRs.next() && crRs.getString("cancel_reason") != null)
                        cancelReason = crRs.getString("cancel_reason");
                    crRs.close(); crPs.close(); crConn.close();
                } catch (Exception crEx) { crEx.printStackTrace(); }
            %>
            <div class="w-100 mb-2 p-2 rounded-3"
                 style="background:#fff3cd; border:1px solid #ffc107; font-size:12px;">
                <i class="bi bi-chat-left-text text-warning me-1"></i>
                <strong>Cancel Reason:</strong> <%= cancelReason.isEmpty() ? "No reason provided" : cancelReason %>
            </div>
            <button class="btn btn-success btn-sm"
                onclick="approveCancel(<%= ord.get("id") %>, 'approve')">
                <i class="bi bi-check-circle"></i> Approve Cancel
            </button>
            <button class="btn btn-outline-danger btn-sm"
                onclick="approveCancel(<%= ord.get("id") %>, 'decline')">
                <i class="bi bi-x-circle"></i> Decline
            </button>
        <% } else if ("Cancelled".equals(sStatus)) { %>
    <%
        String cancelledReason = "";
        try {
            java.sql.Connection crConn2 = com.shopeasy.DBConnection.getConnection();
            java.sql.PreparedStatement crPs2 = crConn2.prepareStatement(
                "SELECT cancel_reason FROM orders WHERE order_id=?");
            crPs2.setInt(1, (int) ord.get("id"));
            java.sql.ResultSet crRs2 = crPs2.executeQuery();
            if (crRs2.next() && crRs2.getString("cancel_reason") != null)
                cancelledReason = crRs2.getString("cancel_reason");
            crRs2.close(); crPs2.close(); crConn2.close();
        } catch (Exception crEx2) { crEx2.printStackTrace(); }
        boolean cancelledByCustomer = cancelledReason.toLowerCase().contains("cancelled by customer");
    %>
    <% if (cancelledByCustomer) { %>
        <span class="badge bg-danger px-3 py-2" style="font-size:12px;">
            <i class="bi bi-person-x-fill"></i> Cancelled by Customer
        </span>
    <% } else { %>
        <span class="badge bg-secondary px-3 py-2" style="font-size:12px;">
            <i class="bi bi-x-circle"></i> Cancelled
        </span>
    <% } %>
    <% if (!cancelledReason.isEmpty()) { %>
        <div class="mt-1 p-2 rounded-3" style="background:#fff0f0; border:1px solid #f5c2c7; font-size:12px;">
            <i class="bi bi-chat-left-text text-danger me-1"></i>
            <strong>Reason:</strong> <%= cancelledReason %>
        </div>
    <% } %>
<% } else if ("Completed".equals(sStatus)) { %>
    <%
        String selRefundStatus = null;
        int selRefundId = 0;
        String selRefundReason = "", selRefundDesc = "", selRefundProof = "";
        try {
            java.sql.Connection srConn2 = com.shopeasy.DBConnection.getConnection();
            java.sql.PreparedStatement srPs2 = srConn2.prepareStatement(
                "SELECT refund_id, reason, description, proof_image, status FROM refund_requests WHERE order_id=?");
            srPs2.setInt(1, (int) ord.get("id"));
            java.sql.ResultSet srRs2 = srPs2.executeQuery();
            if (srRs2.next()) {
                selRefundId = srRs2.getInt("refund_id");
                selRefundReason = srRs2.getString("reason") != null ? srRs2.getString("reason") : "";
                selRefundDesc = srRs2.getString("description") != null ? srRs2.getString("description") : "";
                selRefundProof = srRs2.getString("proof_image") != null ? srRs2.getString("proof_image") : "";
                selRefundStatus = srRs2.getString("status");
            }
            srRs2.close(); srPs2.close(); srConn2.close();
        } catch (Exception srEx) { srEx.printStackTrace(); }
    %>
    <% if (selRefundStatus == null) { %>
        <span class="text-muted" style="font-size:12px;">
            <i class="bi bi-check2-all"></i> Completed
        </span>
    <% } else if ("Pending".equals(selRefundStatus)) { %>
        <div class="p-2 rounded-3 mb-2 w-100" style="background:#fff8e1; border:1px solid #ffc107; font-size:12px;">
            <p class="fw-bold mb-1" style="color:#fd7e14;"><i class="bi bi-arrow-counterclockwise me-1"></i>Refund Request</p>
            <p class="mb-1"><strong>Reason:</strong> <%= selRefundReason %></p>
            <% if (!selRefundDesc.isEmpty()) { %><p class="mb-1"><strong>Description:</strong> <%= selRefundDesc %></p><% } %>
            <% if (!selRefundProof.isEmpty()) { %>
                <img src="<%= selRefundProof %>" style="width:80px; height:80px; object-fit:cover; border-radius:8px; border:1px solid #dee2e6; margin-bottom:6px;">
            <% } %>
        </div>
        <button class="btn btn-success btn-sm fw-semibold w-100 mb-1"
            onclick="sellerRefundAction(<%= selRefundId %>, 'approve')">
            <i class="bi bi-check-circle"></i> Approve Refund
        </button>
        <button class="btn btn-outline-danger btn-sm w-100"
            onclick="sellerRefundAction(<%= selRefundId %>, 'reject')">
            <i class="bi bi-x-circle"></i> Reject Refund
        </button>
  <% } else if ("Refunded".equals(selRefundStatus)) { %>
        <span class="badge px-3 py-2" style="font-size:12px; background:#6c757d; color:white;">
            <i class="bi bi-arrow-counterclockwise"></i> Refunded
        </span>
    <% } else if ("Rejected".equals(selRefundStatus)) { %>
        <span class="badge bg-danger px-3 py-2" style="font-size:12px;">
            <i class="bi bi-x-circle"></i> Refund Rejected
        </span>
    <% } %>
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
            <p class="section-title"><i class="bi bi-speedometer2 text-success"></i> Dashboard</p>
            <%
            try {
                java.sql.Connection saConn = com.shopeasy.DBConnection.getConnection();
                int userId = (int) session.getAttribute("userId");
                int sellerId = -1;
                java.sql.PreparedStatement sidPs = saConn.prepareStatement("SELECT seller_id FROM seller WHERE user_id=?");
                sidPs.setInt(1, userId);
                java.sql.ResultSet sidRs = sidPs.executeQuery();
                if (sidRs.next()) sellerId = sidRs.getInt("seller_id");
                sidRs.close(); sidPs.close();

                // Total Revenue
                java.sql.PreparedStatement revPs = saConn.prepareStatement(
                		"SELECT COALESCE(SUM(oi.subtotal),0) as total_revenue, " +
                    "COUNT(DISTINCT o.order_id) as total_orders, " +
                    "SUM(oi.quantity) as total_items " +
                    "FROM order_items oi " +
                    "JOIN orders o ON oi.order_id = o.order_id " +
                    "JOIN product p ON oi.product_id = p.product_id " +
                		"WHERE p.seller_id = ? AND o.status = 'Completed' AND o.order_id NOT IN (SELECT order_id FROM refund_requests WHERE status='Refunded')");
                revPs.setInt(1, sellerId);
                java.sql.ResultSet revRs = revPs.executeQuery();
                double totalRevenue = 0; int totalOrders = 0; int totalItems = 0;
                if (revRs.next()) {
                    totalRevenue = revRs.getDouble("total_revenue");
                    totalOrders = revRs.getInt("total_orders");
                    totalItems = revRs.getInt("total_items");
                }

                // Top 5 Products
                java.sql.PreparedStatement topPs = saConn.prepareStatement(
                		"SELECT p.name, SUM(oi.quantity) as sold, SUM(oi.subtotal) as revenue " +
                    "FROM order_items oi " +
                    "JOIN orders o ON oi.order_id = o.order_id " +
                    "JOIN product p ON oi.product_id = p.product_id " +
                    "WHERE p.seller_id = ? AND o.status = 'Completed' " +
                    "AND o.order_id NOT IN (SELECT order_id FROM refund_requests WHERE status='Refunded') " +
                    "GROUP BY p.product_id, p.name ORDER BY sold DESC LIMIT 5");
                topPs.setInt(1, sellerId);
                java.sql.ResultSet topRs = topPs.executeQuery();

                // Monthly Sales (last 6 months)
                java.sql.PreparedStatement monthPs = saConn.prepareStatement(
                    "SELECT DATE_FORMAT(o.order_date, '%b %Y') as month, " +
                    		"SUM(oi.subtotal) as revenue " +
                    "FROM order_items oi " +
                    "JOIN orders o ON oi.order_id = o.order_id " +
                    "JOIN product p ON oi.product_id = p.product_id " +
                    		"WHERE p.seller_id = ? AND o.status = 'Completed' " +
                            "AND o.order_id NOT IN (SELECT order_id FROM refund_requests WHERE status='Refunded') " +
                            "AND o.order_date IS NOT NULL " +
                            "GROUP BY DATE_FORMAT(o.order_date, '%b %Y'), YEAR(o.order_date), MONTH(o.order_date) " +
                    "ORDER BY YEAR(o.order_date), MONTH(o.order_date)");
                monthPs.setInt(1, sellerId);
                java.sql.ResultSet monthRs = monthPs.executeQuery();

                StringBuilder monthLabels = new StringBuilder("[");
                StringBuilder monthData = new StringBuilder("[");
                boolean firstMonth = true;
                while (monthRs.next()) {
                    if (!firstMonth) { monthLabels.append(","); monthData.append(","); }
                    monthLabels.append("'").append(monthRs.getString("month")).append("'");
                    monthData.append(monthRs.getDouble("revenue"));
                    firstMonth = false;
                }
                monthLabels.append("]"); monthData.append("]");

                // Store top products in a list before closing connection
                java.util.List<String> topNames = new java.util.ArrayList<>();
                java.util.List<Integer> topSold = new java.util.ArrayList<>();
                java.util.List<Double> topRevenue = new java.util.ArrayList<>();
                while (topRs.next()) {
                    topNames.add(topRs.getString("name"));
                    topSold.add(topRs.getInt("sold"));
                    topRevenue.add(topRs.getDouble("revenue"));
                }
                saConn.close();
            %>

            <!-- Summary Cards -->
            <div class="row g-3 mb-4" id="section-stats" style="display:none;">
                <div class="col-md-4">
                    <div class="p-3 rounded-3 text-center" style="background:#f0fdf4; border:1px solid #bbf7d0;">
                        <p class="mb-0 text-muted" style="font-size:12px;">Total Revenue</p>
                        <h4 class="fw-bold text-success mb-0">₱<%= String.format("%.2f", totalRevenue) %></h4>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="p-3 rounded-3 text-center" style="background:#eff6ff; border:1px solid #bfdbfe;">
                        <p class="mb-0 text-muted" style="font-size:12px;">Completed Orders</p>
                        <h4 class="fw-bold text-primary mb-0"><%= totalOrders %></h4>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="p-3 rounded-3 text-center" style="background:#fefce8; border:1px solid #fde68a;">
                        <p class="mb-0 text-muted" style="font-size:12px;">Items Sold</p>
                        <h4 class="fw-bold text-warning mb-0"><%= totalItems %></h4>
                    </div>
                </div>
            </div>

<%-- TODAY'S SUMMARY + RECENT ORDERS + LOW STOCK --%>
            <%
            try {
                java.sql.Connection dashConn = com.shopeasy.DBConnection.getConnection();
                int dashSellerId = (int) session.getAttribute("sellerId");

                // Today's orders
                java.sql.PreparedStatement todayPs = dashConn.prepareStatement(
                    "SELECT COUNT(DISTINCT o.order_id) as today_orders, " +
                    		"COALESCE(SUM(oi.subtotal),0) as today_revenue " +
                    "FROM order_items oi JOIN orders o ON oi.order_id=o.order_id " +
                    "JOIN product p ON oi.product_id=p.product_id " +
                		"WHERE p.seller_id=? AND DATE(o.order_date)=CURDATE() AND o.order_id NOT IN (SELECT order_id FROM refund_requests WHERE status='Refunded')");
                todayPs.setInt(1, dashSellerId);
                java.sql.ResultSet todayRs = todayPs.executeQuery();
                int todayOrders = 0; double todayRevenue = 0;
                if (todayRs.next()) {
                    todayOrders = todayRs.getInt("today_orders");
                    todayRevenue = todayRs.getDouble("today_revenue");
                }
                todayRs.close(); todayPs.close();

                // Recent 5 orders
                java.sql.PreparedStatement recentPs = dashConn.prepareStatement(
                    "SELECT DISTINCT o.order_id, c.name as customer_name, o.status, o.order_date, " +
                    		"COALESCE(SUM(oi2.subtotal),0) as order_total " +
                    "FROM orders o " +
                    "JOIN order_items oi ON o.order_id=oi.order_id " +
                    "JOIN product p ON oi.product_id=p.product_id " +
                    "JOIN order_items oi2 ON o.order_id=oi2.order_id " +
                    "LEFT JOIN customer c ON o.customer_id=c.customer_id " +
                    "WHERE p.seller_id=? " +
                    "GROUP BY o.order_id, c.name, o.status, o.order_date " +
                    "ORDER BY o.order_date DESC LIMIT 5");
                recentPs.setInt(1, dashSellerId);
                java.sql.ResultSet recentRs = recentPs.executeQuery();
                java.util.List<java.util.Map<String,Object>> recentOrders = new java.util.ArrayList<>();
                while (recentRs.next()) {
                    java.util.Map<String,Object> ro = new java.util.HashMap<>();
                    ro.put("id", recentRs.getInt("order_id"));
                    ro.put("customer", recentRs.getString("customer_name"));
                    ro.put("status", recentRs.getString("status"));
                    ro.put("date", recentRs.getString("order_date"));
                    ro.put("total", recentRs.getDouble("order_total"));
                    recentOrders.add(ro);
                }
                recentRs.close(); recentPs.close();

                // Low stock products (stock <= 5)
                java.sql.PreparedStatement lowPs = dashConn.prepareStatement(
                		"SELECT name, stock FROM product WHERE seller_id=? AND status='active' AND stock <= 10 ORDER BY stock ASC LIMIT 5");
                lowPs.setInt(1, dashSellerId);
                java.sql.ResultSet lowRs = lowPs.executeQuery();
                java.util.List<java.util.Map<String,Object>> lowStockList = new java.util.ArrayList<>();
                while (lowRs.next()) {
                    java.util.Map<String,Object> ls = new java.util.HashMap<>();
                    ls.put("name", lowRs.getString("name"));
                    ls.put("stock", lowRs.getInt("stock"));
                    lowStockList.add(ls);
                }
                lowRs.close(); lowPs.close();
                dashConn.close();
            %>

            <!-- TODAY'S SUMMARY -->
            <p class="fw-bold mb-2" style="font-size:14px;"><i class="bi bi-calendar-check text-success me-1"></i> Today's Summary</p>
            <div class="row g-3 mb-4">
                <div class="col-6">
                    <div class="p-3 rounded-3 text-center" style="background:#f0fdf4; border:1px solid #bbf7d0;">
                        <p class="mb-1 text-muted" style="font-size:11px;">ORDERS TODAY</p>
                        <h3 class="fw-bold text-success mb-0"><%= todayOrders %></h3>
                    </div>
                </div>
                <div class="col-6">
                    <div class="p-3 rounded-3 text-center" style="background:#eff6ff; border:1px solid #bfdbfe;">
                        <p class="mb-1 text-muted" style="font-size:11px;">REVENUE TODAY</p>
                        <h3 class="fw-bold text-primary mb-0">₱<%= String.format("%.0f", todayRevenue) %></h3>
                    </div>
                </div>
            </div>

            <!-- RECENT ORDERS -->
            <p class="fw-bold mb-2" style="font-size:14px;"><i class="bi bi-clock-history text-success me-1"></i> Recent Orders</p>
            <div class="mb-4">
            <% if (recentOrders.isEmpty()) { %>
                <div class="text-center text-muted py-3" style="font-size:13px;">
                    <i class="bi bi-inbox" style="font-size:24px;"></i><br>No orders yet.
                </div>
            <% } else { for (java.util.Map<String,Object> ro : recentOrders) {
                String roStatus = (String) ro.get("status");
                String roBadge = "Pending".equals(roStatus) ? "bg-warning text-dark" :
                                 "Completed".equals(roStatus) ? "bg-success" :
                                 "Cancelled".equals(roStatus) ? "bg-danger" : "bg-secondary";
            %>
                <div class="d-flex align-items-center justify-content-between p-2 mb-2 rounded-3"
                     style="background:#f8f9fa; border:1px solid #e9ecef; font-size:13px;">
                    <div>
                        <span class="fw-bold">#<%= ro.get("id") %></span>
                        <span class="text-muted ms-2"><%= ro.get("customer") != null ? ro.get("customer") : "Customer" %></span>
                    </div>
                    <div class="d-flex align-items-center gap-2">
                        <span class="text-success fw-bold">₱<%= String.format("%.0f", (double)ro.get("total")) %></span>
                        <span class="badge <%= roBadge %>" style="font-size:10px;"><%= roStatus %></span>
                    </div>
                </div>
            <% } } %>
            </div>

          <% } catch (Exception dashEx) { dashEx.printStackTrace(); } %>

           
            
            <!-- Monthly Revenue Chart -->
            <p class="fw-bold mb-2" style="font-size:14px;"><i class="bi bi-graph-up text-success me-1"></i> Monthly Revenue (Last 6 Months)</p>
            <div style="height:250px;" class="mb-4">
                <canvas id="revenueChart"></canvas>
            </div>

            <!-- Top Products -->
            <p class="fw-bold mb-2" style="font-size:14px;"><i class="bi bi-trophy text-warning me-1"></i> Top Products</p>
            <div class="table-responsive">
                <table class="table table-hover" style="font-size:13px;">
                    <thead class="table-light">
                        <tr>
                            <th>#</th>
                            <th>Product</th>
                            <th>Units Sold</th>
                            <th>Revenue</th>
                        </tr>
                    </thead>
                    <tbody>
                       <% for (int rank = 1; rank <= topNames.size(); rank++) { %>
                        <tr>
                            <td><span class="badge <%= rank == 1 ? "bg-warning" : rank == 2 ? "bg-secondary" : "bg-light text-dark" %>"><%= rank %></span></td>
                            <td class="fw-bold"><%= topNames.get(rank-1) %></td>
                            <td><%= topSold.get(rank-1) %> units</td>
                            <td class="text-success fw-bold">₱<%= String.format("%.2f", topRevenue.get(rank-1)) %></td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>

            <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
            <script>
            document.addEventListener('DOMContentLoaded', function() {
                const ctx = document.getElementById('revenueChart');
                if (ctx) {
                    new Chart(ctx, {
                    	type: 'line',
                        data: {
                            labels: <%= monthLabels %>,
                            datasets: [{
                                label: 'Revenue (₱)',
                                data: <%= monthData %>,
                                backgroundColor: 'rgba(34,197,94,0.2)',
                                borderColor: 'rgba(34,197,94,1)',
                                borderWidth: 2,
                                borderRadius: 6
                            }]
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            plugins: { legend: { display: false } },
                            scales: { y: { beginAtZero: true, ticks: { callback: v => '₱' + v } } }
                        }
                    });
                }
            });
            </script>

            <% } catch (Exception saEx) { saEx.printStackTrace(); } %>
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
            		"SELECT r.rating, r.comment, r.photo, p.product_id, p.name AS pname, p.image AS pimage, " +
            				"c.name AS cname " +
                "FROM review r " +
                "JOIN product p ON r.product_id = p.product_id " +
                "JOIN customer c ON r.customer_id = c.customer_id " +
                "WHERE p.seller_id = ? ORDER BY r.review_id DESC");
            srPs.setInt(1, (int) session.getAttribute("sellerId"));
            java.sql.ResultSet srRs = srPs.executeQuery();
            while (srRs.next()) {
                hasSellerReviews = true;
        %>
        <div class="d-flex gap-3 p-3 mb-3 border rounded-3">
            <% if (srRs.getString("pimage") != null && !srRs.getString("pimage").isEmpty()) { %>
               <a href="product.jsp?id=<%= srRs.getInt("product_id") %>">
    <img src="<%= srRs.getString("pimage") %>"
         style="width:60px; height:60px; object-fit:cover; border-radius:8px; cursor:pointer;">
</a>
            <% } else { %>
                <div style="width:60px; height:60px; background:#f0f0f0; border-radius:8px;
                     display:flex; align-items:center; justify-content:center;">
                    <i class="bi bi-image text-muted"></i>
                </div>
            <% } %>
            <div class="flex-grow-1">
              <p class="mb-0 fw-bold" style="font-size:14px;">
   <%= srRs.getString("pname") %>
</p>
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

    

   
    <div id="tab-notifications" class="tab-content-section" style="display:none;">
        <div class="card-section">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <p class="section-title mb-0">
                    <i class="bi bi-bell-fill text-success"></i> Notifications
                    <% if (sellerUnreadCount > 0) { %>
                    <span class="badge bg-danger ms-2" style="font-size:11px;"><%= sellerUnreadCount %> new</span>
                    <% } %>
                </p>
                <% if (!sellerNotifList.isEmpty()) { %>
                <div class="d-flex gap-2">
                    <button class="btn btn-outline-success btn-sm" onclick="sellerMarkAllRead()">
                        <i class="bi bi-check2-all"></i> Mark all read
                    </button>
                    <button class="btn btn-outline-danger btn-sm" onclick="sellerClearAll()">
                        <i class="bi bi-trash"></i> Clear all
                    </button>
                </div>
                <% } %>
            </div>

            <div id="sellerNotifList">
            <% if (sellerNotifList.isEmpty()) { %>
                <div class="text-center py-5 text-muted">
                    <i class="bi bi-bell-slash fs-1 opacity-25"></i>
                    <p class="mt-2">No notifications yet.</p>
                </div>
            <% } else { %>
                <% for (java.util.Map<String, Object> n : sellerNotifList) { %>
                <div class="d-flex align-items-start gap-3 p-3 mb-2 rounded-3 seller-notif-item"
                     id="snotif-<%= n.get("id") %>"
                     style="background:<%= (boolean)n.get("isRead") ? "#f8f9fa" : "#edfaf1" %>; border:1px solid <%= (boolean)n.get("isRead") ? "#eee" : "#a3d9b1" %>; cursor:pointer;"
                     onclick="sellerMarkOneRead(<%= n.get("id") %>, this)">
                    <div style="width:36px; height:36px; border-radius:50%; background:<%= (boolean)n.get("isRead") ? "#dee2e6" : "#198754" %>; display:flex; align-items:center; justify-content:center; flex-shrink:0;">
                        <i class="bi bi-bell-fill" style="color:white; font-size:14px;"></i>
                    </div>
                    <div class="flex-grow-1">
                        <p class="mb-0" style="font-size:13px; font-weight:<%= (boolean)n.get("isRead") ? "400" : "600" %>;">
                            <%= n.get("message") %>
                        </p>
                        <p class="mb-0 text-muted" style="font-size:11px;">
                            <i class="bi bi-clock"></i> <%= n.get("createdAt") %>
                        </p>
                    </div>
                    <% if (!(boolean)n.get("isRead")) { %>
                    <span class="badge bg-success" style="font-size:9px;">New</span>
                    <% } %>
                </div>
        <% } %>
            <% } %>
</div>
   </div>
</div><!-- end tab-notifications -->

        <div id="tab-payout" class="tab-content-section" style="display:none;">
    <div class="card-section">
        <p class="section-title"><i class="bi bi-wallet2 text-success"></i> Payout</p>

        <!-- Available Balance -->
        <div class="p-4 rounded-3 mb-4 text-center" style="background:linear-gradient(135deg,#0d6efd,#6610f2); color:white;">
            <p class="mb-1" style="font-size:13px; opacity:0.85;">Available Balance</p>
          <%
          double payoutBalance = 0.0;
          double totalRevenue = 0.0;
          double totalPaidOut = 0.0;
          try {
              Integer payoutSellerId = (Integer) session.getAttribute("sellerId");
              if (payoutSellerId != null) {
              	java.sql.Connection payoutConn = com.shopeasy.DBConnection.getConnection();
                  // Get total revenue from completed orders
                 java.sql.PreparedStatement payoutPs = payoutConn.prepareStatement(
                		  "SELECT COALESCE(SUM(oi.subtotal),0) FROM order_items oi JOIN orders o ON oi.order_id=o.order_id WHERE oi.seller_id=? AND o.status='Completed' AND o.order_id NOT IN (SELECT order_id FROM refund_requests WHERE status='Refunded')");
        payoutPs.setInt(1, payoutSellerId);
        java.sql.ResultSet payoutRs = payoutPs.executeQuery();
        totalRevenue = payoutRs.next() ? payoutRs.getDouble(1) : 0.0;
        payoutRs.close(); payoutPs.close();
        java.sql.PreparedStatement paidPs = payoutConn.prepareStatement(
            "SELECT COALESCE(SUM(amount),0) FROM payout_requests WHERE seller_id=? AND status='Completed'");
        paidPs.setInt(1, payoutSellerId);
        java.sql.ResultSet paidRs = paidPs.executeQuery();
        totalPaidOut = paidRs.next() ? paidRs.getDouble(1) : 0.0;
        paidRs.close(); paidPs.close(); payoutConn.close();
        payoutBalance = totalRevenue - totalPaidOut;
        if (payoutBalance < 0) payoutBalance = 0.0;
    }
} catch (Exception ex) { ex.printStackTrace(); }
%>
<h2 class="fw-bold mb-0" style="font-size:38px;">₱<%= String.format("%.2f", payoutBalance) %></h2>
<p class="mb-0 mt-1" style="font-size:12px; opacity:0.75;">Available for withdrawal</p>
<div class="d-flex justify-content-center gap-4 mt-3" style="font-size:11px; opacity:0.85;">
    <div>
        <i class="bi bi-arrow-down-circle me-1"></i>Total Earned
        <div class="fw-bold" style="font-size:13px;">₱<%= String.format("%.2f", totalRevenue) %></div>
    </div>
    <div style="width:1px; background:rgba(255,255,255,0.3);"></div>
    <div>
        <i class="bi bi-arrow-up-circle me-1"></i>Total Withdrawn
        <div class="fw-bold" style="font-size:13px;">₱<%= String.format("%.2f", totalPaidOut) %></div>
    </div>
</div>
        </div>

   <!-- Payout Method -->
        <p class="fw-bold mb-3" style="font-size:14px;"><i class="bi bi-credit-card me-1"></i> Select Payout Method</p>
        <div class="row g-3 mb-4">
            <div class="col-md-4">
                <div class="payout-method-card border rounded-3 p-3 text-center" onclick="selectPayoutMethod(this, 'GCash')"
                     style="cursor:pointer; transition:0.2s;">
                    <div style="width:48px; height:48px; background:#e8f0fe; border-radius:12px; display:flex; align-items:center; justify-content:center; margin:0 auto 10px;">
                        <i class="bi bi-phone-fill" style="font-size:22px; color:#1a73e8;"></i>
                    </div>
                    <p class="fw-bold mb-0" style="font-size:13px; color:#1a73e8;">GCash</p>
                  <p class="text-muted mb-0" style="font-size:11px;"><i class="bi bi-lightning-fill text-warning" style="font-size:10px;"></i> Instant transfer</p>
                    <p class="text-muted mb-0" style="font-size:11px; color:#dc3545 !important;">Fee: ₱12</p>
                </div>
            </div>
            <div class="col-md-4">
                <div class="payout-method-card border rounded-3 p-3 text-center" onclick="selectPayoutMethod(this, 'Maya')"
                     style="cursor:pointer; transition:0.2s;">
                    <div style="width:48px; height:48px; background:#e6f9f0; border-radius:12px; display:flex; align-items:center; justify-content:center; margin:0 auto 10px;">
                        <i class="bi bi-credit-card-fill" style="font-size:22px; color:#00b14f;"></i>
                    </div>
                    <p class="fw-bold mb-0" style="font-size:13px; color:#00b14f;">Maya</p>
                    <p class="text-muted mb-0" style="font-size:11px;"><i class="bi bi-lightning-fill text-warning" style="font-size:10px;"></i> Instant transfer</p>
                    <p style="font-size:11px; color:#dc3545; margin-bottom:0;">Fee: ₱12</p>
                </div>
            </div>
            <div class="col-md-4">
                <div class="payout-method-card border rounded-3 p-3 text-center" onclick="selectPayoutMethod(this, 'Bank')"
                     style="cursor:pointer; transition:0.2s;">
                    <div style="width:48px; height:48px; background:#f0f0f0; border-radius:12px; display:flex; align-items:center; justify-content:center; margin:0 auto 10px;">
                        <i class="bi bi-bank2" style="font-size:22px; color:#555;"></i>
                    </div>
                    <p class="fw-bold mb-0" style="font-size:13px; color:#444;">Bank Transfer</p>
                   <p class="text-muted mb-0" style="font-size:11px;"><i class="bi bi-clock" style="font-size:10px;"></i> 1-3 banking days</p>
                    <p class="text-muted mb-0" style="font-size:11px; color:#dc3545 !important;">Fee: ₱18</p>
                </div>
            </div>
        </div>

        <!-- Account Number Input -->
        <div id="payoutDetails" style="display:none;" class="mb-4">
            <label class="form-label fw-bold" style="font-size:13px;" id="payoutLabel">Account Number</label>
            <input type="text" class="form-control" id="payoutAccount" placeholder="Enter account number">
            <div class="mt-3">
                <label class="form-label fw-bold" style="font-size:13px;">Amount to Withdraw</label>
                <div class="input-group">
                    <span class="input-group-text">₱</span>
                  <input type="number" class="form-control" id="payoutAmount" placeholder="0.00" min="1"
    oninput="validatePayoutAmount(this)">
                </div>
              <p class="text-muted mt-1" style="font-size:11px;"><i class="bi bi-info-circle"></i> Minimum withdrawal: ₱50.00</p>
<p id="amountError" style="display:none; color:#dc3545; font-size:11px; margin-top:4px;"><i class="bi bi-exclamation-circle"></i> Amount exceeds your available balance!</p>
            </div>
        </div>

        <button class="btn w-100 fw-bold py-2" id="payoutBtn" onclick="submitPayout()"
                style="background:linear-gradient(135deg,#198754,#0d6efd); color:white; border-radius:12px; display:none;">
            <i class="bi bi-send me-1"></i> Request Payout
        </button>

     <!-- Payout History -->
<hr class="my-4">
<p class="fw-bold mb-3" style="font-size:14px;"><i class="bi bi-clock-history me-1 text-success"></i> Payout History</p>
<%
try {
    Integer phSellerId = (Integer) session.getAttribute("sellerId");
    if (phSellerId != null) {
        Connection phConn = DBConnection.getConnection();
        PreparedStatement phPs = phConn.prepareStatement(
            "SELECT payout_id, method, account_number, amount, status, requested_at " +
            "FROM payout_requests WHERE seller_id=? ORDER BY requested_at DESC LIMIT 20");
        phPs.setInt(1, phSellerId);
        ResultSet phRs = phPs.executeQuery();
        boolean hasHistory = false;
        while (phRs.next()) {
            hasHistory = true;
            String phStatus = phRs.getString("status");
            String phBadge = "warning";
            if ("Completed".equals(phStatus)) phBadge = "success";
            else if ("Rejected".equals(phStatus)) phBadge = "danger";
%>
<div class="border rounded-3 px-4 py-3 mb-3" style="background:#fafffe; font-size:13px;">
    <div class="d-flex justify-content-between align-items-start">
        <div class="d-flex align-items-center gap-3">
        <%
                String phMethod = phRs.getString("method");
                String phIconColor = "GCash".equals(phMethod) ? "#1a73e8" : "Maya".equals(phMethod) ? "#00b14f" : "#555";
                String phIconBg = "GCash".equals(phMethod) ? "#e8f0fe" : "Maya".equals(phMethod) ? "#e6f9f0" : "#f0f0f0";
                String phIcon = "GCash".equals(phMethod) ? "bi-phone-fill" : "Maya".equals(phMethod) ? "bi-credit-card-fill" : "bi-bank2";
            %>
            <div style="width:44px; height:44px; border-radius:12px; background:<%= phIconBg %>; display:flex; align-items:center; justify-content:center; flex-shrink:0;">
                <i class="bi <%= phIcon %>" style="font-size:20px; color:<%= phIconColor %>;"></i>
            </div>
            <div>
                <p class="fw-bold mb-0" style="font-size:14px;"><%= phRs.getString("method") %></p>
                <p class="text-muted mb-0" style="font-size:12px;"><%= phRs.getString("account_number") %></p>
                <p class="text-muted mb-0" style="font-size:11px;"><i class="bi bi-clock me-1"></i><%= phRs.getTimestamp("requested_at").toString().substring(0,16) %></p>
            </div>
        </div>
        <div class="text-end">
            <p class="fw-bold mb-1" style="font-size:16px; color:#198754;">₱<%= String.format("%.2f", phRs.getDouble("amount")) %></p>
            <span class="badge bg-<%= phBadge %> px-3 py-1" style="font-size:11px; border-radius:20px;"><%= phStatus %></span>
        </div>
    </div>
</div>
<%
        }
        phRs.close(); phPs.close(); phConn.close();
        if (!hasHistory) {
%>
<div class="text-center text-muted py-3" style="font-size:13px;">
    <i class="bi bi-inbox" style="font-size:28px; opacity:0.4;"></i>
    <p class="mt-2 mb-0">No payout requests yet.</p>
</div>
<% } } } catch (Exception phEx) { phEx.printStackTrace(); } %>
</div>
    </div><!-- end card-section -->
</div><!-- end tab-payout -->
        </div><!-- end col-md-9 -->
    </div><!-- end row -->
</div><!-- end container -->
<!-- PAYOUT CONFIRMATION MODAL -->
<div class="modal fade" id="payoutConfirmModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-body p-4">
                <div class="text-center mb-4">
                    <div style="width:60px; height:60px; background:#f0fdf4; border-radius:50%; display:flex; align-items:center; justify-content:center; margin:0 auto 12px;">
                        <i class="bi bi-send-fill" style="font-size:24px; color:#198754;"></i>
                    </div>
                    <h5 class="fw-bold mb-1">Confirm Payout</h5>
                    <p class="text-muted mb-0" style="font-size:13px;">Please review your payout details before proceeding.</p>
                </div>

                <div class="rounded-3 p-3 mb-3" style="background:#f8f9fa; border:1px solid #e9ecef;">
                    <div class="d-flex justify-content-between mb-2" style="font-size:13px;">
                        <span class="text-muted">Method</span>
                        <span class="fw-bold" id="confirmMethodText"></span>
                    </div>
                    <div class="d-flex justify-content-between mb-2" style="font-size:13px;">
                        <span class="text-muted">Account</span>
                        <span class="fw-bold" id="confirmAccountText"></span>
                    </div>
                  <hr class="my-2">
                    <div class="d-flex justify-content-between mb-2" style="font-size:13px;">
                        <span class="text-muted">Service Fee</span>
                        <span class="fw-bold text-danger" id="confirmFeeText"></span>
                    </div>
                    <div class="d-flex justify-content-between" style="font-size:16px;">
                        <span class="fw-bold">You'll Receive</span>
                        <span class="fw-bold text-success" id="confirmAmountText"></span>
                    </div>
                </div>

                <div class="d-flex gap-2">
                    <button class="btn btn-outline-secondary w-100" data-bs-dismiss="modal">
                        <i class="bi bi-x me-1"></i> Cancel
                    </button>
                    <button class="btn btn-success w-100 fw-bold" onclick="bootstrap.Modal.getInstance(document.getElementById('payoutConfirmModal')).hide(); setTimeout(proceedPayout, 300);">
                        <i class="bi bi-check2 me-1"></i> Proceed
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- PAYOUT LOADING MODAL -->
<div class="modal fade" id="payoutLoadingModal" tabindex="-1" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-dialog-centered modal-sm">
        <div class="modal-content rounded-4 border-0 shadow text-center p-4">
            <div class="spinner-border text-success mx-auto mb-3" style="width:48px; height:48px;"></div>
            <h6 class="fw-bold mb-1">Processing Payout</h6>
            <p class="text-muted mb-0" style="font-size:13px;">Please wait while we process your request...</p>
        </div>
    </div>
</div>

<!-- PAYOUT SUCCESS MODAL (GCash / Maya) -->
<div class="modal fade" id="payoutSuccessModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-body text-center p-5">
                <div style="width:70px; height:70px; background:linear-gradient(135deg,#198754,#20c997); border-radius:50%; display:flex; align-items:center; justify-content:center; margin:0 auto 20px;">
                    <i class="bi bi-check-lg" style="font-size:34px; color:white;"></i>
                </div>
                <h5 class="fw-bold mb-1">Payout Successful! 🎉</h5>
                <p class="text-muted mb-1" style="font-size:14px;">
                    <span id="successAmountText" class="fw-bold text-success"></span> has been sent to your <span id="successMethodText"></span> account.
                </p>
                <p class="text-muted" style="font-size:12px;">Transfer is instant. Check your app for confirmation.</p>
           <button class="btn btn-success px-4 mt-2" onclick="bootstrap.Modal.getInstance(document.getElementById('payoutSuccessModal')).hide(); setTimeout(()=>window.location.href='seller.jsp?tab=payout',300)">Done</button>
            </div>
        </div>
    </div>
</div>

<!-- PAYOUT BANK MODAL -->
<div class="modal fade" id="payoutBankModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-body text-center p-5">
                <div style="width:70px; height:70px; background:linear-gradient(135deg,#0d6efd,#6610f2); border-radius:50%; display:flex; align-items:center; justify-content:center; margin:0 auto 20px;">
                    <i class="bi bi-bank" style="font-size:30px; color:white;"></i>
                </div>
                <h5 class="fw-bold mb-1">Request Submitted!</h5>
                <p class="text-muted mb-1" style="font-size:14px;">
                    <span id="bankAmountText" class="fw-bold text-primary"></span> bank transfer is now being processed.
                </p>
                <p class="text-muted" style="font-size:12px;">Expected arrival: <strong>1-3 banking days</strong>. We'll notify you once it's completed.</p>
             <button class="btn btn-primary px-4 mt-2" onclick="bootstrap.Modal.getInstance(document.getElementById('payoutBankModal')).hide(); setTimeout(()=>window.location.href='seller.jsp?tab=payout',300)">Got It</button>
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


let selectedPayoutMethod = '';

function selectPayoutMethod(el, method) {
    selectedPayoutMethod = method;
    document.querySelectorAll('.payout-method-card').forEach(c => {
        c.style.background = '';
        c.style.borderColor = '#dee2e6';
        c.style.boxShadow = '';
    });
    el.style.borderColor = '#198754';
    el.style.boxShadow = '0 0 0 3px rgba(25,135,84,0.15)';
    el.style.background = '#f0fdf4';
    const labels = { GCash: 'GCash Number', Maya: 'Maya Number', Bank: 'Bank Account Number' };
    document.getElementById('payoutLabel').innerText = labels[method] || 'Account Number';
    document.getElementById('payoutDetails').style.display = 'block';
    document.getElementById('payoutBtn').style.display = 'block';
    document.getElementById('payoutAccount').placeholder = 'Enter your ' + labels[method];
}

function validatePayoutAmount(input) {
    const balance = <%= payoutBalance %>;
    const val = parseFloat(input.value);
    const fee = (selectedPayoutMethod === 'Bank') ? 18 : 12;
    const minAmount = 50 + fee;
    if (val > balance) {
        input.style.borderColor = '#dc3545';
        input.style.background = '#fff5f5';
        document.getElementById('amountError').innerText = 'Amount exceeds your available balance!';
        document.getElementById('amountError').style.display = 'block';
    } else if (val < minAmount && val > 0) {
        input.style.borderColor = '#dc3545';
        input.style.background = '#fff5f5';
        document.getElementById('amountError').innerText = 'Minimum withdrawal is ₱' + minAmount + ' (includes ₱' + fee + ' fee)';
        document.getElementById('amountError').style.display = 'block';
    } else {
        input.style.borderColor = '';
        input.style.background = '';
        document.getElementById('amountError').style.display = 'none';
    }
}
function submitPayout() {
    const account = document.getElementById('payoutAccount').value.trim();
    const amount = parseFloat(document.getElementById('payoutAmount').value);
    const balance = <%= payoutBalance %>;
    const method = selectedPayoutMethod;
    const fee = (method === 'Bank') ? 18 : 12;
    const receive = amount - fee;
    const minAmount = 50 + fee;
    if (!account) { alert('Please enter your account number!'); return; }
    if (!amount || amount < minAmount) { alert('Minimum withdrawal is ₱' + minAmount + ' (includes ₱' + fee + ' fee)!'); return; }
    if (amount > balance) { alert('Amount exceeds your available balance!'); return; }
  
    // Show confirmation modal first
    document.getElementById('confirmMethodText').innerText = method;
    document.getElementById('confirmAccountText').innerText = account;
    document.getElementById('confirmFeeText').innerText = '₱' + fee.toFixed(2);
    document.getElementById('confirmAmountText').innerText = '₱' + receive.toFixed(2);
    new bootstrap.Modal(document.getElementById('payoutConfirmModal')).show();
}

function proceedPayout() {
    bootstrap.Modal.getInstance(document.getElementById('payoutConfirmModal')).hide();
    const account = document.getElementById('payoutAccount').value.trim();
    const amount = parseFloat(document.getElementById('payoutAmount').value);
    const method = selectedPayoutMethod;
    const fee = (method === 'Bank') ? 18 : 12;
    const receive = amount - fee;
    setTimeout(() => {
    new bootstrap.Modal(document.getElementById('payoutLoadingModal')).show();

    fetch('PayoutServlet', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'method=' + encodeURIComponent(method) +
              '&account=' + encodeURIComponent(account) +
              '&amount=' + encodeURIComponent(receive)
    })
        .then(r => r.json())
        .then(data => {
            if (!data.success) {
                bootstrap.Modal.getInstance(document.getElementById('payoutLoadingModal')).hide();
                alert(data.message || 'Error processing payout.');
                return;
            }
            const isInstant = (method === 'GCash' || method === 'Maya');
            const delay = isInstant ? 2500 : 3000;
            setTimeout(() => {
                bootstrap.Modal.getInstance(document.getElementById('payoutLoadingModal')).hide();
                setTimeout(() => {
                    if (isInstant) {
                    	document.getElementById('successMethodText').innerText = method;
                        document.getElementById('successAmountText').innerText = '₱' + receive.toFixed(2);
                        new bootstrap.Modal(document.getElementById('payoutSuccessModal')).show();
                    } else {
                        document.getElementById('bankAmountText').innerText = '₱' + receive.toFixed(2);
                        new bootstrap.Modal(document.getElementById('payoutBankModal')).show();
                    }
                }, 300);
            }, delay);
        })
        .catch(() => {
            bootstrap.Modal.getInstance(document.getElementById('payoutLoadingModal')).hide();
            alert('Server error. Please try again.');
        });
    }, 300);
}

    // SIDEBAR NAV — hide shop+profile sections, show selected tab
    function showTab(tab, el) {
        // Hide shop and profile sections
        document.getElementById('section-shop').style.display = 'none';
        
        document.getElementById('section-stats').style.display = 'none';
        // Hide all other tabs
        document.querySelectorAll('.tab-content-section').forEach(t => t.style.display = 'none');
        document.querySelectorAll('.sidebar-nav a').forEach(a => a.classList.remove('active'));

        const otherTab = document.getElementById('tab-' + tab);
        if (otherTab) {
            otherTab.style.display = 'block';
        } else {
            // If no tab found, show shop+profile (home view)
            document.getElementById('section-stats').style.display = 'flex';
            document.getElementById('section-shop').style.display = 'block';
            
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
    document.getElementById('editBannerBtn2').style.display = 'block';
    document.getElementById('removeBannerBtn2').style.display = 'block';
}
    function cancelShopEdit() {
        document.querySelectorAll('#section-shop input, #section-shop select, #section-shop textarea').forEach(el => el.disabled = true);
        document.getElementById('editShopBtn').style.display = 'inline-block';
        document.getElementById('saveShopBtn').style.display = 'none';
        document.getElementById('cancelShopBtn').style.display = 'none';
        document.getElementById('editBannerBtn2').style.display = 'none';
        // Revert banner preview if not saved
        document.getElementById('bannerData').value = '';
        document.getElementById('removeBannerBtn2').style.display = 'none';
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

    function openAvatarCrop(input) {
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
     // avatarPreview removed
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
        document.getElementById('editBannerBtn2').style.display = 'block';
        document.getElementById('removeBannerBtn2').style.display = 'block';
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
        document.getElementById('section-stats').style.display = 'none';
        document.querySelectorAll('.tab-content-section').forEach(t => t.style.display = 'none');
        const ordersTab = document.getElementById('tab-orders');
        if (ordersTab) ordersTab.style.display = 'block';
        const ordersLink = document.querySelector('.sidebar-nav a[href*="orders"]');
        if (ordersLink) ordersLink.classList.add('active');
    } else if (tab === 'sales') {
        const link = document.querySelector('.sidebar-nav a[onclick*="sales"]');
        if (link) link.click();
    } else if (tab) {
        const link = document.querySelector('.sidebar-nav a[onclick*="' + tab + '"]');
        if (link) link.click();
    } else {
        document.getElementById('section-stats').style.display = 'flex';
        document.getElementById('section-shop').style.display = 'block';
        
    }
});
    function doLogout() {
        if (!confirm('Are you sure you want to logout?')) return;
        document.getElementById('logoutOverlay').style.display = 'flex';
        setTimeout(() => { window.location.href = 'LogoutServlet'; }, 1500);
    }
    
   

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
    
    function addVariationRow() {
        const container = document.getElementById('variationsContainer');
        const row = document.createElement('div');
        row.className = 'border rounded-3 p-2 mb-1';
        row.innerHTML = `
            <div class="d-flex gap-2 align-items-center flex-wrap">
                <select name="variationType[]" class="form-select form-select-sm" style="width:110px; flex-shrink:0;">
                    <option value="Size">Size</option>
                    <option value="Color">Color</option>
                    <option value="Kilos">Kilos</option>
                    <option value="Style">Style</option>
                </select>
                <input type="text" name="variationValue[]" class="form-control form-control-sm"
                       placeholder="e.g. XL, Red, 5kg" style="width:180px;" required>
                <button type="button" class="btn btn-outline-danger btn-sm px-2"
                        onclick="this.closest('.border').remove()">
                    <i class="bi bi-x"></i>
                </button>
            </div>
        `;
        container.appendChild(row);
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

    function editProduct(id, name, price, stock, description, category, originalPrice, categoryId) {
        document.getElementById('editProductId').value = id;
        document.getElementById('editProductName').value = name;
        document.getElementById('editProductPrice').value = price;
        document.getElementById('editProductStock').value = stock;
        document.getElementById('editProductDesc').value = description;
        document.getElementById('editOriginalPrice').value = originalPrice || '';
        if (categoryId) document.getElementById('editCategoryId').value = categoryId;

        // Load existing variations via fetch
        const container = document.getElementById('editVariationsContainer');
        container.innerHTML = '<p class="text-muted" style="font-size:12px;">Loading variations...</p>';
        fetch('GetVariationsServlet?productId=' + id)
            .then(r => r.json())
            .then(vars => {
                container.innerHTML = '';
                vars.forEach(v => addEditVariationRow(v));
            })
            .catch(() => { container.innerHTML = ''; });

        const eModal = document.getElementById('editProductModal');
        eModal.style.display = 'flex';
        eModal.scrollTop = 0;
        document.querySelector('.navbar-shopeasy').style.zIndex = '0';
    }

    function addEditVariationRow(v) {
        const container = document.getElementById('editVariationsContainer');
        const row = document.createElement('div');
        row.className = 'border rounded-3 p-2 mb-1';
        const varId = v ? v.id : '';
        const varVal = v ? v.value : '';
        const varPrice = (v && v.price) ? v.price : '';
        const varStock = (v && v.stock !== null && v.stock !== undefined) ? v.stock : '';
        const selSize  = (v && v.type==='Size')  ? 'selected' : '';
        const selColor = (v && v.type==='Color') ? 'selected' : '';
        const selKilos = (v && v.type==='Kilos') ? 'selected' : '';
        const selStyle = (v && v.type==='Style') ? 'selected' : '';
        row.innerHTML =
            '<div class="d-flex gap-2 align-items-center flex-wrap">' +
                '<input type="hidden" name="editVarId[]" value="' + varId + '">' +
                '<select name="editVarType[]" class="form-select form-select-sm" style="width:110px; flex-shrink:0;">' +
                    '<option value="Size" ' + selSize + '>Size</option>' +
                    '<option value="Color" ' + selColor + '>Color</option>' +
                    '<option value="Kilos" ' + selKilos + '>Kilos</option>' +
                    '<option value="Style" ' + selStyle + '>Style</option>' +
                '</select>' +
                '<input type="text" name="editVarValue[]" class="form-control form-control-sm" placeholder="e.g. XL, Red" style="width:180px;" value="' + varVal + '" required>' +
                '<button type="button" class="btn btn-outline-danger btn-sm px-2" onclick="this.closest(\'.border\').remove()">' +
                    '<i class="bi bi-x"></i>' +
                '</button>' +
            '</div>';
        container.appendChild(row);
    }
    
    function closeEditModal() {
        document.getElementById('editProductModal').style.display = 'none';
        document.querySelector('.navbar-shopeasy').style.zIndex = '';
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
    
    function approveCancel(orderId, action) {
        const label = action === 'approve'
            ? 'Approve cancellation? Stock will be restored.'
            : 'Decline this cancellation request? Order will return to Processing.';
        if (!confirm(label)) return;

        fetch('ApproveCancelServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'orderId=' + orderId + '&action=' + action
        })
        .then(res => res.json())
        .then(data => {
            if (data.success) {
                document.getElementById('successBarMsg').textContent =
                    action === 'approve'
                        ? 'Cancellation approved. Order cancelled. ✅'
                        : 'Cancellation declined. Order returned to Processing. ✅';
                document.getElementById('successBar').style.display = 'block';
                setTimeout(() => {
                    document.getElementById('successBar').style.display = 'none';
                    location.reload();
                }, 1500);
            } else {
                alert('Error: ' + (data.message || 'Something went wrong.'));
            }
        })
        .catch(err => alert('Error: ' + err));
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
<div id="editProductModal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.5); z-index:99999; align-items:center; justify-content:center; overflow-y:auto;" onclick="if(event.target===this)closeEditModal()">

<div style="background:white; border-radius:20px; padding:32px; width:92%; max-width:580px; margin:0 auto 40px auto; box-shadow:0 20px 60px rgba(0,0,0,0.2);">
<div class="d-flex align-items-center justify-content-between mb-4 pb-2 border-bottom">
    <h5 class="fw-bold mb-0"><i class="bi bi-pencil-fill text-success me-2"></i>Edit Product</h5>
    <button type="button" onclick="closeEditModal()" style="background:none; border:none; font-size:20px; color:#aaa; cursor:pointer;">&times;</button>
</div>
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
                <div class="col-md-6">
   <label class="form-label fw-bold" style="font-size:13px;">Discounted Price (₱) <span class="text-muted fw-normal" style="font-size:11px;">optional</span></label>
    <input type="number" name="originalPrice" id="editOriginalPrice" class="form-control" step="0.01" min="0">
</div>
                <div class="col-12">
                    <label class="form-label fw-bold" style="font-size:13px;">Category</label>
                    <select name="categoryId" id="editCategoryId" class="form-select" required>
                        <option value="">Select category</option>
                        <%
                            java.sql.Connection editCatConn = com.shopeasy.DBConnection.getConnection();
                            java.sql.PreparedStatement editCatPs = editCatConn.prepareStatement("SELECT category_id, name FROM category ORDER BY name");
                            java.sql.ResultSet editCatRs = editCatPs.executeQuery();
                            while (editCatRs.next()) {
                        %>
                            <option value="<%= editCatRs.getInt("category_id") %>"><%= editCatRs.getString("name") %></option>
                        <%
                            }
                            editCatRs.close(); editCatPs.close(); editCatConn.close();
                        %>
                    </select>
                </div>
                <div class="col-12">
                    <label class="form-label fw-bold" style="font-size:13px;">Description</label>
                    <textarea name="description" id="editProductDesc" class="form-control" rows="3"></textarea>
                </div>
                <div class="col-12">
    <label class="form-label fw-bold" style="font-size:13px;">
        Variations <span class="text-muted fw-normal" style="font-size:11px;">optional</span>
    </label>
    <div id="editVariationsContainer" class="d-flex flex-column gap-1 mb-2"></div>
    <button type="button" class="btn btn-outline-success btn-sm" onclick="addEditVariationRow()">
        <i class="bi bi-plus"></i> Add Variation
    </button>
</div>
<div class="col-12 d-flex gap-2 justify-content-end">
    <button type="button" class="btn btn-outline-secondary" onclick="closeEditModal()">Cancel</button>
    <button type="submit" class="btn btn-success px-4">Save Changes</button>
</div>
            </div>
        </form>
    </div>
</div>
<!-- SELLER CANCEL ORDER MODAL -->
<div id="sellerCancelModal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.5); z-index:9999; align-items:center; justify-content:center;">
    <div style="background:white; border-radius:16px; padding:28px; width:90%; max-width:420px;">
        <h6 class="fw-bold mb-3"><i class="bi bi-x-circle text-danger me-2"></i>Cancel Order</h6>
        <p class="text-muted mb-3" style="font-size:13px;">Please provide a reason for cancelling this order. The customer will be notified.</p>
        <input type="hidden" id="sellerCancelOrderId">
        <div class="mb-3">
            <label class="form-label fw-bold" style="font-size:13px;">Reason</label>
            <select id="sellerCancelReason" class="form-select mb-2">
                <option value="">-- Select a reason --</option>
                <option value="Out of stock">Out of stock</option>
                <option value="Pricing error">Pricing error</option>
                <option value="Cannot fulfill order">Cannot fulfill order</option>
                <option value="System/logistics issue">System/logistics issue</option>
                <option value="Other">Other</option>
            </select>
            <textarea id="sellerCancelOther" class="form-control" rows="2" placeholder="Additional details (optional)" style="font-size:13px;"></textarea>
        </div>
        <div id="sellerCancelError" class="text-danger mb-2" style="display:none; font-size:13px;">Please select a reason.</div>
        <div class="d-flex gap-2 justify-content-end">
            <button class="btn btn-outline-secondary btn-sm" onclick="closeSellerCancelModal()">Back</button>
            <button class="btn btn-danger btn-sm" onclick="submitSellerCancel()">
                <i class="bi bi-x-circle"></i> Confirm Cancel
            </button>
        </div>
    </div>
</div>

<%@ include file="modals.jsp" %>
<script>


function updatePassword() {
    const current = document.getElementById('currentPw').value.trim();
    const newPw = document.getElementById('newPw').value.trim();
    const confirm = document.getElementById('confirmPw').value.trim();

    document.getElementById('securitySuccess').style.display = 'none';
    document.getElementById('securityError').style.display = 'none';

    if (!current || !newPw || !confirm) {
        document.getElementById('securityErrorText').textContent = 'Please fill in all fields.';
        document.getElementById('securityError').style.display = 'block';
        return;
    }
    if (newPw !== confirm) {
        document.getElementById('securityErrorText').textContent = 'New passwords do not match.';
        document.getElementById('securityError').style.display = 'block';
        return;
    }
    if (newPw.length < 6) {
        document.getElementById('securityErrorText').textContent = 'Password must be at least 6 characters.';
        document.getElementById('securityError').style.display = 'block';
        return;
    }

    const btn = document.getElementById('updatePwBtn');
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span> Updating...';

    const overlay = document.createElement('div');
    overlay.id = 'pwOverlay';
    overlay.style.cssText = 'display:flex; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.9); z-index:9999; flex-direction:column; align-items:center; justify-content:center; gap:12px;';
    overlay.innerHTML = '<div class="spinner-border text-success" style="width:3rem; height:3rem;"></div><p class="fw-bold text-success fs-5">Updating password...</p><p class="text-muted" style="font-size:13px;">Please wait a moment</p>';
    document.body.appendChild(overlay);
    setTimeout(() => { document.getElementById('pwOverlay')?.remove(); }, 5000);

    fetch('UpdatePasswordServlet', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'currentPassword=' + encodeURIComponent(current) + '&newPassword=' + encodeURIComponent(newPw)
    })
    .then(r => r.json())
    .then(data => new Promise(resolve => setTimeout(() => resolve(data), 1500)))
    .then(data => {
        document.getElementById('pwOverlay')?.remove();
        btn.disabled = false;
        btn.innerHTML = '<i class="bi bi-shield-check"></i> Update Password';
        if (data.success) {
            document.getElementById('currentPw').value = '';
            document.getElementById('newPw').value = '';
            document.getElementById('confirmPw').value = '';
            document.getElementById('securitySuccessText').textContent = 'Password updated successfully!';
            document.getElementById('securitySuccess').style.display = 'block';
        } else {
            document.getElementById('securityErrorText').textContent = data.message || 'Current password is incorrect.';
            document.getElementById('securityError').style.display = 'block';
        }
    })
    .catch(() => {
        document.getElementById('pwOverlay')?.remove();
        btn.disabled = false;
        btn.innerHTML = '<i class="bi bi-shield-check"></i> Update Password';
        document.getElementById('securityErrorText').textContent = 'Server error. Please try again.';
        document.getElementById('securityError').style.display = 'block';
    });
}
function sellerMarkAllRead() {
    fetch('NotificationServlet', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'action=markAllRead&userType=seller'
    }).then(() => {
        document.querySelectorAll('.seller-notif-item').forEach(el => {
            el.style.background = '#f8f9fa';
            el.style.border = '1px solid #eee';
            const icon = el.querySelector('div[style*="border-radius:50%"]');
            if (icon) icon.style.background = '#dee2e6';
            const badge = el.querySelector('.badge.bg-success');
            if (badge) badge.remove();
            const msg = el.querySelector('p[style*="font-weight"]');
            if (msg) msg.style.fontWeight = '400';
        });
        document.querySelectorAll('.badge.bg-danger').forEach(b => b.remove());
        showToast('All notifications marked as read!');
    });
}

function sellerMarkOneRead(notifId, el) {
    const isUnread = el.style.background === 'rgb(237, 250, 241)' || el.getAttribute('data-read') !== '1';
    if (isUnread) {
        fetch('NotificationServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'action=markRead&notifId=' + notifId + '&userType=seller'
        }).then(() => {
            el.style.background = '#f8f9fa';
            el.style.border = '1px solid #eee';
            el.setAttribute('data-read', '1');
            const icon = el.querySelector('div[style*="border-radius:50%"]');
            if (icon) icon.style.background = '#dee2e6';
            const badge = el.querySelector('.badge.bg-success');
            if (badge) badge.remove();
            const msg = el.querySelector('p[style*="font-weight"]');
            if (msg) msg.style.fontWeight = '400';
         // Update sidebar badge
            const sidebarBadge = document.querySelector('.sidebar-nav .badge.bg-danger');
            if (sidebarBadge) {
                const count = parseInt(sidebarBadge.textContent) - 1;
                if (count <= 0) sidebarBadge.remove();
                else sidebarBadge.textContent = count;
            }
            // Update header badge
            const headerBadge = document.querySelector('#tab-notifications .badge.bg-danger');
            if (headerBadge) {
                const count = parseInt(headerBadge.textContent) - 1;
                if (count <= 0) headerBadge.remove();
                else headerBadge.textContent = count;
            }
        });
    }
}

function sellerClearAll() {
    if (!confirm('Clear all notifications?')) return;
    fetch('NotificationServlet', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'action=clearAll&userType=seller'
    }).then(() => {
        document.getElementById('sellerNotifList').innerHTML = `
            <div class="text-center py-5 text-muted">
                <i class="bi bi-bell-slash fs-1 opacity-25"></i>
                <p class="mt-2">No notifications yet.</p>
            </div>`;
        document.querySelectorAll('.badge.bg-danger').forEach(b => b.remove());
        showToast('All notifications cleared!');
    });
}
function openSellerCancelModal(orderId) {
    document.getElementById('sellerCancelOrderId').value = orderId;
    document.getElementById('sellerCancelReason').value = '';
    document.getElementById('sellerCancelOther').value = '';
    document.getElementById('sellerCancelError').style.display = 'none';
    document.getElementById('sellerCancelModal').style.display = 'flex';
}

function closeSellerCancelModal() {
    document.getElementById('sellerCancelModal').style.display = 'none';
}

function submitSellerCancel() {
    const orderId = document.getElementById('sellerCancelOrderId').value;
    const reason = document.getElementById('sellerCancelReason').value;
    const other = document.getElementById('sellerCancelOther').value.trim();
    
    if (!reason) {
        document.getElementById('sellerCancelError').style.display = 'block';
        return;
    }
    
    const fullReason = reason === 'Other' && other 
        ? other 
        		: reason + (other ? ' - ' + other : '') + ' (Cancelled by Seller)';

    fetch('UpdateOrderServlet', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'orderId=' + orderId + '&status=Cancelled&reason=' + encodeURIComponent(fullReason)
    })
    .then(res => res.text())
    .then(() => {
        closeSellerCancelModal();
        document.getElementById('successBarMsg').textContent = 'Order cancelled successfully. ✅';
        document.getElementById('successBar').style.display = 'block';
        setTimeout(() => {
            document.getElementById('successBar').style.display = 'none';
            location.reload();
        }, 1500);
    })
    .catch(err => alert('Error: ' + err));
}
//SHOP LOGO CROP
let shopLogoImg = new Image();
let shopLogoOffX = 0, shopLogoOffY = 0;
let shopLogoIsDragging = false;
let shopLogoStartX, shopLogoStartY;
let shopLogoScale = 1;
const SHOP_LOGO_SIZE = 300;

function openShopLogoCrop(input) {
    if (input.files && input.files[0]) {
        const reader = new FileReader();
        reader.onload = function(e) {
            document.getElementById('shopLogoCropModal').style.display = 'flex';
            shopLogoScale = 1;
            shopLogoImg = new Image();
            shopLogoImg.onload = function() {
                const fitScale = Math.max(SHOP_LOGO_SIZE / shopLogoImg.width, SHOP_LOGO_SIZE / shopLogoImg.height);
                shopLogoScale = fitScale;
                document.getElementById('shopLogoCropZoom').min = fitScale;
                document.getElementById('shopLogoCropZoom').value = fitScale;
                shopLogoOffX = (SHOP_LOGO_SIZE - shopLogoImg.width * shopLogoScale) / 2;
                shopLogoOffY = (SHOP_LOGO_SIZE - shopLogoImg.height * shopLogoScale) / 2;
                drawShopLogoCrop();
            };
            shopLogoImg.src = e.target.result;
            const canvas = document.getElementById('shopLogoCropCanvas');
            canvas.width = SHOP_LOGO_SIZE;
            canvas.height = SHOP_LOGO_SIZE;
            const newCanvas = canvas.cloneNode(true);
            canvas.parentNode.replaceChild(newCanvas, canvas);
            const c = document.getElementById('shopLogoCropCanvas');
            c.addEventListener('mousedown', (e) => { shopLogoIsDragging = true; shopLogoStartX = e.clientX - shopLogoOffX; shopLogoStartY = e.clientY - shopLogoOffY; });
            c.addEventListener('mousemove', (e) => { if (!shopLogoIsDragging) return; shopLogoOffX = e.clientX - shopLogoStartX; shopLogoOffY = e.clientY - shopLogoStartY; clampShopLogo(); drawShopLogoCrop(); });
            c.addEventListener('mouseup', () => shopLogoIsDragging = false);
            c.addEventListener('mouseleave', () => shopLogoIsDragging = false);
            document.getElementById('shopLogoCropZoom').oninput = function() {
                const oldScale = shopLogoScale;
                shopLogoScale = parseFloat(this.value);
                shopLogoOffX = SHOP_LOGO_SIZE/2 - (SHOP_LOGO_SIZE/2 - shopLogoOffX) * (shopLogoScale / oldScale);
                shopLogoOffY = SHOP_LOGO_SIZE/2 - (SHOP_LOGO_SIZE/2 - shopLogoOffY) * (shopLogoScale / oldScale);
                clampShopLogo();
                drawShopLogoCrop();
            };
        };
        reader.readAsDataURL(input.files[0]);
    }
}

function clampShopLogo() {
    const w = shopLogoImg.width * shopLogoScale;
    const h = shopLogoImg.height * shopLogoScale;
    if (shopLogoOffX > 0) shopLogoOffX = 0;
    if (shopLogoOffY > 0) shopLogoOffY = 0;
    if (shopLogoOffX + w < SHOP_LOGO_SIZE) shopLogoOffX = SHOP_LOGO_SIZE - w;
    if (shopLogoOffY + h < SHOP_LOGO_SIZE) shopLogoOffY = SHOP_LOGO_SIZE - h;
}

function drawShopLogoCrop() {
    const canvas = document.getElementById('shopLogoCropCanvas');
    const ctx = canvas.getContext('2d');
    canvas.width = SHOP_LOGO_SIZE; canvas.height = SHOP_LOGO_SIZE;
    ctx.fillStyle = '#ffffff'; ctx.fillRect(0, 0, SHOP_LOGO_SIZE, SHOP_LOGO_SIZE);
    ctx.drawImage(shopLogoImg, shopLogoOffX, shopLogoOffY, shopLogoImg.width * shopLogoScale, shopLogoImg.height * shopLogoScale);
    ctx.save();
    ctx.fillStyle = 'rgba(0,0,0,0.5)'; ctx.fillRect(0, 0, SHOP_LOGO_SIZE, SHOP_LOGO_SIZE);
    ctx.globalCompositeOperation = 'destination-out';
    ctx.beginPath(); ctx.arc(SHOP_LOGO_SIZE/2, SHOP_LOGO_SIZE/2, SHOP_LOGO_SIZE/2 - 2, 0, Math.PI * 2); ctx.fill();
    ctx.restore();
    ctx.strokeStyle = '#198754'; ctx.lineWidth = 3;
    ctx.beginPath(); ctx.arc(SHOP_LOGO_SIZE/2, SHOP_LOGO_SIZE/2, SHOP_LOGO_SIZE/2 - 2, 0, Math.PI * 2); ctx.stroke();
}

function applyShopLogoCrop() {
    const output = document.createElement('canvas');
    output.width = 300; output.height = 300;
    const ctx = output.getContext('2d');
    ctx.beginPath(); ctx.arc(150, 150, 150, 0, Math.PI * 2); ctx.clip();
    ctx.drawImage(shopLogoImg, shopLogoOffX, shopLogoOffY, shopLogoImg.width * shopLogoScale, shopLogoImg.height * shopLogoScale);
    const result = output.toDataURL('image/png');
    document.getElementById('shopLogoPreview').src = result;
    document.getElementById('sidebarAvatar').src = result;
    document.getElementById('shopLogoData').value = result;
    closeShopLogoCropModal();
    document.getElementById('savingOverlay').style.display = 'flex';
    setTimeout(() => {
        const result2 = document.getElementById('shopLogoData').value;
        fetch('UpdateSellerServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'action=shopLogo&shopLogo=' + encodeURIComponent(result2)
        }).then(() => {
            document.getElementById('savingOverlay').style.display = 'none';
            document.getElementById('successBarMsg').textContent = 'Shop logo updated! ✅';
            document.getElementById('successBar').style.display = 'block';
            setTimeout(() => document.getElementById('successBar').style.display = 'none', 3000);
        });
    }, 1500);
}

function closeShopLogoCropModal() {
    document.getElementById('shopLogoCropModal').style.display = 'none';
}

function sellerRefundAction(refundId, action) {
    const label = action === 'approve'
        ? 'Approve this refund? Amount will be deducted from your revenue.'
        : 'Reject this refund request?';
    if (!confirm(label)) return;

    fetch('RefundServlet', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'action=' + action + '&refundId=' + refundId
    })
    .then(r => r.json())
    .then(data => {
        if (data.success) {
            document.getElementById('successBarMsg').textContent =
                action === 'approve' ? 'Refund approved! ✅' : 'Refund rejected. ✅';
            document.getElementById('successBar').style.display = 'block';
            setTimeout(() => {
                document.getElementById('successBar').style.display = 'none';
                location.reload();
            }, 1500);
        } else {
            alert(data.message || 'Error processing refund.');
        }
    })
    .catch(() => alert('Server error. Please try again.'));
}

</script>
<!-- SHOP LOGO CROP MODAL -->
<div class="crop-modal-overlay" id="shopLogoCropModal">
    <div class="crop-container">
        <p class="fw-bold mb-3 text-center" style="font-size:15px;"><i class="bi bi-crop text-success"></i> Crop Shop Logo</p>
        <div style="width:300px; height:300px; margin:0 auto; overflow:hidden; border-radius:8px;">
            <canvas id="shopLogoCropCanvas"></canvas>
        </div>
        <div class="mt-3 d-flex justify-content-between align-items-center">
            <div>
                <label style="font-size:12px;" class="text-muted">Zoom</label>
                <input type="range" id="shopLogoCropZoom" min="0.5" max="3" step="0.01" value="1" style="width:120px;">
            </div>
            <div class="d-flex gap-2">
                <button class="btn btn-outline-secondary btn-sm" onclick="closeShopLogoCropModal()">
                    <i class="bi bi-x"></i> Cancel
                </button>
                <button class="btn btn-success btn-sm" onclick="applyShopLogoCrop()">
                    <i class="bi bi-check2"></i> Apply
                </button>
            </div>
        </div>
    </div>
</div>

</body>
</html>