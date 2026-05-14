<%@ page session="true" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    if(session.getAttribute("userId") == null) {
        response.sendRedirect("index.jsp");
        return;
    }
String userName = (String) session.getAttribute("userName");
String userFirstName = (String) session.getAttribute("userFirstName");
String userLastName = (String) session.getAttribute("userLastName");
String userMiddleInitial = (String) session.getAttribute("userMiddleInitial");
if (userFirstName == null) userFirstName = "";
if (userLastName == null) userLastName = "";
if (userMiddleInitial == null) userMiddleInitial = "";
    String userEmail = (String) session.getAttribute("userEmail");
    String userPhone = (String) session.getAttribute("userPhone");
    String userUsername = (String) session.getAttribute("userUsername");
    String userBirthday = (String) session.getAttribute("userBirthday");
    String userGender = (String) session.getAttribute("userGender");
    String userRole = (String) session.getAttribute("userRole");
    if (userRole == null) userRole = "customer";
    // Fetch seller_id if seller or both
    int _custSellerPageId = 0;
    if ("seller".equals(userRole) || "both".equals(userRole)) {
        try {
            int _csUserId = (int) session.getAttribute("userId");
            java.sql.Connection _csConn = com.shopeasy.DBConnection.getConnection();
            java.sql.PreparedStatement _csPs = _csConn.prepareStatement(
                "SELECT seller_id FROM seller WHERE user_id=? LIMIT 1");
            _csPs.setInt(1, _csUserId);
            java.sql.ResultSet _csRs = _csPs.executeQuery();
            if (_csRs.next()) _custSellerPageId = _csRs.getInt("seller_id");
            _csRs.close(); _csPs.close(); _csConn.close();
        } catch(Exception ex) {}
    }
    String userBanReason = "";
    try {
        int banCheckId = (int) session.getAttribute("userId");
        java.sql.Connection banConn = com.shopeasy.DBConnection.getConnection();
        java.sql.PreparedStatement banPs = banConn.prepareStatement("SELECT status, ban_reason FROM users WHERE user_id=?");
        banPs.setInt(1, banCheckId);
        java.sql.ResultSet banRs = banPs.executeQuery();
        String userStatus = "";
        if (banRs.next()) {
            userStatus = banRs.getString("status") != null ? banRs.getString("status") : "";
            userBanReason = banRs.getString("ban_reason") != null ? banRs.getString("ban_reason") : "Violation of platform policies.";
        }
        banRs.close(); banPs.close(); banConn.close();
        if ("Banned".equals(userStatus)) {
    %>
    <div class="modal fade show" id="bannedModal" tabindex="-1" style="display:block;background:rgba(0,0,0,0.6);" data-bs-backdrop="static" data-bs-keyboard="false">
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content border-danger">
          <div class="modal-header bg-danger text-white">
            <h5 class="modal-title"><i class="bi bi-slash-circle me-2"></i>Account Banned</h5>
          </div>
          <div class="modal-body text-center py-4">
            <i class="bi bi-slash-circle text-danger" style="font-size:48px;"></i>
            <h5 class="mt-3 fw-bold">Your account has been banned</h5>
            <p class="text-muted">Reason: <strong><%= userBanReason %></strong></p>
            <p class="text-muted" style="font-size:13px;">If you believe this is a mistake, please contact support.</p>
          </div>
          <div class="modal-footer justify-content-center">
            <a href="LogoutServlet" class="btn btn-danger"><i class="bi bi-box-arrow-right me-1"></i>Logout</a>
          </div>
        </div>
      </div>
    </div>
    <script>document.addEventListener('DOMContentLoaded',function(){new bootstrap.Modal(document.getElementById('bannedModal'),{backdrop:'static',keyboard:false}).show();});</script>
    <%
        }
    } catch(Exception eBan) { /* ignore */ }
    String initial = (userFirstName != null && !userFirstName.isEmpty()) ? String.valueOf(userFirstName.charAt(0)).toUpperCase() : "?";

    // Cart count
    int navCartCount = 0;
    try {
        int cartUserId = (int) session.getAttribute("userId");
        java.sql.Connection cartConn = com.shopeasy.DBConnection.getConnection();
        java.sql.PreparedStatement cartPs = cartConn.prepareStatement(
            "SELECT COALESCE(SUM(ci.quantity), 0) FROM cart c " +
            "JOIN cartitem ci ON c.cart_id = ci.cart_id " +
            "WHERE c.customer_id = ?");
        cartPs.setInt(1, cartUserId);
        java.sql.ResultSet cartRs = cartPs.executeQuery();
        if (cartRs.next()) navCartCount = cartRs.getInt(1);
        cartRs.close(); cartPs.close(); cartConn.close();
    } catch (Exception ex) { ex.printStackTrace(); }
%>
 <!-- NOTIFICATIONS TAB -->
            <%
            int unreadCount = 0;
            java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("MMM d, yyyy h:mm a");
         // No timezone conversion needed - already stored correctly
            // Store as formatted string na
            java.util.List<java.util.Map<String, Object>> notifList = new java.util.ArrayList<>();
            try {
                int notifUserId = (int) session.getAttribute("userId");
                java.sql.Connection notifConn = com.shopeasy.DBConnection.getConnection();
                java.sql.PreparedStatement notifPs = notifConn.prepareStatement(
                    "SELECT * FROM notifications WHERE user_id=? AND user_type='customer' ORDER BY created_at DESC LIMIT 50");
                notifPs.setInt(1, notifUserId);
                java.sql.ResultSet notifRs = notifPs.executeQuery();
                while (notifRs.next()) {
                    java.util.Map<String, Object> n = new java.util.HashMap<>();
                    n.put("id", notifRs.getInt("notif_id"));
                    n.put("message", notifRs.getString("message"));
                    n.put("isRead", notifRs.getInt("is_read") == 1);
                    n.put("createdAt", sdf.format(notifRs.getTimestamp("created_at")));
                    notifList.add(n);
                    if (notifRs.getInt("is_read") == 0) unreadCount++;
                }
                notifRs.close(); notifPs.close(); notifConn.close();
            } catch (Exception ex) { ex.printStackTrace(); }
            %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Profile - ShopEasy</title>
   <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css">
    <style>
    #reviewModal > div {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    max-height: 90vh;
    overflow-y: auto;
}
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
    background: linear-gradient(90deg, #e8f0fe, #f0f4ff);
    color: #0d6efd;
    border-left-color: #0d6efd;
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
    border-bottom: 2px solid #e8f0fe;
}
.stat-box {
    background: linear-gradient(135deg, #f0f4ff, #e8f0fe);
    border-radius: 16px;
    padding: 16px;
    text-align: center;
    border: 1px solid #dce8fd;
    transition: 0.2s;
}
.tab-content-section { display: none; }
.tab-content-section.active { display: block; }
.navbar-shopeasy { background: white; box-shadow: 0 2px 8px rgba(0,0,0,0.08); }
.sidebar-avatar {
    width: 80px; height: 80px;
    border-radius: 50%;
    object-fit: cover;
    border: 3px solid white;
    box-shadow: 0 4px 12px rgba(13,110,253,0.3);
}
.stat-box:hover { transform: translateY(-2px); box-shadow: 0 4px 16px rgba(13,110,253,0.1); }
.stat-box .stat-num { font-size: 26px; font-weight: 800; color: #0d6efd; }
.stat-box .stat-label { font-size: 12px; color: #666; font-weight: 500; }
        
        .avatar-circle {
            width: 100px; height: 100px;
            border-radius: 50%;
            background: #0d6efd;
            color: white;
            font-size: 36px;
            font-weight: 700;
            display: flex;
            align-items: center;
            justify-content: center;
            border: 3px solid #0d6efd;
            margin: 0 auto;
        }
        .avatar-circle-sm {
            width: 80px; height: 80px;
            border-radius: 50%;
            background: #0d6efd;
            color: white;
            font-size: 28px;
            font-weight: 700;
            display: flex;
            align-items: center;
            justify-content: center;
            border: 3px solid #0d6efd;
            margin: 0 auto 8px;
        }
        .avatar-upload {
            position: relative;
            width: 100px;
            height: 100px;
            margin: 0 auto 16px;
        }
        .upload-btn {
    position: absolute;
    bottom: 2px; right: 2px;
    background: #0d6efd;
    color: white;
    border: none;
    border-radius: 50%;
    width: 28px; height: 28px;
    font-size: 12px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
}
        .order-badge { font-size: 11px; padding: 3px 8px; border-radius: 20px; }
        .order-item {
            border: 1px solid #e8f0fe;
            border-radius: 12px;
            padding: 14px;
            margin-bottom: 12px;
            transition: 0.2s;
        }
        .order-item:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.08); }
        .order-img { width: 60px; height: 60px; border-radius: 8px; object-fit: cover; }
        .review-star { color: #ffc107; font-size: 13px; }
        .address-card {
            border: 1px solid #e0e0e0;
            border-radius: 12px;
            padding: 14px;
            margin-bottom: 12px;
            position: relative;
            transition: 0.2s;
        }
        .address-card.default { border-color: #0d6efd; background: #f0f4ff; }
        .address-card:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.08); }
        .default-badge {
            position: absolute;
            top: 10px; right: 10px;
            background: #0d6efd;
            color: white;
            font-size: 10px;
            padding: 2px 8px;
            border-radius: 20px;
        }
        
       .password-strength { height: 4px; border-radius: 2px; margin-top: 6px; transition: 0.3s; }
        input[type="password"]::-ms-reveal,
        input[type="password"]::-ms-clear,
        input[type="text"]::-ms-reveal { display: none; }
        input::-webkit-credentials-auto-fill-button { display: none !important; }
        input[type="password"] { -webkit-text-security: disc; }
        ::-webkit-inner-spin-button { display: none; }
        .crop-modal-overlay {
            display: none; position: fixed; top: 0; left: 0;
            width: 100%; height: 100%; background: rgba(0,0,0,0.8);
            z-index: 99999; flex-direction: column; align-items: center; justify-content: center;
        }
        .crop-container { background: white; border-radius: 16px; padding: 20px; width: 90%; max-width: 500px; }
        #customerCropCanvas { display: block; width: 300px; height: 300px; cursor: grab; border-radius: 4px; }

#starRating i {
    cursor: pointer !important;
    pointer-events: auto !important;
    font-size: 2rem;
}
#starRating {
    pointer-events: auto !important;
}
/* MOBILE BOTTOM NAV */
@media (max-width: 767px) {
    .col-md-3 { display: none !important; }
    .col-md-9 { width: 100% !important; max-width: 100% !important; flex: 0 0 100% !important; }
    body { padding-bottom: 70px; }
    .mobile-bottom-nav {
        display: flex !important;
        position: fixed;
        bottom: 0; left: 0; right: 0;
        background: white;
        border-top: 1px solid #e8f0fe;
        z-index: 1000;
        box-shadow: 0 -2px 12px rgba(0,0,0,0.08);
    }
    .mobile-bottom-nav a {
        flex: 1;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: 8px 4px;
        color: #888;
        text-decoration: none;
        font-size: 10px;
        gap: 3px;
        transition: 0.2s;
        border-top: 2px solid transparent;
    }
    .mobile-bottom-nav a.active {
        color: #0d6efd;
        border-top-color: #0d6efd;
    }
    .mobile-bottom-nav a i { font-size: 18px; }
    .container.pb-5.mt-5 { margin-top: 10px !important; padding-top: 0 !important; }
}
@media (min-width: 768px) {
    .mobile-bottom-nav { display: none !important; }
}


@media (max-width: 576px) {
    /* General card sections */
    .card-section { padding: 14px 12px !important; border-radius: 12px !important; }
    .section-title { font-size: 13px !important; }

    /* Notifications header — stack vertically */
    #tab-notifications .d-flex.justify-content-between { flex-direction: column !important; align-items: flex-start !important; gap: 8px !important; }
    #tab-notifications .d-flex.gap-2 { width: 100%; }
    #tab-notifications .d-flex.gap-2 button { flex: 1; font-size: 11px !important; padding: 5px 6px !important; }

    /* Push enable bar */
    #pushEnableBar { padding: 10px !important; }
    #pushEnableBar p { font-size: 11px !important; }
    #pushToggleBtn { font-size: 11px !important; padding: 5px 10px !important; }

    /* Orders tabs — scrollable */
    #orderTabs { font-size: 11px !important; }
    #orderTabs .nav-link { padding: 6px 8px !important; font-size: 11px !important; white-space: nowrap; }
    #orderTabs .badge { font-size: 9px !important; }

    /* Order cards */
    .order-card, [class*="card mb-3"] { border-radius: 12px !important; }
    .order-card .fw-bold { font-size: 13px !important; }

    /* Wishlist */
    #tab-wishlist .d-flex { gap: 8px !important; }
    #tab-wishlist img { width: 60px !important; height: 60px !important; }
    #tab-wishlist .fw-bold { font-size: 13px !important; }

    /* Wallet */
    #tab-wallet h2 { font-size: 28px !important; }
    #tab-wallet .p-4 { padding: 16px !important; }

    /* Security */
    #tab-security .form-control { font-size: 13px !important; }
    #tab-security .btn { font-size: 13px !important; }

    /* Reviews */
    #tab-reviews img { width: 52px !important; height: 52px !important; }
    #tab-reviews .fw-bold { font-size: 13px !important; }
    #tab-reviews p { font-size: 12px !important; }

    /* Address */
    #tab-address .fw-semibold { font-size: 13px !important; }
    #tab-address .text-muted { font-size: 11px !important; }
    #tab-address .btn-sm { font-size: 11px !important; padding: 4px 8px !important; }
}
    </style>
</head>
<body>

<!-- NAVBAR -->
<%
request.setAttribute("navType", "simple");
request.setAttribute("navBackUrl", "index.jsp");
request.setAttribute("navCartCount", navCartCount);
%>
<%@ include file="navbar.jsp" %>

<div class="container pb-5 mt-5">
    <div class="row g-4">

        <!-- SIDEBAR -->
        <div class="col-md-3">
            <div class="sidebar">
                <div class="text-center px-3 mb-3">
                    <%
    String sideAvatar = (String) session.getAttribute("userAvatar");
%>
<% if (sideAvatar != null && !sideAvatar.isEmpty()) { %>
   <img id="sidebarAvatar" src="<%= sideAvatar %>" class="sidebar-avatar mb-2" alt="Avatar">
    <div id="sidebarInitials" class="avatar-circle-sm" style="display:none;"><%= initial %></div>
<% } else { %>
    <img id="sidebarAvatar" src="" style="width:80px; height:80px; border-radius:50%; object-fit:cover; border:4px solid white; box-shadow: 0 0 0 3px #0d6efd, 0 4px 16px rgba(13,110,253,0.35); display:none;" alt="Avatar">
    <div id="sidebarInitials" class="avatar-circle-sm"><%= initial %></div>
<% } %>
             <p class="fw-bold mb-0" style="font-size:15px;"><%= userFirstName %> <%= userMiddleInitial.isEmpty() ? "" : userMiddleInitial + ". " %><%= userLastName %></p>
                    <p class="text-muted mb-0" style="font-size:12px;"><%= userEmail %></p>
                    <span class="badge bg-primary mt-1" style="font-size:10px;">Customer</span>
                </div>
                <hr class="mx-3">
                <div class="sidebar-nav">
                    <a href="#" class="active" onclick="showTab('profile', this)"><i class="bi bi-person"></i> My Profile</a>
                    <a href="#" onclick="showTab('orders', this)"><i class="bi bi-bag"></i> My Orders</a>
                    <a href="#" onclick="showTab('reviews', this)"><i class="bi bi-star"></i> My Reviews</a>
                    <a href="#" onclick="showTab('address', this)"><i class="bi bi-geo-alt"></i> Addresses</a>
                    <a href="#" onclick="showTab('wishlist', this)"><i class="bi bi-heart"></i> Wishlist</a>
                    <a href="#" onclick="showTab('security', this)"><i class="bi bi-shield-lock"></i> Security</a>
                    <a href="#" onclick="showTab('wallet', this)"><i class="bi bi-wallet2"></i> My Wallet</a>
                    <a href="#" onclick="showTab('notifications', this)"><i class="bi bi-bell"></i> Notifications
                        <% if (unreadCount > 0) { %>
                        <span class="badge bg-danger ms-auto" style="font-size:10px;"><%= unreadCount %></span>
                        <% } %>
                    </a>
                </div>
            </div>
        </div>

        <!-- MAIN CONTENT -->
        <div class="col-md-9">

           <!-- STATS ROW -->
