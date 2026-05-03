<%@ page session="true" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    if(session.getAttribute("userId") == null) {
        response.sendRedirect("index.jsp");
        return;
    }
    String userName = (String) session.getAttribute("userName");
    String userEmail = (String) session.getAttribute("userEmail");
    String userPhone = (String) session.getAttribute("userPhone");
    String userUsername = (String) session.getAttribute("userUsername");
    String userBirthday = (String) session.getAttribute("userBirthday");
    String userGender = (String) session.getAttribute("userGender");
    String initial = (userName != null && !userName.isEmpty()) ? String.valueOf(userName.charAt(0)).toUpperCase() : "?";
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Profile - ShopEasy</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
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
        body { background: #f4f6fb; }
        .sidebar {
            background: white;
            border-radius: 16px;
            box-shadow: 0 2px 12px rgba(0,0,0,0.07);
            padding: 24px 0;
            position: sticky;
            top: 20px;
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
            background: #e8f0fe;
            color: #0d6efd;
            border-left-color: #0d6efd;
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
            border-bottom: 2px solid #e8f0fe;
        }
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
        .tab-content-section { display: none; }
        .tab-content-section.active { display: block; }
        .stat-box { background: #f0f4ff; border-radius: 12px; padding: 14px; text-align: center; }
        .stat-box .stat-num { font-size: 24px; font-weight: 700; color: #0d6efd; }
        .stat-box .stat-label { font-size: 12px; color: #666; }
        .navbar-shopeasy { background: white; box-shadow: 0 2px 8px rgba(0,0,0,0.08); }
        .password-strength { height: 4px; border-radius: 2px; margin-top: 6px; transition: 0.3s; }
        .crop-modal-overlay {
            display: none; position: fixed; top: 0; left: 0;
            width: 100%; height: 100%; background: rgba(0,0,0,0.8);
            z-index: 99999; flex-direction: column; align-items: center; justify-content: center;
        }
        .crop-container { background: white; border-radius: 16px; padding: 20px; width: 90%; max-width: 500px; }
        #customerCropCanvas { display: block; width: 300px; height: 300px; cursor: grab; border-radius: 4px; }
        #reviewModal > div {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
}

#starRating i {
    cursor: pointer !important;
    pointer-events: auto !important;
    font-size: 2rem;
}
#starRating {
    pointer-events: auto !important;
}

    </style>
</head>
<body>

<!-- NAVBAR -->
<nav class="navbar navbar-light navbar-shopeasy py-2 mb-4">
    <div class="container-fluid px-3">
        <a class="navbar-brand fw-bold text-primary" href="index.jsp">
            <i class="bi bi-bag-heart-fill"></i> ShopEasy
        </a>
        <div class="d-flex align-items-center gap-3">
            <a href="index.jsp" class="text-decoration-none text-muted" style="font-size:14px;">
                <i class="bi bi-house"></i> Home
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
                    <%
    String sideAvatar = (String) session.getAttribute("userAvatar");
%>
<% if (sideAvatar != null && !sideAvatar.isEmpty()) { %>
    <img id="sidebarAvatar" src="<%= sideAvatar %>" style="width:80px; height:80px; border-radius:50%; object-fit:cover; border:3px solid #0d6efd;" alt="Avatar">
    <div id="sidebarInitials" class="avatar-circle-sm" style="display:none;"><%= initial %></div>
<% } else { %>
    <img id="sidebarAvatar" src="" style="width:80px; height:80px; border-radius:50%; object-fit:cover; border:3px solid #0d6efd; display:none;" alt="Avatar">
    <div id="sidebarInitials" class="avatar-circle-sm"><%= initial %></div>
<% } %>
                    <p class="fw-bold mb-0" style="font-size:15px;"><%= userName %></p>
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
                    <a href="#" onclick="showTab('notifications', this)"><i class="bi bi-bell"></i> Notifications</a>
                </div>
            </div>
        </div>

        <!-- MAIN CONTENT -->
        <div class="col-md-9">

           <!-- STATS ROW -->
<%
    int statTotal = 0, statPending = 0, statCompleted = 0, statCancelled = 0;
    try {
        int statId = (int) session.getAttribute("userId");
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
</div>

            <!-- MY PROFILE TAB -->
<div id="tab-profile" class="tab-content-section active">
    <div class="card-section">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <p class="section-title mb-0"><i class="bi bi-person-fill text-primary"></i> Personal Information</p>
            <button class="btn btn-outline-primary btn-sm" id="editBtn" onclick="enableEdit()">
                <i class="bi bi-pencil"></i> Edit Profile
            </button>
        </div>

        <div class="text-center mb-4">
        
     <div class="avatar-upload">
    <%
        String profileAvatar = (String) session.getAttribute("userAvatar");
    %>
    <% if (profileAvatar != null && !profileAvatar.isEmpty()) { %>
        <div class="avatar-circle" id="avatarInitials" style="display:none;"><%= initial %></div>
        <img src="<%= profileAvatar %>" alt="Avatar" id="avatarPreview" 
             style="width:100px; height:100px; border-radius:50%; object-fit:cover; border:3px solid #0d6efd; position:absolute; top:0; left:0; right:0; margin:0 auto;">
    <% } else { %>
        <div class="avatar-circle" id="avatarInitials"><%= initial %></div>
        <img src="" alt="Avatar" id="avatarPreview" 
             style="width:100px; height:100px; border-radius:50%; object-fit:cover; border:3px solid #0d6efd; display:none; position:absolute; top:0; left:0;">
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
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">Full Name</label>
                    <input type="text" name="fullname" id="inputFullname" class="form-control" value="<%= userName != null ? userName : "" %>" readonly>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">Username</label>
                    <input type="text" name="username" id="inputUsername" class="form-control" value="<%= userUsername != null ? userUsername : "" %>" readonly>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">Email</label>
                    <input type="email" class="form-control" value="<%= userEmail != null ? userEmail : "" %>" readonly style="background:#f8f9fa;">
                    <small class="text-muted">Email cannot be changed</small>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">Phone Number</label>
                    <div class="input-group">
                        <span class="input-group-text">+63</span>
                        <input type="tel" name="phone" id="inputPhone" class="form-control" value="<%= userPhone != null ? userPhone : "" %>" readonly>
                    </div>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">Birthday</label>
                    <input type="date" name="birthday" id="inputBirthday" class="form-control" value="<%= userBirthday != null ? userBirthday : "" %>" readonly>
                </div>
                <div class="col-md-6">
                    <label class="form-label fw-bold" style="font-size:13px;">Gender</label>
                    <select name="gender" id="inputGender" class="form-select" disabled>
    <option value="" disabled <%= (userGender == null || userGender.isEmpty()) ? "selected" : "" %>>Select your gender</option>
    <option <%= "Male".equals(userGender) ? "selected" : "" %>>Male</option>
    <option <%= "Female".equals(userGender) ? "selected" : "" %>>Female</option>
    <option <%= "Prefer not to say".equals(userGender) ? "selected" : "" %>>Prefer not to say</option>
</select>
                </div>
                <div class="col-12 text-end" id="saveSection" style="display:none;">
                    <button type="button" class="btn btn-outline-secondary me-2" onclick="cancelEdit()">
                        <i class="bi bi-x"></i> Cancel
                    </button>
                    <button type="submit" class="btn btn-primary px-4">
                        <i class="bi bi-check2"></i> Save Changes
                    </button>
                </div>
            </div>
        </form>
    </div>
</div>

           <!-- MY ORDERS TAB -->
            <div id="tab-orders" class="tab-content-section">
                <div class="card-section">
                    <p class="section-title"><i class="bi bi-bag-fill text-primary"></i> My Orders</p>
                    <%
                        java.util.List<java.util.Map<String, Object>> myOrders = new java.util.ArrayList<>();
                        try {
                            int custId2 = (int) session.getAttribute("userId");
                            java.sql.Connection ordConn = com.shopeasy.DBConnection.getConnection();
                            java.sql.PreparedStatement ordPs = ordConn.prepareStatement(
                                    "SELECT order_id, total_amount, status, payment_method, shipping_address, order_date " +
                                    "FROM orders WHERE customer_id=? ORDER BY order_id DESC");
                            ordPs.setInt(1, custId2);
                            java.sql.ResultSet ordRs = ordPs.executeQuery();
                            while (ordRs.next()) {
                                java.util.Map<String, Object> ord = new java.util.HashMap<>();
                                ord.put("id", ordRs.getInt("order_id"));
                                ord.put("total", ordRs.getDouble("total_amount"));
                                ord.put("status", ordRs.getString("status"));
                                ord.put("payment", ordRs.getString("payment_method"));
                                ord.put("address", ordRs.getString("shipping_address"));
                                ord.put("date", ordRs.getString("order_date"));
                                myOrders.add(ord);
                            }
                            ordRs.close(); ordPs.close(); ordConn.close();
                        } catch (Exception ex) { ex.printStackTrace(); }
                    %>
                    <!-- STATUS TABS -->
                    <ul class="nav nav-tabs mb-3" id="orderTabs" style="flex-wrap:nowrap; overflow-x:auto;">
                        <li class="nav-item"><a class="nav-link active" href="#" onclick="filterOrders('All', this)">All</a></li>
                        <li class="nav-item"><a class="nav-link" href="#" onclick="filterOrders('Pending', this)">To Pay</a></li>
                        <li class="nav-item"><a class="nav-link" href="#" onclick="filterOrders('Processing', this)">To Ship</a></li>
                        <li class="nav-item"><a class="nav-link" href="#" onclick="filterOrders('Shipped', this)">To Receive</a></li>
                        <li class="nav-item"><a class="nav-link" href="#" onclick="filterOrders('Completed', this)">Completed</a></li>
                        <li class="nav-item"><a class="nav-link" href="#" onclick="filterOrders('Cancelled', this)">Cancelled</a></li>
                    </ul>
                    <% if (myOrders.isEmpty()) { %>
                        <div class="text-center py-4 text-muted">
                            <i class="bi bi-bag fs-1 opacity-25"></i>
                            <p class="mt-2">No orders yet.</p>
                        </div>
                    <% } else { %>
                        <% for (java.util.Map<String, Object> ord : myOrders) { %>
                        <div class="order-item order-card" data-status="<%= ord.get("status") %>">
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
                            <p class="mb-1 text-muted" style="font-size:12px;">
                                <i class="bi bi-geo-alt"></i> <%= ord.get("address") %>
                            </p>
                            <p class="mb-1 text-muted" style="font-size:12px;">
                                <i class="bi bi-credit-card"></i> <%= ord.get("payment") %>
                            </p>

                            <%-- Load items for this order --%>
                            <%
    int firstProductId = 0;
    try {
        java.sql.Connection itemConn = com.shopeasy.DBConnection.getConnection();
        java.sql.PreparedStatement itemPs = itemConn.prepareStatement(
        	    "SELECT p.product_id, p.name, p.image, oi.quantity, oi.price, " +
        	    "pv.variation_type, pv.variation_value " +
        	    "FROM order_items oi " +
        	    "JOIN product p ON oi.product_id = p.product_id " +
        	    "LEFT JOIN product_variation pv ON oi.variation_id = pv.variation_id " +
        	    "WHERE oi.order_id = ?");
        itemPs.setInt(1, (Integer) ord.get("id"));
        java.sql.ResultSet itemRs = itemPs.executeQuery();
        while (itemRs.next()) {
            if (firstProductId == 0) firstProductId = itemRs.getInt("product_id");
%>
                                <div class="d-flex align-items-center gap-2 mb-1 mt-1">
                                    <% if (itemRs.getString("image") != null && !itemRs.getString("image").isEmpty()) { %>
                                        <img src="<%= itemRs.getString("image") %>" style="width:40px; height:40px; object-fit:cover; border-radius:6px; border:1px solid #eee;">
                                    <% } else { %>
                                        <div style="width:40px; height:40px; background:#f0f0f0; border-radius:6px; display:flex; align-items:center; justify-content:center; font-size:16px; color:#aaa;"><i class="bi bi-image"></i></div>
                                    <% } %>
                                    <div>
                                        <p class="mb-0 fw-bold" style="font-size:12px;"><%= itemRs.getString("name") %></p>
<% if (itemRs.getString("variation_type") != null) { %>
<p class="mb-0" style="font-size:11px;">
    <span class="badge bg-light text-dark border" style="font-size:10px;">
        <i class="bi bi-tag"></i> <%= itemRs.getString("variation_type") %>: <%= itemRs.getString("variation_value") %>
    </span>
</p>
<% } %>
<p class="mb-0 text-muted" style="font-size:11px;">Qty: <%= itemRs.getInt("quantity") %> &nbsp;|&nbsp; ₱<%= String.format("%.2f", itemRs.getDouble("price")) %></p>
                                    </div>
                                </div>
                                <%
                                    }
                                    itemRs.close(); itemPs.close(); itemConn.close();
                                } catch (Exception itemEx) { itemEx.printStackTrace(); }
                                %>                         

                            <div class="d-flex justify-content-between align-items-center mt-2">
    <p class="mb-0 fw-bold text-primary">Total: ₱<%= String.format("%.2f", ord.get("total")) %></p>
    <div class="d-flex gap-2 flex-wrap">
    <% if ("Pending".equals(ord.get("status"))) { %>
        <form action="CancelOrderServlet" method="post" style="display:inline;">
            <input type="hidden" name="orderId" value="<%= ord.get("id") %>">
            <button type="submit" class="btn btn-outline-danger btn-sm"
                onclick="return confirm('Cancel this order?')">
                <i class="bi bi-x-circle"></i> Cancel Order
            </button>
        </form>
    <% } %>
    <% if ("Completed".equals(ord.get("status"))) { %>
        <%
            // Check if already reviewed
            boolean hasReview = false;
            try {
                java.sql.Connection rvChkConn = com.shopeasy.DBConnection.getConnection();
                java.sql.PreparedStatement rvChkPs = rvChkConn.prepareStatement(
                	    "SELECT review_id FROM review WHERE customer_id=? AND product_id IN " +
                	    "(SELECT product_id FROM order_items WHERE order_id=?)");
                	rvChkPs.setInt(1, (int) session.getAttribute("userId"));
                	rvChkPs.setInt(2, (Integer) ord.get("id"));
                java.sql.ResultSet rvChkRs = rvChkPs.executeQuery();
                if (rvChkRs.next()) hasReview = true;
                rvChkRs.close(); rvChkPs.close(); rvChkConn.close();
            } catch (Exception rvEx) { rvEx.printStackTrace(); }
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
                int rvCustId = (int) session.getAttribute("userId");
                java.sql.Connection rvConn = com.shopeasy.DBConnection.getConnection();
                java.sql.PreparedStatement rvPs = rvConn.prepareStatement(
                		"SELECT r.rating, r.comment, r.photo, p.name AS pname, p.image AS pimage " +
                				"FROM review r JOIN product p ON r.product_id = p.product_id " +
                				"WHERE r.customer_id = ? ORDER BY r.review_id DESC");
                rvPs.setInt(1, rvCustId);
                java.sql.ResultSet rvRs = rvPs.executeQuery();
                boolean hasReviews = false;
                while (rvRs.next()) {
                    hasReviews = true;
        %>
        <div class="d-flex gap-3 p-3 mb-3 border rounded-3">
            <% if (rvRs.getString("pimage") != null && !rvRs.getString("pimage").isEmpty()) { %>
                <img src="<%= rvRs.getString("pimage") %>" style="width:60px; height:60px; object-fit:cover; border-radius:8px;">
            <% } else { %>
                <div style="width:60px; height:60px; background:#f0f0f0; border-radius:8px; display:flex; align-items:center; justify-content:center;"><i class="bi bi-image text-muted"></i></div>
            <% } %>
            <div class="flex-grow-1">
                <p class="mb-1 fw-bold" style="font-size:14px;"><%= rvRs.getString("pname") %></p>
                <div class="mb-1">
                    <% for (int s = 1; s <= 5; s++) { %>
                        <i class="bi bi-star-fill" style="color:<%= s <= rvRs.getInt("rating") ? "#ffc107" : "#ddd" %>; font-size:13px;"></i>
                    <% } %>
                </div>
                <p class="mb-0 text-muted" style="font-size:13px;"><%= rvRs.getString("comment") %></p>
               <% if (rvRs.getString("photo") != null && !rvRs.getString("photo").isEmpty()) { %>
    <img src="<%= rvRs.getString("photo") %>" 
         style="width:80px; height:80px; object-fit:cover; border-radius:8px; border:2px solid #eee; margin-top:6px;">
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
    <div class="card-section">
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
                            <input type="tel" name="phone" id="addrPhone" class="form-control" placeholder="9XX XXX XXXX" required>
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
                        <button type="submit" class="btn btn-primary btn-sm">
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
                int custId = (int) session.getAttribute("userId");
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
                            <button type="submit" class="btn btn-outline-danger btn-sm" onclick="return confirm('Delete this address?')">
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
            int wlCustId = (int) session.getAttribute("userId");
            java.sql.Connection wlConn = com.shopeasy.DBConnection.getConnection();
            java.sql.PreparedStatement wlPs = wlConn.prepareStatement(
                "SELECT p.product_id, p.name, p.price, p.image, p.stock " +
                "FROM wishlist w JOIN product p ON w.product_id = p.product_id " +
                "WHERE w.customer_id = ? ORDER BY w.created_at DESC");
            wlPs.setInt(1, wlCustId);
            java.sql.ResultSet wlRs = wlPs.executeQuery();
            boolean hasWishlist = false;
            while (wlRs.next()) {
                hasWishlist = true;
        %>
        <div class="d-flex align-items-center gap-3 p-3 mb-3 border rounded-3" id="wl-<%= wlRs.getInt("product_id") %>">
            <% if (wlRs.getString("image") != null && !wlRs.getString("image").isEmpty()) { %>
                <img src="<%= wlRs.getString("image") %>"
                     style="width:70px; height:70px; object-fit:cover; border-radius:10px; border:1px solid #eee;">
            <% } else { %>
                <div style="width:70px; height:70px; background:#f0f0f0; border-radius:10px;
                     display:flex; align-items:center; justify-content:center;">
                    <i class="bi bi-image text-muted"></i>
                </div>
            <% } %>
            <div class="flex-grow-1">
                <p class="mb-0 fw-bold" style="font-size:14px;"><%= wlRs.getString("name") %></p>
                <p class="mb-0 text-primary fw-bold">₱<%= String.format("%.2f", wlRs.getDouble("price")) %></p>
                <% if (wlRs.getInt("stock") > 0) { %>
                    <span class="badge bg-success" style="font-size:10px;">In Stock</span>
                <% } else { %>
                    <span class="badge bg-danger" style="font-size:10px;">Out of Stock</span>
                <% } %>
            </div>
            <div class="d-flex flex-column gap-2">
                <a href="product.jsp?id=<%= wlRs.getInt("product_id") %>"
                   class="btn btn-primary btn-sm">
                    <i class="bi bi-eye"></i> View
                </a>
                <button type="button" class="btn btn-outline-danger btn-sm"
    onclick="removeWishlist(<%= wlRs.getInt("product_id") %>, this)">
    <i class="bi bi-trash"></i>
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
                    <p class="section-title"><i class="bi bi-shield-lock-fill text-primary"></i> Security Settings</p>
                    <div class="row g-3">
                        <div class="col-12">
                            <label class="form-label fw-bold" style="font-size:13px;">Current Password</label>
                            <div class="input-group">
                                <span class="input-group-text"><i class="bi bi-lock"></i></span>
                                <input type="password" id="currentPw" class="form-control" placeholder="Enter current password">
                                <button class="btn btn-outline-secondary" onclick="togglePassword('currentPw', this)"><i class="bi bi-eye"></i></button>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label fw-bold" style="font-size:13px;">New Password</label>
                            <div class="input-group">
                                <span class="input-group-text"><i class="bi bi-lock"></i></span>
                                <input type="password" id="newPw" class="form-control" placeholder="Enter new password" oninput="checkStrength(this.value)">
                                <button class="btn btn-outline-secondary" onclick="togglePassword('newPw', this)"><i class="bi bi-eye"></i></button>
                            </div>
                            <div id="strengthBar" class="password-strength bg-secondary" style="width:0%"></div>
                            <small id="strengthText" class="text-muted"></small>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label fw-bold" style="font-size:13px;">Confirm New Password</label>
                            <div class="input-group">
                                <span class="input-group-text"><i class="bi bi-lock"></i></span>
                                <input type="password" id="confirmPw" class="form-control" placeholder="Confirm new password">
                                <button class="btn btn-outline-secondary" onclick="togglePassword('confirmPw', this)"><i class="bi bi-eye"></i></button>
                            </div>
                        </div>
                        <div class="col-12">
                            <button class="btn btn-primary px-4" onclick="showToast('Password changed successfully!')">
                                <i class="bi bi-shield-check"></i> Update Password
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- NOTIFICATIONS TAB -->
            <div id="tab-notifications" class="tab-content-section">
                <div class="card-section">
                    <p class="section-title"><i class="bi bi-bell-fill text-primary"></i> Notification Settings</p>
                    <div class="d-flex flex-column gap-3">
                        <div class="d-flex justify-content-between align-items-center p-3 border rounded-3">
                            <div>
                                <p class="mb-0 fw-bold" style="font-size:14px;">Order Updates</p>
                                <p class="mb-0 text-muted" style="font-size:12px;">Get notified when your order status changes</p>
                            </div>
                            <div class="form-check form-switch mb-0">
                                <input class="form-check-input" type="checkbox" checked style="width:40px; height:20px;">
                            </div>
                        </div>
                        <div class="d-flex justify-content-between align-items-center p-3 border rounded-3">
                            <div>
                                <p class="mb-0 fw-bold" style="font-size:14px;">Promotions & Sales</p>
                                <p class="mb-0 text-muted" style="font-size:12px;">Receive alerts for flash sales and discounts</p>
                            </div>
                            <div class="form-check form-switch mb-0">
                                <input class="form-check-input" type="checkbox" checked style="width:40px; height:20px;">
                            </div>
                        </div>
                        <button class="btn btn-primary px-4 align-self-end" onclick="showToast('Notification settings saved!')">
                            <i class="bi bi-check2"></i> Save Settings
                        </button>
                    </div>
                </div>
            </div>

        </div>
    </div>
</div>

<!-- GREEN BAR NOTIFICATION -->
<div id="successBar" style="display:none; position:fixed; top:0; left:0; width:100%; background:#198754; color:white; padding:12px 20px; z-index:9999; text-align:center; font-size:14px; font-weight:600; box-shadow:0 2px 8px rgba(0,0,0,0.15);">
    <i class="bi bi-check-circle-fill me-2"></i>Profile saved successfully ✅
</div>

<!-- TOAST (para sa ibang messages like address) -->
<div id="toast" style="display:none; position:fixed; top:50%; left:50%; transform:translate(-50%,-50%); background:#0d6efd; color:white; padding:20px 40px; border-radius:16px; font-size:16px; font-weight:600; z-index:9999; box-shadow:0 8px 30px rgba(0,0,0,0.3); text-align:center; align-items:center; gap:10px;">
    <i class="bi bi-check-circle-fill" style="font-size:20px;"></i><span id="toastMsg"></span>
</div>


<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
window.addEventListener('load', function() {
    const profileParams = new URLSearchParams(window.location.search);
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
    if (tabParam === 'orders') {
        document.querySelectorAll('.tab-content-section').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.sidebar-nav a').forEach(a => a.classList.remove('active'));
        document.getElementById('tab-orders').classList.add('active');
        document.querySelector('.sidebar-nav a[onclick*="orders"]').classList.add('active');
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
        document.getElementById('inputFullname').removeAttribute('readonly');
        document.getElementById('inputUsername').removeAttribute('readonly');
        document.getElementById('inputPhone').removeAttribute('readonly');
        document.getElementById('inputBirthday').removeAttribute('readonly');
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

    function showTab(tab, el) {
        document.querySelectorAll('.tab-content-section').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.sidebar-nav a').forEach(a => a.classList.remove('active'));
        document.getElementById('tab-' + tab).classList.add('active');
        el.classList.add('active');
        event.preventDefault();
    }

    function togglePassword(fieldId, btn) {
        const field = document.getElementById(fieldId);
        const icon = btn.querySelector('i');
        if (field.type === 'password') { field.type = 'text'; icon.className = 'bi bi-eye-slash'; }
        else { field.type = 'password'; icon.className = 'bi bi-eye'; }
    }

    function checkStrength(val) {
        const bar = document.getElementById('strengthBar');
        const text = document.getElementById('strengthText');
        if (val.length === 0) { bar.style.width = '0%'; text.textContent = ''; return; }
        if (val.length < 6) { bar.style.width = '25%'; bar.className = 'password-strength bg-danger'; text.textContent = 'Weak'; text.className = 'text-danger'; }
        else if (val.length < 10) { bar.style.width = '60%'; bar.className = 'password-strength bg-warning'; text.textContent = 'Medium'; text.className = 'text-warning'; }
        else { bar.style.width = '100%'; bar.className = 'password-strength bg-success'; text.textContent = 'Strong'; text.className = 'text-success'; }
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

    function showToast(msg) {
        const toast = document.getElementById('toast');
        document.getElementById('toastMsg').textContent = msg;
        toast.style.display = 'flex';
        setTimeout(() => toast.style.display = 'none', 3000);
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
    
    function filterOrders(status, el) {
        event.preventDefault();
        document.querySelectorAll('#orderTabs .nav-link').forEach(a => a.classList.remove('active'));
        el.classList.add('active');
        const cards = document.querySelectorAll('.order-card');
        let visible = 0;
        cards.forEach(card => {
            if (status === 'All' || card.dataset.status === status) {
                card.style.display = 'block';
                visible++;
            } else {
                card.style.display = 'none';
            }
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

        if (rating === 0) { alert('Please select a star rating!'); return; }
        if (comment === '') { alert('Please write a comment!'); return; }

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
    closeReviewModal();
    document.getElementById('savingOverlay').style.display = 'flex';
    setTimeout(() => location.reload(), 1000);
})
        .catch(err => alert('Error submitting review: ' + err));
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
</script>
<!-- REVIEW MODAL -->
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

</body>
</html>