<%
    int statTotal = 0, statPending = 0, statCompleted = 0, statCancelled = 0;
    try {
    	Integer statId = (Integer) session.getAttribute("customerId");
        if (statId == null) {
            // Try to get customerId from DB using userId
            try {
                java.sql.Connection cidConn = com.shopeasy.DBConnection.getConnection();
                java.sql.PreparedStatement cidPs = cidConn.prepareStatement(
                    "SELECT customer_id FROM customer WHERE user_id=?");
                cidPs.setInt(1, (int) session.getAttribute("userId"));
                java.sql.ResultSet cidRs = cidPs.executeQuery();
                if (cidRs.next()) statId = cidRs.getInt("customer_id");
                cidRs.close(); cidPs.close(); cidConn.close();
            } catch (Exception ignored) {}
        }
        if (statId == null) statId = (int) session.getAttribute("userId");
        java.sql.Connection statConn = com.shopeasy.DBConnection.getConnection();
        java.sql.PreparedStatement statPs = statConn.prepareStatement(
            "SELECT status, COUNT(*) as cnt FROM orders WHERE customer_id=? GROUP BY status");
        statPs.setInt(1, statId);
        java.sql.ResultSet statRs = statPs.executeQuery();
        while (statRs.next()) {
            int cnt = statRs.getInt("cnt");
            statTotal += cnt;
            String st = statRs.getString("status");
            if ("Pending".equals(st)) statPending += cnt;
            else if ("Completed".equals(st)) statCompleted += cnt;
            else if ("Cancelled".equals(st)) statCancelled += cnt;
        }
        statRs.close(); statPs.close(); statConn.close();
    } catch (Exception ex) { ex.printStackTrace(); }
%>
<div class="row g-3 mb-4">
    <div class="col-6 col-md-3">
        <div class="stat-box"><div class="stat-num"><%= statTotal %></div><div class="stat-label">Total Orders</div></div>
    </div>
    <div class="col-6 col-md-3">
        <div class="stat-box"><div class="stat-num"><%= statPending %></div><div class="stat-label">Pending</div></div>
    </div>
    <div class="col-6 col-md-3">
        <div class="stat-box"><div class="stat-num"><%= statCompleted %></div><div class="stat-label">Completed</div></div>
    </div>
    <div class="col-6 col-md-3">
        <div class="stat-box"><div class="stat-num"><%= statCancelled %></div><div class="stat-label">Cancelled</div></div>
   </div>
</div><!-- end stats row -->

            <!-- MY PROFILE TAB -->
<div id="tab-profile" class="tab-content-section active">
    <div class="card-section">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <p class="section-title mb-0"><i class="bi bi-person-fill text-primary"></i> Personal Information</p>
            <button class="btn btn-outline-primary btn-sm" id="editBtn" onclick="enableEdit()">
                <i class="bi bi-pencil"></i> Edit Profile
            </button>
            <% if (("seller".equals(userRole) || "both".equals(userRole)) && _custSellerPageId > 0) { %>
            <a href="SellerPageServlet?id=<%= _custSellerPageId %>" class="btn btn-outline-success btn-sm ms-2">
                <i class="bi bi-shop"></i> View My Shop
            </a>
            <% } %>
        </div>

        <div class="text-center mb-4">
        
     <div class="avatar-upload">
    <%
        String profileAvatar = (String) session.getAttribute("userAvatar");
    %>
    <% if (profileAvatar != null && !profileAvatar.isEmpty()) { %>
        <div class="avatar-circle" id="avatarInitials" style="display:none;"><%= initial %></div>
 <img src="<%= profileAvatar %>" alt="Avatar" id="avatarPreview" 
           style="width:100px; height:100px; border-radius:50%; object-fit:cover; border:4px solid white; box-shadow: 0 0 0 3px #0d6efd, 0 6px 20px rgba(13,110,253,0.35); position:absolute; top:0; left:0; right:0; margin:0 auto;">
    <% } else { %>
        <div class="avatar-circle" id="avatarInitials"><%= initial %></div>
       <img src="" alt="Avatar" id="avatarPreview" 
             style="width:100px; height:100px; border-radius:50%; object-fit:cover; border:4px solid white; box-shadow: 0 0 0 3px #0d6efd, 0 6px 20px rgba(13,110,253,0.35); display:none; position:absolute; top:0; left:0;">
    <% } %>
    <button class="upload-btn" id="avatarBtn" onclick="document.getElementById('avatarInput').click()">
        <i class="bi bi-camera"></i>
    </button>
    <input type="file" id="avatarInput" style="display:none" accept="image/*" onchange="openCustomerCropModal(this)">
</div>

           <p class="text-muted" id="avatarHint" style="font-size:12px;">Click the camera icon to change photo</p>
        </div>

        <form action="UpdateProfileServlet" method="post" id="profileForm">
    <input type="hidden" id="profilePictureData" name="profilePicture" value="">
    
         <div class="row g-3">
                <%-- ROW 1: Name --%>
                <div class="col-12">
                 <div class="row g-2">
                        <div class="col-md-5">
                            <label class="form-label fw-bold" style="font-size:12px; color:#64748b; text-transform:uppercase; letter-spacing:0.5px;">Last Name</label>
                            <input type="text" name="last_name" id="inputLastName" class="form-control" value="<%= userLastName %>" placeholder="Last Name" readonly>
                        </div>
                     <div class="col-md-5">
                            <label class="form-label fw-bold" style="font-size:12px; color:#64748b; text-transform:uppercase; letter-spacing:0.5px;">First Name</label>
                            <input type="text" name="first_name" id="inputFirstName" class="form-control" value="<%= userFirstName %>" placeholder="First Name" readonly>
                        </div>
                       <div class="col-md-2">
                            <label class="form-label fw-bold" style="font-size:12px; color:#64748b; text-transform:uppercase; letter-spacing:0.5px;">M.I.</label>
                            <input type="text" name="middle_initial" id="inputMI" class="form-control" value="<%= userMiddleInitial %>" placeholder="M.I." maxlength="2" readonly>
                        </div>
                    </div>
                </div>

                <%-- ROW 2: Username + Email --%>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:12px; color:#64748b; text-transform:uppercase; letter-spacing:0.5px;">Username</label>
                    <input type="text" name="username" id="inputUsername" class="form-control" value="<%= userUsername != null ? userUsername : "" %>" readonly>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:12px; color:#64748b; text-transform:uppercase; letter-spacing:0.5px;">Email <i class="bi bi-lock-fill text-muted ms-1" style="font-size:11px;"></i></label>
                    <input type="email" class="form-control" value="<%= userEmail != null ? userEmail : "" %>" readonly style="background:#f8f9fa; color:#94a3b8;">
                </div>

                <%-- ROW 3: Phone + Birthday --%>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:12px; color:#64748b; text-transform:uppercase; letter-spacing:0.5px;">Phone Number</label>
                    <div class="input-group">
                        <span class="input-group-text">+63</span>
                        <input type="tel" name="phone" id="inputPhone" class="form-control" value="<%= userPhone != null ? userPhone : "" %>" readonly oninput="formatPHPhone(this)">
                    </div>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:12px; color:#64748b; text-transform:uppercase; letter-spacing:0.5px;">
                        Birthday
                        <% if (userBirthday == null || userBirthday.isEmpty()) { %>
                            <span class="text-danger ms-1" style="font-size:10px; text-transform:none;">* one-time edit</span>
                        <% } else { %>
                            <i class="bi bi-lock-fill text-muted ms-1" style="font-size:11px;"></i>
                        <% } %>
                    </label>
                    <input type="text" name="birthday" id="inputBirthday" class="form-control" value="<%= userBirthday != null ? userBirthday : "" %>" placeholder="Select your birthday" readonly>
                </div>

                <%-- ROW 4: Gender --%>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:12px; color:#64748b; text-transform:uppercase; letter-spacing:0.5px;">Gender</label>
                    <select name="gender" id="inputGender" class="form-select" disabled>
                        <option value="" disabled <%= (userGender == null || userGender.isEmpty()) ? "selected" : "" %>>Select your gender</option>
                        <option <%= "Male".equals(userGender) ? "selected" : "" %>>Male</option>
                        <option <%= "Female".equals(userGender) ? "selected" : "" %>>Female</option>
                        <option <%= "Prefer not to say".equals(userGender) ? "selected" : "" %>>Prefer not to say</option>
                    </select>
                </div>
       <div class="col-md-6 d-flex align-items-end">
                    <div id="saveSection" style="display:none; width:100%;">
                        <div class="d-flex gap-2 justify-content-end">
                            <button type="button" class="btn btn-outline-secondary" onclick="cancelEdit()">
                                <i class="bi bi-x"></i> Cancel
                            </button>
                            <button type="submit" class="btn btn-primary px-4">
                                <i class="bi bi-check2"></i> Save Changes
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </form>
    </div>
</div>

           <!-- MY ORDERS TAB -->
            <div id="tab-orders" class="tab-content-section">
                <div class="card-section">
                <div class="d-flex justify-content-between align-items-center mb-3">
    <p class="section-title mb-0"><i class="bi bi-bag-fill text-primary"></i> My Orders</p>
    <div class="input-group" style="width:220px;">
        <span class="input-group-text bg-white border-end-0">
            <i class="bi bi-search text-muted" style="font-size:13px;"></i>
        </span>
        <input type="text" id="orderSearch" class="form-control border-start-0 ps-0" 
               placeholder="Search Order #..." 
               style="font-size:13px;"
               oninput="searchOrders(this.value)">
    </div>
</div>
                    <%
                        java.util.List<java.util.Map<String, Object>> myOrders = new java.util.ArrayList<>();
                        try {
                        	Integer custId2 = (Integer) session.getAttribute("customerId");
                            if (custId2 == null) custId2 = (int) session.getAttribute("userId");
                            java.sql.Connection ordConn = com.shopeasy.DBConnection.getConnection();
                            java.text.SimpleDateFormat ordSdf = new java.text.SimpleDateFormat("MMM d, yyyy h:mm a");
                            ordSdf.setTimeZone(java.util.TimeZone.getTimeZone("Asia/Manila"));
                            java.sql.PreparedStatement ordPs = ordConn.prepareStatement(
                            		"SELECT o.order_id, o.total_amount, o.status, o.payment_method, o.shipping_address, o.order_date, o.cancel_reason, " +
                            				"GROUP_CONCAT(DISTINCT s.business_name ORDER BY s.business_name SEPARATOR ', ') AS shop_names " +
                            				"FROM orders o " +
                            				"JOIN order_items oi ON o.order_id = oi.order_id " +
                            				"LEFT JOIN seller s ON oi.seller_id = s.seller_id " +
                            				"WHERE o.customer_id=? AND o.status != 'Awaiting Payment' GROUP BY o.order_id ORDER BY o.order_id DESC");
                            ordPs.setInt(1, custId2);
                            java.sql.ResultSet ordRs = ordPs.executeQuery();
                            while (ordRs.next()) {
                                java.util.Map<String, Object> ord = new java.util.HashMap<>();
                                ord.put("id", ordRs.getInt("order_id"));
                                ord.put("total", ordRs.getDouble("total_amount"));
                                ord.put("status", ordRs.getString("status"));
                                ord.put("payment", ordRs.getString("payment_method"));
                                ord.put("address", ordRs.getString("shipping_address"));
                                java.sql.Timestamp ordTs = ordRs.getTimestamp("order_date");
                                ord.put("date", ordTs != null ? ordSdf.format(ordTs) : "Date not available");
                                ord.put("cancelReason", ordRs.getString("cancel_reason"));
                                ord.put("shopNames", ordRs.getString("shop_names"));
                                myOrders.add(ord);
                            }
                            ordRs.close(); ordPs.close(); ordConn.close();
                        } catch (Exception ex) { ex.printStackTrace(); }

                    // BATCH QUERY 1 — All order items for all orders
                    java.util.Map<Integer, java.util.List<java.util.Map<String,Object>>> allOrderItems = new java.util.HashMap<>();
                    java.util.Map<Integer, Integer> firstProductIds = new java.util.HashMap<>();
                    // BATCH QUERY 2 — All review checks
                    java.util.Set<Integer> reviewedOrderIds = new java.util.HashSet<>();
                    // BATCH QUERY 3 — All refund statuses
                    java.util.Map<Integer, String> refundStatuses = new java.util.HashMap<>();
                    // BATCH QUERY 4 — All refund eligibility (days since order)
                    java.util.Map<Integer, Integer> orderDaysSince = new java.util.HashMap<>();

                    if (!myOrders.isEmpty()) {
                        // Build comma-separated order IDs
                        StringBuilder orderIds = new StringBuilder();
                        for (java.util.Map<String,Object> o : myOrders) {
                            if (orderIds.length() > 0) orderIds.append(",");
                            orderIds.append((Integer) o.get("id"));
                        }
                        String orderIdList = orderIds.toString();

                        try {
                            Integer batchCustId = (Integer) session.getAttribute("customerId");
                            if (batchCustId == null) batchCustId = (int) session.getAttribute("userId");
                            java.sql.Connection batchConn = com.shopeasy.DBConnection.getConnection();

                            // BATCH 1 — Order items
                            java.sql.Statement itemStmt = batchConn.createStatement();
                            java.sql.ResultSet itemBatchRs = itemStmt.executeQuery(
                            		"SELECT oi.order_id, p.product_id, p.name, p.image, p.thumbnail, oi.quantity, oi.price, oi.subtotal, " +
                            				"pv.variation_type, pv.variation_value, pv.image as var_image " +
                                "FROM order_items oi " +
                                "JOIN product p ON oi.product_id = p.product_id " +
                                "LEFT JOIN product_variation pv ON oi.variation_id = pv.variation_id " +
                                "WHERE oi.order_id IN (" + orderIdList + ")");
                            while (itemBatchRs.next()) {
                                int oid = itemBatchRs.getInt("order_id");
                                if (!allOrderItems.containsKey(oid)) allOrderItems.put(oid, new java.util.ArrayList<>());
                                java.util.Map<String,Object> itm = new java.util.HashMap<>();
                                itm.put("productId", itemBatchRs.getInt("product_id"));
                                itm.put("name", itemBatchRs.getString("name"));
                                String itmImg = itemBatchRs.getString("var_image");
                                if (itmImg == null || itmImg.isEmpty()) itmImg = itemBatchRs.getString("image");
                                if (itmImg == null || itmImg.isEmpty()) itmImg = itemBatchRs.getString("thumbnail");
                                itm.put("image", itmImg);
                                itm.put("quantity", itemBatchRs.getInt("quantity"));
                                itm.put("price", itemBatchRs.getDouble("price"));
                                itm.put("subtotal", itemBatchRs.getDouble("subtotal"));
                                itm.put("variationType", itemBatchRs.getString("variation_type"));
                                itm.put("variationValue", itemBatchRs.getString("variation_value"));
                                allOrderItems.get(oid).add(itm);
                                if (!firstProductIds.containsKey(oid)) firstProductIds.put(oid, itemBatchRs.getInt("product_id"));
                            }
                            itemBatchRs.close(); itemStmt.close();

                            // BATCH 2 — Review checks
                            java.sql.PreparedStatement rvBatchPs = batchConn.prepareStatement(
                                "SELECT DISTINCT order_id FROM review WHERE customer_id=? AND order_id IN (" + orderIdList + ")");
                            rvBatchPs.setInt(1, batchCustId);
                            java.sql.ResultSet rvBatchRs = rvBatchPs.executeQuery();
                            while (rvBatchRs.next()) reviewedOrderIds.add(rvBatchRs.getInt("order_id"));
                            rvBatchRs.close(); rvBatchPs.close();

                            // BATCH 3 — Refund statuses
                            java.sql.PreparedStatement rfBatchPs = batchConn.prepareStatement(
                                "SELECT order_id, status FROM refund_requests WHERE customer_id=? AND order_id IN (" + orderIdList + ")");
                            rfBatchPs.setInt(1, batchCustId);
                            java.sql.ResultSet rfBatchRs = rfBatchPs.executeQuery();
                            while (rfBatchRs.next()) refundStatuses.put(rfBatchRs.getInt("order_id"), rfBatchRs.getString("status"));
                            rfBatchRs.close(); rfBatchPs.close();

                            // BATCH 4 — Days since order
                            java.sql.Statement dayStmt = batchConn.createStatement();
                            java.sql.ResultSet dayBatchRs = dayStmt.executeQuery(
                            		"SELECT order_id, DATEDIFF(NOW(), completed_at) as days FROM orders WHERE order_id IN (" + orderIdList + ")");
                            while (dayBatchRs.next()) orderDaysSince.put(dayBatchRs.getInt("order_id"), dayBatchRs.getInt("days"));
                            dayBatchRs.close(); dayStmt.close();

                            batchConn.close();
                        } catch (Exception batchEx) { batchEx.printStackTrace(); }
                    }
                    %>
                    
                    <!-- STATUS TABS -->
   <%
int cntAll=0, cntToShip=0, cntShipped=0, cntCompleted=0, cntCancelReq=0, cntCancelled=0, cntRefund=0;
for (java.util.Map<String,Object> o : myOrders) {
    String os = (String) o.get("status");
    cntAll++;
    if ("Pending".equals(os) || "Processing".equals(os)) cntToShip++;
    else if ("Shipped".equals(os)) cntShipped++;
    else if ("Completed".equals(os)) cntCompleted++;
    else if ("Cancellation Requested".equals(os)) cntCancelReq++;
    else if ("Cancelled".equals(os)) cntCancelled++;
    String rs = refundStatuses.get((Integer) o.get("id"));
    if (rs != null && !rs.isEmpty()) cntRefund++;
}
%>
<ul class="nav nav-tabs mb-3" id="orderTabs" style="flex-wrap:nowrap; overflow-x:auto;">
    <li class="nav-item"><a class="nav-link active" href="#" onclick="filterOrders('All', this)">
        All <span class="badge bg-secondary ms-1" style="font-size:10px;"><%= cntAll %></span></a></li>
    <li class="nav-item"><a class="nav-link" href="#" onclick="filterOrders('To Ship', this)">
        To Ship <% if(cntToShip > 0) { %><span class="badge bg-warning text-dark ms-1" style="font-size:10px;"><%= cntToShip %></span><% } %></a></li>
    <li class="nav-item"><a class="nav-link" href="#" onclick="filterOrders('Shipped', this)">
        To Receive <% if(cntShipped > 0) { %><span class="badge bg-info text-dark ms-1" style="font-size:10px;"><%= cntShipped %></span><% } %></a></li>
    <li class="nav-item"><a class="nav-link" href="#" onclick="filterOrders('Completed', this)">
        Completed <% if(cntCompleted > 0) { %><span class="badge bg-success ms-1" style="font-size:10px;"><%= cntCompleted %></span><% } %></a></li>
    <li class="nav-item"><a class="nav-link" href="#" onclick="filterOrders('Cancellation Requested', this)">
        Cancel Requests <% if(cntCancelReq > 0) { %><span class="badge bg-danger ms-1" style="font-size:10px;"><%= cntCancelReq %></span><% } %></a></li>
    <li class="nav-item"><a class="nav-link" href="#" onclick="filterOrders('Cancelled', this)">
        Cancelled <% if(cntCancelled > 0) { %><span class="badge bg-danger ms-1" style="font-size:10px;"><%= cntCancelled %></span><% } %></a></li>
    <li class="nav-item"><a class="nav-link" href="#" onclick="filterOrders('Refund', this)">
        Returns/Refunds <% if(cntRefund > 0) { %><span class="badge bg-primary ms-1" style="font-size:10px;"><%= cntRefund %></span><% } %></a></li>
</ul>

              <% if (myOrders.isEmpty()) { %>
                        <div class="text-center py-4 text-muted">
                            <i class="bi bi-bag fs-1 opacity-25"></i>
                            <p class="mt-2">No orders yet.</p>
                        </div>
                    <% } else { %>
                        <% for (java.util.Map<String, Object> ord : myOrders) { %>
                  <div class="order-item order-card" data-status="<%= ord.get("status") %>" data-payment="<%= ord.get("payment") %>" data-refund-status="">
                            <div class="d-flex justify-content-between align-items-start mb-2">
                                <div>
                                    <p class="mb-0 fw-bold" style="font-size:14px;">Order #SE-<%= ord.get("id") %></p>
                                    <p class="mb-0 text-muted" style="font-size:12px;"><%= ord.get("date") != null ? ord.get("date") : "Date not available" %></p>
                                </div>
                               <%
                                    String ordStatus = (String) ord.get("status");
                                    String badgeColor = "bg-warning text-dark";
                                    if ("Completed".equals(ordStatus)) badgeColor = "bg-success";
                                    else if ("Cancelled".equals(ordStatus)) badgeColor = "bg-danger";
                                    else if ("Shipped".equals(ordStatus)) badgeColor = "bg-info text-dark";
                                    else if ("Processing".equals(ordStatus)) badgeColor = "bg-primary";
                                %>
                                <span class="badge <%= badgeColor %> order-badge"><%= ordStatus %></span>
                                

                            </div>
                            <p class="mb-1 fw-semibold" style="font-size:12px; color:#0d6efd;">
    <i class="bi bi-shop"></i> <%= ord.get("shopNames") != null ? ord.get("shopNames") : "Unknown Shop" %>
</p>
                            <p class="mb-1 text-muted" style="font-size:12px;">
                                <i class="bi bi-geo-alt"></i> <%= ord.get("address") %>
                            </p>
                            <p class="mb-1 text-muted" style="font-size:12px;">
                                <i class="bi bi-credit-card"></i> <%= ord.get("payment") %>
                            </p>

                            <%-- Load items for this order --%>
                            <%
                            int ordIdKey = (Integer) ord.get("id");
                            int firstProductId = firstProductIds.getOrDefault(ordIdKey, 0);
                            java.util.List<java.util.Map<String,Object>> ordItems = allOrderItems.getOrDefault(ordIdKey, new java.util.ArrayList<>());
                            for (java.util.Map<String,Object> itemMap : ordItems) {
                        %>
                                <div class="d-flex align-items-center gap-2 mb-1 mt-1">
<a href="product.jsp?id=<%= itemMap.get("productId") %>" style="text-decoration:none; flex-shrink:0;">
        <% if (itemMap.get("image") != null && !((String)itemMap.get("image")).isEmpty()) { %>
            <img src="<%= itemMap.get("image") %>" style="width:40px; height:40px; object-fit:cover; border-radius:6px; border:1px solid #eee; transition:0.2s;" onmouseover="this.style.opacity='0.8'" onmouseout="this.style.opacity='1'">
        <% } else { %>
            <div style="width:40px; height:40px; background:#f0f0f0; border-radius:6px; display:flex; align-items:center; justify-content:center; font-size:16px; color:#aaa;"><i class="bi bi-image"></i></div>
        <% } %>
    </a>
    <div>
        <a href="product.jsp?id=<%= itemMap.get("productId") %>" class="text-decoration-none text-dark">
            <p class="mb-0 fw-bold" style="font-size:12px;"><%= itemMap.get("name") %></p>
        </a>
<% if (itemMap.get("variationType") != null) { %>
<p class="mb-0" style="font-size:11px;">
    <span class="badge bg-light text-dark border" style="font-size:10px;">
        <i class="bi bi-tag"></i> <%= itemMap.get("variationType") %>: <%= itemMap.get("variationValue") %>
    </span>
</p>
<% } %>
<% double displayPrice = (double)itemMap.get("subtotal") / (int)itemMap.get("quantity"); %>
<p class="mb-0 text-muted" style="font-size:11px;">Qty: <%= itemMap.get("quantity") %> &nbsp;|&nbsp; ₱<%= String.format("%.2f", displayPrice) %></p> 
    </div>
</div>
                              <%
                                    }
                                %>                      

                            <div class="d-flex justify-content-between align-items-center mt-2">
   <%
   double displayTotal = (double) ord.get("total");
   if (displayTotal == 0) {
       double batchTotal = 0;
       java.util.List<java.util.Map<String,Object>> totalItems = allOrderItems.getOrDefault(ordIdKey, new java.util.ArrayList<>());
       for (java.util.Map<String,Object> ti : totalItems) batchTotal += (double) ti.get("subtotal");
       if (batchTotal > 0) displayTotal = batchTotal;
   }
%>
<p class="mb-0 fw-bold text-primary">Total: ₱<%= String.format("%.2f", displayTotal) %></p>
    <div class="d-flex gap-2 flex-wrap flex-column align-items-end">
    <% if ("Cancelled".equals(ord.get("status"))) {
        String custCancelReason = ord.get("cancelReason") != null ? (String) ord.get("cancelReason") : "";
        boolean cancelledBySeller = custCancelReason.toLowerCase().contains("cancelled by seller");
        boolean cancelledByCustomer = custCancelReason.toLowerCase().contains("cancelled by customer");
    %>
        <% if (cancelledBySeller) { %>
            <span class="badge bg-danger px-3 py-2" style="font-size:12px;">
                <i class="bi bi-shop"></i> Cancelled by Seller
            </span>
        <% } else if (cancelledByCustomer) { %>
            <span class="badge bg-secondary px-3 py-2" style="font-size:12px;">
                <i class="bi bi-person-x-fill"></i> Cancelled by You
            </span>
        <% } %>
        <% if (!custCancelReason.isEmpty()) { %>
            <div class="p-2 rounded-3" style="background:#fff0f0; border:1px solid #f5c2c7; font-size:12px;">
                <i class="bi bi-chat-left-text text-danger me-1"></i>
                <strong>Reason:</strong> <%= custCancelReason %>
            </div>
        <% } %>
    <% } %>
    <% if ("Pending".equals(ord.get("status"))) { %>
<button class="btn btn-outline-danger btn-sm"
    onclick="cancelPendingOrder(<%= ord.get("id") %>)">
    <i class="bi bi-x-circle"></i> Cancel Order
</button>
<% } %>
<% if ("Processing".equals(ord.get("status"))) { %>
<button class="btn btn-outline-danger btn-sm"
    onclick="openCancelModal(<%= ord.get("id") %>)">
    <i class="bi bi-x-circle"></i> Request Cancel
</button>
<% } %>
<% if ("Cancellation Requested".equals(ord.get("status"))) { %>
    <span class="badge bg-warning text-dark px-3 py-2" style="font-size:12px;">
        <i class="bi bi-hourglass-split"></i> Cancellation Pending
    </span>
<% } %>
    <% if ("Completed".equals(ord.get("status"))) { %>
        <%
            // Check if already reviewed
           boolean hasReview = reviewedOrderIds.contains(ordIdKey);
        %>
<% if (hasReview) { %>
        <span class="badge bg-success px-3 py-2" style="font-size:12px;">
            <i class="bi bi-check-circle"></i> Reviewed
        </span>
   <% } else { %>
<button class="btn btn-warning btn-sm text-dark fw-semibold"
    onclick="openReviewModal(<%= ord.get("id") %>, <%= firstProductId %>)">
    <i class="bi bi-star-fill"></i> Write a Review
</button>
<% } %>
<%
    // Check refund status + eligibility
  String refundStatus = refundStatuses.get(ordIdKey);
    int daysSince = orderDaysSince.getOrDefault(ordIdKey, 999);
    boolean refundEligible = (daysSince <= 7);
%>
<% if (refundStatus != null) { %>
   <% if ("Pending".equals(refundStatus)) { %>
    <span class="badge px-3 py-2" style="font-size:12px; background:#ffc107; color:#333;">
        <i class="bi bi-hourglass-split"></i> Refund Pending
    </span>
    <button class="btn btn-outline-secondary btn-sm fw-semibold ms-1"
        onclick="cancelRefundRequest(<%= ord.get("id") %>)">
        <i class="bi bi-x-circle"></i> Cancel Return
    </button>
 <% } else if ("Refunded".equals(refundStatus)) { %>
        <span class="badge px-3 py-2" style="font-size:12px; background:#6c757d; color:white;">
            <i class="bi bi-cash-coin"></i> Refunded
        </span>
    <% } else if ("Rejected".equals(refundStatus)) { %>
        <span class="badge bg-danger px-3 py-2" style="font-size:12px;">
            <i class="bi bi-x-circle"></i> Refund Rejected
        </span>
<% } %>
    <script>document.currentScript.closest('.order-card').dataset.refundStatus = '<%= refundStatus %>';</script>
<% } else if (refundEligible) { %>
    <button class="btn btn-outline-danger btn-sm fw-semibold"
        onclick="openRefundModal(<%= ord.get("id") %>)">
        <i class="bi bi-arrow-counterclockwise"></i> Request Refund
    </button>
    <small class="text-muted d-block mt-1" style="font-size:11px;">
        <i class="bi bi-clock"></i> <%= 7 - daysSince %> day<%= (7 - daysSince) != 1 ? "s" : "" %> left to request
    </small>
<% } else if ("Completed".equals(ord.get("status")) && refundStatus == null) { %>
    <small class="text-muted" style="font-size:11px;">
        <i class="bi bi-x-circle"></i> Refund period expired
    </small>
<% } %>
    <% } %>
    </div>
</div>
                        </div>
                        <div class="text-center py-4 text-muted" id="emptyFilter" style="display:none;">
                            <i class="bi bi-inbox fs-1 opacity-25"></i>
                            <p class="mt-2">No orders in this category.</p>
                        </div>
                        <% } %>
                    <% } %>
            </div>
        </div>
<!-- MY REVIEWS TAB -->
            <div id="tab-reviews" class="tab-content-section">
    <div class="card-section">
        <p class="section-title"><i class="bi bi-star-fill text-primary"></i> My Reviews</p>
        <%
            try {
            	Integer rvCustId = (Integer) session.getAttribute("customerId");
                if (rvCustId == null) rvCustId = (int) session.getAttribute("userId");
                java.sql.Connection rvConn = com.shopeasy.DBConnection.getConnection();
                java.sql.PreparedStatement rvPs = rvConn.prepareStatement(
                		"SELECT r.review_id, r.product_id, r.rating, r.comment, r.photo, r.created_at, r.is_edited, " +
                				"p.name AS pname, p.image AS pimage, p.thumbnail AS pthumbnail, " +
                				"(SELECT pv.image FROM product_variation pv WHERE pv.product_id = p.product_id AND pv.image IS NOT NULL ORDER BY pv.price ASC LIMIT 1) AS var_image " +
                                "FROM review r JOIN product p ON r.product_id = p.product_id " +
                	    "WHERE r.customer_id = ? ORDER BY r.review_id DESC");
                rvPs.setInt(1, rvCustId);
                java.sql.ResultSet rvRs = rvPs.executeQuery();
                boolean hasReviews = false;
                while (rvRs.next()) {
                    hasReviews = true;
        %>
        <%
        int rvId = rvRs.getInt("review_id");
        int rvProdId = rvRs.getInt("product_id");
        int rvRating = rvRs.getInt("rating");
        String rvComment = rvRs.getString("comment");
        String rvPhoto = rvRs.getString("photo");
        String rvPname = rvRs.getString("pname");
        String rvPimage = rvRs.getString("pimage");
        if (rvPimage == null || rvPimage.isEmpty()) rvPimage = rvRs.getString("var_image");
        if (rvPimage == null || rvPimage.isEmpty()) rvPimage = rvRs.getString("pthumbnail");
        java.sql.Timestamp rvCreatedAt = rvRs.getTimestamp("created_at");
        long rvDaysSince = rvCreatedAt != null
            ? (System.currentTimeMillis() - rvCreatedAt.getTime()) / (1000 * 60 * 60 * 24)
            : 999;
        int rvIsEdited = rvRs.getInt("is_edited");
        boolean rvCanEdit = rvDaysSince <= 7 && rvIsEdited == 0;
        %>
<div class="d-flex gap-3 p-3 mb-3 border rounded-3" id="review-<%= rvId %>">
    <a href="product.jsp?id=<%= rvProdId %>" style="flex-shrink:0;">
    <% if (rvPimage != null && !rvPimage.isEmpty()) { %>
        <img src="<%= rvPimage %>" style="width:60px; height:60px; object-fit:cover; border-radius:8px;">
    <% } else { %>
        <div style="width:60px; height:60px; background:#f0f0f0; border-radius:8px; display:flex; align-items:center; justify-content:center;">
            <i class="bi bi-image text-muted"></i>
        </div>
    <% } %>
    </a>
    <div class="flex-grow-1">
        <div class="d-flex justify-content-between align-items-start">
            <a href="product.jsp?id=<%= rvProdId %>" class="text-decoration-none text-dark">
                <p class="mb-1 fw-bold" style="font-size:14px;"><%= rvPname %></p>
            </a>
            <% if (rvCanEdit) { %>
    <div class="d-flex flex-column align-items-end gap-1">
        <button class="btn btn-outline-primary btn-sm"
            onclick="openEditReviewModal(<%= rvId %>, <%= rvProdId %>, <%= rvRating %>, '<%= rvComment != null ? rvComment.replace("'", "\\'").replace("\n", "\\n") : "" %>', '<%= rvPhoto != null ? rvPhoto : "" %>')">
            <i class="bi bi-pencil"></i> Edit
        </button>
        <span class="text-muted" style="font-size:11px;">
            <i class="bi bi-clock"></i> <%= 7 - rvDaysSince %> day<%= (7 - rvDaysSince) == 1 ? "" : "s" %> left to edit
        </span>
    </div>
<% } else if (rvIsEdited == 1) { %>
    <span class="badge bg-success" style="font-size:11px;">
        <i class="bi bi-check-circle"></i> Reviewed
    </span>
<% } else { %>
    <span class="badge bg-secondary" style="font-size:11px;">
        <i class="bi bi-lock"></i> Edit expired
    </span>
<% } %>
        </div>
     <p class="mb-1 fw-semibold" style="font-size:13px;">
            <i class="bi bi-person-circle text-primary me-1"></i><%= userName %>
        </p>
        <div class="mb-1" id="rvStars-<%= rvId %>">
            <% for (int s = 1; s <= 5; s++) { %>
                <i class="bi bi-star-fill" style="color:<%= s <= rvRating ? "#ffc107" : "#ddd" %>; font-size:13px;"></i>
            <% } %>
        </div>
        <p class="mb-0 text-muted" style="font-size:13px;" id="rvComment-<%= rvId %>"><%= rvComment %></p>
        <% if (rvPhoto != null && !rvPhoto.isEmpty()) { %>
            <img src="<%= rvPhoto %>" id="rvPhoto-<%= rvId %>"
                 style="width:80px; height:80px; object-fit:cover; border-radius:8px; border:2px solid #eee; margin-top:6px;">
        <% } else { %>
            <img src="" id="rvPhoto-<%= rvId %>" style="display:none; width:80px; height:80px; object-fit:cover; border-radius:8px; border:2px solid #eee; margin-top:6px;">
        <% } %>
    </div>
</div>
        <%
                }
                rvRs.close(); rvPs.close(); rvConn.close();
                if (!hasReviews) {
        %>
        <div class="text-center py-4 text-muted">
            <i class="bi bi-star fs-1 opacity-25"></i>
            <p class="mt-2">No reviews yet.</p>
        </div>
      
<%
        }
    } catch (Exception rvEx) { rvEx.printStackTrace(); }
%>
    </div>
</div>
           <!-- ADDRESSES TAB -->
            <div id="tab-address" class="tab-content-section">
   <div class="card-section" style="position:relative;">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <p class="section-title mb-0"><i class="bi bi-geo-alt-fill text-primary"></i> My Addresses</p>
            <button class="btn btn-primary btn-sm" onclick="showAddressForm()">
                <i class="bi bi-plus"></i> Add Address
            </button>
        </div>

        <%-- ADD ADDRESS FORM --%>
        <div id="addressForm" style="display:none;" class="mb-4 p-3 border rounded-3 bg-light">
            <p class="fw-bold mb-3" style="font-size:14px;" id="addressFormTitle">
                <i class="bi bi-plus-circle text-primary"></i> Add New Address
            </p>
            <form action="AddressServlet" method="post" id="addressFormEl">
                <input type="hidden" name="action" id="addressAction" value="add">
                <input type="hidden" name="addressId" id="editAddressId" value="">
                <div class="row g-2">
                    <div class="col-md-6">
                        <label class="form-label fw-bold" style="font-size:13px;">Full Name</label>
                        <input type="text" name="fullname" id="addrFullname" class="form-control" placeholder="Enter full name" required>
                    </div>
                 <div class="col-md-6">
                        <label class="form-label fw-bold" style="font-size:13px;">Phone Number</label>
                        <div class="input-group">
                            <span class="input-group-text">+63</span>
                          <input type="tel" name="phone" id="addrPhone" class="form-control" placeholder="9XX XXX XXXX" required maxlength="10" oninput="formatPHPhone(this)">
                        </div>
                        <div id="addrPhoneError" class="text-danger mt-1" style="display:none; font-size:11px;">
                            <i class="bi bi-exclamation-circle"></i> <span id="addrPhoneErrorText">Phone number must be exactly 10 digits</span>
                        </div>
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-bold" style="font-size:13px;">Full Address</label>
                        <input type="text" name="address" id="addrAddress" class="form-control" placeholder="Street, Barangay, City, Province, ZIP" required>
                    </div>
                    <div class="col-12">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" name="isDefault" id="addrIsDefault">
                            <label class="form-check-label" for="addrIsDefault" style="font-size:13px;">Set as default address</label>
                        </div>
                    </div>
                    <div class="col-12 d-flex gap-2 justify-content-end mt-2">
                        <button type="button" class="btn btn-outline-secondary btn-sm" onclick="hideAddressForm()">
                            <i class="bi bi-x"></i> Cancel
                        </button>
                     <button type="button" class="btn btn-primary btn-sm" onclick="submitAddressForm()">
                        <i class="bi bi-check2"></i> Save Address
                    </button>
                    </div>
                </div>
            </form>
        </div>

        <%-- LOAD ADDRESSES FROM DATABASE --%>
        <%
            java.util.List<java.util.Map<String, Object>> addresses = new java.util.ArrayList<>();
            try {
            	Integer custId = (Integer) session.getAttribute("customerId");
                if (custId == null) custId = (int) session.getAttribute("userId");
                java.sql.Connection addrConn = com.shopeasy.DBConnection.getConnection();
                java.sql.PreparedStatement addrPs = addrConn.prepareStatement(
                    "SELECT * FROM customer_address WHERE customer_id=? ORDER BY is_default DESC, address_id ASC");
                addrPs.setInt(1, custId);
                java.sql.ResultSet addrRs = addrPs.executeQuery();
                while (addrRs.next()) {
                    java.util.Map<String, Object> addr = new java.util.HashMap<>();
                    addr.put("id", addrRs.getInt("address_id"));
                    addr.put("fullname", addrRs.getString("full_name"));
                    addr.put("phone", addrRs.getString("phone"));
                    addr.put("address", addrRs.getString("address"));
                    addr.put("isDefault", addrRs.getInt("is_default") == 1);
                    addresses.add(addr);
                }
                addrRs.close();
                addrPs.close();
                addrConn.close();
            } catch (Exception ex) {
                ex.printStackTrace();
            }
        %>

        <% if (addresses.isEmpty()) { %>
            <div class="text-center py-4 text-muted">
                <i class="bi bi-geo-alt fs-1 opacity-25"></i>
                <p class="mt-2">No addresses yet. Click Add Address to add one.</p>
            </div>
        <% } else { %>
            <% for (java.util.Map<String, Object> addr : addresses) { %>
                <div class="address-card <%= (boolean)addr.get("isDefault") ? "default" : "" %>">
                    <% if ((boolean)addr.get("isDefault")) { %>
                        <span class="default-badge">Default</span>
                    <% } %>
                    <p class="fw-bold mb-1" style="font-size:14px;"><%= addr.get("fullname") %></p>
                    <p class="text-muted mb-1" style="font-size:13px;"><%= addr.get("address") %></p>
                    <p class="text-muted mb-2" style="font-size:13px;">
                        <i class="bi bi-telephone"></i> +63 <%= addr.get("phone") %>
                    </p>
                    <div class="d-flex gap-2 flex-wrap">
                        <button class="btn btn-outline-primary btn-sm" onclick="editAddress(<%= addr.get("id") %>, '<%= addr.get("fullname") %>', '<%= addr.get("phone") %>', '<%= ((String)addr.get("address")).replace("'", "\\'") %>')">
                            <i class="bi bi-pencil"></i> Edit
                        </button>
                        <form action="AddressServlet" method="post" style="display:inline;">
                            <input type="hidden" name="action" value="delete">
                            <input type="hidden" name="addressId" value="<%= addr.get("id") %>">
                           <button type="submit" class="btn btn-outline-danger btn-sm" onclick="return confirmDelete(this.closest('form'))">
                                <i class="bi bi-trash"></i> Delete
                            </button>
                        </form>
                        <% if (!(boolean)addr.get("isDefault")) { %>
                            <form action="AddressServlet" method="post" style="display:inline;">
                                <input type="hidden" name="action" value="setDefault">
                                <input type="hidden" name="addressId" value="<%= addr.get("id") %>">
                                <button type="submit" class="btn btn-outline-success btn-sm">
                                    <i class="bi bi-check-circle"></i> Set as Default
                                </button>
                            </form>
                        <% } %>
                    </div>
                </div>
            <% } %>
        <% } %>
    </div>
        </div>

            <!-- WISHLIST TAB -->
            <div id="tab-wishlist" class="tab-content-section">
    <div class="card-section">
        <p class="section-title"><i class="bi bi-heart-fill text-primary"></i> My Wishlist</p>
        <%
        try {
        	Integer wlCustId = (Integer) session.getAttribute("customerId");
            if (wlCustId == null) wlCustId = (int) session.getAttribute("userId");
            java.sql.Connection wlConn = com.shopeasy.DBConnection.getConnection();
            java.sql.PreparedStatement wlPs = wlConn.prepareStatement(
            		"SELECT p.product_id, p.name, p.price, p.original_price, p.image, p.thumbnail, p.stock, " +
            				"w.variation_id, w.variation_value, w.variation_type " +
            				"FROM wishlist w JOIN product p ON w.product_id = p.product_id " +
            				"WHERE w.customer_id = ? ORDER BY w.created_at DESC");
            wlPs.setInt(1, wlCustId);
            java.sql.ResultSet wlRs = wlPs.executeQuery();
            boolean hasWishlist = false;
            while (wlRs.next()) {
                hasWishlist = true;
        %>
    <div class="d-flex align-items-center gap-3 p-3 mb-3 border rounded-3" id="wl-<%= wlRs.getInt("product_id") %>">
            <a href="product.jsp?id=<%= wlRs.getInt("product_id") %>" style="text-decoration:none; flex-shrink:0;">
  <% 
  String wlVarId = wlRs.getString("variation_id");
  String wlVarValue = wlRs.getString("variation_value");
  String wlVarType = wlRs.getString("variation_type");
  boolean wlHasVar = wlVarId != null && !wlVarId.isEmpty();
  String wlImg = wlRs.getString("image");
  if (wlImg == null || wlImg.isEmpty()) wlImg = wlRs.getString("thumbnail");
  double wlOrigPrice = wlRs.getDouble("original_price");
  double wlRealPrice = wlRs.getDouble("price");
  if (wlHasVar) {
      try {
          java.sql.Connection wlVarConn = com.shopeasy.DBConnection.getConnection();
          java.sql.PreparedStatement wlVarPs = wlVarConn.prepareStatement(
              "SELECT image, price, original_price FROM product_variation WHERE variation_id=?");
          wlVarPs.setInt(1, Integer.parseInt(wlVarId));
          java.sql.ResultSet wlVarRs = wlVarPs.executeQuery();
          if (wlVarRs.next()) {
              String vImg = wlVarRs.getString("image");
              if (vImg != null && !vImg.isEmpty()) wlImg = vImg;
              double vPrice = wlVarRs.getDouble("price");
              double vOrigPrice = wlVarRs.getDouble("original_price");
              if (vPrice > 0) { wlRealPrice = vPrice; wlOrigPrice = vOrigPrice; }
          }
          wlVarRs.close(); wlVarPs.close(); wlVarConn.close();
      } catch (Exception ignored) {}
  }
  int wlDiscPct = 0;
  double wlDisplayPrice = wlRealPrice;
  double wlStrikePrice = 0;
  if (wlOrigPrice > 0 && wlRealPrice > 0 && wlOrigPrice < wlRealPrice) {
	    wlDiscPct = (int) Math.round((wlRealPrice - wlOrigPrice) / wlRealPrice * 100);
	    wlDisplayPrice = wlOrigPrice;
	    wlStrikePrice = wlRealPrice;
	}
  if (wlImg != null && !wlImg.isEmpty()) { %>
    <img src="<%= wlImg %>"
                     style="width:70px; height:70px; object-fit:cover; border-radius:10px; border:1px solid #eee;">
            <% } else { %>
                <div style="width:70px; height:70px; background:#f0f0f0; border-radius:10px;
                     display:flex; align-items:center; justify-content:center;">
                    <i class="bi bi-image text-muted"></i>
                </div>
            <% } %>
            </a>
   <div class="flex-grow-1">
                <a href="product.jsp?id=<%= wlRs.getInt("product_id") %>" style="text-decoration:none; color:inherit;">
                <p class="mb-0 fw-bold" style="font-size:14px;"><%= wlRs.getString("name") %></p>
                </a>
            <% if (wlHasVar) { %>
<span class="badge bg-light text-dark border mb-1" style="font-size:10px;">
    <i class="bi bi-tag"></i> <%= wlVarType %>: <%= wlVarValue %>
</span>
<% } %>
                <%
           
                %>
                <% if (wlDiscPct > 0) { %>
                    <div class="d-flex align-items-center gap-2">
                        <span class="text-muted text-decoration-line-through" style="font-size:11px;">₱<%= String.format("%.2f", wlStrikePrice) %></span>
                        <span class="badge bg-danger" style="font-size:10px;">-<%= wlDiscPct %>% OFF</span>
                    </div>
                    <p class="mb-0 text-primary fw-bold">₱<%= String.format("%.2f", wlDisplayPrice) %></p>
                <% } else { %>
                    <p class="mb-0 text-primary fw-bold">₱<%= String.format("%.2f", wlDisplayPrice) %></p>
                <% } %>
                <% if (wlRs.getInt("stock") > 0) { %>
                    <span class="badge bg-success" style="font-size:10px;">In Stock</span>
                <% } else { %>
                    <span class="badge bg-danger" style="font-size:10px;">Out of Stock</span>
                <% } %>
            </div>
        <div class="d-flex flex-column gap-2">
    <button type="button" class="btn btn-outline-danger"
    style="width:42px; height:42px; display:flex; align-items:center; justify-content:center;"
    onclick="removeWishlist(<%= wlRs.getInt("product_id") %>, this)">
    <i class="bi bi-trash" style="font-size:16px;"></i>
</button>
            </div>
        </div>
        <%
            }
            wlRs.close(); wlPs.close(); wlConn.close();
            if (!hasWishlist) {
        %>
        <div class="text-center py-4 text-muted">
            <i class="bi bi-heart fs-1 opacity-25"></i>
            <p class="mt-2">No items in wishlist yet.</p>
        </div>
        <% } } catch (Exception wlEx) { wlEx.printStackTrace(); } %>
    </div>
</div>
           <!-- SECURITY TAB -->
            <div id="tab-security" class="tab-content-section">
                <div class="card-section">
      <p class="section-title"><i class="bi bi-shield-lock-fill text-primary"></i> Security</p>
<div class="d-flex align-items-center gap-3 mb-4 pb-3 border-bottom">
    <div style="width:48px; height:48px; border-radius:12px; background:#e8f0fe; display:flex; align-items:center; justify-content:center; flex-shrink:0;">
        <i class="bi bi-shield-lock-fill text-primary" style="font-size:22px;"></i>
    </div>
    <div>
        <h6 class="fw-bold mb-0">Change Password</h6>
        <p class="text-muted mb-0" style="font-size:12px;">Update your account password to keep it secure.</p>
    </div>
</div>
                    <!-- Alert messages -->
                    <div id="securitySuccess" class="alert alert-success py-2 mb-3" style="display:none; font-size:13px;">
                        <i class="bi bi-check-circle-fill"></i> <span id="securitySuccessText">Password updated successfully!</span>
                    </div>
                    <div id="securityError" class="alert alert-danger py-2 mb-3" style="display:none; font-size:13px;">
                        <i class="bi bi-x-circle-fill"></i> <span id="securityErrorText">Error updating password.</span>
                    </div>

                    <div class="row g-3">
                        <div class="col-12">
                       <label class="form-label fw-bold" style="font-size:13px;">Current Password <span class="text-muted fw-normal" style="font-size:11px;">— enter your existing password</span></label>
                            <div class="input-group">
                                <span class="input-group-text"><i class="bi bi-lock"></i></span>
                            <input type="password" id="currentPw" class="form-control" placeholder="Enter current password" autocomplete="new-password">
                                <button class="btn btn-outline-secondary" type="button" onclick="togglePassword('currentPw', this)"><i class="bi bi-eye"></i></button>
                            </div>
                        </div>
                        <div class="col-md-6">
                      <label class="form-label fw-bold" style="font-size:13px;">New Password <span class="text-muted fw-normal" style="font-size:11px;">— min. 6 characters</span></label>
                            <div class="input-group">
                                <span class="input-group-text"><i class="bi bi-lock"></i></span>
                                <input type="password" id="newPw" class="form-control" placeholder="Enter new password" autocomplete="new-password" oninput="checkStrength(this.value)">
                                <button class="btn btn-outline-secondary" type="button" onclick="togglePassword('newPw', this)"><i class="bi bi-eye"></i></button>
                            </div>
                            <div id="strengthBar" class="password-strength bg-secondary" style="width:0%"></div>
                            <small id="strengthText" class="text-muted"></small>
                        </div>
                        <div class="col-md-6">
                        <label class="form-label fw-bold" style="font-size:13px;">Confirm New Password <span class="text-muted fw-normal" style="font-size:11px;">— re-enter new password</span></label>
                            <div class="input-group">
                                <span class="input-group-text"><i class="bi bi-lock"></i></span>
                                <input type="password" id="confirmPw" class="form-control" placeholder="Confirm new password" autocomplete="new-password">
                                <button class="btn btn-outline-secondary" type="button" onclick="togglePassword('confirmPw', this)"><i class="bi bi-eye"></i></button>
                            </div>
                        </div>
                      <div class="col-12">
                            <button class="btn btn-primary px-4" id="updatePwBtn" onclick="updatePassword()">
                                <i class="bi bi-shield-check"></i> Update Password
                            </button>
                        </div>
                        <div class="col-12">
                            <div class="p-3 rounded-3" style="background:#f8f9fa; border:1px solid #e0e6ff;">
                              <p class="mb-1 fw-bold" style="font-size:13px;"><i class="bi bi-question-circle-fill text-primary me-1"></i> Forgot your current password?</p>
                                <p class="mb-2 text-muted" style="font-size:12px;">Verify your identity using your email and username to reset your password.</p>
                                <a href="#" class="btn btn-outline-primary btn-sm" onclick="openForgotFromSecurity()">
                                    <i class="bi bi-shield-lock"></i> Verify Identity & Reset
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

          
            <div id="tab-notifications" class="tab-content-section">
                <div class="card-section">
                 <div class="d-flex justify-content-between align-items-center mb-3">
    <p class="section-title mb-0">
        <i class="bi bi-bell-fill text-primary"></i> Notifications
        <% if (unreadCount > 0) { %>
        <span class="badge bg-danger ms-2" style="font-size:11px;"><%= unreadCount %> new</span>
        <% } %>
    </p>
    <% if (!notifList.isEmpty()) { %>
    <div class="d-flex gap-2">
        <button class="btn btn-outline-primary btn-sm" onclick="markAllRead()">
            <i class="bi bi-check2-all"></i> Mark all read
        </button>
        <button class="btn btn-outline-danger btn-sm" onclick="clearAllNotifs()">
            <i class="bi bi-trash"></i> Clear all
        </button>
    </div>
    <% } %>
</div>

<!-- Enable Push Button -->
<div id="pushEnableBar" class="d-flex align-items-center justify-content-between p-3 mb-3 rounded-3"
     style="background:#e8f0fe; border:1px solid #c5d8fb;">
    <div class="d-flex align-items-center gap-2">
        <div style="width:36px; height:36px; border-radius:50%; background:#0d6efd; display:flex; align-items:center; justify-content:center;">
            <i class="bi bi-bell-fill" style="color:white; font-size:14px;"></i>
        </div>
        <div>
            <p class="mb-0 fw-bold" style="font-size:13px;">Enable Push Notifications</p>
            <p class="mb-0 text-muted" style="font-size:11px;">Get notified about your orders and updates</p>
        </div>
    </div>
    <button class="btn btn-primary btn-sm px-3 fw-bold" id="pushToggleBtn" onclick="requestNotifPermission()">
        <i class="bi bi-bell-fill me-1"></i> Enable
    </button>
</div>
               

                    <div id="notifList">
                    <% if (notifList.isEmpty()) { %>
                        <div class="text-center py-5 text-muted" id="emptyNotif">
                            <i class="bi bi-bell-slash fs-1 opacity-25"></i>
                            <p class="mt-2">No notifications yet.</p>
                        </div>
                    <% } else { %>
                        <% for (java.util.Map<String, Object> notif : notifList) { %>
                        <div class="d-flex align-items-start gap-3 p-3 mb-2 rounded-3 notif-item"
                             id="notif-<%= notif.get("id") %>"
                             style="background:<%= (boolean)notif.get("isRead") ? "#f8f9fa" : "#e8f0fe" %>; border:1px solid <%= (boolean)notif.get("isRead") ? "#eee" : "#c5d8fb" %>; cursor:pointer;"
                             onclick="markOneRead(<%= notif.get("id") %>, this)">
                            <div style="width:36px; height:36px; border-radius:50%; background:<%= (boolean)notif.get("isRead") ? "#dee2e6" : "#0d6efd" %>; display:flex; align-items:center; justify-content:center; flex-shrink:0;">
                                <i class="bi bi-bell-fill" style="color:white; font-size:14px;"></i>
                            </div>
                            <div class="flex-grow-1">
                                <p class="mb-0" style="font-size:13px; font-weight:<%= (boolean)notif.get("isRead") ? "400" : "600" %>;">
                                    <%= notif.get("message") %>
                                </p>
                                <p class="mb-0 text-muted" style="font-size:11px;">
                                    <i class="bi bi-clock"></i> <%= notif.get("createdAt") %>
                                </p>
                            </div>
                            <% if (!(boolean)notif.get("isRead")) { %>
                            <span class="badge bg-primary" style="font-size:9px;">New</span>
                            <% } %>
                        </div>
                        <% } %>
                    <% } %>
                    </div>
              </div>
     </div><!-- end tab-notifications -->
        <!-- WALLET TAB -->
      <div id="tab-wallet" class="tab-content-section" style="display:none;">
            <div class="card-section">
        <p class="section-title"><i class="bi bi-wallet2 text-primary"></i> My Wallet</p>
        <%
        double custWalletBalance = 0;
        java.util.List<java.util.Map<String,Object>> walletTxns = new java.util.ArrayList<>();
        try {
            Integer wCustId = (Integer) session.getAttribute("customerId");
            if (wCustId == null) wCustId = (int) session.getAttribute("userId");
            java.sql.Connection wConn = com.shopeasy.DBConnection.getConnection();
            java.sql.PreparedStatement wPs = wConn.prepareStatement(
                "SELECT wallet_balance FROM customer WHERE customer_id=?");
            wPs.setInt(1, wCustId);
            java.sql.ResultSet wRs = wPs.executeQuery();
            if (wRs.next()) custWalletBalance = wRs.getDouble("wallet_balance");
            wRs.close(); wPs.close();
            java.sql.PreparedStatement txPs = wConn.prepareStatement(
                "SELECT amount, type, description, created_at FROM wallet_transactions WHERE customer_id=? ORDER BY created_at DESC LIMIT 20");
            txPs.setInt(1, wCustId);
            java.sql.ResultSet txRs = txPs.executeQuery();
            while (txRs.next()) {
                java.util.Map<String,Object> tx = new java.util.HashMap<>();
                tx.put("amount", txRs.getDouble("amount"));
                tx.put("type", txRs.getString("type"));
                tx.put("description", txRs.getString("description"));
                tx.put("date", txRs.getTimestamp("created_at").toString().substring(0,16));
                walletTxns.add(tx);
            }
            txRs.close(); txPs.close(); wConn.close();
        } catch (Exception wEx) { wEx.printStackTrace(); }
        %>
        <!-- Balance Card -->
        <div class="p-4 rounded-3 mb-4 text-center" style="background:linear-gradient(135deg,#0d6efd,#6610f2); color:white;">
            <p class="mb-1" style="font-size:13px; opacity:0.85;">Available Wallet Balance</p>
            <h2 class="fw-bold mb-0" style="font-size:38px;">₱<%= String.format("%.2f", custWalletBalance) %></h2>
            <p class="mb-0 mt-1" style="font-size:12px; opacity:0.75;">Can be used on your next order</p>
        </div>
        <!-- Transaction History -->
        <p class="fw-bold mb-3" style="font-size:14px;"><i class="bi bi-clock-history me-1 text-primary"></i> Transaction History</p>
        <% if (walletTxns.isEmpty()) { %>
            <div class="text-center text-muted py-4">
                <i class="bi bi-wallet2" style="font-size:2rem; opacity:0.3;"></i>
                <p class="mt-2" style="font-size:13px;">No transactions yet.</p>
            </div>
        <% } else { for (java.util.Map<String,Object> tx : walletTxns) { %>
            <div class="d-flex justify-content-between align-items-center p-3 mb-2 rounded-3"
                 style="background:#f0f4ff; border:1px solid #d0e0ff; font-size:13px;">
                <div class="d-flex align-items-center gap-3">
                   <div style="width:40px; height:40px; border-radius:50%; background:<%= "purchase".equals(tx.get("type")) ? "#dc3545" : "#198754" %>; display:flex; align-items:center; justify-content:center;">
    <i class="bi bi-arrow-<%= "purchase".equals(tx.get("type")) ? "up" : "down" %>-circle-fill" style="color:white; font-size:18px;"></i>
</div>
                    <div>
                        <p class="mb-0 fw-bold"><%= tx.get("description") %></p>
                        <p class="mb-0 text-muted" style="font-size:11px;"><i class="bi bi-clock me-1"></i><%= tx.get("date") %></p>
                    </div>
                </div>
               <span class="fw-bold" style="font-size:15px; color:<%= "purchase".equals(tx.get("type")) ? "#dc3545" : "#198754" %>;">
    <%= "purchase".equals(tx.get("type")) ? "-" : "+" %>₱<%= String.format("%.2f", (double)tx.get("amount")) %>
</span>
            </div>
        <% } } %>
</div>
        </div><!-- end tab-wallet -->
        </div><!-- end col-md-9 -->
    </div><!-- end row -->
</div><!-- end container -->

<!-- GREEN BAR NOTIFICATION -->
<div id="successBar" style="display:none; position:fixed; top:0; left:0; width:100%; background:#198754; color:white; padding:12px 20px; z-index:99999; text-align:center; font-size:14px; font-weight:600; box-shadow:0 2px 8px rgba(0,0,0,0.15); margin:0;">
    <i class="bi bi-check-circle-fill me-2"></i>Profile saved successfully ✅
</div>



<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
<script>
const bdayInput = document.getElementById('inputBirthday');
const fp = flatpickr(bdayInput, {
    dateFormat: "Y-m-d",
    maxDate: new Date(new Date().setFullYear(new Date().getFullYear() - 1)),
    disableMobile: true,
    allowInput: false,
    onReady: function() {
        const bdayVal = bdayInput.value;
        if (bdayVal) this.setDate(bdayVal);
    }
});
const bdayVal = bdayInput.value;
if (!bdayVal) {
    bdayInput.removeAttribute('readonly');
} else {
    fp.set('clickOpens', false);
}
</script>
<script>

//Hide Write a Review button kapag refunded or pending
document.querySelectorAll('.order-card').forEach(card => {
    const refundStatus = card.dataset.refundStatus;
    if (refundStatus === 'Refunded' || refundStatus === 'Pending') {
        const reviewBtn = card.querySelector('.btn-warning');
        if (reviewBtn) reviewBtn.style.display = 'none';
    }
});

window.addEventListener('load', function() {
    const profileParams = new URLSearchParams(window.location.search);
    if (profileParams.get('tab') === 'orders') {
        filterOrders('All', document.querySelector('.nav-link[onclick*="All"]'));
    }
    const tabParam = profileParams.get('tab');
    const msg = profileParams.get('msg');

    if (profileParams.get('updated') === 'true') {
        const bar = document.getElementById('successBar');
        const msg = profileParams.get('msg');
        bar.querySelector('span') 
            ? bar.querySelector('span').textContent = (msg === 'avatar' ? 'Profile picture updated! ✅' : 'Profile saved successfully! ✅')
            : bar.innerHTML = '<i class="bi bi-check-circle-fill me-2"></i>' + (msg === 'avatar' ? 'Profile picture updated! ✅' : 'Profile saved successfully! ✅');
        bar.style.display = 'block';
        setTimeout(() => { bar.style.display = 'none'; }, 3000);
        window.history.replaceState({}, '', 'customer.jsp');
    }
    if (!tabParam || tabParam === 'wallet') {
        document.querySelectorAll('.tab-content-section').forEach(t => { t.classList.remove('active'); t.style.display = 'none'; });
        const activeTab = tabParam || 'profile';
        document.getElementById('tab-' + activeTab).style.display = 'block';
        document.getElementById('tab-' + activeTab).classList.add('active');
        const activeLink = document.querySelector('.sidebar-nav a[onclick*="' + activeTab + '"]');
        if (activeLink) { document.querySelectorAll('.sidebar-nav a').forEach(a => a.classList.remove('active')); activeLink.classList.add('active'); }
    }
    if (tabParam === 'orders') {
        document.querySelectorAll('.tab-content-section').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.sidebar-nav a').forEach(a => a.classList.remove('active'));
        document.getElementById('tab-orders').style.display = 'block';
        document.getElementById('tab-orders').classList.add('active');
        document.querySelector('.sidebar-nav a[onclick*="orders"]').classList.add('active');
    }
    if (tabParam === 'reviews') {
        document.querySelectorAll('.tab-content-section').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.sidebar-nav a').forEach(a => a.classList.remove('active'));
        document.getElementById('tab-reviews').classList.add('active');
        document.querySelector('.sidebar-nav a[onclick*="reviews"]').classList.add('active');
    }
    
    if (tabParam === 'address') {
        document.querySelectorAll('.tab-content-section').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.sidebar-nav a').forEach(a => a.classList.remove('active'));
        document.getElementById('tab-address').classList.add('active');
        document.querySelector('.sidebar-nav a[onclick*="address"]').classList.add('active');
        if (msg === 'success') showToast('Address saved successfully!');
    }
});

function enableEdit() {
    document.getElementById('inputLastName').removeAttribute('readonly');
    document.getElementById('inputFirstName').removeAttribute('readonly');
    document.getElementById('inputMI').removeAttribute('readonly');
    document.getElementById('inputUsername').removeAttribute('readonly');
    document.getElementById('inputPhone').removeAttribute('readonly');
     // Lock birthday if already set
        const bdayVal = document.getElementById('inputBirthday').value;
        if (!bdayVal || bdayVal.trim() === '') {
            fp.set('clickOpens', true);
        }
        document.getElementById('inputGender').removeAttribute('disabled');
        document.getElementById('saveSection').style.display = 'block';
        document.getElementById('editBtn').style.display = 'none';
       

        document.querySelectorAll('#profileForm .form-control:not([style*="background"])').forEach(el => {
            el.style.borderColor = '#0d6efd';
        });
    }

    function cancelEdit() {
        location.reload();
    }

    function showTab(tab, el, e) {
        if (e) e.preventDefault();
        document.querySelectorAll('.tab-content-section').forEach(t => {
            t.classList.remove('active');
            t.style.display = 'none';
        });
        document.querySelectorAll('.sidebar-nav a').forEach(a => a.classList.remove('active'));
        document.getElementById('tab-' + tab).style.display = 'block';
        document.getElementById('tab-' + tab).classList.add('active');
        el.classList.add('active');
    }

    function togglePassword(fieldId, btn) {
        const field = document.getElementById(fieldId);
        const icon = btn.querySelector('i');
        if (field.type === 'password') { field.type = 'text'; icon.className = 'bi bi-eye-slash'; }
        else { field.type = 'password'; icon.className = 'bi bi-eye'; }
    }

    function openForgotFromSecurity() {
        var modal = new bootstrap.Modal(document.getElementById('forgotPasswordModal'));
        modal.show();
    }

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
        if (newPw === current) {
            document.getElementById('securityErrorText').textContent = 'New password cannot be the same as current password.';
            document.getElementById('securityError').style.display = 'block';
            return;
        }
      
        if (newPw !== confirm) {
            document.getElementById('securityErrorText').textContent = 'New passwords do not match.';
            document.getElementById('securityError').style.display = 'block';
            return;
        }
        if (newPw.length < 4) {
            document.getElementById('securityErrorText').textContent = 'Password must be at least 4 characters.'
            document.getElementById('securityError').style.display = 'block';
            return;
        }

        const btn = document.getElementById('updatePwBtn');
        btn.disabled = true;
        btn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span> Updating password...';

     // Show overlay
        const overlay = document.createElement('div');
        overlay.id = 'pwOverlay';
        overlay.style.cssText = 'display:flex; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.9); z-index:9999; flex-direction:column; align-items:center; justify-content:center; gap:12px;';
        overlay.innerHTML = '<div class="spinner-border text-primary" style="width:3rem; height:3rem;"></div><p class="fw-bold text-primary fs-5">Updating password...</p><p class="text-muted" style="font-size:13px;">Please wait a moment</p>';
        document.body.appendChild(overlay);

        fetch('UpdatePasswordServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'currentPassword=' + encodeURIComponent(current) + '&newPassword=' + encodeURIComponent(newPw)
        })
        .then(r => r.json())
        .then(data => {
            btn.disabled = false;
            btn.innerHTML = '<i class="bi bi-shield-check"></i> Update Password';
            overlay.remove();
            if (data.success) {
                document.getElementById('currentPw').value = '';
                document.getElementById('newPw').value = '';
                document.getElementById('confirmPw').value = '';
                document.getElementById('strengthBar').style.width = '0%';
                document.getElementById('strengthBar').className = 'password-strength bg-secondary';
                document.getElementById('strengthText').textContent = '';
                document.getElementById('securitySuccessText').textContent = 'Password updated successfully!';
                document.getElementById('securitySuccess').style.display = 'block';
            } else {
                document.getElementById('securityErrorText').textContent = data.message || 'Current password is incorrect.';
                document.getElementById('securityError').style.display = 'block';
            }
        })
        .catch(() => {
            overlay.remove();
            btn.disabled = false;
            btn.innerHTML = '<i class="bi bi-shield-check"></i> Update Password';
            document.getElementById('securityErrorText').textContent = 'Server error. Please try again.';
            document.getElementById('securityError').style.display = 'block';
        });
    }
    
    function checkStrength(val) {
    	const bar = document.getElementById('strengthBar');
        const text = document.getElementById('strengthText');
        const currentVal = document.getElementById('currentPw').value.trim();
        let score = 0;
        if (val.length >= 4) score++;
        if (val.length >= 8) score++;
        if (/[A-Z]/.test(val)) score++;
        if (/[0-9]/.test(val)) score++;
        if (/[^A-Za-z0-9]/.test(val)) score++;
        const sameAsCurrent = val.length > 0 && val === currentVal;
        if (val.length === 0) { bar.style.width = '0%'; bar.className = 'password-strength bg-secondary'; text.textContent = ''; text.className = 'text-muted'; }
        else if (sameAsCurrent) { bar.style.width = '100%'; bar.className = 'password-strength bg-danger'; text.innerHTML = '<span class="text-danger">Cannot be the same as current password</span>'; }
        else if (score <= 2) { bar.style.width = '33%'; bar.className = 'password-strength bg-danger'; text.innerHTML = '<span class="text-danger">Weak - password too simple</span>'; }
        else if (score === 3) { bar.style.width = '66%'; bar.className = 'password-strength bg-warning'; text.innerHTML = '<span class="text-warning">Medium - acceptable but could be stronger</span>'; }
        else { bar.style.width = '100%'; bar.className = 'password-strength bg-success'; text.innerHTML = '<span class="text-success">Strong - great password!</span>'; }
    }

    let custCropImg = new Image();
    let custCropOffX = 0, custCropOffY = 0;
    let custCropDragging = false;
    let custCropStartX, custCropStartY;
    let custCropScale = 1;
    const CUST_SIZE = 300;

    function openCustomerCropModal(input) {
        if (input.files && input.files[0]) {
            const reader = new FileReader();
            reader.onload = function(e) {
                document.getElementById('customerCropModal').style.display = 'flex';
                custCropImg = new Image();
                custCropImg.onload = function() {
                    const fit = Math.max(CUST_SIZE / custCropImg.width, CUST_SIZE / custCropImg.height);
                    custCropScale = fit;
                    document.getElementById('custCropZoom').min = fit;
                    document.getElementById('custCropZoom').value = fit;
                    custCropOffX = (CUST_SIZE - custCropImg.width * custCropScale) / 2;
                    custCropOffY = (CUST_SIZE - custCropImg.height * custCropScale) / 2;
                    drawCustomerCrop();
                };
                custCropImg.src = e.target.result;
                const canvas = document.getElementById('customerCropCanvas');
                canvas.width = CUST_SIZE; canvas.height = CUST_SIZE;
                const nc = canvas.cloneNode(true);
                canvas.parentNode.replaceChild(nc, canvas);
                const c = document.getElementById('customerCropCanvas');
                c.addEventListener('mousedown', e => { custCropDragging = true; custCropStartX = e.clientX - custCropOffX; custCropStartY = e.clientY - custCropOffY; });
                c.addEventListener('mousemove', e => { if (!custCropDragging) return; custCropOffX = e.clientX - custCropStartX; custCropOffY = e.clientY - custCropStartY; clampCustCrop(); drawCustomerCrop(); });
                c.addEventListener('mouseup', () => custCropDragging = false);
                c.addEventListener('mouseleave', () => custCropDragging = false);
                c.addEventListener('touchstart', e => { custCropDragging = true; custCropStartX = e.touches[0].clientX - custCropOffX; custCropStartY = e.touches[0].clientY - custCropOffY; }, {passive:true});
                c.addEventListener('touchmove', e => { if (!custCropDragging) return; custCropOffX = e.touches[0].clientX - custCropStartX; custCropOffY = e.touches[0].clientY - custCropStartY; clampCustCrop(); drawCustomerCrop(); }, {passive:true});
                c.addEventListener('touchend', () => custCropDragging = false);
                document.getElementById('custCropZoom').oninput = function() {
                    const old = custCropScale; custCropScale = parseFloat(this.value);
                    custCropOffX = CUST_SIZE/2 - (CUST_SIZE/2 - custCropOffX) * (custCropScale/old);
                    custCropOffY = CUST_SIZE/2 - (CUST_SIZE/2 - custCropOffY) * (custCropScale/old);
                    clampCustCrop(); drawCustomerCrop();
                };
            };
            reader.readAsDataURL(input.files[0]);
        }
    }

    function clampCustCrop() {
        const w = custCropImg.width * custCropScale, h = custCropImg.height * custCropScale;
        if (custCropOffX > 0) custCropOffX = 0; if (custCropOffY > 0) custCropOffY = 0;
        if (custCropOffX + w < CUST_SIZE) custCropOffX = CUST_SIZE - w;
        if (custCropOffY + h < CUST_SIZE) custCropOffY = CUST_SIZE - h;
    }

    function drawCustomerCrop() {
        const c = document.getElementById('customerCropCanvas');
        const ctx = c.getContext('2d');
        c.width = CUST_SIZE; c.height = CUST_SIZE;
        ctx.fillStyle = '#fff'; ctx.fillRect(0, 0, CUST_SIZE, CUST_SIZE);
        ctx.drawImage(custCropImg, custCropOffX, custCropOffY, custCropImg.width * custCropScale, custCropImg.height * custCropScale);
        ctx.save(); ctx.fillStyle = 'rgba(0,0,0,0.5)'; ctx.fillRect(0, 0, CUST_SIZE, CUST_SIZE);
        ctx.globalCompositeOperation = 'destination-out';
        ctx.beginPath(); ctx.arc(CUST_SIZE/2, CUST_SIZE/2, CUST_SIZE/2 - 2, 0, Math.PI*2); ctx.fill(); ctx.restore();
        ctx.strokeStyle = '#0d6efd'; ctx.lineWidth = 3;
        ctx.beginPath(); ctx.arc(CUST_SIZE/2, CUST_SIZE/2, CUST_SIZE/2 - 2, 0, Math.PI*2); ctx.stroke();
    }

    function applyCustomerCrop() {
        const out = document.createElement('canvas');
        out.width = CUST_SIZE; out.height = CUST_SIZE;
        const ctx = out.getContext('2d');
        ctx.beginPath(); ctx.arc(CUST_SIZE/2, CUST_SIZE/2, CUST_SIZE/2, 0, Math.PI*2); ctx.clip();
        ctx.drawImage(custCropImg, custCropOffX, custCropOffY, custCropImg.width * custCropScale, custCropImg.height * custCropScale);
        const result = out.toDataURL('image/png');
        document.getElementById('avatarPreview').src = result;
        document.getElementById('avatarPreview').style.display = 'block';
        document.getElementById('avatarInitials').style.display = 'none';
        document.getElementById('sidebarAvatar').src = result;
        document.getElementById('profilePictureData').value = result;
        document.getElementById('customerCropModal').style.display = 'none';

        // Auto-save to database
        document.getElementById('savingOverlay').style.display = 'flex';
        setTimeout(() => {
            document.getElementById('profileForm').submit();
        }, 600);
    }

    document.getElementById('profileForm').addEventListener('submit', function(e) {
        e.preventDefault();
        const btn = document.querySelector('#saveSection button[type="submit"]');
        btn.disabled = true;
        btn.innerHTML = '<i class="bi bi-hourglass-split"></i> Saving...';
        setTimeout(() => { this.submit(); }, 600);
    });
    
    function confirmDelete(form) {
        if (!confirm('Delete this address?')) return false;
        return true;
    }
    
    function showAddressForm() {
        document.getElementById('addressForm').style.display = 'block';
        document.getElementById('addressAction').value = 'add';
        document.getElementById('addressFormTitle').innerHTML = '<i class="bi bi-plus-circle text-primary"></i> Add New Address';
        document.getElementById('addrFullname').value = '';
        document.getElementById('addrPhone').value = '';
        document.getElementById('addrAddress').value = '';
        document.getElementById('editAddressId').value = '';
        document.getElementById('addrIsDefault').checked = false;
    }

    function hideAddressForm() {
        document.getElementById('addressForm').style.display = 'none';
    }

    function editAddress(id, fullname, phone, address) {
        document.getElementById('addressForm').style.display = 'block';
        document.getElementById('addressAction').value = 'edit';
        document.getElementById('addressFormTitle').innerHTML = '<i class="bi bi-pencil text-primary"></i> Edit Address';
        document.getElementById('editAddressId').value = id;
        document.getElementById('addrFullname').value = fullname;
        document.getElementById('addrPhone').value = phone;
        document.getElementById('addrAddress').value = address;
        document.getElementById('addrIsDefault').checked = false;
        document.getElementById('addrIsDefault').parentElement.style.display = 'none';
        document.getElementById('addressForm').scrollIntoView({behavior: 'smooth'});
    }
    
    function doLogout() {
        if (confirm('Are you sure you want to logout?')) {
            document.getElementById('logoutOverlay').style.display = 'flex';
            setTimeout(() => { window.location.href = 'LogoutServlet'; }, 1500);
        }
    }
    
    function searchOrders(query) {
        const q = query.toLowerCase().trim();
        const cards = document.querySelectorAll('.order-card');
        let visible = 0;
        cards.forEach(card => {
            const orderId = card.querySelector('.fw-bold')?.innerText?.toLowerCase() || '';
            const shopName = card.querySelector('.fw-semibold')?.innerText?.toLowerCase() || '';
            const show = q === '' || orderId.includes(q) || shopName.includes(q);
            card.style.display = show ? 'block' : 'none';
            if (show) visible++;
        });
        const ef = document.getElementById('emptyFilter');
        if (ef) ef.style.display = visible === 0 ? 'block' : 'none';
        // Reset active tab to All when searching
        if (q !== '') {
            document.querySelectorAll('#orderTabs .nav-link').forEach(a => a.classList.remove('active'));
            document.querySelector('#orderTabs .nav-link').classList.add('active');
        }
    }
    
    function filterOrders(status, el) {
        event.preventDefault();
        document.querySelectorAll('#orderTabs .nav-link').forEach(a => a.classList.remove('active'));
        el.classList.add('active');
        const cards = document.querySelectorAll('.order-card');
        let visible = 0;
        cards.forEach(card => {
            let show = false;
            if (status === 'All') {
                show = true;
            } else if (status === 'To Ship') {
                show = card.dataset.status === 'Pending' || card.dataset.status === 'Processing';
            } else if (status === 'Shipped') {
                show = card.dataset.status === 'Shipped';
            } else if (status === 'Refund') {
                show = card.dataset.refundStatus !== undefined && 
                       card.dataset.refundStatus !== '' &&
                       card.dataset.refundStatus !== 'Rejected';
            } else {
                show = card.dataset.status === status;
            }
            card.style.display = show ? 'block' : 'none';
            if (show) visible++;
        });
        const ef = document.getElementById('emptyFilter');
        if (ef) ef.style.display = visible === 0 ? 'block' : 'none';
    }
 // REVIEW MODAL
    let currentReviewOrderId = 0;
    let currentRating = 0;

    function openReviewModal(orderId, productId) {
        currentReviewOrderId = orderId;
        currentRating = 0;
        document.getElementById('reviewOrderId').value = orderId;
        document.getElementById('reviewProductId').value = productId;
        document.getElementById('reviewComment').value = '';
        document.getElementById('reviewPhotoData').value = '';
        document.getElementById('reviewPhotoPreview').style.display = 'none';
        document.getElementById('reviewPhotoInput').value = '';
        setRating(0);
        document.getElementById('reviewModal').style.display = 'block';
    }

    function closeReviewModal() {
        document.getElementById('reviewModal').style.display = 'none';
    }

    function setRating(val) {
        currentRating = val;
        document.getElementById('selectedRating').value = val;
        for (let i = 1; i <= 5; i++) {
            const star = document.getElementById('star' + i);
            star.style.color = i <= val ? '#ffc107' : '#ccc';
        }
    }

    function previewReviewPhoto(input) {
        if (input.files && input.files[0]) {
            const reader = new FileReader();
            reader.onload = function(e) {
                document.getElementById('reviewPhotoImg').src = e.target.result;
                document.getElementById('reviewPhotoPreview').style.display = 'block';
                document.getElementById('reviewPhotoData').value = e.target.result;
            };
            reader.readAsDataURL(input.files[0]);
        }
    }

    function submitReview() {
        const rating = parseInt(document.getElementById('selectedRating').value);
        const comment = document.getElementById('reviewComment').value.trim();
        const orderId = document.getElementById('reviewOrderId').value;
        const productId = document.getElementById('reviewProductId').value;
        const photo = document.getElementById('reviewPhotoData').value;
        if (rating === 0) { showToast('Please select a star rating!', 'error'); return; }
     // comment is optional
        
        const formData = new URLSearchParams();
        formData.append('orderId', orderId);
        formData.append('rating', rating);
        formData.append('productId', productId);
        formData.append('comment', comment);
        formData.append('reviewPhoto', photo);

        fetch('ReviewServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: formData.toString()
        })
       .then(res => res.text())
.then(data => {
	if (data.trim() === 'already_reviewed') {
        closeReviewModal();
        showToast('You have already reviewed this order.', 'error');
        setTimeout(() => location.reload(), 2000);
        return;
    }
    if (data.trim() === 'ok') {
        closeReviewModal();
        document.getElementById('savingOverlay').style.display = 'flex';
        setTimeout(() => {
            window.location.href = 'customer.jsp?tab=reviews';
        }, 1000);
    } else {
        showToast('Something went wrong. Please try again.', 'error');
    }
})
        .catch(err => showToast('Error submitting review. Please try again.', 'error'));
    }
    
    function markAllRead() {
        fetch('NotificationServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'action=markAllRead'
        }).then(() => {
            document.querySelectorAll('.notif-item').forEach(el => {
                el.style.background = '#f8f9fa';
                el.style.border = '1px solid #eee';
                const icon = el.querySelector('div[style*="border-radius:50%"]');
                if (icon) icon.style.background = '#dee2e6';
                const badge = el.querySelector('.badge.bg-primary');
                if (badge) badge.remove();
                const msg = el.querySelector('p[style*="font-weight"]');
                if (msg) msg.style.fontWeight = '400';
            });
            // Remove all danger badges (sidebar + header)
            document.querySelectorAll('.badge.bg-danger').forEach(b => b.remove());
            showToast('All notifications marked as read!');
        });
    }

    function markOneRead(notifId, el) {
        const isUnread = el.style.background === 'rgb(232, 240, 254)' || el.getAttribute('data-read') !== '1';
        if (isUnread) {
            fetch('NotificationServlet', {
                method: 'POST',
                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                body: 'action=markRead&notifId=' + notifId
            }).then(() => {
                el.style.background = '#f8f9fa';
                el.style.border = '1px solid #eee';
                el.setAttribute('data-read', '1');
                const icon = el.querySelector('div[style*="border-radius:50%"]');
                if (icon) icon.style.background = '#dee2e6';
                const badge = el.querySelector('.badge.bg-primary');
                if (badge) badge.remove();
                const msg = el.querySelector('p[style*="font-weight"]');
                if (msg) msg.style.fontWeight = '400';
                // Update sidebar badge count
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

    function clearAllNotifs() {
        if (!confirm('Clear all notifications?')) return; // TODO: replace with modal if needed
        fetch('NotificationServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'action=clearAll'
        }).then(() => {
            document.getElementById('notifList').innerHTML = `
                <div class="text-center py-5 text-muted">
                    <i class="bi bi-bell-slash fs-1 opacity-25"></i>
                    <p class="mt-2">No notifications yet.</p>
                </div>`;
            const newBadge = document.querySelector('.badge.bg-danger');
            if (newBadge) newBadge.remove();
            showToast('All notifications cleared!');
        });
    }

    function removeWishlist(productId, btn) {
        if (!confirm('Remove from wishlist?')) return;
        fetch('WishlistServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'productId=' + productId + '&action=remove'
        })
        .then(res => res.json())
        .then(data => {
            if (data.success) {
                const card = document.getElementById('wl-' + productId);
                if (card) card.remove();
                showToast('Removed from wishlist! ✅');
                // Check if no more items
                const remaining = document.querySelectorAll('[id^="wl-"]');
                if (remaining.length === 0) {
                    const wishlistSection = document.querySelector('#tab-wishlist .card-section');
                    wishlistSection.innerHTML += `
                        <div class="text-center py-4 text-muted" id="emptyWishlist">
                            <i class="bi bi-heart fs-1 opacity-25"></i>
                            <p class="mt-2">No items in wishlist yet.</p>
                        </div>`;
                }
            }
        });
    }
    
    let cancelOrderType = 'processing'; // track kung pending or processing

    function openCancelModal(orderId, type) {
        cancelOrderType = type || 'processing';
        document.getElementById('cancelOrderId').value = orderId;
        document.getElementById('cancelReasonSelect').value = '';
        document.getElementById('otherReasonText').value = '';
        document.getElementById('cancelError').style.display = 'none';
        document.getElementById('cancelOrderModal').style.display = 'flex';
    }

    function cancelPendingOrder(orderId) {
        openCancelModal(orderId, 'pending');
    }

    function closeCancelModal() {
        document.getElementById('cancelOrderModal').style.display = 'none';
    }

    function submitCancelOrder() {
        const orderId = document.getElementById('cancelOrderId').value;
        const reason = document.getElementById('cancelReasonSelect').value;
        const other = document.getElementById('otherReasonText').value.trim();
        document.getElementById('cancelError').style.display = 'none';

        if (!reason) {
            document.getElementById('cancelError').style.display = 'block';
            return;
        }

        const fullReason = reason === 'Other' && other
            ? other + ' (Cancelled by customer)'
            : reason + ' (Cancelled by customer)';

        const cancelBody = cancelOrderType === 'pending'
            ? 'orderId=' + orderId + '&reason=' + encodeURIComponent(fullReason) + '&type=direct'
            : 'orderId=' + orderId + '&reason=' + encodeURIComponent(fullReason);

        fetch('CancelOrderServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: cancelBody
        })
        .then(res => res.json())
        .then(data => {
            if (data.success) {
                closeCancelModal();
                document.getElementById('savingOverlay').style.display = 'flex';
                setTimeout(() => location.reload(), 1000);
            } else {
                document.getElementById('cancelError').style.display = 'block';
                document.getElementById('cancelError').textContent = data.message || 'Error submitting request.';
            }
        });
    }
 // EDIT REVIEW
    let editCurrentRating = 0;

    function openEditReviewModal(reviewId, productId, rating, comment, photoUrl) {
        document.getElementById('editReviewId').value = reviewId;
        document.getElementById('editReviewProductId').value = productId;
        document.getElementById('editReviewComment').value = comment.replace(/\\n/g, '\n');
        document.getElementById('editReviewPhotoData').value = '';
        document.getElementById('editReviewPhotoInput').value = '';
        document.getElementById('editReviewPhotoPreview').style.display = 'none';
        document.getElementById('editReviewError').style.display = 'none';

        // Show current photo if exists
        if (photoUrl && photoUrl.trim() !== '') {
            document.getElementById('editCurrentPhotoImg').src = photoUrl;
            document.getElementById('editCurrentPhoto').style.display = 'block';
        } else {
            document.getElementById('editCurrentPhoto').style.display = 'none';
        }

        setEditRating(rating);
        document.getElementById('editReviewModal').style.display = 'block';
    }

    function closeEditReviewModal() {
        document.getElementById('editReviewModal').style.display = 'none';
    }

    function setEditRating(val) {
        editCurrentRating = val;
        document.getElementById('editSelectedRating').value = val;
        for (let i = 1; i <= 5; i++) {
            document.getElementById('editStar' + i).style.color = i <= val ? '#ffc107' : '#ccc';
        }
    }

    function previewEditPhoto(input) {
        if (input.files && input.files[0]) {
            const reader = new FileReader();
            reader.onload = function(e) {
                document.getElementById('editReviewPhotoImg').src = e.target.result;
                document.getElementById('editReviewPhotoPreview').style.display = 'block';
                document.getElementById('editReviewPhotoData').value = e.target.result;
            };
            reader.readAsDataURL(input.files[0]);
        }
    }

    function submitEditReview() {
        const reviewId = document.getElementById('editReviewId').value;
        const rating   = parseInt(document.getElementById('editSelectedRating').value);
        const comment  = document.getElementById('editReviewComment').value.trim();
        const newPhoto = document.getElementById('editReviewPhotoData').value;

        document.getElementById('editReviewError').style.display = 'none';

        if (rating === 0) {
            document.getElementById('editReviewError').style.display = 'block';
            return;
        }

        fetch('EditReviewServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'reviewId=' + reviewId +
                  '&rating=' + rating +
                  '&comment=' + encodeURIComponent(comment) +
                  '&newPhoto=' + encodeURIComponent(newPhoto)
        })
        .then(res => res.json())
        .then(data => {
            if (data.success) {
                closeEditReviewModal();
                document.getElementById('savingOverlay').style.display = 'flex';
                setTimeout(() => location.reload(), 1000);
            } else {
                document.getElementById('editReviewError').textContent = data.message || 'Error saving review.';
                document.getElementById('editReviewError').style.display = 'block';
            }
        })
        .catch(() => showToast('Error saving review. Please try again.', 'error'));
    }
    function openRefundModal(orderId) {
        document.getElementById('refundOrderId').value = orderId;
        document.getElementById('refundReason').value = '';
        document.getElementById('refundDescription').value = '';
        document.getElementById('refundProofInput').value = '';
        document.getElementById('refundProofPreview').style.display = 'none';
        document.getElementById('refundError').style.display = 'none';
        new bootstrap.Modal(document.getElementById('refundModal')).show();
    }

    function previewRefundProof(input) {
        if (input.files && input.files[0]) {
            const reader = new FileReader();
            reader.onload = function(e) {
                document.getElementById('refundProofImg').src = e.target.result;
                document.getElementById('refundProofPreview').style.display = 'block';
            };
            reader.readAsDataURL(input.files[0]);
        }
    }

    function submitRefund() {
        const orderId = document.getElementById('refundOrderId').value;
        const reason = document.getElementById('refundReason').value;
        const description = document.getElementById('refundDescription').value.trim();
        const proofImage = document.getElementById('refundProofImg').src || '';
        const errEl = document.getElementById('refundError');

        if (!reason) {
            errEl.innerText = 'Please select a reason.';
            errEl.style.display = 'block';
            return;
        }
        errEl.style.display = 'none';

        fetch('RefundServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'action=submit&orderId=' + orderId +
                  '&reason=' + encodeURIComponent(reason) +
                  '&description=' + encodeURIComponent(description) +
                  '&proofImage=' + encodeURIComponent(
                      document.getElementById('refundProofPreview').style.display !== 'none'
                      ? document.getElementById('refundProofImg').src : '')
        })
        .then(r => r.json())
       .then(data => {
        if (data.success) {
            bootstrap.Modal.getInstance(document.getElementById('refundModal')).hide();
            showToast('Refund request submitted successfully!', 'success');
            setTimeout(() => {
                window.location.href = 'customer.jsp?tab=orders';
            }, 1500);
            } else {
                errEl.innerText = data.message || 'Error submitting refund.';
                errEl.style.display = 'block';
            }
        })
        .catch(() => {
            errEl.innerText = 'Server error. Please try again.';
            errEl.style.display = 'block';
        });
    }
</script>
<!-- RE	VIEW MODAL -->
<div id="reviewModal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.5); z-index:10000;">
    <div style="background:white; border-radius:16px; padding:24px; width:90%; max-width:480px; max-height:90vh; overflow-y:auto;">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <p class="fw-bold mb-0" style="font-size:16px;"><i class="bi bi-star-fill text-warning me-2"></i>Write a Review</p>
            <button class="btn btn-sm btn-outline-secondary" onclick="closeReviewModal()"><i class="bi bi-x"></i></button>
        </div>

        <input type="hidden" id="reviewOrderId">
<input type="hidden" id="reviewProductId">
        <%-- Star Rating --%>
        <p class="fw-semibold mb-2" style="font-size:13px;">Rating</p>
        <div class="d-flex gap-2 mb-3" id="starRating">
    <i class="bi bi-star-fill" id="star1" style="font-size:2rem; color:#ccc; cursor:pointer;" onclick="setRating(1)"></i>
    <i class="bi bi-star-fill" id="star2" style="font-size:2rem; color:#ccc; cursor:pointer;" onclick="setRating(2)"></i>
    <i class="bi bi-star-fill" id="star3" style="font-size:2rem; color:#ccc; cursor:pointer;" onclick="setRating(3)"></i>
    <i class="bi bi-star-fill" id="star4" style="font-size:2rem; color:#ccc; cursor:pointer;" onclick="setRating(4)"></i>
    <i class="bi bi-star-fill" id="star5" style="font-size:2rem; color:#ccc; cursor:pointer;" onclick="setRating(5)"></i>
</div>
        <input type="hidden" id="selectedRating" value="0">

        <%-- Comment --%>
        <p class="fw-semibold mb-2" style="font-size:13px;">Comment</p>
        <textarea id="reviewComment" class="form-control mb-3" rows="3"
            placeholder="Share your experience with this product..."></textarea>

        <%-- Photo Upload --%>
        <p class="fw-semibold mb-2" style="font-size:13px;">Photo <span class="text-muted fw-normal">(optional)</span></p>
        <input type="file" id="reviewPhotoInput" class="form-control mb-1" accept="image/*"
            onchange="previewReviewPhoto(this)">
        <div id="reviewPhotoPreview" style="display:none;" class="mb-3">
            <img id="reviewPhotoImg" src="" style="width:80px; height:80px; object-fit:cover; border-radius:8px; border:2px solid #0d6efd;">
        </div>
        <input type="hidden" id="reviewPhotoData">

        <div class="d-flex gap-2 justify-content-end mt-3">
            <button class="btn btn-outline-secondary" onclick="closeReviewModal()">Cancel</button>
            <button class="btn btn-primary px-4" onclick="submitReview()">
                <i class="bi bi-send"></i> Submit Review
            </button>
        </div>
    </div>
</div>


<!-- CROP MODAL FOR CUSTOMER AVATAR -->
<div class="crop-modal-overlay" id="customerCropModal">
    <div class="crop-container">
        <p class="fw-bold mb-3 text-center" style="font-size:15px;"><i class="bi bi-crop text-primary"></i> Crop Profile Photo</p>
        <div class="crop-canvas-wrapper" id="custCropWrapper" style="width:300px; height:300px; margin:0 auto; overflow:hidden; border-radius:8px;">
            <canvas id="customerCropCanvas"></canvas>
        </div>
        <div class="mt-3 d-flex justify-content-between align-items-center">
            <div>
                <label style="font-size:12px;" class="text-muted">Zoom</label>
                <input type="range" id="custCropZoom" min="0.5" max="3" step="0.01" value="1" style="width:120px;">
            </div>
            <div class="d-flex gap-2">
                <button class="btn btn-outline-secondary btn-sm" onclick="document.getElementById('customerCropModal').style.display='none'">
                    <i class="bi bi-x"></i> Cancel
                </button>
                <button class="btn btn-primary btn-sm" onclick="applyCustomerCrop()">
                    <i class="bi bi-check2"></i> Apply
                </button>
            </div>
        </div>
    </div>
</div>
<!-- SAVING OVERLAY -->
<div id="savingOverlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.9); z-index:9999; flex-direction:column; align-items:center; justify-content:center;">
    <div class="spinner-border text-primary mb-3" style="width:3rem; height:3rem;" role="status"></div>
    <p class="fw-bold text-primary fs-5">Saving...</p>
</div>

<!-- LOGOUT OVERLAY -->
<div id="logoutOverlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.9); z-index:9999; flex-direction:column; align-items:center; justify-content:center;">
    <div class="spinner-border text-primary mb-3" style="width:3rem; height:3rem;" role="status"></div>
    <p class="fw-bold text-primary fs-5">Logging out...</p>
</div>
<%@ include file="modals.jsp" %>

<!-- EDIT REVIEW MODAL -->
<div id="editReviewModal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.5); z-index:10002;">
    <div style="background:white; border-radius:16px; padding:24px; width:90%; max-width:480px; max-height:90vh; overflow-y:auto; position:absolute; top:50%; left:50%; transform:translate(-50%,-50%);">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <p class="fw-bold mb-0" style="font-size:16px;"><i class="bi bi-pencil-fill text-primary me-2"></i>Edit Review</p>
            <button class="btn btn-sm btn-outline-secondary" onclick="closeEditReviewModal()"><i class="bi bi-x"></i></button>
        </div>

        <input type="hidden" id="editReviewId">
        <input type="hidden" id="editReviewProductId">

        <p class="fw-semibold mb-2" style="font-size:13px;">Rating</p>
        <div class="d-flex gap-2 mb-3" id="editStarRating">
            <i class="bi bi-star-fill" id="editStar1" style="font-size:2rem; color:#ccc; cursor:pointer;" onclick="setEditRating(1)"></i>
            <i class="bi bi-star-fill" id="editStar2" style="font-size:2rem; color:#ccc; cursor:pointer;" onclick="setEditRating(2)"></i>
            <i class="bi bi-star-fill" id="editStar3" style="font-size:2rem; color:#ccc; cursor:pointer;" onclick="setEditRating(3)"></i>
            <i class="bi bi-star-fill" id="editStar4" style="font-size:2rem; color:#ccc; cursor:pointer;" onclick="setEditRating(4)"></i>
            <i class="bi bi-star-fill" id="editStar5" style="font-size:2rem; color:#ccc; cursor:pointer;" onclick="setEditRating(5)"></i>
        </div>
        <input type="hidden" id="editSelectedRating" value="0">

        <p class="fw-semibold mb-2" style="font-size:13px;">Comment</p>
        <textarea id="editReviewComment" class="form-control mb-3" rows="3"
            placeholder="Share your experience..."></textarea>

        <p class="fw-semibold mb-2" style="font-size:13px;">Photo <span class="text-muted fw-normal">(optional — leave blank to keep existing)</span></p>
        <div id="editCurrentPhoto" class="mb-2" style="display:none;">
            <p class="text-muted mb-1" style="font-size:12px;">Current photo:</p>
            <img id="editCurrentPhotoImg" src="" style="width:80px; height:80px; object-fit:cover; border-radius:8px; border:2px solid #eee;">
        </div>
        <input type="file" id="editReviewPhotoInput" class="form-control mb-1" accept="image/*"
            onchange="previewEditPhoto(this)">
        <div id="editReviewPhotoPreview" style="display:none;" class="mb-3">
            <p class="text-muted mb-1" style="font-size:12px;">New photo:</p>
            <img id="editReviewPhotoImg" src="" style="width:80px; height:80px; object-fit:cover; border-radius:8px; border:2px solid #0d6efd;">
        </div>
        <input type="hidden" id="editReviewPhotoData">

        <div id="editReviewError" class="alert alert-danger py-2 mb-2" style="display:none; font-size:13px;">
       Please select a rating.
        </div>

        <div class="d-flex gap-2 justify-content-end mt-3">
            <button class="btn btn-outline-secondary" onclick="closeEditReviewModal()">Cancel</button>
            <button class="btn btn-primary px-4" onclick="submitEditReview()">
                <i class="bi bi-check2"></i> Save Changes
            </button>
        </div>
    </div>
</div>

<!-- CANCEL ORDER MODAL -->
<div id="cancelOrderModal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.5); z-index:10001; align-items:center; justify-content:center;">
    <div style="background:white; border-radius:16px; padding:28px; width:90%; max-width:420px;">
        <h6 class="fw-bold mb-3"><i class="bi bi-x-circle text-danger me-2"></i>Cancel Order</h6>
        <p class="text-muted mb-3" style="font-size:13px;">Please provide a reason for cancelling. The seller will be notified.</p>
        <input type="hidden" id="cancelOrderId">
        <div class="mb-3">
            <label class="form-label fw-bold" style="font-size:13px;">Reason</label>
            <select id="cancelReasonSelect" class="form-select mb-2">
                <option value="">-- Select a reason --</option>
                <option value="Changed my mind">Changed my mind</option>
                <option value="Found a better price elsewhere">Found a better price elsewhere</option>
                <option value="Ordered by mistake">Ordered by mistake</option>
                <option value="Shipping takes too long">Shipping takes too long</option>
                <option value="Other">Other</option>
            </select>
            <textarea id="otherReasonText" class="form-control" rows="2"
                placeholder="Additional details (optional)" style="font-size:13px;"></textarea>
        </div>
        <div id="cancelError" class="text-danger mb-2" style="display:none; font-size:13px;">Please select a reason.</div>
        <div class="d-flex gap-2 justify-content-end">
            <button class="btn btn-outline-secondary btn-sm" onclick="closeCancelModal()">Back</button>
            <button class="btn btn-danger btn-sm" onclick="submitCancelOrder()">
                <i class="bi bi-x-circle"></i> Confirm Cancel
            </button>
        </div>
    </div>
</div>
<!-- REFUND REQUEST MODAL -->
<div class="modal fade" id="refundModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-body p-4">
                <div class="text-center mb-3">
                    <div style="width:56px; height:56px; background:#fff3cd; border-radius:50%; display:flex; align-items:center; justify-content:center; margin:0 auto 10px;">
                        <i class="bi bi-arrow-counterclockwise" style="font-size:24px; color:#fd7e14;"></i>
                    </div>
                    <h5 class="fw-bold mb-1">Request Return / Refund</h5>
                    <p class="text-muted mb-0" style="font-size:13px;">Please provide details for your refund request.</p>
                </div>
                <input type="hidden" id="refundOrderId">
                <div class="mb-3">
                    <label class="form-label fw-bold" style="font-size:13px;">Reason <span class="text-danger">*</span></label>
                    <select class="form-select" id="refundReason" style="font-size:13px;">
                        <option value="">-- Select a reason --</option>
                        <option value="Wrong item received">Wrong item received</option>
                        <option value="Damaged product">Damaged product</option>
                        <option value="Missing item">Missing item</option>
                        <option value="Item not as described">Item not as described</option>
                        <option value="Change of mind">Change of mind</option>
                    </select>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-bold" style="font-size:13px;">Description <span class="text-muted fw-normal">(optional)</span></label>
                    <textarea class="form-control" id="refundDescription" rows="3" placeholder="Describe your issue..." style="font-size:13px;"></textarea>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-bold" style="font-size:13px;">Proof Image <span class="text-muted fw-normal">(optional)</span></label>
                    <input type="file" class="form-control" id="refundProofInput" accept="image/*" onchange="previewRefundProof(this)" style="font-size:13px;">
                    <div id="refundProofPreview" class="mt-2" style="display:none;">
                        <img id="refundProofImg" src="" style="width:100px; height:100px; object-fit:cover; border-radius:8px; border:2px solid #dee2e6;">
                    </div>
                </div>
                <div id="refundError" class="text-danger mb-2" style="display:none; font-size:13px;"></div>
                <div class="d-flex gap-2">
                    <button class="btn btn-outline-secondary w-100" data-bs-dismiss="modal">Cancel</button>
                    <button class="btn btn-danger w-100 fw-bold" onclick="submitRefund()">
                        <i class="bi bi-send me-1"></i> Submit Request
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>
<!-- Seller Center Loading Overlay -->
<div id="sellerCenterOverlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.95);
     z-index:99999; flex-direction:column; align-items:center; justify-content:center; gap:16px;">
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
    var overlay = document.getElementById('sellerCenterOverlay');
    overlay.style.cssText = "display:flex; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.95); z-index:99999; flex-direction:column; align-items:center; justify-content:center; gap:16px;";
    setTimeout(function() {
        window.location.href = 'seller.jsp';
    }, 1500);
}

function cancelRefundRequest(orderId) {
    if (!confirm('Cancel your refund request?')) return;
    fetch('CancelRefundServlet', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'orderId=' + orderId
    }).then(r => r.text()).then(() => location.reload());
}

function showToast(message, type) {
    if (!type) type = 'success';
    const toast = document.createElement('div');
    const bg = type === 'success' ? '#198754' : '#dc3545';
    toast.style.cssText = 'position:fixed; bottom:30px; left:50%; transform:translateX(-50%);' +
        'background:' + bg + '; color:white; padding:14px 28px; border-radius:10px;' +
        'font-weight:600; font-size:15px; z-index:99999; box-shadow:0 4px 15px rgba(0,0,0,0.2);';
    toast.innerHTML = '<i class="bi bi-check-circle-fill me-2"></i>' + message;
    document.body.appendChild(toast);
    setTimeout(function() { toast.remove(); }, 2500);
}

function formatPHPhone(input) {
    let val = input.value.replace(/\D/g, '');
    if (val.length > 10) val = val.substring(0, 10);
    input.value = val;
    const err = document.getElementById('addrPhoneError');
    if (val.length > 0 && val[0] !== '9') {
        err.style.display = 'block';
    } else {
        err.style.display = 'none';
    }
}

function submitAddressForm() {
    const phone = document.getElementById('addrPhone').value.trim();
    const err = document.getElementById('addrPhoneError');
    if (phone.length !== 10) {
    	document.getElementById('addrPhoneErrorText').textContent = 'Phone number must be exactly 10 digits (e.g. 9171234567)';
        err.style.display = 'block';
        document.getElementById('addrPhone').focus();
        return;
    }
    if (phone[0] !== '9') {
    	document.getElementById('addrPhoneErrorText').textContent = 'First digit must be 9 (e.g. 9171234567)';
        err.style.display = 'block';
        document.getElementById('addrPhone').focus();
        return;
    }
    err.style.display = 'none';
    document.getElementById('addrPhone').closest('form').submit();
}


let lastNotifId = 0;
function startNotifPolling() {
    if (Notification.permission !== 'granted') return;
    fetch('NotificationServlet?action=getLatest')
        .then(r => r.json())
        .then(data => { if (data.latestId) lastNotifId = data.latestId; })
        .catch(() => {});

    setInterval(() => {
        if (document.hidden) return; // skip if tab not visible
        fetch('NotificationServlet?action=getNew&since=' + lastNotifId)
            .then(r => r.json())
            .then(data => {
                if (data.notifications && data.notifications.length > 0) {
                    data.notifications.forEach(n => {
                        new Notification('ShopEasy', {
                            body: n.message,
                            icon: '/Online_Shopping/favicon.ico'
                        });
                        lastNotifId = Math.max(lastNotifId, n.id);
                    });
                }
            });
    }, 30000); // every 30 seconds
}

window.addEventListener('load', function() {
    updatePushBtn();
    if (Notification.permission === 'granted') {
        startNotifPolling();
        // Check agad after 3 seconds para hindi pa kailangan maghintay ng 30s
        setTimeout(() => {
            fetch('NotificationServlet?action=getNew&since=' + lastNotifId)
                .then(r => r.json())
                .then(data => {
                    if (data.notifications && data.notifications.length > 0) {
                        data.notifications.forEach(n => {
                            new Notification('ShopEasy', {
                                body: n.message,
                                icon: '/Online_Shopping/favicon.ico'
                            });
                            lastNotifId = Math.max(lastNotifId, n.id);
                        });
                    }
                });
        }, 3000);
    }
});

function updatePushBtn() {
    const bar = document.getElementById('pushEnableBar');
    const btn = document.getElementById('pushToggleBtn');
    if (!bar || !btn) return;
    if (!('Notification' in window)) { bar.style.display = 'none'; return; }
    if (Notification.permission === 'granted') {
        bar.style.background = '#d1fae5'; bar.style.borderColor = '#6ee7b7';
        btn.className = 'btn btn-success btn-sm px-3 fw-bold';
        btn.innerHTML = '<i class="bi bi-bell-fill me-1"></i> Enabled ✓';
        btn.disabled = true;
    } else if (Notification.permission === 'denied') {
        bar.style.background = '#fff0f0'; bar.style.borderColor = '#f5c2c7';
        btn.className = 'btn btn-danger btn-sm px-3 fw-bold';
        btn.innerHTML = '<i class="bi bi-bell-slash me-1"></i> Blocked';
        btn.disabled = true;
    }
}

function requestNotifPermission() {
    if (!('Notification' in window)) return;
    if (Notification.permission === 'granted') {
        window.open('chrome://settings/content/notifications');
        showToast('Opening browser settings — set localhost to Block to disable.', 'error');
        return;
    }
    Notification.requestPermission().then(perm => {
        updatePushBtn();
        if (perm === 'granted') { showToast('Notifications enabled! ✅'); startNotifPolling(); }
    });
}
function showTabMobile(tab, el) {
    if (tab === 'more') {
        const drawer = document.getElementById('moreDrawer');
        drawer.style.display = drawer.style.display === 'none' ? 'block' : 'none';
        return;
    }
    closeMoreDrawer();
    // Use existing showTab logic
    document.querySelectorAll('.tab-content-section').forEach(t => {
        t.classList.remove('active');
        t.style.display = 'none';
    });
    document.getElementById('tab-' + tab).style.display = 'block';
    document.getElementById('tab-' + tab).classList.add('active');
    // Update bottom nav active state
    document.querySelectorAll('.mobile-bottom-nav a').forEach(a => a.classList.remove('active'));
    el.classList.add('active');
    window.scrollTo(0, 0);
}

function closeMoreDrawer() {
    document.getElementById('moreDrawer').style.display = 'none';
}
</script>
<!-- MOBILE BOTTOM NAV -->
<div class="mobile-bottom-nav" style="display:none;">
    <a href="#" onclick="showTabMobile('profile', this)" class="active" id="mbnav-profile">
        <i class="bi bi-person-fill"></i>
        <span>Profile</span>
    </a>
    <a href="#" onclick="showTabMobile('orders', this)" id="mbnav-orders">
        <i class="bi bi-bag-fill"></i>
        <span>Orders</span>
    </a>
    <a href="#" onclick="showTabMobile('wishlist', this)" id="mbnav-wishlist">
        <i class="bi bi-heart-fill"></i>
        <span>Wishlist</span>
    </a>
    <a href="#" onclick="showTabMobile('wallet', this)" id="mbnav-wallet">
        <i class="bi bi-wallet2"></i>
        <span>Wallet</span>
    </a>
    <a href="#" onclick="showTabMobile('notifications', this)" id="mbnav-notifs">
        <i class="bi bi-bell-fill"></i>
        <span>Notifs
        <% if (unreadCount > 0) { %>
        <span class="badge bg-danger" style="font-size:8px; padding:2px 4px; border-radius:10px; position:absolute; margin-top:-8px; margin-left:2px;"><%= unreadCount %></span>
        <% } %>
        </span>
    </a>
    <a href="#" onclick="showTabMobile('more', this)" id="mbnav-more">
        <i class="bi bi-grid-fill"></i>
        <span>More</span>
    </a>
</div>

<!-- MORE DRAWER (mobile) -->
<div id="moreDrawer" style="display:none; position:fixed; bottom:70px; left:0; right:0; background:white; border-top:1px solid #e8f0fe; z-index:999; padding:12px; box-shadow:0 -4px 16px rgba(0,0,0,0.1);">
    <div class="row g-2 text-center">
        <div class="col-4">
            <a href="#" onclick="showTabMobile('reviews', document.getElementById('mbnav-more')); closeMoreDrawer();" class="d-flex flex-column align-items-center gap-1 text-decoration-none text-muted p-2 rounded-3" style="font-size:12px;">
                <i class="bi bi-star-fill text-warning" style="font-size:22px;"></i>Reviews
            </a>
        </div>
        <div class="col-4">
            <a href="#" onclick="showTabMobile('address', document.getElementById('mbnav-more')); closeMoreDrawer();" class="d-flex flex-column align-items-center gap-1 text-decoration-none text-muted p-2 rounded-3" style="font-size:12px;">
                <i class="bi bi-geo-alt-fill text-primary" style="font-size:22px;"></i>Addresses
            </a>
        </div>
        <div class="col-4">
            <a href="#" onclick="showTabMobile('security', document.getElementById('mbnav-more')); closeMoreDrawer();" class="d-flex flex-column align-items-center gap-1 text-decoration-none text-muted p-2 rounded-3" style="font-size:12px;">
                <i class="bi bi-shield-lock-fill text-success" style="font-size:22px;"></i>Security
            </a>
        </div>
    </div>
</div>
</body>
</html>