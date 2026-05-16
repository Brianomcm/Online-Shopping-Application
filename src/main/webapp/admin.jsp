<%@ page session="true" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.Connection, java.sql.PreparedStatement, java.sql.ResultSet, com.shopeasy.DBConnection" %>
<%
    // Auth check — admin only
    String adminRole = (String) session.getAttribute("userRole");
    if (adminRole == null || !adminRole.equals("admin")) {
        response.sendRedirect("index.jsp");
        return;
    }
    String adminName = (String) session.getAttribute("userName");
    if (adminName == null) adminName = "Admin";

    // Stats
    int totalUsers = 0, totalSellers = 0, totalOrders = 0, totalProducts = 0;
    int pendingSellers = 0, pendingRefunds = 0;

    try {
        Connection conn = DBConnection.getConnection();

        ResultSet rs;
        PreparedStatement ps;

        ps = conn.prepareStatement("SELECT COUNT(*) FROM users WHERE role='customer' OR role='both'");
        rs = ps.executeQuery(); if (rs.next()) totalUsers = rs.getInt(1); rs.close(); ps.close();

        ps = conn.prepareStatement("SELECT COUNT(*) FROM seller");
        rs = ps.executeQuery(); if (rs.next()) totalSellers = rs.getInt(1); rs.close(); ps.close();

        ps = conn.prepareStatement("SELECT COUNT(*) FROM orders");
        rs = ps.executeQuery(); if (rs.next()) totalOrders = rs.getInt(1); rs.close(); ps.close();

        ps = conn.prepareStatement("SELECT COUNT(*) FROM product WHERE status='active'");
        rs = ps.executeQuery(); if (rs.next()) totalProducts = rs.getInt(1); rs.close(); ps.close();

        try {
        	ps = conn.prepareStatement("SELECT COUNT(*) FROM seller_application WHERE status='pending'");
            rs = ps.executeQuery(); if (rs.next()) pendingSellers = rs.getInt(1); rs.close(); ps.close();
        } catch(Exception ex) {}

        try {
            ps = conn.prepareStatement("SELECT COUNT(*) FROM refund_requests WHERE status='Pending'");
            rs = ps.executeQuery(); if (rs.next()) pendingRefunds = rs.getInt(1); rs.close(); ps.close();
        } catch(Exception ex) {}

        conn.close();
    } catch(Exception e) { e.printStackTrace(); }

    String tab = request.getParameter("tab");
    if (tab == null) tab = "dashboard";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ShopEasy Admin Panel</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
        :root {
            --sidebar-bg: #0f172a;
            --sidebar-width: 250px;
            --accent: #3b82f6;
            --accent-hover: #2563eb;
            --danger: #ef4444;
            --success: #22c55e;
            --warning: #f59e0b;
        }
        * { box-sizing: border-box; }
        body { margin: 0; font-family: 'Segoe UI', sans-serif; background: #f1f5f9; display: flex; min-height: 100vh; }

        /* SIDEBAR */
        .sidebar {
            width: var(--sidebar-width);
            background: var(--sidebar-bg);
            min-height: 100vh;
            position: fixed;
            top: 0; left: 0;
            display: flex; flex-direction: column;
            z-index: 100;
            transition: transform 0.3s;
        }
        .sidebar-logo {
            padding: 20px 20px 16px;
            border-bottom: 1px solid rgba(255,255,255,0.08);
        }
        .sidebar-logo a {
            color: white; text-decoration: none; font-size: 1.3rem; font-weight: 700;
        }
        .sidebar-logo span { color: var(--accent); }
        .sidebar-admin {
            padding: 16px 20px;
            border-bottom: 1px solid rgba(255,255,255,0.08);
            display: flex; align-items: center; gap: 10px;
        }
        .sidebar-admin .avatar {
            width: 36px; height: 36px; border-radius: 50%;
            background: var(--accent); color: white;
            display: flex; align-items: center; justify-content: center;
            font-weight: 700; font-size: 14px; flex-shrink: 0;
        }
        .sidebar-admin .info p { margin: 0; color: white; font-size: 13px; font-weight: 600; }
        .sidebar-admin .info small { color: #94a3b8; font-size: 11px; }
        .sidebar-nav { flex: 1; padding: 12px 0; overflow-y: auto; }
        .nav-section-label {
            padding: 8px 20px 4px;
            font-size: 10px; font-weight: 700; letter-spacing: 1px;
            color: #475569; text-transform: uppercase;
        }
        .sidebar-nav a {
            display: flex; align-items: center; gap: 10px;
            padding: 10px 20px; color: #94a3b8;
            text-decoration: none; font-size: 13.5px;
            transition: all 0.2s; border-left: 3px solid transparent;
        }
        .sidebar-nav a:hover { background: rgba(255,255,255,0.05); color: white; }
        .sidebar-nav a.active { background: rgba(59,130,246,0.15); color: white; border-left-color: var(--accent); }
        .sidebar-nav a .badge-pill {
            margin-left: auto; background: var(--danger);
            color: white; border-radius: 20px; font-size: 10px;
            padding: 1px 7px; font-weight: 700;
        }
        .sidebar-footer {
            padding: 16px 20px;
            border-top: 1px solid rgba(255,255,255,0.08);
        }
        .sidebar-footer a {
            color: #ef4444; text-decoration: none; font-size: 13px;
            display: flex; align-items: center; gap: 8px;
        }
        .sidebar-footer a:hover { color: #fca5a5; }

        /* MAIN CONTENT */
        .main-content {
            margin-left: var(--sidebar-width);
            flex: 1; padding: 0;
            min-height: 100vh;
        }
        .top-bar {
            background: white; padding: 14px 28px;
            border-bottom: 1px solid #e2e8f0;
            display: flex; align-items: center; justify-content: space-between;
            position: sticky; top: 0; z-index: 50;
        }
        .top-bar h5 { margin: 0; font-weight: 700; font-size: 16px; color: #0f172a; }
        .top-bar .breadcrumb { margin: 0; font-size: 12px; }
        .content-area { padding: 24px 28px; }

        /* STAT CARDS */
        .stat-card {
            background: white; border-radius: 12px;
            padding: 20px 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.06);
            display: flex; align-items: center; gap: 16px;
            border: 1px solid #e2e8f0;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .stat-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.08); }
        .stat-icon {
            width: 52px; height: 52px; border-radius: 12px;
            display: flex; align-items: center; justify-content: center;
            font-size: 22px; flex-shrink: 0;
        }
        .stat-card .stat-num { font-size: 26px; font-weight: 800; color: #0f172a; margin: 0; }
        .stat-card .stat-label { font-size: 12px; color: #64748b; margin: 0; }

        /* DATA TABLE */
        .admin-card {
            background: white; border-radius: 12px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.06);
            border: 1px solid #e2e8f0; overflow: hidden;
        }
        .admin-card-header {
            padding: 16px 20px; border-bottom: 1px solid #e2e8f0;
            display: flex; align-items: center; justify-content: space-between;
        }
        .admin-card-header h6 { margin: 0; font-weight: 700; font-size: 14px; color: #0f172a; }
        .table { margin: 0; font-size: 13px; }
        .table th { background: #f8fafc; color: #475569; font-size: 11px; font-weight: 700;
                    text-transform: uppercase; letter-spacing: 0.5px; border-bottom: 1px solid #e2e8f0; padding: 10px 16px; }
        .table td { padding: 12px 16px; vertical-align: middle; border-bottom: 1px solid #f1f5f9; color: #374151; }
        .table tbody tr:hover { background: #f8fafc; }
        .badge-role { padding: 3px 10px; border-radius: 20px; font-size: 11px; font-weight: 600; }

        /* MOBILE OVERLAY */
        .sidebar-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 99; }
        .mobile-toggle { display: none; }

        @media (max-width: 768px) {
            .sidebar { transform: translateX(-100%); }
            .sidebar.open { transform: translateX(0); }
            .main-content { margin-left: 0; }
            .mobile-toggle { display: block; }
            .sidebar-overlay.show { display: block; }
            .content-area { padding: 16px; }
        }
    </style>
</head>
<body>

<!-- SIDEBAR OVERLAY (mobile) -->
<div class="sidebar-overlay" id="sidebarOverlay" onclick="closeSidebar()"></div>

<!-- SIDEBAR -->
<div class="sidebar" id="sidebar">
    <div class="sidebar-logo">
        <a href="admin.jsp"><i class="bi bi-bag-heart-fill"></i> Shop<span>Easy</span></a>
        <div style="font-size:10px; color:#475569; margin-top:2px;">Admin Panel</div>
    </div>
    <div class="sidebar-admin">
        <div class="avatar"><%= adminName.charAt(0) %></div>
        <div class="info">
            <p><%= adminName %></p>
            <small>Administrator</small>
        </div>
    </div>
    <nav class="sidebar-nav">
        <div class="nav-section-label">Overview</div>
        <a href="admin.jsp?tab=dashboard" class="<%= "dashboard".equals(tab) ? "active" : "" %>">
            <i class="bi bi-grid-1x2-fill"></i> Dashboard
        </a>

   <div class="nav-section-label">Management</div>
        <a href="admin.jsp?tab=users" class="<%= "users".equals(tab) ? "active" : "" %>">
            <i class="bi bi-people-fill"></i> All Users
        </a>
        <a href="admin.jsp?tab=sellers" class="<%= "sellers".equals(tab) ? "active" : "" %>">
            <i class="bi bi-shop"></i> Sellers
        </a>
        <a href="admin.jsp?tab=products" class="<%= "products".equals(tab) ? "active" : "" %>">
            <i class="bi bi-box-seam"></i> Products
        </a>
        <a href="admin.jsp?tab=orders" class="<%= "orders".equals(tab) ? "active" : "" %>">
            <i class="bi bi-bag-check"></i> Orders
        </a>
        <a href="admin.jsp?tab=refunds" class="<%= "refunds".equals(tab) ? "active" : "" %>">
            <i class="bi bi-arrow-counterclockwise"></i> Refunds
            <% if (pendingRefunds > 0) { %><span class="badge-pill"><%= pendingRefunds %></span><% } %>
        </a>
        <a href="admin.jsp?tab=reports" class="<%= "reports".equals(tab) ? "active" : "" %>">
            <i class="bi bi-bar-chart-line-fill"></i> Sales Reports
        </a>
<a href="admin.jsp?tab=reviews" class="<%= "reviews".equals(tab) ? "active" : "" %>">
    <i class="bi bi-star-fill"></i> Reviews
</a>
<a href="admin.jsp?tab=vouchers" class="<%= "vouchers".equals(tab) ? "active" : "" %>">
    <i class="bi bi-ticket-perforated"></i> Vouchers
        </a>

        <div class="nav-section-label">Approvals</div>
        <a href="admin.jsp?tab=seller_applications" class="<%= "seller_applications".equals(tab) ? "active" : "" %>">
            <i class="bi bi-shop-window"></i> Seller Applications
            <% if (pendingSellers > 0) { %><span class="badge-pill"><%= pendingSellers %></span><% } %>
        </a>
        <a href="admin.jsp?tab=product_approvals" class="<%= "product_approvals".equals(tab) ? "active" : "" %>">
            <i class="bi bi-box-seam"></i> Product Approvals
        </a>
        <a href="admin.jsp?tab=payout_requests" class="<%= "payout_requests".equals(tab) ? "active" : "" %>">
            <i class="bi bi-cash-coin"></i> Payout Requests
        </a>
    </nav>
    <div class="sidebar-footer">
        <a href="#" onclick="doAdminLogout()"><i class="bi bi-box-arrow-left"></i> Logout</a>
    </div>
</div>

<!-- MAIN CONTENT -->
<div class="main-content">
    <div class="top-bar">
        <div class="d-flex align-items-center gap-3">
            <button class="btn btn-sm btn-light border mobile-toggle" onclick="openSidebar()">
                <i class="bi bi-list fs-5"></i>
            </button>
            <div>
                <h5>
                    <% if ("dashboard".equals(tab)) { %>Dashboard
                    <% } else if ("users".equals(tab)) { %>All Users
               <% } else if ("approvals".equals(tab) || "seller_applications".equals(tab)) { %>Seller Applications
                    <% } else if ("product_approvals".equals(tab)) { %>Product Approvals
                    <% } else if ("payout_requests".equals(tab)) { %>Payout Requests
                    <% } else if ("products".equals(tab)) { %>Products
                    <% } else if ("orders".equals(tab)) { %>Orders
                    <% } else if ("refunds".equals(tab)) { %>Refunds
                    <% } else if ("reviews".equals(tab)) { %>Review Management
                    <% } else if ("reports".equals(tab)) { %>Sales Reports
                    <% } %>
                </h5>
            </div>
        </div>
        <div style="font-size:12px; color:#64748b;">
            <i class="bi bi-calendar3 me-1"></i>
            <%= new java.util.Date().toString().substring(0,10) %>
        </div>
    </div>

    <div class="content-area">

    <%-- ==================== DASHBOARD TAB ==================== --%>
    <% if ("dashboard".equals(tab)) { %>

        <div class="row g-3 mb-4">
            <div class="col-6 col-md-3">
                <div class="stat-card">
                    <div class="stat-icon" style="background:#dbeafe;">
                        <i class="bi bi-people-fill" style="color:#3b82f6;"></i>
                    </div>
                    <div>
                        <p class="stat-num"><%= totalUsers %></p>
                        <p class="stat-label">Total Customers</p>
                    </div>
                </div>
            </div>
            <div class="col-6 col-md-3">
                <div class="stat-card">
                    <div class="stat-icon" style="background:#dcfce7;">
                        <i class="bi bi-shop" style="color:#22c55e;"></i>
                    </div>
                    <div>
                        <p class="stat-num"><%= totalSellers %></p>
                        <p class="stat-label">Total Sellers</p>
                    </div>
                </div>
            </div>
            <div class="col-6 col-md-3">
                <div class="stat-card">
                    <div class="stat-icon" style="background:#fef9c3;">
                        <i class="bi bi-bag-check" style="color:#f59e0b;"></i>
                    </div>
                    <div>
                        <p class="stat-num"><%= totalOrders %></p>
                        <p class="stat-label">Total Orders</p>
                    </div>
                </div>
            </div>
            <div class="col-6 col-md-3">
                <div class="stat-card">
                    <div class="stat-icon" style="background:#fce7f3;">
                        <i class="bi bi-box-seam" style="color:#ec4899;"></i>
                    </div>
                    <div>
                        <p class="stat-num"><%= totalProducts %></p>
                        <p class="stat-label">Total Products</p>
                    </div>
                </div>
            </div>
        </div>

        <% if (pendingSellers > 0 || pendingRefunds > 0) { %>
        <div class="row g-3 mb-4">
            <% if (pendingSellers > 0) { %>
            <div class="col-12 col-md-6">
                <div class="alert alert-warning d-flex align-items-center gap-3 mb-0 rounded-3">
                    <i class="bi bi-exclamation-triangle-fill fs-4"></i>
                    <div>
                        <strong><%= pendingSellers %> Pending Seller Application<%= pendingSellers > 1 ? "s" : "" %></strong>
                        <div style="font-size:12px;">Waiting for your review</div>
                    </div>
                    <a href="admin.jsp?tab=sellers" class="btn btn-sm btn-warning ms-auto">Review</a>
                </div>
            </div>
            <% } %>
            <% if (pendingRefunds > 0) { %>
            <div class="col-12 col-md-6">
                <div class="alert alert-danger d-flex align-items-center gap-3 mb-0 rounded-3">
                    <i class="bi bi-arrow-counterclockwise fs-4"></i>
                    <div>
                        <strong><%= pendingRefunds %> Pending Refund<%= pendingRefunds > 1 ? "s" : "" %></strong>
                        <div style="font-size:12px;">Waiting for your review</div>
                    </div>
                    <a href="admin.jsp?tab=refunds" class="btn btn-sm btn-danger ms-auto">Review</a>
                </div>
            </div>
            <% } %>
        </div>
        <% } %>

     <!-- Revenue Card + Chart -->
        <div class="row g-3 mb-4">
        <div class="col-12 col-md-4">
        <div class="admin-card h-100 p-4 d-flex flex-column justify-content-between">
       <div class="d-flex align-items-center gap-3 mb-3">
            <div class="stat-icon" style="background:#d1fae5;">
                <i class="bi bi-currency-dollar" style="color:#10b981;"></i>
            </div>
            <div>
                <%
                    double totalRevenue = 0;
                    try {
                        Connection cRev = DBConnection.getConnection();
                        PreparedStatement psRev = cRev.prepareStatement(
                            "SELECT COALESCE(SUM(total_amount),0) FROM orders WHERE status NOT IN ('Cancelled','cancelled')");
                        ResultSet rsRev = psRev.executeQuery();
                        if (rsRev.next()) totalRevenue = rsRev.getDouble(1);
                        rsRev.close(); psRev.close(); cRev.close();
                    } catch(Exception ex) {}
                %>
                <p class="stat-num">₱<%= String.format("%,.2f", totalRevenue) %></p>
                <p class="stat-label">Total Revenue</p>
            </div>
        </div>
        <hr class="my-2">
        <%
            double[] monthlyRev = new double[6];
            String[] monthLabels = new String[6];
            try {
                Connection cMonth = DBConnection.getConnection();
                java.util.Calendar cal = java.util.Calendar.getInstance();
                for (int m = 5; m >= 0; m--) {
                    java.util.Calendar tmp = (java.util.Calendar) cal.clone();
                    tmp.add(java.util.Calendar.MONTH, -m);
                    int yr = tmp.get(java.util.Calendar.YEAR);
                    int mo = tmp.get(java.util.Calendar.MONTH) + 1;
                    monthLabels[5-m] = new java.text.SimpleDateFormat("MMM").format(tmp.getTime());
                    PreparedStatement psM = cMonth.prepareStatement(
                        "SELECT COALESCE(SUM(total_amount),0) FROM orders " +
                        "WHERE YEAR(order_date)=? AND MONTH(order_date)=? AND status NOT IN ('Cancelled','cancelled')");
                    psM.setInt(1, yr); psM.setInt(2, mo);
                    ResultSet rsM = psM.executeQuery();
                    if (rsM.next()) monthlyRev[5-m] = rsM.getDouble(1);
                    rsM.close(); psM.close();
                }
                cMonth.close();
            } catch(Exception ex) {}
        %>
        <canvas id="revenueChart" height="120"></canvas>
        <script>
        window.revenueChartData = {
            labels: ['<%= monthLabels[0] %>','<%= monthLabels[1] %>','<%= monthLabels[2] %>','<%= monthLabels[3] %>','<%= monthLabels[4] %>','<%= monthLabels[5] %>'],
            data: [<%= monthlyRev[0] %>,<%= monthlyRev[1] %>,<%= monthlyRev[2] %>,<%= monthlyRev[3] %>,<%= monthlyRev[4] %>,<%= monthlyRev[5] %>]
        };
        </script>
        <hr class="my-2">
        <%
            int ordCompleted = 0, ordCancelledCount = 0, ordPendingCount = 0;
            try {
                Connection cMini = DBConnection.getConnection();
                PreparedStatement psMini;
                ResultSet rsMini;
                psMini = cMini.prepareStatement("SELECT COUNT(*) FROM orders WHERE status='Completed'");
                rsMini = psMini.executeQuery(); if(rsMini.next()) ordCompleted = rsMini.getInt(1); rsMini.close(); psMini.close();
                psMini = cMini.prepareStatement("SELECT COUNT(*) FROM orders WHERE status='Cancelled'");
                rsMini = psMini.executeQuery(); if(rsMini.next()) ordCancelledCount = rsMini.getInt(1); rsMini.close(); psMini.close();
                psMini = cMini.prepareStatement("SELECT COUNT(*) FROM orders WHERE status='Pending'");
                rsMini = psMini.executeQuery(); if(rsMini.next()) ordPendingCount = rsMini.getInt(1); rsMini.close(); psMini.close();
                cMini.close();
            } catch(Exception ex) {}
        %>
        <div class="d-flex flex-column gap-2 mt-2">
            <div class="d-flex justify-content-between align-items-center">
                <span style="font-size:12px;color:#64748b;"><i class="bi bi-check-circle-fill text-success me-1"></i>Completed Orders</span>
                <span class="badge bg-success"><%= ordCompleted %></span>
            </div>
            <div class="d-flex justify-content-between align-items-center">
                <span style="font-size:12px;color:#64748b;"><i class="bi bi-clock-fill text-warning me-1"></i>Pending Orders</span>
                <span class="badge bg-warning text-dark"><%= ordPendingCount %></span>
            </div>
            <div class="d-flex justify-content-between align-items-center">
                <span style="font-size:12px;color:#64748b;"><i class="bi bi-x-circle-fill text-danger me-1"></i>Cancelled Orders</span>
                <span class="badge bg-danger"><%= ordCancelledCount %></span>
            </div>
            <div class="d-flex justify-content-between align-items-center mt-1">
                <span style="font-size:12px;color:#64748b;"><i class="bi bi-arrow-counterclockwise text-info me-1"></i>Refund Requests</span>
                <span class="badge bg-info"><%= pendingRefunds >= 0 ? totalOrders > 0 ? pendingRefunds : 0 : 0 %></span>
            </div>
        </div>
   </div>
</div>
            <div class="col-12 col-md-8">
                <div class="admin-card h-100">
                    <div class="admin-card-header">
                        <h6><i class="bi bi-bar-chart-fill me-2 text-primary"></i>Orders by Status</h6>
                    </div>
                    <div class="p-3">
                        <%
                            int ordPending=0, ordProcessing=0, ordShipped=0, ordDelivered=0, ordCancelled=0;
                            try {
                                Connection cStat = DBConnection.getConnection();
                                PreparedStatement psStat = cStat.prepareStatement(
                                    "SELECT status, COUNT(*) as cnt FROM orders GROUP BY status");
                                ResultSet rsStat = psStat.executeQuery();
                                while (rsStat.next()) {
                                    String st = rsStat.getString("status");
                                    int cnt = rsStat.getInt("cnt");
                                    if ("Pending".equalsIgnoreCase(st)) ordPending = cnt;
                                    else if ("Processing".equalsIgnoreCase(st)) ordProcessing = cnt;
                                    else if ("Shipped".equalsIgnoreCase(st)) ordShipped = cnt;
                                    else if ("Delivered".equalsIgnoreCase(st) || "Completed".equalsIgnoreCase(st)) ordDelivered = cnt;
                                    else if ("Cancelled".equalsIgnoreCase(st)) ordCancelled = cnt;
                                }
                                rsStat.close(); psStat.close(); cStat.close();
                            } catch(Exception ex) {}
                        %>
                        <canvas id="orderChart" height="100"></canvas>
                        <script>
                        window.orderChartData = {
                        		labels: ['Pending','Processing','Shipped','Completed','Cancelled'],
                            data: [<%= ordPending %>,<%= ordProcessing %>,<%= ordShipped %>,<%= ordDelivered %>,<%= ordCancelled %>]
                        };
                        </script>
                    </div>
                </div>
            </div>
        </div>
<!-- Quick Actions -->
        <div class="row g-3 mb-4">
            <div class="col-6 col-md-3">
                <a href="admin.jsp?tab=users" class="text-decoration-none">
                    <div class="stat-card" style="background:linear-gradient(135deg,#3b82f6,#2563eb);border:none;cursor:pointer;">
                        <div class="stat-icon" style="background:rgba(255,255,255,0.2);">
                            <i class="bi bi-people-fill" style="color:white;"></i>
                        </div>
                        <div>
                            <p class="stat-num" style="color:white;font-size:16px;">Manage Users</p>
                            <p class="stat-label" style="color:rgba(255,255,255,0.8);">View all users</p>
                        </div>
                    </div>
                </a>
            </div>
            <div class="col-6 col-md-3">
                <a href="admin.jsp?tab=sellers" class="text-decoration-none">
                    <div class="stat-card" style="background:linear-gradient(135deg,#22c55e,#15803d);border:none;cursor:pointer;">
                        <div class="stat-icon" style="background:rgba(255,255,255,0.2);">
                            <i class="bi bi-shop" style="color:white;"></i>
                        </div>
                        <div>
                            <p class="stat-num" style="color:white;font-size:16px;">Manage Sellers</p>
                            <p class="stat-label" style="color:rgba(255,255,255,0.8);">View all sellers</p>
                        </div>
                    </div>
                </a>
            </div>
            <div class="col-6 col-md-3">
                <a href="admin.jsp?tab=orders" class="text-decoration-none">
                    <div class="stat-card" style="background:linear-gradient(135deg,#f59e0b,#d97706);border:none;cursor:pointer;">
                        <div class="stat-icon" style="background:rgba(255,255,255,0.2);">
                            <i class="bi bi-bag-check" style="color:white;"></i>
                        </div>
                        <div>
                            <p class="stat-num" style="color:white;font-size:16px;">Manage Orders</p>
                            <p class="stat-label" style="color:rgba(255,255,255,0.8);">View all orders</p>
                        </div>
                    </div>
                </a>
            </div>
            <div class="col-6 col-md-3">
                <a href="admin.jsp?tab=products" class="text-decoration-none">
                    <div class="stat-card" style="background:linear-gradient(135deg,#ec4899,#be185d);border:none;cursor:pointer;">
                        <div class="stat-icon" style="background:rgba(255,255,255,0.2);">
                            <i class="bi bi-box-seam" style="color:white;"></i>
                        </div>
                        <div>
                            <p class="stat-num" style="color:white;font-size:16px;">Manage Products</p>
                            <p class="stat-label" style="color:rgba(255,255,255,0.8);">View all products</p>
                        </div>
                    </div>
                </a>
            </div>
        </div>

        <!-- Recent Orders + Recent Users -->
        <div class="row g-3">
        <!-- Recent Orders + Recent Users -->
        <div class="row g-3">
            <div class="col-12 col-md-7">
                <div class="admin-card">
                    <div class="admin-card-header">
                        <h6><i class="bi bi-bag-check me-2 text-warning"></i>Recent Orders</h6>
                        <a href="admin.jsp?tab=orders" class="btn btn-sm btn-outline-secondary">View All</a>
                    </div>
                    <div class="table-responsive">
                        <table class="table">
                            <thead><tr><th>#</th><th>Customer</th><th>Amount</th><th>Status</th><th>Date</th></tr></thead>
                            <tbody>
                            <%
                                try {
                                    Connection cOrd = DBConnection.getConnection();
                                    PreparedStatement psOrd = cOrd.prepareStatement(
                                        "SELECT o.order_id, c.name as customer_name, o.total_amount, o.status, o.order_date " +
                                        "FROM orders o LEFT JOIN customer c ON o.customer_id = c.customer_id " +
                                        "ORDER BY o.order_id DESC LIMIT 5");
                                    ResultSet rsOrd = psOrd.executeQuery();
                                    boolean hasOrd = false;
                                    while (rsOrd.next()) {
                                        hasOrd = true;
                                        String ordStatus = rsOrd.getString("status");
                                        String badgeColor = "secondary";
                                        if ("Delivered".equalsIgnoreCase(ordStatus)) badgeColor = "success";
                                        else if ("Pending".equalsIgnoreCase(ordStatus)) badgeColor = "warning";
                                        else if ("Cancelled".equalsIgnoreCase(ordStatus)) badgeColor = "danger";
                                        else if ("Shipped".equalsIgnoreCase(ordStatus)) badgeColor = "info";
                            %>
                                <tr>
                                    <td>#<%= rsOrd.getInt("order_id") %></td>
                                    <td><%= rsOrd.getString("customer_name") != null ? rsOrd.getString("customer_name") : "—" %></td>
                                    <td>₱<%= String.format("%,.2f", rsOrd.getDouble("total_amount")) %></td>
                                    <td><span class="badge bg-<%= badgeColor %>"><%= ordStatus %></span></td>
                                    <td style="font-size:11px;color:#64748b;"><%= rsOrd.getString("order_date") != null ? rsOrd.getString("order_date").toString().substring(0,10) : "—" %></td>
                                </tr>
                            <% } if (!hasOrd) { %>
                                <tr><td colspan="5" class="text-center text-muted py-3">No orders yet.</td></tr>
                            <% } rsOrd.close(); psOrd.close(); cOrd.close(); } catch(Exception ex) { %>
                                <tr><td colspan="5" class="text-center text-danger py-3">Error loading orders.</td></tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            <div class="col-12 col-md-5">
                <div class="admin-card">
                    <div class="admin-card-header">
                        <h6><i class="bi bi-person-plus me-2 text-primary"></i>Recent Users</h6>
                        <a href="admin.jsp?tab=users" class="btn btn-sm btn-outline-secondary">View All</a>
                    </div>
                    <div class="table-responsive">
                        <table class="table">
                            <thead><tr><th>Name</th><th>Email</th><th>Role</th></tr></thead>
                            <tbody>
                            <%
                                try {
                                    Connection cUsr = DBConnection.getConnection();
                                    PreparedStatement psUsr = cUsr.prepareStatement(
                                        "SELECT u.email, u.role, c.name FROM users u " +
                                        "LEFT JOIN customer c ON u.user_id = c.user_id " +
                                        "WHERE u.role != 'admin' ORDER BY u.user_id DESC LIMIT 5");
                                    ResultSet rsUsr = psUsr.executeQuery();
                                    boolean hasUsr = false;
                                    while (rsUsr.next()) {
                                        hasUsr = true;
                                        String uRole = rsUsr.getString("role");
                                        String roleBadge = "seller".equals(uRole) ? "success" : "both".equals(uRole) ? "purple" : "primary";
                            %>
                                <tr>
                                    <td><%= rsUsr.getString("name") != null ? rsUsr.getString("name") : "—" %></td>
                                    <td style="font-size:11px;color:#64748b;"><%= rsUsr.getString("email") %></td>
                                    <td><span class="badge bg-<%= roleBadge %>" style="<%= "both".equals(uRole) ? "background:#7c3aed!important;" : "" %>"><%= uRole %></span></td>
                                </tr>
                            <% } if (!hasUsr) { %>
                                <tr><td colspan="3" class="text-center text-muted py-3">No users yet.</td></tr>
                            <% } rsUsr.close(); psUsr.close(); cUsr.close(); } catch(Exception ex) { %>
                                <tr><td colspan="3" class="text-center text-danger py-3">Error loading users.</td></tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
     </div>


    <%-- ==================== USERS TAB ==================== --%>
    <% } else if ("users".equals(tab)) {
        String searchUser = request.getParameter("search");
        if (searchUser == null) searchUser = "";
    %>
<div class="admin-card" style="overflow:visible;">
    <div class="admin-card-header">
        <h6><i class="bi bi-people me-2 text-primary"></i>All Users</h6>
                <form method="get" action="admin.jsp" class="d-flex gap-2">
                    <input type="hidden" name="tab" value="users">
                    <input type="text" class="form-control form-control-sm" name="search"
                           placeholder="Search name or email..." value="<%= searchUser %>" style="width:200px;">
                    <button class="btn btn-primary btn-sm" type="submit"><i class="bi bi-search"></i></button>
                </form>
            </div>
     <div class="table-responsive" style="overflow:visible;">
    <table class="table">
        <thead>
            <tr>
                <th>#</th>
                <th>Name</th>
                            <th>Email</th>
                            <th>Username</th>
                            <th>Role</th>
                            <th>Status</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        try {
                            Connection conn = DBConnection.getConnection();
                            String sql = "SELECT u.user_id, u.email, u.role, u.active_mode, u.status, c.name, c.username, c.phone, " +
                                    "COALESCE((SELECT COUNT(*) FROM user_violations WHERE user_id = u.user_id), 0) as offense_count " +
                                    "FROM users u LEFT JOIN customer c ON u.user_id = c.user_id " +
                                    "WHERE u.role != 'admin' ";
                            if (!searchUser.isEmpty()) {
                                sql += "AND (c.name LIKE ? OR u.email LIKE ? OR c.username LIKE ?) ";
                            }
                            sql += "ORDER BY u.user_id DESC LIMIT 100";
                            PreparedStatement ps = conn.prepareStatement(sql);
                            if (!searchUser.isEmpty()) {
                                String q = "%" + searchUser + "%";
                                ps.setString(1, q); ps.setString(2, q); ps.setString(3, q);
                            }
                            ResultSet rs = ps.executeQuery();
                            int totalRowsU = 0;
                            while (rs.next()) totalRowsU++;
                            rs.close();

                            rs = ps.executeQuery();
                            int rowNum = totalRowsU + 1;
                            while (rs.next()) {
                                rowNum--;
                                int uid = rs.getInt("user_id");
                                String uName = rs.getString("name"); if (uName == null) uName = "-";
                                String uEmail = rs.getString("email"); if (uEmail == null) uEmail = "-";
                                String uUsername = rs.getString("username"); if (uUsername == null) uUsername = "-";
                                String uRole = rs.getString("role"); if (uRole == null) uRole = "customer";
                                String uMode = rs.getString("active_mode"); if (uMode == null) uMode = "customer";
                    %>
                        <tr>
                            <td class="text-muted"><%= rowNum %></td>
                 <%
    int uOffenseCount = rs.getInt("offense_count");
    if (uOffenseCount > 3) uOffenseCount = 3;
%>
<td>
    <strong><%= uName %></strong>
    <% if (uOffenseCount > 0) { %>
    <div class="d-flex gap-1 mt-1">
        <% for (int bar = 1; bar <= 3; bar++) { %>
            <div style="width:18px; height:6px; border-radius:3px; background:<%= bar <= uOffenseCount ? "#ef4444" : "#d1d5db" %>;"></div>
        <% } %>
    </div>
    <% } %>
</td>
                            <td><%= uEmail %></td>
                            <td><%= uUsername %></td>
                            <td>
                                <% if ("both".equals(uRole)) { %>
                                    <span class="badge-role" style="background:#dbeafe;color:#1d4ed8;">Customer</span>
                                    <span class="badge-role" style="background:#dcfce7;color:#15803d;">Seller</span>
                                <% } else if ("seller".equals(uRole)) { %>
                                    <span class="badge-role" style="background:#dcfce7;color:#15803d;">Seller</span>
                                <% } else { %>
                                    <span class="badge-role" style="background:#dbeafe;color:#1d4ed8;">Customer</span>
                                <% } %>
                            </td>
                       <%
    String uStatus = rs.getString("status");
    if (uStatus == null) uStatus = "Active";
%>
<td><span class="badge <%= "Banned".equals(uStatus) ? "bg-danger" : "bg-success" %>" style="font-size:11px;"><%= uStatus %></span></td>
                         <td>
    <div class="dropdown">
        <button class="btn btn-outline-secondary btn-sm dropdown-toggle" 
                type="button" data-bs-toggle="dropdown">
            <i class="bi bi-three-dots-vertical"></i> Actions
        </button>
        <ul class="dropdown-menu">
         <% if ("Banned".equals(uStatus)) { %>
            <li>
                <a class="dropdown-item text-success" href="#"
                   onclick="activateUser(<%= uid %>, '<%= uName.replace("'","") %>')">
                    <i class="bi bi-check-circle me-2"></i>Activate
                </a>
            </li>
            <% } else { %>
           <% if (uOffenseCount == 0) { %>
            <li>
                <a class="dropdown-item text-warning" href="#"
                   onclick="sendOffense(<%= uid %>, '<%= uName.replace("'","") %>', 1)">
                    <i class="bi bi-exclamation-triangle me-2"></i>1st Offense
                </a>
            </li>
            <% } else if (uOffenseCount == 1) { %>
            <li>
                <a class="dropdown-item text-warning" href="#"
                   onclick="sendOffense(<%= uid %>, '<%= uName.replace("'","") %>', 2)">
                    <i class="bi bi-exclamation-triangle-fill me-2"></i>2nd Offense
                </a>
            </li>
            <% } else if (uOffenseCount == 2) { %>
            <li>
                <a class="dropdown-item text-danger" href="#"
                   onclick="sendOffense(<%= uid %>, '<%= uName.replace("'","") %>', 3)">
                    <i class="bi bi-x-octagon me-2"></i>3rd Offense
                </a>
            </li>
            <% } %>
         <li><hr class="dropdown-divider"></li>
<% if (uOffenseCount > 0) { %>
<li>
    <a class="dropdown-item text-secondary" href="#"
       onclick="revertOffense(<%= uid %>, '<%= uName.replace("'","") %>')">
        <i class="bi bi-arrow-counterclockwise me-2"></i>Revert Last Offense
    </a>
</li>
<% } %>
<li>
    <a class="dropdown-item text-danger" href="#"
       onclick="banUser(<%= uid %>, '<%= uName.replace("'","") %>')">
        <i class="bi bi-slash-circle me-2"></i>Ban
    </a>
</li>
            <% } %>
            <li>
             <a class="dropdown-item" href="admin.jsp?tab=orders&search=<%= uName.replace("'","") %>">
    <i class="bi bi-bag me-2"></i>View Orders
</a>
            </li>
            <li>
                <a class="dropdown-item text-primary" href="#"
                   onclick="viewUserProfile(<%= uid %>, '<%= uName.replace("'","") %>', '<%= uEmail %>', '<%= uRole %>')">
                    <i class="bi bi-person-lines-fill me-2"></i>View Profile
                </a>
            </li>
        </ul>
    </div>
</td>
                        </tr>
                    <%      }
                            rs.close(); ps.close(); conn.close();
                            if (rowNum == 0) { %>
                        <tr><td colspan="7" class="text-center text-muted py-4">No users found.</td></tr>
                    <%      }
                        } catch(Exception e) { e.printStackTrace(); %>
                        <tr><td colspan="7" class="text-center text-danger py-4">Error loading users.</td></tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        </div>

    <%-- ==================== SELLERS TAB ==================== --%>
    <% } else if ("sellers".equals(tab)) { %>
        <%-- Auto-reactivate expired suspensions --%>
        <%
        try {
            java.sql.Connection expConn = com.shopeasy.DBConnection.getConnection();
            java.sql.PreparedStatement expPs = expConn.prepareStatement(
                "UPDATE seller SET status='active', suspend_until=NULL WHERE status='suspended' AND suspend_until IS NOT NULL AND suspend_until <= NOW()");
            expPs.executeUpdate(); expPs.close(); expConn.close();
        } catch(Exception ex) {}
        %>
        <div class="admin-card">
            <div class="admin-card-header">
                <h6><i class="bi bi-shop me-2 text-success"></i>All Sellers</h6>
            </div>
            <div class="table-responsive">
                <table class="table">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Business Name</th>
                            <th>Owner</th>
                            <th>Business Type</th>
                            <th>Status</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        try {
                            Connection conn = DBConnection.getConnection();
                            PreparedStatement ps = conn.prepareStatement(
                                    "SELECT s.seller_id, s.user_id, s.business_name, s.business_type, " +
                                    "COALESCE(s.status, 'active') as status, " +
                                    "s.name as owner_name, u.email " +
                                    "FROM seller s " +
                                    "LEFT JOIN users u ON s.user_id = u.user_id " +
                                    "ORDER BY s.seller_id DESC LIMIT 100");
                            ResultSet rs = ps.executeQuery();
                            int totalRowsS = 0;
                            while (rs.next()) totalRowsS++;
                            rs.close();

                            rs = ps.executeQuery();
                            int rowNum = totalRowsS + 1;
                            while (rs.next()) {
                                rowNum--;
                                int sid = rs.getInt("seller_id");
                                int saUserId = rs.getInt("user_id");
                                String bName = rs.getString("business_name"); if (bName == null) bName = "-";
                                String bType = rs.getString("business_type"); if (bType == null) bType = "-";
                                String status = rs.getString("status"); if (status == null) status = "active";
                                String ownerName = rs.getString("owner_name"); if (ownerName == null) ownerName = "-";
                            %>
                        <tr>
                            <td class="text-muted"><%= rowNum %></td>
                            <td><strong><%= bName %></strong></td>
                            <td><%= ownerName %></td>
                            <td><%= bType %></td>
                            <td>
                                <% if ("pending".equals(status)) { %>
                                    <span class="badge bg-warning text-dark" style="font-size:11px;">Pending</span>
                                <% } else if ("active".equals(status) || "approved".equals(status)) { %>
                                    <span class="badge bg-success" style="font-size:11px;">Active</span>
                                <% } else if ("suspended".equals(status)) { %>
                                    <span class="badge bg-warning text-dark" style="font-size:11px;">Suspended</span>
                                <% } else if ("deactivated".equals(status)) { %>
                                    <span class="badge bg-danger" style="font-size:11px;">Deactivated</span>
                                <% } else { %>
                                    <span class="badge bg-secondary" style="font-size:11px;"><%= status %></span>
                                <% } %>
                            </td>
                            <td class="d-flex gap-1 flex-wrap">
                                <% if ("pending".equals(status)) { %>
                                    <button class="btn btn-success btn-sm"
                                        onclick="approveSeller(<%= saUserId %>, '<%= bName.replace("'","") %>')">
                                        <i class="bi bi-check-lg me-1"></i>Approve
                                    </button>
                                    <button class="btn btn-danger btn-sm"
                                        onclick="rejectSeller(<%= saUserId %>, '<%= bName.replace("'","") %>')">
                                        <i class="bi bi-x-lg me-1"></i>Reject
                                    </button>
                                <% } else if ("active".equals(status) || "approved".equals(status)) { %>
                                    <button class="btn btn-outline-warning btn-sm"
                                        onclick="openSellerAction(<%= sid %>, '<%= bName.replace("'","") %>', 'suspend')">
                                        <i class="bi bi-pause-circle me-1"></i>Suspend
                                    </button>
                                    <button class="btn btn-outline-danger btn-sm"
                                        onclick="openSellerAction(<%= sid %>, '<%= bName.replace("'","") %>', 'deactivate')">
                                        <i class="bi bi-slash-circle me-1"></i>Deactivate
                                    </button>
                                <% } else if ("suspended".equals(status)) { %>
                                    <button class="btn btn-outline-success btn-sm"
                                        onclick="reactivateSeller(<%= sid %>, '<%= bName.replace("'","") %>')">
                                        <i class="bi bi-play-circle me-1"></i>Reactivate
                                    </button>
                                    <button class="btn btn-outline-danger btn-sm"
                                        onclick="openSellerAction(<%= sid %>, '<%= bName.replace("'","") %>', 'deactivate')">
                                        <i class="bi bi-slash-circle me-1"></i>Deactivate
                                    </button>
                                <% } else if ("deactivated".equals(status)) { %>
                                    <button class="btn btn-outline-success btn-sm"
                                        onclick="reactivateSeller(<%= sid %>, '<%= bName.replace("'","") %>')">
                                        <i class="bi bi-play-circle me-1"></i>Reactivate
                                    </button>
                                <% } %>
                            </td>
                        </tr>
                    <%      }
                            rs.close(); ps.close(); conn.close();
                            if (rowNum == 0) { %>
                        <tr><td colspan="6" class="text-center text-muted py-4">No sellers found.</td></tr>
                    <%      }
                        } catch(Exception e) { e.printStackTrace(); %>
                        <tr><td colspan="6" class="text-center text-danger py-4">Error loading sellers.</td></tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        </div>
<%-- ==================== APPROVALS TAB ==================== --%>
   <% } else if ("approvals".equals(tab) || "seller_applications".equals(tab)) { %>

        <%-- SECTION 1: SELLER APPLICATIONS --%>
        <div class="admin-card mb-4">
            <div class="admin-card-header">
                <h6><i class="bi bi-shop me-2 text-warning"></i>Seller Applications
                    <% if (pendingSellers > 0) { %>
                        <span class="badge bg-warning text-dark ms-2" style="font-size:11px;"><%= pendingSellers %> Pending</span>
                    <% } %>
                </h6>
            </div>
            <div class="table-responsive">
                <table class="table">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Business Name</th>
                            <th>Owner</th>
                            <th>Business Type</th>
                            <th>Description</th>
                            <th>Applied</th>
                            <th>Status</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        try {
                            Connection connA = DBConnection.getConnection();
                            PreparedStatement psA = connA.prepareStatement(
                                "SELECT sa.application_id, sa.user_id, sa.business_name, sa.business_type, " +
                                "sa.shop_description, sa.status, sa.applied_at, " +
                                "c.name as owner_name, u.email " +
                                "FROM seller_application sa " +
                                "LEFT JOIN users u ON sa.user_id = u.user_id " +
                                "LEFT JOIN customer c ON sa.user_id = c.user_id " +
                                		"WHERE sa.status IN ('pending','rejected','approved') " +
                                "ORDER BY sa.applied_at DESC LIMIT 100");
                            ResultSet rsA = psA.executeQuery();
                            int totalRowsA = 0;
                            while (rsA.next()) totalRowsA++;
                            rsA.close();

                            rsA = psA.executeQuery();
                            int rowNumA = totalRowsA + 1;
                            while (rsA.next()) {
                                rowNumA--;
                                int saUserId = rsA.getInt("user_id");
                                String bName = rsA.getString("business_name"); if (bName == null) bName = "-";
                                String bType = rsA.getString("business_type"); if (bType == null) bType = "-";
                                String bDesc = rsA.getString("shop_description"); if (bDesc == null) bDesc = "-";
                                String status = rsA.getString("status"); if (status == null) status = "pending";
                                String ownerName = rsA.getString("owner_name"); if (ownerName == null) ownerName = "-";
                                String email = rsA.getString("email"); if (email == null) email = "-";
                                String appliedAt = rsA.getString("applied_at"); if (appliedAt == null) appliedAt = "-";
                                // Format date — show date only
                                if (appliedAt.length() > 10) appliedAt = appliedAt.substring(0, 10);
                    %>
                        <tr>
                            <td class="text-muted"><%= rowNumA %></td>
                            <td>
                                <strong><%= bName %></strong><br>
                                <small class="text-muted"><%= email %></small>
                            </td>
                            <td><%= ownerName %></td>
                            <td><small><%= bType %></small></td>
                            <td style="max-width:200px;">
                                <small class="text-muted" style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis;display:block;">
                                    <%= bDesc.length() > 60 ? bDesc.substring(0,60) + "…" : bDesc %>
                                </small>
                            </td>
                            <td><small class="text-muted"><%= appliedAt %></small></td>
                            <td>
                                <% if ("pending".equals(status)) { %>
                                    <span class="badge bg-warning text-dark" style="font-size:11px;">Pending</span>
                               <% } else if ("rejected".equals(status)) { %>
                                    <span class="badge bg-danger" style="font-size:11px;">Rejected</span>
                                <% } else if ("approved".equals(status)) { %>
                                    <span class="badge bg-success" style="font-size:11px;">Approved</span>
                                <% } %>
                            </td>
                            <td class="d-flex gap-1 flex-wrap">
                                <% if ("pending".equals(status)) { %>
                                    <button class="btn btn-success btn-sm"
                                            onclick="approveSeller(<%= saUserId %>, '<%= bName.replace("'","") %>')">
                                        <i class="bi bi-check-lg me-1"></i>Approve
                                    </button>
                                    <button class="btn btn-danger btn-sm"
                                            onclick="rejectSeller(<%= saUserId %>, '<%= bName.replace("'","") %>')">
                                        <i class="bi bi-x-lg me-1"></i>Reject
                                    </button>
                                <% } else { %>
                                    <span class="text-muted" style="font-size:12px;">No actions</span>
                                <% } %>
                            </td>
                        </tr>
                    <%      }
                            rsA.close(); psA.close(); connA.close();
                            if (rowNumA == 0) { %>
                        <tr><td colspan="8" class="text-center text-muted py-4">
                            <i class="bi bi-inbox" style="font-size:24px; display:block; margin-bottom:8px;"></i>
                            No applications found.
                        </td></tr>
                    <%      }
                        } catch(Exception e) { e.printStackTrace(); %>
                        <tr><td colspan="8" class="text-center text-danger py-4">Error loading applications.</td></tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        </div>

      <%-- ==================== PRODUCT APPROVALS TAB ==================== --%>
 <% } else if ("product_approvals".equals(tab)) { %>
        <div class="admin-card mb-4">
            <div class="admin-card-header">
                <h6><i class="bi bi-box-seam me-2 text-primary"></i>Product Approvals
                    <%
                    String pageParam = request.getParameter("page");
                    int paPage = (pageParam != null) ? Integer.parseInt(pageParam) : 1;
                    int paLimit = 50;
                    int paOffset = (paPage - 1) * paLimit;
                    int totalPaAll = 0;
                    try {
                        Connection cntConn = DBConnection.getConnection();
                        PreparedStatement cntPs = cntConn.prepareStatement(
                            "SELECT COUNT(*) FROM product WHERE status IN ('pending','rejected','active')");
                        ResultSet cntRs = cntPs.executeQuery();
                        if (cntRs.next()) totalPaAll = cntRs.getInt(1);
                        cntRs.close(); cntPs.close(); cntConn.close();
                    } catch(Exception e) {}
                    int totalPaPages = (int) Math.ceil((double) totalPaAll / paLimit);
                    
                        int pendingProducts = 0;
                        try {
                            Connection ppConn = DBConnection.getConnection();
                            PreparedStatement ppPs = ppConn.prepareStatement(
                                "SELECT COUNT(*) FROM product WHERE status='pending'");
                            ResultSet ppRs = ppPs.executeQuery();
                            if (ppRs.next()) pendingProducts = ppRs.getInt(1);
                            ppRs.close(); ppPs.close(); ppConn.close();
                        } catch(Exception e) {}
                    %>
                    <% if (pendingProducts > 0) { %>
                        <span class="badge bg-warning text-dark ms-2" style="font-size:11px;"><%= pendingProducts %> Pending</span>
                    <% } %>
                </h6>
            </div>
            <div class="table-responsive">
                <table class="table">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Product</th>
                            <th>Seller</th>
                            <th>Category</th>
                            <th>Price</th>
                            <th>Stock</th>
                            <th>Submitted</th>
                            <th>Status</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        try {
                            Connection paConn = DBConnection.getConnection();
                            PreparedStatement paPs = paConn.prepareStatement(
                            		"SELECT p.product_id, p.name, p.price, p.stock, p.thumbnail, p.status, p.created_at, " +
                            				"(SELECT pg.image FROM product_gallery pg WHERE pg.product_id = p.product_id ORDER BY pg.sort_order LIMIT 1) as gallery_img, " +
                            				"(SELECT pv.image FROM product_variation pv WHERE pv.product_id = p.product_id AND pv.image IS NOT NULL LIMIT 1) as var_img, " +
                            						"s.business_name, c.name as category_name " +
                                "FROM product p " +
                                "LEFT JOIN seller s ON p.seller_id = s.seller_id " +
                                "LEFT JOIN category c ON p.category_id = c.category_id " +
                                		"WHERE p.status IN ('pending','rejected','active') " +
                                		"ORDER BY p.product_id DESC LIMIT " + paLimit + " OFFSET " + paOffset);
                         // Use totalPaAll for reverse numbering (across all pages)
                            ResultSet paRs = paPs.executeQuery();
                            int paRow = totalPaAll - paOffset + 1;
                            while (paRs.next()) {
                                paRow--;
                                int productId = paRs.getInt("product_id");
                                String pName = paRs.getString("name"); if (pName == null) pName = "-";
                                double pPrice = paRs.getDouble("price");
                                int pStock = paRs.getInt("stock");
                                String pImage = paRs.getString("thumbnail");
                                if (pImage == null || pImage.isEmpty()) pImage = paRs.getString("gallery_img");
                                if (pImage == null || pImage.isEmpty()) pImage = paRs.getString("var_img");
                                if (pImage == null) pImage = "";
                                String pStatus = paRs.getString("status"); if (pStatus == null) pStatus = "pending";
                                String pSeller = paRs.getString("business_name"); if (pSeller == null) pSeller = "-";
                                String pCategory = paRs.getString("category_name"); if (pCategory == null) pCategory = "-";
                    %>
                        <tr>
                            <td class="text-muted"><%= paRow %></td>
                            <td>
                                <div class="d-flex align-items-center gap-2">
                                    <% if (!pImage.isEmpty()) { %>
                                        <img src="<%= pImage %>" style="width:40px;height:40px;object-fit:cover;border-radius:6px;border:1px solid #eee;">
                                    <% } else { %>
                                        <div style="width:40px;height:40px;background:#f0f0f0;border-radius:6px;display:flex;align-items:center;justify-content:center;">
                                            <i class="bi bi-image text-muted"></i>
                                        </div>
                                    <% } %>
                                    <strong style="font-size:13px;"><%= pName.length() > 40 ? pName.substring(0,40) + "…" : pName %></strong>
                                </div>
                            </td>
                            <td><small><%= pSeller %></small></td>
                            <td><small><%= pCategory %></small></td>
                            <td><small>₱<%= String.format("%.2f", pPrice) %></small></td>
                            <td><small><%= pStock %></small></td>
                         <%
    String pCreatedAt = paRs.getString("created_at");
    String pDate = (pCreatedAt != null && pCreatedAt.length() >= 10) ? pCreatedAt.substring(0,10) : "—";
%>
<td><small class="text-muted"><%= pDate %></small></td>
                            <td>
                                <% if ("pending".equals(pStatus)) { %>
                                    <span class="badge bg-warning text-dark" style="font-size:11px;">Pending</span>
                               <% } else if ("rejected".equals(pStatus)) { %>
    <span class="badge bg-danger" style="font-size:11px;">Rejected</span>
<% } else if ("active".equals(pStatus)) { %>
    <span class="badge bg-success" style="font-size:11px;">Approved</span>
<% } %>
                            </td>
                            <td class="d-flex gap-1 flex-wrap">
                                <% if ("pending".equals(pStatus)) { %>
                                    <button class="btn btn-success btn-sm"
                                            onclick="approveProduct(<%= productId %>, '<%= pName.replace("'","") %>')">
                                        <i class="bi bi-check-lg me-1"></i>Approve
                                    </button>
                                    <button class="btn btn-danger btn-sm"
                                            onclick="rejectProduct(<%= productId %>, '<%= pName.replace("'","") %>')">
                                        <i class="bi bi-x-lg me-1"></i>Reject
                                    </button>
                                <% } else { %>
                                    <span class="text-muted" style="font-size:12px;">No actions</span>
                                <% } %>
                            </td>
                        </tr>
              <%
                            }
                            paRs.close(); paPs.close(); paConn.close();
                            if (paRow == 0) {
                    %>
                        <tr><td colspan="9" class="text-center text-muted py-4">
                            <i class="bi bi-inbox" style="font-size:24px; display:block; margin-bottom:8px;"></i>
                            No pending product approvals.
                        </td></tr>
                    <%
                            }
                        } catch(Exception e) { e.printStackTrace(); %>
                        <tr><td colspan="9" class="text-center text-danger py-4">Error loading products.</td></tr>
                    <% } %>
                    </tbody>
                </table>
                
                <% if (totalPaPages > 1) { %>
<div class="d-flex justify-content-between align-items-center px-3 py-2 border-top">
    <small class="text-muted">Page <%= paPage %> of <%= totalPaPages %></small>
    <div class="d-flex gap-2">
        <% if (paPage > 1) { %>
        <a href="admin.jsp?tab=product_approvals&page=<%= paPage - 1 %>" class="btn btn-sm btn-outline-secondary">
            <i class="bi bi-chevron-left"></i> Previous
        </a>
        <% } %>
        <% if (paPage < totalPaPages) { %>
        <a href="admin.jsp?tab=product_approvals&page=<%= paPage + 1 %>" class="btn btn-sm btn-primary">
            Next <i class="bi bi-chevron-right"></i>
        </a>
        <% } %>
    </div>
</div>
<% } %>

            </div>
        </div>

    <%-- ==================== PAYOUT REQUESTS TAB ==================== --%>
    <% } else if ("payout_requests".equals(tab)) {
        // Fetch all payout requests with seller info
        java.util.List<java.util.Map<String,Object>> allPayouts = new java.util.ArrayList<>();
        try {
            java.sql.Connection payConn = com.shopeasy.DBConnection.getConnection();
            java.sql.PreparedStatement payPs = payConn.prepareStatement(
                "SELECT pr.payout_id, pr.seller_id, pr.method, pr.account_number, pr.amount, pr.status, pr.requested_at, " +
                "sel.business_name AS seller_name, u.email AS seller_email " +
                "FROM payout_requests pr " +
                "JOIN seller sel ON pr.seller_id = sel.seller_id " +
                "JOIN users u ON sel.user_id = u.user_id " +
                "ORDER BY pr.requested_at DESC");
            java.sql.ResultSet payRs = payPs.executeQuery();
            while (payRs.next()) {
                java.util.Map<String,Object> p = new java.util.HashMap<>();
                p.put("id", payRs.getInt("payout_id"));
                p.put("seller_id", payRs.getInt("seller_id"));
                p.put("method", payRs.getString("method"));
                p.put("account", payRs.getString("account_number"));
                p.put("amount", payRs.getDouble("amount"));
                p.put("status", payRs.getString("status"));
                p.put("requested_at", payRs.getTimestamp("requested_at"));
                p.put("seller_name", payRs.getString("seller_name"));
                p.put("seller_email", payRs.getString("seller_email"));
                p.put("business_name", payRs.getString("seller_name"));
                allPayouts.add(p);
            }
            payRs.close(); payPs.close(); payConn.close();
        } catch(Exception ex) { ex.printStackTrace(); }

        long pendingPayouts = allPayouts.stream().filter(p -> "Pending".equals(p.get("status"))).count();
    %>
        <div class="admin-card">
            <div class="admin-card-header d-flex justify-content-between align-items-center">
                <h6 class="mb-0"><i class="bi bi-cash-coin me-2 text-success"></i>Payout Requests
                    <% if (pendingPayouts > 0) { %>
                    <span class="badge bg-warning text-dark ms-2" style="font-size:11px;"><%= pendingPayouts %> Pending</span>
                    <% } %>
                </h6>
            </div>
            <% if (allPayouts.isEmpty()) { %>
            <div class="text-center py-5 text-muted">
                <i class="bi bi-inbox" style="font-size:36px; display:block; margin-bottom:12px; color:#cbd5e1;"></i>
                <p class="mb-1 fw-semibold">No payout requests yet.</p>
            </div>
            <% } else { %>
            <div class="table-responsive">
                <table class="table table-hover align-middle" style="font-size:13px;">
                    <thead class="table-light">
                        <tr>
                            <th>#</th>
                            <th>Seller</th>
                            <th>Method</th>
                            <th>Account</th>
                            <th>Amount</th>
                            <th>Requested</th>
                            <th>Status</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                    <% int payNum = 0; for (java.util.Map<String,Object> p : allPayouts) {
                        payNum++;
                        String pStatus = (String) p.get("status");
                        String pBadge = "Pending".equals(pStatus) ? "warning text-dark" : "Completed".equals(pStatus) ? "success" : "danger";
                        java.sql.Timestamp pTs = (java.sql.Timestamp) p.get("requested_at");
                        String pDate = pTs != null ? new java.text.SimpleDateFormat("MMM d, yyyy h:mm a").format(pTs) : "-";
                        String pMethod = (String) p.get("method");
                        String pMethodIcon = "GCash".equals(pMethod) ? "bi-phone-fill text-primary" : "Maya".equals(pMethod) ? "bi-credit-card-fill text-success" : "bi-bank2 text-secondary";
                    %>
                        <tr>
                            <td class="text-muted"><%= payNum %></td>
                            <td>
                                <p class="mb-0 fw-bold" style="font-size:13px;"><%= p.get("business_name") %></p>
                                <p class="mb-0 text-muted" style="font-size:11px;"><%= p.get("seller_email") %></p>
                            </td>
                            <td><i class="bi <%= pMethodIcon %> me-1"></i><%= pMethod %></td>
                            <td><code style="font-size:12px;"><%= p.get("account") %></code></td>
                            <td class="fw-bold text-success">₱<%= String.format("%.2f", p.get("amount")) %></td>
                            <td class="text-muted" style="font-size:11px;"><%= pDate %></td>
                            <td><span class="badge bg-<%= pBadge %> px-2 py-1"><%= pStatus %></span></td>
                            <td>
                                <% if ("Pending".equals(pStatus)) { %>
                                <div class="d-flex gap-1">
                                    <button class="btn btn-success btn-sm" onclick="approvePayout(<%= p.get("id") %>, '<%= p.get("business_name") %>', '₱<%= String.format("%.2f", p.get("amount")) %>')">
                                        <i class="bi bi-check-circle"></i> Approve
                                    </button>
                                    <button class="btn btn-outline-danger btn-sm" onclick="rejectPayout(<%= p.get("id") %>, '<%= p.get("business_name") %>')">
                                        <i class="bi bi-x-circle"></i> Reject
                                    </button>
                                </div>
                                <% } else { %>
                                <span class="text-muted" style="font-size:12px;">No actions</span>
                                <% } %>
                            </td>
                        </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
            <% } %>
        </div>

    <%-- ==================== PRODUCTS TAB ==================== --%>
        
    <%-- ==================== PRODUCTS TAB ==================== --%>
    <% } else if ("products".equals(tab)) {
        String searchProd = request.getParameter("search");
        if (searchProd == null) searchProd = "";
        String prodPageParam = request.getParameter("page");
        int prodPage = (prodPageParam != null) ? Integer.parseInt(prodPageParam) : 1;
        int prodLimit = 50;
        int prodOffset = (prodPage - 1) * prodLimit;
        int totalProdAll = 0;
        try {
            Connection cntProd = DBConnection.getConnection();
            String cntSql = "SELECT COUNT(*) FROM product p WHERE p.status = 'active'";
            if (!searchProd.isEmpty()) cntSql += " AND p.name LIKE '%" + searchProd.replace("'","") + "%'";
            PreparedStatement cntProdPs = cntProd.prepareStatement(cntSql);
            ResultSet cntProdRs = cntProdPs.executeQuery();
            if (cntProdRs.next()) totalProdAll = cntProdRs.getInt(1);
            cntProdRs.close(); cntProdPs.close(); cntProd.close();
        } catch(Exception e) {}
        int totalProdPages = (int) Math.ceil((double) totalProdAll / prodLimit);
    %>
        <div class="admin-card">
            <div class="admin-card-header">
                <h6><i class="bi bi-box-seam me-2 text-danger"></i>All Products</h6>
                <form method="get" action="admin.jsp" class="d-flex gap-2">
                    <input type="hidden" name="tab" value="products">
                    <input type="text" class="form-control form-control-sm" name="search"
                           placeholder="Search product..." value="<%= searchProd %>" style="width:200px;">
                    <button class="btn btn-primary btn-sm" type="submit"><i class="bi bi-search"></i></button>
                </form>
            </div>
            <div class="table-responsive">
                <table class="table">
                    <thead>
                        <tr>
                 <th>#</th>
<th>Product</th>
<th>Seller</th>
<th>Category</th>
<th>Price</th>
<th>Stock</th>
<th>Submitted</th>
<th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        try {
                            Connection conn = DBConnection.getConnection();
                            String sql = "SELECT p.product_id, p.name as product_name, p.price, p.original_price, p.stock, " +
                                    "p.image, p.thumbnail, p.status, p.created_at, " +
                                    "(SELECT pv.image FROM product_variation pv WHERE pv.product_id = p.product_id AND pv.image IS NOT NULL LIMIT 1) as var_img, " +
                                    "s.business_name, c.name as category_name " +
                                    "FROM product p " +
                                    "LEFT JOIN seller s ON p.seller_id = s.seller_id " +
                                    "LEFT JOIN category c ON p.category_id = c.category_id " +
                                    "WHERE p.status = 'active' ";
                       if (!searchProd.isEmpty()) {
                           sql += "AND (p.name LIKE ? OR s.business_name LIKE ?) ";
                       }
                       sql += "ORDER BY p.product_id DESC LIMIT " + prodLimit + " OFFSET " + prodOffset;
                            PreparedStatement ps = conn.prepareStatement(sql);
                            if (!searchProd.isEmpty()) {
                                String q = "%" + searchProd + "%";
                                ps.setString(1, q); ps.setString(2, q);
                            }
                            ResultSet rs = ps.executeQuery();
                            int rowNum = totalProdAll - prodOffset + 1;
                            while (rs.next()) {
                                rowNum--;
                                int pid = rs.getInt("product_id");
                                String pName = rs.getString("product_name"); if (pName == null) pName = "-";
                                double pBasePrice = rs.getDouble("price");
                                double pSalePrice = rs.getDouble("original_price");
                                boolean pHasSale = !rs.wasNull() && pSalePrice > 0;
                                double pPrice = pHasSale ? pSalePrice : pBasePrice;
                                int pStock = rs.getInt("stock");
                                String sellerName = rs.getString("business_name"); if (sellerName == null) sellerName = "-";
                                String pCat = rs.getString("category_name"); if (pCat == null) pCat = "-";
                                String pImg = rs.getString("thumbnail");
                                if (pImg == null || pImg.isEmpty()) pImg = rs.getString("image");
                                if (pImg == null || pImg.isEmpty()) pImg = rs.getString("var_img");
                                if (pImg == null) pImg = "";
                                String pDate = rs.getString("created_at");
                                if (pDate != null && pDate.length() >= 10) pDate = pDate.substring(0,10); else pDate = "—";
                    %>
                        <tr>
                          <td class="text-muted"><%= rowNum %></td>
<td>
    <div class="d-flex align-items-center gap-2">
        <% if (!pImg.isEmpty()) { %>
            <img src="<%= pImg %>" style="width:40px;height:40px;object-fit:cover;border-radius:6px;border:1px solid #eee;">
        <% } else { %>
            <div style="width:40px;height:40px;background:#f0f0f0;border-radius:6px;display:flex;align-items:center;justify-content:center;">
                <i class="bi bi-image text-muted"></i>
            </div>
        <% } %>
        <strong style="font-size:13px;"><%= pName.length() > 35 ? pName.substring(0,35)+"..." : pName %></strong>
    </div>
</td>
<td><small><%= sellerName %></small></td>
<td><small><%= pCat %></small></td>
<td><small>₱<%= String.format("%.2f", pPrice) %></small></td>
<td>
    <% if (pStock <= 0) { %>
                                    <span class="badge bg-danger" style="font-size:11px;">Out of Stock</span>
                                <% } else if (pStock <= 5) { %>
                                    <span class="badge bg-warning text-dark" style="font-size:11px;"><%= pStock %> left</span>
                                <% } else { %>
                                    <span class="text-success fw-semibold"><%= pStock %></span>
                                <% } %>
                            </td>
                      <td><small class="text-muted"><%= pDate %></small></td>
<td>
    <button class="btn btn-outline-danger btn-sm"
            onclick="removeProduct(<%= pid %>, '<%= pName.replace("'","").replace("\"","") %>')">
        <i class="bi bi-trash me-1"></i>Remove
    </button>
</td>
                        </tr>
                    <%      }
                            rs.close(); ps.close(); conn.close();
                            if (rowNum == 0) { %>
                        <tr><td colspan="6" class="text-center text-muted py-4">No products found.</td></tr>
                    <%      }
                        } catch(Exception e) { e.printStackTrace(); %>
                        <tr><td colspan="6" class="text-center text-danger py-4">Error loading products.</td></tr>
                    <% } %>
                 </tbody>
                </table>
                <% if (totalProdPages > 1) { %>
                <div class="d-flex justify-content-between align-items-center px-3 py-2 border-top">
                    <small class="text-muted">Page <%= prodPage %> of <%= totalProdPages %></small>
                    <div class="d-flex gap-2">
                        <% if (prodPage > 1) { %>
                        <a href="admin.jsp?tab=products&page=<%= prodPage - 1 %>" class="btn btn-sm btn-outline-secondary">
                            <i class="bi bi-chevron-left"></i> Previous
                        </a>
                        <% } %>
                        <% if (prodPage < totalProdPages) { %>
                        <a href="admin.jsp?tab=products&page=<%= prodPage + 1 %>" class="btn btn-sm btn-primary">
                            Next <i class="bi bi-chevron-right"></i>
                        </a>
                        <% } %>
                    </div>
                </div>
                <% } %>
            </div>
        </div>

    <%-- ==================== ORDERS TAB ==================== --%>
    <% } else if ("orders".equals(tab)) { %>
        <div class="admin-card">
          <div class="admin-card-header">
    <h6><i class="bi bi-bag-check me-2 text-warning"></i>All Orders</h6>
    <%
        String searchOrder = request.getParameter("search");
        if (searchOrder == null) searchOrder = "";
    %>
    <% if (!searchOrder.isEmpty()) { %>
    <span class="badge bg-primary" style="font-size:12px;">
        <i class="bi bi-search me-1"></i>Showing orders for: <%= searchOrder %>
        <a href="admin.jsp?tab=orders" class="text-white ms-2" style="text-decoration:none;">✕</a>
    </span>
    <% } %>
</div>
            <div class="table-responsive">
                <table class="table">
                    <thead>
                        <tr>
                   <th>#</th>
<th>Order ID</th>
<th>Customer</th>
<th>Total</th>
<th>Status</th>
<th>Date</th>
<th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        try {
                            Connection conn = DBConnection.getConnection();
                            String orderSql = "SELECT o.order_id, o.total_amount, o.status, o.order_date, " +
                            	    "c.name as customer_name " +
                            	    "FROM orders o " +
                            	    "LEFT JOIN customer c ON o.customer_id = c.customer_id ";
                            	if (!searchOrder.isEmpty()) {
                            	    orderSql += "WHERE c.name LIKE ? ";
                            	}
                            	orderSql += "ORDER BY o.order_id DESC LIMIT 100";
                            	PreparedStatement ps = conn.prepareStatement(orderSql);
                            	if (!searchOrder.isEmpty()) {
                            	    ps.setString(1, "%" + searchOrder + "%");
                            	}
                            ResultSet rs = ps.executeQuery();
                            int totalRowsO = 0;
                            while (rs.next()) totalRowsO++;
                            rs.close();

                            rs = ps.executeQuery();
                            int rowNum = totalRowsO + 1;
                            while (rs.next()) {
                                rowNum--;
                                int oid = rs.getInt("order_id");
                                String custName = rs.getString("customer_name"); if (custName == null) custName = "-";
                                double total = rs.getDouble("total_amount");
                                String status = rs.getString("status"); if (status == null) status = "-";
                                String createdAt = rs.getString("order_date"); if (createdAt == null) createdAt = "-";
                                if (createdAt.length() > 10) createdAt = createdAt.substring(0,10);
                                String statusColor = "secondary";
                                String statusLower = status.toLowerCase();
                                if ("completed".equals(statusLower) || "delivered".equals(statusLower)) statusColor = "success";
                                else if ("pending".equals(statusLower)) statusColor = "warning";
                                else if ("cancelled".equals(statusLower)) statusColor = "danger";
                                else if ("processing".equals(statusLower)) statusColor = "primary";
                                else if ("shipped".equals(statusLower)) statusColor = "info";
                                else if ("refunded".equals(statusLower)) statusColor = "purple";
                    %>
                      <tr>
    <td class="text-muted"><%= rowNum %></td>
    <td><strong>#<%= oid %></strong></td>
    <td><%= custName %></td>
    <td>₱<%= String.format("%.2f", total) %></td>
                          <td><span class="badge bg-<%= statusColor %>" style="font-size:11px;<%= "purple".equals(statusColor) ? "background:#7c3aed!important;" : "" %>"><%= status %></span></td>
                        <td><%= createdAt %></td>
            <td>
                <select class="form-select form-select-sm" style="width:130px;font-size:11px;"
                        onchange="updateOrderStatus(<%= oid %>, this.value)">
                    <option value="Pending" <%= "Pending".equals(status) ? "selected" : "" %>>Pending</option>
                    <option value="Processing" <%= "Processing".equals(status) ? "selected" : "" %>>Processing</option>
                    <option value="Shipped" <%= "Shipped".equals(status) ? "selected" : "" %>>Shipped</option>
                    <option value="Completed" <%= "Completed".equals(status) ? "selected" : "" %>>Completed</option>
                    <option value="Cancelled" <%= "Cancelled".equals(status) ? "selected" : "" %>>Cancelled</option>
                </select>
            </td>
        </tr>
                    <%      }
                            rs.close(); ps.close(); conn.close();
                            if (rowNum == 0) { %>
                        <tr><td colspan="6" class="text-center text-muted py-4">No orders found.</td></tr>
                    <%      }
                        } catch(Exception e) { e.printStackTrace(); %>
                        <tr><td colspan="6" class="text-center text-danger py-4">Error loading orders.</td></tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        </div>


<%-- ==================== REPORTS TAB ==================== --%>
    <% } else if ("reports".equals(tab)) {
        double repRevenue = 0;
        int repOrders = 0, repCompleted = 0, repCancelled = 0, repPending = 0;
        double[] repMonthly = new double[6];
        String[] repLabels = new String[6];
        try {
            Connection cRep = DBConnection.getConnection();
            PreparedStatement psRep;
            ResultSet rsRep;

            psRep = cRep.prepareStatement("SELECT COALESCE(SUM(total_amount),0) FROM orders WHERE status NOT IN ('Cancelled','cancelled')");
            rsRep = psRep.executeQuery(); if(rsRep.next()) repRevenue = rsRep.getDouble(1); rsRep.close(); psRep.close();

            psRep = cRep.prepareStatement("SELECT COUNT(*) FROM orders");
            rsRep = psRep.executeQuery(); if(rsRep.next()) repOrders = rsRep.getInt(1); rsRep.close(); psRep.close();

            psRep = cRep.prepareStatement("SELECT COUNT(*) FROM orders WHERE status='Completed'");
            rsRep = psRep.executeQuery(); if(rsRep.next()) repCompleted = rsRep.getInt(1); rsRep.close(); psRep.close();

            psRep = cRep.prepareStatement("SELECT COUNT(*) FROM orders WHERE status='Cancelled'");
            rsRep = psRep.executeQuery(); if(rsRep.next()) repCancelled = rsRep.getInt(1); rsRep.close(); psRep.close();

            psRep = cRep.prepareStatement("SELECT COUNT(*) FROM orders WHERE status='Pending'");
            rsRep = psRep.executeQuery(); if(rsRep.next()) repPending = rsRep.getInt(1); rsRep.close(); psRep.close();

            java.util.Calendar calRep = java.util.Calendar.getInstance();
            for (int m = 5; m >= 0; m--) {
                java.util.Calendar tmp = (java.util.Calendar) calRep.clone();
                tmp.add(java.util.Calendar.MONTH, -m);
                int yr = tmp.get(java.util.Calendar.YEAR);
                int mo = tmp.get(java.util.Calendar.MONTH) + 1;
                repLabels[5-m] = new java.text.SimpleDateFormat("MMM yyyy").format(tmp.getTime());
                psRep = cRep.prepareStatement(
                    "SELECT COALESCE(SUM(total_amount),0) FROM orders WHERE YEAR(order_date)=? AND MONTH(order_date)=? AND status NOT IN ('Cancelled','cancelled')");
                psRep.setInt(1, yr); psRep.setInt(2, mo);
                rsRep = psRep.executeQuery();
                if(rsRep.next()) repMonthly[5-m] = rsRep.getDouble(1);
                rsRep.close(); psRep.close();
            }
            cRep.close();
        } catch(Exception ex) {}
    %>
        <!-- Summary Cards -->
        <div class="row g-3 mb-4">
            <div class="col-6 col-md-3">
                <div class="stat-card">
                    <div class="stat-icon" style="background:#d1fae5;">
                        <i class="bi bi-currency-dollar" style="color:#10b981;"></i>
                    </div>
                    <div>
                        <p class="stat-num">₱<%= String.format("%,.0f", repRevenue) %></p>
                        <p class="stat-label">Total Revenue</p>
                    </div>
                </div>
            </div>
            <div class="col-6 col-md-3">
                <div class="stat-card">
                    <div class="stat-icon" style="background:#fef9c3;">
                        <i class="bi bi-bag-check" style="color:#f59e0b;"></i>
                    </div>
                    <div>
                        <p class="stat-num"><%= repOrders %></p>
                        <p class="stat-label">Total Orders</p>
                    </div>
                </div>
            </div>
            <div class="col-6 col-md-3">
                <div class="stat-card">
                    <div class="stat-icon" style="background:#dcfce7;">
                        <i class="bi bi-check-circle" style="color:#22c55e;"></i>
                    </div>
                    <div>
                        <p class="stat-num"><%= repCompleted %></p>
                        <p class="stat-label">Completed</p>
                    </div>
                </div>
            </div>
            <div class="col-6 col-md-3">
                <div class="stat-card">
                    <div class="stat-icon" style="background:#fee2e2;">
                        <i class="bi bi-x-circle" style="color:#ef4444;"></i>
                    </div>
                    <div>
                        <p class="stat-num"><%= repCancelled %></p>
                        <p class="stat-label">Cancelled</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Charts Row -->
        <div class="row g-3 mb-4">
            <div class="col-12 col-md-8">
                <div class="admin-card p-4">
                    <h6 class="fw-bold mb-3"><i class="bi bi-graph-up-arrow me-2 text-success"></i>Monthly Revenue (Last 6 Months)</h6>
                    <canvas id="repRevenueChart" height="120"></canvas>
                    <script>
                    window.repRevenueData = {
                        labels: ['<%= repLabels[0] %>','<%= repLabels[1] %>','<%= repLabels[2] %>','<%= repLabels[3] %>','<%= repLabels[4] %>','<%= repLabels[5] %>'],
                        data: [<%= repMonthly[0] %>,<%= repMonthly[1] %>,<%= repMonthly[2] %>,<%= repMonthly[3] %>,<%= repMonthly[4] %>,<%= repMonthly[5] %>]
                    };
                    </script>
                </div>
            </div>
            <div class="col-12 col-md-4">
                <div class="admin-card p-4 h-100">
                    <h6 class="fw-bold mb-3"><i class="bi bi-pie-chart me-2 text-primary"></i>Orders by Status</h6>
                    <canvas id="repStatusChart" height="200"></canvas>
                    <script>
                    window.repStatusData = {
                        labels: ['Completed','Pending','Cancelled'],
                        data: [<%= repCompleted %>,<%= repPending %>,<%= repCancelled %>]
                    };
                    </script>
                </div>
            </div>
        </div>

        <!-- Top Products -->
        <div class="admin-card mb-4">
            <div class="admin-card-header">
                <h6><i class="bi bi-trophy me-2 text-warning"></i>Top 5 Best Selling Products</h6>
            </div>
            <div class="table-responsive">
                <table class="table">
                    <thead>
                        <tr><th>#</th><th>Product</th><th>Seller</th><th>Units Sold</th><th>Revenue</th></tr>
                    </thead>
                    <tbody>
                    <%
                        try {
                            Connection cTop = DBConnection.getConnection();
                            PreparedStatement psTop = cTop.prepareStatement(
                                "SELECT p.name, s.business_name, " +
                                "COALESCE(SUM(oi.quantity),0) as units_sold, " +
                                "COALESCE(SUM(oi.quantity * oi.price),0) as revenue " +
                                "FROM product p " +
                                "LEFT JOIN order_items oi ON p.product_id = oi.product_id " +
                                "LEFT JOIN orders o ON oi.order_id = o.order_id AND o.status='Completed' " +
                                "LEFT JOIN seller s ON p.seller_id = s.seller_id " +
                                "GROUP BY p.product_id, p.name, s.business_name " +
                                "ORDER BY units_sold DESC LIMIT 5");
                            ResultSet rsTop = psTop.executeQuery();
                            int topNum = 0;
                            while(rsTop.next()) {
                                topNum++;
                    %>
                        <tr>
                            <td><span class="badge bg-warning text-dark">#<%= topNum %></span></td>
                            <td><strong><%= rsTop.getString("name") %></strong></td>
                            <td><%= rsTop.getString("business_name") != null ? rsTop.getString("business_name") : "—" %></td>
                            <td><%= rsTop.getInt("units_sold") %> units</td>
                            <td>₱<%= String.format("%,.2f", rsTop.getDouble("revenue")) %></td>
                        </tr>
                    <%  } if(topNum == 0) { %>
                        <tr><td colspan="5" class="text-center text-muted py-3">No sales data yet.</td></tr>
                    <%  } rsTop.close(); psTop.close(); cTop.close();
                        } catch(Exception ex) { %>
                        <tr><td colspan="5" class="text-center text-danger py-3">Error loading data.</td></tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        </div>
        
    <%-- ==================== REFUNDS TAB ==================== --%>
    <% } else if ("refunds".equals(tab)) { %>
        <div class="admin-card">
            <div class="admin-card-header">
                <h6><i class="bi bi-arrow-counterclockwise me-2 text-danger"></i>Refund Requests</h6>
            </div>
            <div class="table-responsive">
                <table class="table">
                    <thead>
                        <tr>
                           <th>#</th>
<th>Refund ID</th>
<th>Order ID</th>
<th>Customer</th>
<th>Reason</th>
<th>Status</th>
<th>Date</th>
<th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                    <%
                        try {
                            Connection conn = DBConnection.getConnection();
                            PreparedStatement ps = conn.prepareStatement(
                            		"SELECT r.refund_id, r.order_id, r.reason, r.description, r.status, r.requested_at, " +
                            				"c.name as customer_name " +
                            				"FROM refund_requests r " +
                            				"LEFT JOIN customer c ON r.customer_id = c.customer_id " +
                            				"ORDER BY r.refund_id DESC LIMIT 100");
                            ResultSet rs = ps.executeQuery();
                            int totalRowsR = 0;
                            while (rs.next()) totalRowsR++;
                            rs.close();

                            rs = ps.executeQuery();
                            int rowNum = totalRowsR + 1;
                            while (rs.next()) {
                                rowNum--;
                                int rid = rs.getInt("refund_id");
                                String custName = rs.getString("customer_name"); if (custName == null) custName = "-";
                                String reason = rs.getString("reason"); if (reason == null) reason = "-";
                                if (reason.length() > 30) reason = reason.substring(0,30) + "...";
                                String status = rs.getString("status"); if (status == null) status = "Pending";
                    %>
                        <tr>
                       <td class="text-muted"><%= rowNum %></td>
<td><strong>#<%= rid %></strong></td>
<td><strong>#<%= rs.getInt("order_id") %></strong></td>
<td><%= custName %></td>
<td><%= reason %></td>
                            <td>
                         <% if ("Pending".equalsIgnoreCase(status)) { %>
    <span class="badge bg-warning text-dark" style="font-size:11px;">Pending</span>
<% } else if ("Approved".equalsIgnoreCase(status)) { %>
    <span class="badge bg-success" style="font-size:11px;">Approved</span>
<% } else if ("Refunded".equalsIgnoreCase(status)) { %>
    <span class="badge bg-info" style="font-size:11px;">Refunded</span>
<% } else if ("Rejected".equalsIgnoreCase(status)) { %>
    <span class="badge bg-danger" style="font-size:11px;">Rejected</span>
<% } else if ("Appealed".equalsIgnoreCase(status)) { %>
    <span class="badge bg-purple text-white" style="font-size:11px; background:#6f42c1 !important;">⚠️ Appealed</span>
<% } else { %>
    <span class="badge bg-secondary" style="font-size:11px;"><%= status %></span>
<% } %>
                           </td>
                            <td style="font-size:11px;color:#64748b;"><%= rs.getString("requested_at") != null ? rs.getString("requested_at").toString().substring(0,10) : "—" %></td>
                            <td class="d-flex gap-1">
                          <% if ("Pending".equalsIgnoreCase(status)) { %>
<button class="btn btn-success btn-sm" onclick="approveRefund(<%= rid %>)">
    <i class="bi bi-check-lg"></i>
</button>
<button class="btn btn-danger btn-sm" onclick="rejectRefund(<%= rid %>)">
    <i class="bi bi-x-lg"></i>
</button>
<% } else if ("Appealed".equalsIgnoreCase(status)) { %>
<button class="btn btn-success btn-sm" onclick="adminApproveRefund(<%= rid %>)"
    title="Approve Appeal">
    <i class="bi bi-check-lg"></i> Approve
</button>
<button class="btn btn-danger btn-sm" onclick="adminRejectRefund(<%= rid %>)"
    title="Reject Appeal">
    <i class="bi bi-x-lg"></i> Reject
</button>
<% } %>
                            </td>
                        </tr>
                    <%      }
                            rs.close(); ps.close(); conn.close();
                            if (rowNum == 0) { %>
                        <tr><td colspan="6" class="text-center text-muted py-4">No refund requests found.</td></tr>
                    <%      }
                        } catch(Exception e) { %>
                        <tr><td colspan="6" class="text-center text-muted py-4">No refund data available.</td></tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
        </div>
    <% } else if ("reviews".equals(tab)) {
    java.sql.Connection revConn = com.shopeasy.DBConnection.getConnection();
    java.sql.PreparedStatement revPs = revConn.prepareStatement(
        "SELECT r.review_id, r.rating, r.comment, r.photo, r.created_at, " +
        "p.name AS product_name, " +
        "COALESCE(p.image, p.thumbnail, " +
        "(SELECT pg.image FROM product_gallery pg WHERE pg.product_id = p.product_id ORDER BY pg.sort_order LIMIT 1), " +
        "(SELECT pv.image FROM product_variation pv WHERE pv.product_id = p.product_id AND pv.image IS NOT NULL LIMIT 1)) AS product_image, " +
        "CONCAT(c.first_name, ' ', c.last_name) AS customer_name, c.customer_id, " +
        "u.user_id " +
        "FROM review r " +
        "JOIN product p ON r.product_id = p.product_id " +
        "JOIN customer c ON r.customer_id = c.customer_id " +
        "JOIN users u ON c.user_id = u.user_id " +
        "ORDER BY r.created_at DESC");
    java.sql.ResultSet revRs = revPs.executeQuery();
%>
<div class="card-box">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h6 class="fw-bold mb-0"><i class="bi bi-star-fill text-warning me-2"></i>Customer Reviews</h6>
    </div>
    <div class="table-responsive">
        <table class="table">
            <thead>
                <tr>
                    <th>Customer</th>
                    <th>Product</th>
                    <th>Rating</th>
                    <th>Review</th>
                    <th>Photo</th>
                    <th>Date</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
            <% 
            java.text.SimpleDateFormat revSdf = new java.text.SimpleDateFormat("MMM d, yyyy");
            boolean hasRevs = false;
            while (revRs.next()) { hasRevs = true; %>
                <tr>
                    <td><span class="fw-semibold"><%= revRs.getString("customer_name") %></span></td>
                    <td>
                        <div class="d-flex align-items-center gap-2">
                            <% String revProdImg = revRs.getString("product_image");
                               if (revProdImg != null && !revProdImg.isEmpty()) { %>
                                <img src="<%= revProdImg %>" style="width:36px; height:36px; object-fit:cover; border-radius:6px;">
                            <% } %>
                            <span style="font-size:12px;"><%= revRs.getString("product_name") %></span>
                        </div>
                    </td>
                    <td>
                        <% for (int s = 1; s <= 5; s++) { %>
                            <i class="bi bi-star-fill" style="color:<%= s <= revRs.getInt("rating") ? "#ffc107" : "#ddd" %>; font-size:12px;"></i>
                        <% } %>
                    </td>
                    <td style="max-width:200px; font-size:12px;"><%= revRs.getString("comment") != null ? revRs.getString("comment") : "<span class='text-muted'>No comment</span>" %></td>
                    <td>
                        <% String revPhoto = revRs.getString("photo");
                           if (revPhoto != null && !revPhoto.isEmpty()) { %>
                            <img src="<%= revPhoto %>" style="width:40px; height:40px; object-fit:cover; border-radius:6px; cursor:pointer;"
                                 onclick="window.open('<%= revPhoto %>', '_blank')">
                        <% } else { %>
                            <span class="text-muted" style="font-size:12px;">None</span>
                        <% } %>
                    </td>
                    <td style="font-size:12px;"><%= revSdf.format(revRs.getTimestamp("created_at")) %></td>
                    <td>
                        <button class="btn btn-danger btn-sm"
                            onclick="deleteReview(<%= revRs.getInt("review_id") %>, <%= revRs.getInt("user_id") %>, '<%= revRs.getString("product_name").replace("'", "\\'") %>')">
                            <i class="bi bi-trash"></i> Delete
                        </button>
                    </td>
                </tr>
            <% } %>
            <% if (!hasRevs) { %>
                <tr><td colspan="7" class="text-center text-muted py-4">No reviews yet.</td></tr>
            <% } %>
            </tbody>
        </table>
    </div>
</div>
<% revRs.close(); revPs.close(); revConn.close();
} else if ("vouchers".equals(tab)) { %>
<div class="card border-0 shadow-sm" style="border-radius:16px; overflow: visible;">
    <div class="card-body p-4" style="overflow: visible;">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h5 class="fw-bold mb-0"><i class="bi bi-ticket-perforated text-primary me-2"></i>Platform Vouchers</h5>
            <button class="btn btn-primary btn-sm" onclick="showCreateVoucher()">
                <i class="bi bi-plus-lg me-1"></i> Create Voucher
            </button>
        </div>
        <%-- Voucher List --%>
        <%
        java.sql.Connection vcConn = DBConnection.getConnection();
        java.sql.PreparedStatement vcPs = vcConn.prepareStatement(
            "SELECT * FROM vouchers ORDER BY created_at DESC");
        java.sql.ResultSet vcRs = vcPs.executeQuery();
        %>
   <div class="table-responsive" style="overflow: visible;">
        <table class="table table-hover align-middle">
            <thead style="background:#f8fafc;">
                <tr>
                    <th>Code</th>
                    <th>Type</th>
                    <th>Value</th>
                    <th>Min Order</th>
                    <th>Uses</th>
                    <th>Expiry</th>
                    <th>Status</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
            <% boolean vcEmpty = true; while (vcRs.next()) { vcEmpty = false; %>
            <tr>
                <td><strong><%= vcRs.getString("code") %></strong></td>
           <%
    String vcType2 = vcRs.getString("type");
    String vcBadgeClass = "fixed".equals(vcType2) ? "bg-info" : "freeshipping".equals(vcType2) ? "bg-success" : "bg-warning text-dark";
    String vcTypeLabel = "fixed".equals(vcType2) ? "Fixed ₱" : "freeshipping".equals(vcType2) ? "Free Ship 🚚" : "Percent %";
    String vcValueDisplay = "freeshipping".equals(vcType2) ? "—" : "fixed".equals(vcType2) ? "₱" + vcRs.getString("value") : vcRs.getString("value") + "%";
%>
<td><span class="badge <%= vcBadgeClass %>"><%= vcTypeLabel %></span></td>
<td><%= vcValueDisplay %></td>
                <td>₱<%= vcRs.getString("min_order") %></td>
                <td><%= vcRs.getInt("used_count") %><%= vcRs.getString("max_uses") != null ? "/" + vcRs.getString("max_uses") : "/∞" %></td>
                <td><%= vcRs.getString("expiry_date") != null ? vcRs.getString("expiry_date") : "No expiry" %></td>
                <td><span class="badge <%= vcRs.getInt("is_active") == 1 ? "bg-success" : "bg-secondary" %>">
                    <%= vcRs.getInt("is_active") == 1 ? "Active" : "Inactive" %>
                </span></td>
              <td>
    <div class="dropdown">
        <button class="btn btn-sm btn-outline-secondary dropdown-toggle" data-bs-toggle="dropdown">
            Actions
        </button>
        <ul class="dropdown-menu">
            <li><a class="dropdown-item" href="#" onclick="editVoucher(<%= vcRs.getInt("voucher_id") %>, '<%= vcRs.getString("code") %>', '<%= vcRs.getString("type") %>', '<%= vcRs.getString("value") %>', '<%= vcRs.getString("min_order") %>', '<%= vcRs.getString("max_uses") != null ? vcRs.getString("max_uses") : "" %>')"><i class="bi bi-pencil me-2"></i>Edit</a></li>
            <% if (vcRs.getInt("is_active") == 1) { %>
            <li><a class="dropdown-item text-warning" href="#" onclick="deactivateVoucher(<%= vcRs.getInt("voucher_id") %>)"><i class="bi bi-x-circle me-2"></i>Deactivate</a></li>
            <% } else { %>
            <li><a class="dropdown-item text-success" href="#" onclick="activateVoucher(<%= vcRs.getInt("voucher_id") %>)"><i class="bi bi-check-circle me-2"></i>Activate</a></li>
            <% } %>
            <li><hr class="dropdown-divider"></li>
            <li><a class="dropdown-item text-danger" href="#" onclick="deleteVoucher(<%= vcRs.getInt("voucher_id") %>)"><i class="bi bi-trash me-2"></i>Delete</a></li>
        </ul>
    </div>
</td>
            </tr>
            <% } %>
            <% if (vcEmpty) { %>
            <tr><td colspan="8" class="text-center text-muted py-4">No vouchers yet.</td></tr>
            <% } %>
            </tbody>
        </table>
        </div>
        <% vcRs.close(); vcPs.close(); vcConn.close(); %>
    </div>
</div>

<%-- CREATE VOUCHER MODAL --%>
<div class="modal fade" id="createVoucherModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-header border-0">
                <h5 class="modal-title fw-bold"><i class="bi bi-ticket-perforated text-primary me-2"></i>Create Voucher</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body px-4">
                <div class="row g-3">
                    <div class="col-12">
                        <label class="form-label fw-bold">Voucher Code</label>
                        <div class="input-group">
                            <input type="text" id="vcCode" class="form-control text-uppercase" placeholder="e.g. SALE50">
                            <button class="btn btn-outline-secondary" onclick="generateCode()"><i class="bi bi-shuffle"></i></button>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold">Type</label>
                <select id="vcType" class="form-select" onchange="updateValueLabel()">
                            <option value="fixed">Fixed Amount (₱)</option>
                            <option value="percent">Percentage (%)</option>
                            <option value="freeshipping">Free Shipping</option>
                        </select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold" id="vcValueLabel">Discount Amount (₱)</label>
                        <input type="number" id="vcValue" class="form-control" placeholder="e.g. 50" min="1">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold">Min Order Amount (₱)</label>
                        <input type="number" id="vcMinOrder" class="form-control" placeholder="0 = no minimum" min="0" value="0">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold">Max Uses <small class="text-muted">(optional)</small></label>
                        <input type="number" id="vcMaxUses" class="form-control" placeholder="Leave blank = unlimited" min="1">
                    </div>
              <div class="col-md-6">
    <label class="form-label fw-bold">Expires In <small class="text-muted">(optional)</small></label>
    <input type="number" id="vcDurationValue" class="form-control" placeholder="e.g. 24" min="1">
</div>
<div class="col-md-6">
    <label class="form-label fw-bold">Duration Unit</label>
    <select id="vcDurationUnit" class="form-select">
        <option value="">No expiry</option>
        <option value="hours">Hours</option>
        <option value="days">Days</option>
        <option value="weeks">Weeks</option>
    </select>
</div>
                </div>
            </div>
            <div class="modal-footer border-0">
                <button class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
                <button class="btn btn-primary px-4" onclick="submitCreateVoucher()">
                    <i class="bi bi-plus-lg me-1"></i> Create
                </button>
            </div>
        </div>
    </div>
</div>

<script>
function showCreateVoucher() {
    new bootstrap.Modal(document.getElementById('createVoucherModal')).show();
}
function generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = '';
    for (let i = 0; i < 8; i++) code += chars[Math.floor(Math.random() * chars.length)];
    document.getElementById('vcCode').value = code;
}
function updateValueLabel() {
    const type = document.getElementById('vcType').value;
    const valueWrap = document.getElementById('vcValueWrap');
    if (type === 'freeshipping') {
        document.getElementById('vcValueLabel').textContent = 'Free Shipping';
        document.getElementById('vcValue').value = '0';
        document.getElementById('vcValue').disabled = true;
    } else {
        document.getElementById('vcValue').disabled = false;
        document.getElementById('vcValueLabel').textContent = type === 'fixed' ? 'Discount Amount (₱)' : 'Discount Percent (%)';
    }
}
function submitCreateVoucher() {
    const code = document.getElementById('vcCode').value.trim().toUpperCase();
    const type = document.getElementById('vcType').value;
    const value = document.getElementById('vcValue').value;
    const minOrder = document.getElementById('vcMinOrder').value || '0';
    const maxUses = document.getElementById('vcMaxUses').value || '';
    const durationVal = document.getElementById('vcDurationValue').value || '';
    const durationUnit = document.getElementById('vcDurationUnit').value || '';

    if (!code) { alert('Please fill in voucher code!'); return; }
    if (type !== 'freeshipping' && !value) { alert('Please fill in discount value!'); return; }
    const finalValue = type === 'freeshipping' ? 0 : value;
    if (type === 'percent' && (value < 1 || value > 100)) { alert('Percentage must be 1-100!'); return; }

    fetch('AdminServlet?action=createVoucher', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'code=' + encodeURIComponent(code) + '&type=' + type + '&value=' + finalValue +
              '&minOrder=' + minOrder + '&maxUses=' + encodeURIComponent(maxUses) +
              '&durationValue=' + encodeURIComponent(durationVal) + '&durationUnit=' + encodeURIComponent(durationUnit)
    })
    .then(r => r.json())
    .then(d => {
        if (d.success) { showToast(d.message, 'success'); bootstrap.Modal.getInstance(document.getElementById('createVoucherModal')).hide(); setTimeout(() => location.reload(), 1200); }
        else showToast(d.message, 'danger');
    });
}
function deactivateVoucher(id) {
    fetch('AdminServlet?action=deactivateVoucher&voucherId=' + id, {method:'POST'})
    .then(r => r.json()).then(d => { showToast(d.message, d.success ? 'success' : 'danger'); if(d.success) setTimeout(() => location.reload(), 1200); });
}
function activateVoucher(id) {
    fetch('AdminServlet?action=activateVoucher&voucherId=' + id, {method:'POST'})
    .then(r => r.json()).then(d => { showToast(d.message, d.success ? 'success' : 'danger'); if(d.success) setTimeout(() => location.reload(), 1200); });
}
function deleteVoucher(id) {
    if (!confirm('Delete this voucher permanently?')) return;
    fetch('AdminServlet?action=deleteVoucher&voucherId=' + id, {method:'POST'})
    .then(r => r.json()).then(d => { showToast(d.message, d.success ? 'success' : 'danger'); if(d.success) setTimeout(() => location.reload(), 1200); });
}
function editVoucher(id, code, type, value, minOrder, maxUses) {
    document.getElementById('vcCode').value = code;
    document.getElementById('vcType').value = type;
    updateValueLabel();
    document.getElementById('vcValue').value = value;
    document.getElementById('vcMinOrder').value = minOrder;
    document.getElementById('vcMaxUses').value = maxUses;
    document.getElementById('vcDurationValue').value = '';
    document.getElementById('vcDurationUnit').value = '';
    const btn = document.querySelector('#createVoucherModal .btn-primary');
    btn.innerHTML = '<i class="bi bi-check-lg me-1"></i> Update';
    btn.onclick = function() { updateVoucher(id); };
    new bootstrap.Modal(document.getElementById('createVoucherModal')).show();
}
function updateVoucher(id) {
    const code = document.getElementById('vcCode').value.trim().toUpperCase();
    const type = document.getElementById('vcType').value;
    const value = document.getElementById('vcValue').value;
    const minOrder = document.getElementById('vcMinOrder').value || '0';
    const maxUses = document.getElementById('vcMaxUses').value || '';
    const durationVal = document.getElementById('vcDurationValue').value || '';
    const durationUnit = document.getElementById('vcDurationUnit').value || '';
    const finalValue = type === 'freeshipping' ? 0 : value;

    fetch('AdminServlet?action=editVoucher', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'voucherId=' + id + '&code=' + encodeURIComponent(code) + '&type=' + type + '&value=' + finalValue +
              '&minOrder=' + minOrder + '&maxUses=' + encodeURIComponent(maxUses) +
              '&durationValue=' + encodeURIComponent(durationVal) + '&durationUnit=' + encodeURIComponent(durationUnit)
    })
    .then(r => r.json())
    .then(d => {
        if (d.success) { showToast(d.message, 'success'); bootstrap.Modal.getInstance(document.getElementById('createVoucherModal')).hide(); setTimeout(() => location.reload(), 1200); }
        else showToast(d.message, 'danger');
    });
}
</script>
<% } %>

    </div><!-- end content-area -->
</div><!-- end main-content -->
<!-- CONFIRM MODAL -->
<!-- APPROVE PAYOUT MODAL -->
<div class="modal fade" id="approvePayoutModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-body p-4">
                <div class="text-center mb-3">
                    <div style="width:60px;height:60px;border-radius:50%;background:#22c55e;display:flex;align-items:center;justify-content:center;margin:0 auto 12px;">
                        <i class="bi bi-check-circle-fill" style="color:white;font-size:24px;"></i>
                    </div>
                    <h5 class="fw-bold mb-1">Approve Payout?</h5>
                    <p class="text-muted mb-0" style="font-size:13px;" id="approvePayoutInfo"></p>
                </div>
                <div class="d-flex gap-2 mt-3">
                    <button class="btn btn-outline-secondary w-100" data-bs-dismiss="modal">Cancel</button>
                    <button class="btn btn-success w-100 fw-bold" onclick="confirmApprovePayout()">
                        <i class="bi bi-check-circle me-1"></i> Approve
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- REJECT PAYOUT MODAL -->
<div class="modal fade" id="rejectPayoutModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-body p-4">
                <div class="text-center mb-3">
                    <div style="width:60px;height:60px;border-radius:50%;background:#ef4444;display:flex;align-items:center;justify-content:center;margin:0 auto 12px;">
                        <i class="bi bi-x-circle-fill" style="color:white;font-size:24px;"></i>
                    </div>
                    <h5 class="fw-bold mb-1">Reject Payout?</h5>
                    <p class="text-muted mb-0" style="font-size:13px;" id="rejectPayoutInfo"></p>
                </div>
                <div class="mb-3 mt-2">
                    <label class="form-label fw-bold" style="font-size:13px;">Reason for rejection</label>
                    <select class="form-select mb-2" id="rejectPayoutReasonSelect" style="font-size:13px;">
                        <option value="">-- Select a reason --</option>
                        <option value="Invalid account number">Invalid account number</option>
                        <option value="Insufficient verification">Insufficient verification</option>
                        <option value="Suspicious activity detected">Suspicious activity detected</option>
                        <option value="Account under review">Account under review</option>
                        <option value="Others">Others</option>
                    </select>
                    <textarea id="rejectPayoutReasonOther" class="form-control" rows="2" placeholder="Specify reason..." style="font-size:13px; display:none;"></textarea>
                    <div id="rejectPayoutReasonError" class="text-danger mt-1" style="font-size:12px; display:none;">Please select a reason.</div>
                </div>
                <div class="d-flex gap-2">
                    <button class="btn btn-outline-secondary w-100" data-bs-dismiss="modal">Cancel</button>
                    <button class="btn btn-danger w-100 fw-bold" onclick="confirmRejectPayout()">
                        <i class="bi bi-x-circle me-1"></i> Reject
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- REJECT PRODUCT MODAL -->
<div class="modal fade" id="rejectProductModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-body p-4">
                <div class="text-center mb-3">
                    <div style="width:60px;height:60px;border-radius:50%;background:#ef4444;display:flex;align-items:center;justify-content:center;margin:0 auto 12px;">
                        <i class="bi bi-x-circle-fill" style="color:white;font-size:24px;"></i>
                    </div>
                    <h5 class="fw-bold mb-1">Reject Product?</h5>
                    <p class="text-muted mb-0" style="font-size:13px;" id="rejectProductName"></p>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-bold" style="font-size:13px;">Reason for rejection</label>
                    <select class="form-select mb-2" id="rejectReasonSelect" style="font-size:13px;">
                        <option value="">-- Select a reason --</option>
                        <option value="Prohibited or illegal item">Prohibited or illegal item</option>
                        <option value="Misleading product information">Misleading product information</option>
                        <option value="Inappropriate content or images">Inappropriate content or images</option>
                        <option value="Incomplete product details">Incomplete product details</option>
                        <option value="Counterfeit or fake product">Counterfeit or fake product</option>
                        <option value="Wrong category">Wrong category</option>
                        <option value="Others">Others</option>
                    </select>
                    <textarea id="rejectReasonOther" class="form-control" rows="2" placeholder="Specify reason..." style="font-size:13px; display:none;"></textarea>
                    <div id="rejectReasonError" class="text-danger mt-1" style="font-size:12px; display:none;">Please select a reason.</div>
                </div>
                <div class="d-flex gap-2">
                    <button class="btn btn-outline-secondary w-100" data-bs-dismiss="modal">Cancel</button>
                    <button class="btn btn-danger w-100 fw-bold" onclick="confirmRejectProduct()">
                        <i class="bi bi-x-circle me-1"></i> Reject
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- REMOVE PRODUCT MODAL -->
<div class="modal fade" id="removeProductModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-body p-4">
                <div class="text-center mb-3">
                    <div style="width:60px;height:60px;border-radius:50%;background:#ef4444;display:flex;align-items:center;justify-content:center;margin:0 auto 12px;">
                        <i class="bi bi-trash-fill" style="color:white;font-size:24px;"></i>
                    </div>
                    <h5 class="fw-bold mb-1">Remove Product?</h5>
                    <p class="text-muted mb-0" style="font-size:13px;" id="removeProductName"></p>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-bold" style="font-size:13px;">Reason for removal</label>
                    <select class="form-select mb-2" id="removeReasonSelect" style="font-size:13px;">
                        <option value="">-- Select a reason --</option>
                        <option value="Violates platform policies">Violates platform policies</option>
                        <option value="Prohibited or illegal item">Prohibited or illegal item</option>
                        <option value="Duplicate listing">Duplicate listing</option>
                        <option value="Misleading product information">Misleading product information</option>
                        <option value="Inappropriate content or images">Inappropriate content or images</option>
                        <option value="Counterfeit or fake product">Counterfeit or fake product</option>
                        <option value="Others">Others</option>
                    </select>
                    <textarea id="removeReasonOther" class="form-control" rows="2" placeholder="Specify reason..." style="font-size:13px; display:none;"></textarea>
                    <div id="removeReasonError" class="text-danger mt-1" style="font-size:12px; display:none;">Please select a reason.</div>
                </div>
                <div class="d-flex gap-2">
                    <button class="btn btn-outline-secondary w-100" data-bs-dismiss="modal">Cancel</button>
                    <button class="btn btn-danger w-100 fw-bold" onclick="confirmRemoveProduct()">
                        <i class="bi bi-trash me-1"></i> Remove
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" id="confirmModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-body text-center p-5">
                <div id="confirmIcon" style="width:64px;height:64px;border-radius:50%;display:flex;align-items:center;justify-content:center;margin:0 auto 16px;font-size:28px;"></div>
                <h5 class="fw-bold mb-2" id="confirmTitle">Confirm Action</h5>
                <p class="text-muted mb-4" id="confirmMessage" style="font-size:14px;"></p>
                <div class="d-flex gap-2 justify-content-center">
                    <button class="btn btn-outline-secondary px-4" data-bs-dismiss="modal">Cancel</button>
                    <button class="btn px-4" id="confirmBtn" onclick="executeConfirm()">Confirm</button>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Ban Reason Modal -->
<div class="modal fade" id="banReasonModal" tabindex="-1">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header bg-danger text-white">
    <h5 class="modal-title" id="banModalTitle"><i class="bi bi-slash-circle me-2"></i>Ban User</h5>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <p>Ban <strong id="banUserName"></strong>?</p>
        <input type="hidden" id="banUserId">
        <label class="form-label fw-bold">Select Reason:</label>
<select class="form-select" id="banReasonSelect" onchange="toggleCustomReason(this.value)">
          <option value="">-- Select a reason --</option>
          <option value="Violation of platform policies.">Violation of platform policies</option>
          <option value="Fraudulent activity detected.">Fraudulent activity</option>
          <option value="Harassment or abusive behavior.">Harassment or abusive behavior</option>
          <option value="Selling prohibited items.">Selling prohibited items</option>
          <option value="Multiple policy violations.">Multiple policy violations</option>
          <option value="Spam or fake account.">Spam or fake account</option>
          <option value="other">Other (specify...)</option>
        </select>
        <input type="text" class="form-control mt-2" id="banReasonCustom" placeholder="Type custom reason..." style="display:none;">
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
        <button class="btn btn-danger" onclick="confirmBan()"><i class="bi bi-slash-circle me-1"></i>Ban User</button>
      </div>
    </div>
  </div>
</div>
<!-- LOGOUT OVERLAY -->
<div id="logoutOverlay" style="display:none;position:fixed;inset:0;background:rgba(255,255,255,0.95);z-index:9999;flex-direction:column;align-items:center;justify-content:center;gap:16px;">
    <div style="width:56px;height:56px;border:5px solid #e9ecef;border-top-color:#dc3545;border-radius:50%;animation:spin 0.8s linear infinite;"></div>
    <p style="font-size:16px;font-weight:600;color:#dc3545;margin:0;">Logging out...</p>
</div>
<style>@keyframes spin { to { transform: rotate(360deg); } }</style>

<!-- TOAST -->
<div id="adminToast" style="position:fixed;bottom:24px;right:24px;z-index:9999;display:none;">
    <div id="adminToastInner" style="padding:12px 20px;border-radius:10px;color:white;font-size:13px;font-weight:600;box-shadow:0 4px 16px rgba(0,0,0,0.15);"></div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
    let confirmAction = null;

    function showToast(msg, type) {
        const t = document.getElementById('adminToast');
        const inner = document.getElementById('adminToastInner');
        inner.style.background = type === 'success' ? '#22c55e' : type === 'danger' ? '#ef4444' : '#3b82f6';
        inner.textContent = msg;
        t.style.display = 'block';
        setTimeout(() => t.style.display = 'none', 3000);
    }

    function showConfirm(icon, iconBg, title, msg, btnClass, action) {
        document.getElementById('confirmIcon').innerHTML = icon;
        document.getElementById('confirmIcon').style.background = iconBg;
        document.getElementById('confirmTitle').textContent = title;
        document.getElementById('confirmMessage').innerHTML = msg;
        document.getElementById('confirmBtn').className = 'btn px-4 ' + btnClass;
        confirmAction = action;
        new bootstrap.Modal(document.getElementById('confirmModal')).show();
    }

    function executeConfirm() {
        bootstrap.Modal.getInstance(document.getElementById('confirmModal')).hide();
        if (confirmAction) confirmAction();
    }
    function selectOffenseReason(el) {
        document.querySelectorAll('[onclick="selectOffenseReason(this)"]').forEach(e => {
            e.style.background = '#f9fafb';
            e.style.borderColor = '#d1d5db';
            e.style.color = '';
            e.style.fontWeight = '';
        });
        el.style.background = '#0d6efd';
        el.style.borderColor = '#0d6efd';
        el.style.color = 'white';
        el.style.fontWeight = '600';
        document.getElementById('offenseReason').value = el.innerText;
    }
    
    function sendOffense(userId, name, offense) {
        // 3rd offense — use ban modal directly
        if (offense === 3) {
            document.getElementById('banUserId').value = userId;
            document.getElementById('banUserName').textContent = name;
            document.getElementById('banReasonSelect').value = '';
            document.getElementById('banModalTitle').textContent = '3rd Offense — User will be banned';
            if (document.getElementById('banReasonCustom')) document.getElementById('banReasonCustom').style.display = 'none';
            // Override confirmBan to send offense 3 + ban
            window._pendingOffense3 = {userId, name};
            new bootstrap.Modal(document.getElementById('banReasonModal')).show();
            return;
        }
        const labels = {1: '1st Offense', 2: '2nd Offense'};
        const colors = {1: '#f59e0b', 2: '#f97316'};
        const label = labels[offense];
        const color = colors[offense];
        const extra = '';

        // Show reason input modal
const reasons = ['Spam review','Fake review','Offensive language','Harassment','Duplicate review','Misleading information','Inappropriate content','Suspicious activity'];
        let reasonChips = '';
        for (let i = 0; i < reasons.length; i++) {
            reasonChips += '<span onclick="selectOffenseReason(this)" style="cursor:pointer; padding:4px 10px; border-radius:20px; font-size:11px; border:1px solid #d1d5db; background:#f9fafb; transition:0.2s;">' + reasons[i] + '</span>';
        }
        const reasonHtml = '<div style="text-align:left; margin-top:12px;">'
            + '<label style="font-size:13px; font-weight:600; margin-bottom:6px; display:block;">Reason for ' + label + ':</label>'
            + '<div style="display:flex; flex-wrap:wrap; gap:6px; margin-bottom:10px;">' + reasonChips + '</div>'
            + '<textarea id="offenseReason" class="form-control" rows="2" placeholder="Select a reason above or type custom reason..." style="font-size:13px;"></textarea>'
            + extra
            + '</div>';
        showConfirm(
            `<i class="bi bi-exclamation-triangle" style="color:white;font-size:24px;"></i>`,
            color,
            `Send ${label} to ${name}?`,
            reasonHtml,
            offense >= 3 ? 'btn-danger' : 'btn-warning',
            function() {
                const reason = document.getElementById('offenseReason').value.trim();
                if (!reason) { showToast('Please enter a reason!', 'danger'); return; }
                fetch('AdminServlet?action=sendOffense&userId=' + userId + '&offense=' + offense + '&reason=' + encodeURIComponent(reason), {method:'POST'})
                    .then(r => r.json())
                    .then(d => { showToast(d.message || 'Offense sent.', d.success ? 'success' : 'danger'); if(d.success) setTimeout(()=>location.reload(),1500); })
                    .catch(() => showToast('Offense sent.', 'success'));
            }
        );
    }
    function revertOffense(userId, name) {
        showConfirm(
            `<i class="bi bi-arrow-counterclockwise" style="color:white;font-size:24px;"></i>`,
            '#6b7280',
            `Revert last offense of ${name}?`,
            '<p style="font-size:13px; margin-top:8px;">This will remove the most recent offense record.</p>',
            'btn-secondary',
            function() {
                fetch('AdminServlet?action=revertOffense&userId=' + userId, {method:'POST'})
                    .then(r => r.json())
                    .then(d => { showToast(d.message || 'Offense reverted.', d.success ? 'success' : 'danger'); if(d.success) setTimeout(()=>location.reload(),1500); })
                    .catch(() => showToast('Offense reverted.', 'success'));
            }
        );
    }
    
    function banUser(userId, name) {
        document.getElementById('banUserId').value = userId;
        document.getElementById('banUserName').textContent = name;
        document.getElementById('banReasonSelect').value = '';
        new bootstrap.Modal(document.getElementById('banReasonModal')).show();
    }

    function confirmBan() {
        const userId = document.getElementById('banUserId').value;
        let reason = document.getElementById('banReasonSelect').value;
        if (!reason) { alert('Please select a reason.'); return; }
        if (reason === 'other') {
            reason = document.getElementById('banReasonCustom').value.trim();
            if (!reason) { alert('Please type a reason.'); return; }
        }
        bootstrap.Modal.getInstance(document.getElementById('banReasonModal')).hide();
        // Reset title for next time
        if (document.getElementById('banModalTitle')) document.getElementById('banModalTitle').textContent = 'Ban User';

        if (window._pendingOffense3) {
            // Send 3rd offense first, then ban
            const o3id = window._pendingOffense3.userId;
            window._pendingOffense3 = null;
            fetch('AdminServlet?action=sendOffense&userId=' + o3id + '&offense=3&reason=' + encodeURIComponent(reason), {method:'POST'})
                .then(() => fetch('AdminServlet?action=banUser&userId=' + o3id + '&banReason=' + encodeURIComponent(reason), {method:'POST'}))
                .then(r => r.json())
                .then(d => { showToast('3rd Offense issued & user banned.', 'success'); setTimeout(()=>location.reload(),1500); });
        } else {
            fetch('AdminServlet?action=banUser&userId=' + userId + '&banReason=' + encodeURIComponent(reason), {method:'POST'})
                .then(r => r.json())
                .then(d => { showToast(d.message || 'User banned.', d.success ? 'success' : 'danger'); if(d.success) setTimeout(()=>location.reload(),1500); });
        }
    }
    
    function activateUser(userId, name) {
        showConfirm('<i class="bi bi-check-circle" style="color:white;font-size:24px;"></i>',
            '#22c55e', 'Activate User?', 'Activate account of ' + name + '?',
            'btn-success', function() {
                fetch('AdminServlet?action=activateUser&userId=' + userId, {method:'POST'})
                    .then(r => r.json())
                    .then(d => { showToast(d.message || 'User activated.', d.success ? 'success' : 'danger'); if(d.success) setTimeout(()=>location.reload(),1500); })
                    .catch(() => showToast('User activated.', 'success'));
            });
    }

    function approveSeller(sellerId, name) {
        showConfirm('<i class="bi bi-check-circle" style="color:white;font-size:24px;"></i>',
            '#22c55e', 'Approve Seller?', 'Approve ' + name + ' as a seller?',
            'btn-success', function() {
                fetch('AdminServlet?action=approveSeller&sellerId=' + sellerId, {method:'POST'})
                    .then(r => r.json())
                    .then(d => { showToast(d.message || 'Seller approved.', d.success ? 'success' : 'danger'); if(d.success) setTimeout(()=>location.reload(),1500); })
                    .catch(() => { showToast('Seller approved.', 'success'); setTimeout(()=>location.reload(),1500); });
            });
    }
    function approveProduct(productId, name) {
        showConfirm('<i class="bi bi-check-circle" style="color:white;font-size:24px;"></i>',
            '#22c55e', 'Approve Product?', 'Approve "' + name + '"? It will be visible to buyers.',
            'btn-success', function() {
                fetch('AdminServlet', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                    body: 'action=approveProduct&productId=' + productId
                }).then(r => r.json()).then(data => {
                    showToast(data.success ? '✅ Product approved!' : '❌ Error: ' + (data.message || 'Unknown'), data.success ? 'success' : 'danger');
                    if (data.success) setTimeout(() => location.reload(), 1500);
                });
            });
    }
    function toggleCustomReason(val) {
        document.getElementById('banReasonCustom').style.display = val === 'other' ? 'block' : 'none';
    }
    // PAYOUT FUNCTIONS
    let _approvePayoutId = null;
    let _rejectPayoutId = null;

    function approvePayout(payoutId, sellerName, amount) {
        _approvePayoutId = payoutId;
        document.getElementById('approvePayoutInfo').textContent = 'Approve ' + amount + ' payout for ' + sellerName + '?';
        new bootstrap.Modal(document.getElementById('approvePayoutModal')).show();
    }

    function confirmApprovePayout() {
        bootstrap.Modal.getInstance(document.getElementById('approvePayoutModal')).hide();
        fetch('AdminServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'action=approvePayout&payoutId=' + _approvePayoutId
        }).then(r => r.json()).then(d => {
            showToast(d.success ? '✅ Payout approved!' : '❌ ' + (d.message || 'Error'), d.success ? 'success' : 'danger');
            if (d.success) setTimeout(() => location.reload(), 1500);
        });
    }

    function rejectPayout(payoutId, sellerName) {
        _rejectPayoutId = payoutId;
        document.getElementById('rejectPayoutInfo').textContent = 'Reject payout request for ' + sellerName + '?';
        document.getElementById('rejectPayoutReasonSelect').value = '';
        document.getElementById('rejectPayoutReasonOther').style.display = 'none';
        document.getElementById('rejectPayoutReasonOther').value = '';
        document.getElementById('rejectPayoutReasonError').style.display = 'none';
        new bootstrap.Modal(document.getElementById('rejectPayoutModal')).show();
    }

    document.addEventListener('DOMContentLoaded', function() {
        document.getElementById('rejectPayoutReasonSelect').addEventListener('change', function() {
            document.getElementById('rejectPayoutReasonOther').style.display = this.value === 'Others' ? 'block' : 'none';
            document.getElementById('rejectPayoutReasonError').style.display = 'none';
        });
    });

    function confirmRejectPayout() {
        const select = document.getElementById('rejectPayoutReasonSelect').value;
        const other = document.getElementById('rejectPayoutReasonOther').value.trim();
        if (!select) { document.getElementById('rejectPayoutReasonError').style.display = 'block'; return; }
        const reason = select === 'Others' ? (other || 'Others') : select;
        bootstrap.Modal.getInstance(document.getElementById('rejectPayoutModal')).hide();
        fetch('AdminServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'action=rejectPayout&payoutId=' + _rejectPayoutId + '&reason=' + encodeURIComponent(reason)
        }).then(r => r.json()).then(d => {
            showToast(d.success ? '❌ Payout rejected.' : '❌ ' + (d.message || 'Error'), d.success ? 'danger' : 'danger');
            if (d.success) setTimeout(() => location.reload(), 1500);
        });
    }

    let _rejectProductId = null;

    function rejectProduct(productId, name) {
        _rejectProductId = productId;
        document.getElementById('rejectProductName').textContent = '"' + name + '"';
        document.getElementById('rejectReasonSelect').value = '';
        document.getElementById('rejectReasonOther').style.display = 'none';
        document.getElementById('rejectReasonOther').value = '';
        document.getElementById('rejectReasonError').style.display = 'none';
        new bootstrap.Modal(document.getElementById('rejectProductModal')).show();
    }

    document.addEventListener('DOMContentLoaded', function() {
        document.getElementById('rejectReasonSelect').addEventListener('change', function() {
            document.getElementById('rejectReasonOther').style.display = this.value === 'Others' ? 'block' : 'none';
            document.getElementById('rejectReasonError').style.display = 'none';
        });
    });

    function confirmRejectProduct() {
        const select = document.getElementById('rejectReasonSelect').value;
        const other = document.getElementById('rejectReasonOther').value.trim();
        if (!select) {
            document.getElementById('rejectReasonError').style.display = 'block';
            return;
        }
        const reason = select === 'Others' ? (other || 'Others') : select;
        bootstrap.Modal.getInstance(document.getElementById('rejectProductModal')).hide();
        fetch('AdminServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'action=rejectProduct&productId=' + _rejectProductId + '&reason=' + encodeURIComponent(reason)
        }).then(r => r.json()).then(data => {
            showToast(data.success ? '❌ Product rejected!' : '❌ Error: ' + (data.message || 'Unknown'), data.success ? 'danger' : 'danger');
            if (data.success) setTimeout(() => location.reload(), 1500);
        });
    }
    
    function rejectSeller(sellerId, name) {
        showConfirm('<i class="bi bi-x-circle" style="color:white;font-size:24px;"></i>',
            '#ef4444', 'Reject Seller?', 'Reject application of ' + name + '?',
            'btn-danger', function() {
                fetch('AdminServlet?action=rejectSeller&sellerId=' + sellerId, {method:'POST'})
                    .then(r => r.json())
                    .then(d => { showToast(d.message || 'Seller rejected.', d.success ? 'success' : 'danger'); if(d.success) setTimeout(()=>location.reload(),1500); })
                    .catch(() => { showToast('Seller rejected.', 'success'); setTimeout(()=>location.reload(),1500); });
            });
    }

    let _sellerActionId = null, _sellerActionType = null;
    function openSellerAction(sellerId, name, type) {
        _sellerActionId = sellerId;
        _sellerActionType = type;
        const isSuspend = type === 'suspend';
        document.getElementById('sellerActionTitle').textContent = isSuspend ? 'Suspend Seller?' : 'Deactivate Seller?';
        document.getElementById('sellerActionIcon').className = isSuspend ? 'bi bi-pause-circle-fill' : 'bi bi-slash-circle-fill';
        document.getElementById('sellerActionIconWrap').style.background = isSuspend ? '#fef9c3' : '#fee2e2';
        document.getElementById('sellerActionIcon').style.color = isSuspend ? '#f59e0b' : '#ef4444';
        document.getElementById('sellerActionName').textContent = name;
        document.getElementById('sellerActionDesc').textContent = isSuspend
            ? 'This will temporarily restrict access to the Seller Center. You can reactivate anytime.'
            : 'This will permanently deactivate the seller account. The seller will lose access to their Seller Center.';
        document.getElementById('sellerActionBtn').className = isSuspend ? 'btn btn-warning flex-fill' : 'btn btn-danger flex-fill';
        document.getElementById('sellerActionBtn').textContent = isSuspend ? 'Suspend' : 'Deactivate';
        document.getElementById('sellerActionReason').value = '';
        document.getElementById('sellerActionOther').style.display = 'none';
        document.getElementById('sellerActionOther').value = '';
        document.getElementById('sellerActionError').style.display = 'none';
        // Show duration picker only for suspend
        document.getElementById('sellerDurationWrap').style.display = isSuspend ? 'block' : 'none';
        document.querySelectorAll('.durBtn').forEach(b => b.classList.remove('active','btn-warning','btn-secondary'));
        document.querySelectorAll('.durBtn').forEach(b => { b.classList.add(b.dataset.days==='0'?'btn-outline-secondary':'btn-outline-warning'); });
        document.getElementById('sellerCustomDaysWrap').style.display = 'none';
        document.getElementById('sellerCustomDays').value = '';
        document.getElementById('sellerDurationError').style.display = 'none';
        window._sellerSuspendDays = 0;
        new bootstrap.Modal(document.getElementById('sellerActionModal')).show();
    }
    document.addEventListener('DOMContentLoaded', function() {
        var el = document.getElementById('sellerActionReason');
        if (el) el.addEventListener('change', function() {
            document.getElementById('sellerActionOther').style.display = this.value === 'Others' ? 'block' : 'none';
            document.getElementById('sellerActionError').style.display = 'none';
        });
    });
    function selectDuration(days) {
        window._sellerSuspendDays = days;
        document.querySelectorAll('.durBtn').forEach(b => {
            b.classList.remove('btn-warning','btn-secondary','btn-outline-warning','btn-outline-secondary','active');
            if (parseInt(b.dataset.days) === days) {
                b.classList.add(days === 0 ? 'btn-secondary' : 'btn-warning');
            } else {
                b.classList.add(b.dataset.days === '0' ? 'btn-outline-secondary' : 'btn-outline-warning');
            }
        });
        document.getElementById('sellerCustomDaysWrap').style.display = days === 0 ? 'block' : 'none';
        document.getElementById('sellerDurationError').style.display = 'none';
    }
    function confirmSellerAction() {
        const select = document.getElementById('sellerActionReason').value;
        const other = document.getElementById('sellerActionOther').value.trim();
        if (!select) { document.getElementById('sellerActionError').style.display = 'block'; return; }
        const reason = select === 'Others' ? (other || 'Others') : select;
        const actionName = _sellerActionType === 'suspend' ? 'suspendSeller' : 'deactivateSeller';
        // Validate duration for suspend
        let days = 0;
        if (_sellerActionType === 'suspend') {
            days = window._sellerSuspendDays || 0;
            if (days === 0) {
                // custom
                days = parseInt(document.getElementById('sellerCustomDays').value) || 0;
            }
            if (!days || days < 1) {
                document.getElementById('sellerDurationError').style.display = 'block';
                return;
            }
        }
        bootstrap.Modal.getInstance(document.getElementById('sellerActionModal')).hide();
        fetch('AdminServlet?action=' + actionName + '&sellerId=' + _sellerActionId + '&reason=' + encodeURIComponent(reason) + '&days=' + days, {method:'POST'})
            .then(r => r.json())
            .then(d => { showToast(d.message || 'Done.', d.success ? 'success' : 'danger'); if(d.success) setTimeout(()=>location.reload(),1500); })
            .catch(() => { showToast('Done.', 'success'); setTimeout(()=>location.reload(),1500); });
    }
    function reactivateSeller(sellerId, name) {
        showConfirm('<i class="bi bi-play-circle" style="color:white;font-size:24px;"></i>',
            '#22c55e', 'Reactivate Seller?', 'Reactivate seller account of ' + name + '?',
            'btn-success', function() {
                fetch('AdminServlet?action=reactivateSeller&sellerId=' + sellerId, {method:'POST'})
                    .then(r => r.json())
                    .then(d => { showToast(d.message || 'Seller reactivated.', d.success ? 'success' : 'danger'); if(d.success) setTimeout(()=>location.reload(),1500); })
                    .catch(() => { showToast('Seller reactivated.', 'success'); setTimeout(()=>location.reload(),1500); });
            });
    }

    let _removeProductId = null;

    function removeProduct(productId, name) {
        _removeProductId = productId;
        document.getElementById('removeProductName').textContent = '"' + name + '"';
        document.getElementById('removeReasonSelect').value = '';
        document.getElementById('removeReasonOther').style.display = 'none';
        document.getElementById('removeReasonOther').value = '';
        document.getElementById('removeReasonError').style.display = 'none';
        new bootstrap.Modal(document.getElementById('removeProductModal')).show();
    }

    document.addEventListener('DOMContentLoaded', function() {
        document.getElementById('removeReasonSelect').addEventListener('change', function() {
            document.getElementById('removeReasonOther').style.display = this.value === 'Others' ? 'block' : 'none';
            document.getElementById('removeReasonError').style.display = 'none';
        });
    });

    function confirmRemoveProduct() {
        const select = document.getElementById('removeReasonSelect').value;
        const other = document.getElementById('removeReasonOther').value.trim();
        if (!select) {
            document.getElementById('removeReasonError').style.display = 'block';
            return;
        }
        const reason = select === 'Others' ? (other || 'Others') : select;
        bootstrap.Modal.getInstance(document.getElementById('removeProductModal')).hide();
        fetch('AdminServlet?action=removeProduct&productId=' + _removeProductId + '&reason=' + encodeURIComponent(reason), {method:'POST'})
            .then(r => r.json())
            .then(d => { showToast(d.message || 'Product removed.', d.success ? 'success' : 'danger'); if(d.success) setTimeout(()=>location.reload(),1500); })
            .catch(() => { showToast('Product removed.', 'success'); setTimeout(()=>location.reload(),1500); });
    }

    function approveRefund(refundId) {
        showConfirm('<i class="bi bi-check-circle" style="color:white;font-size:24px;"></i>',
            '#22c55e', 'Approve Refund?', 'Approve refund request #' + refundId + '?',
            'btn-success', function() {
                fetch('AdminServlet?action=approveRefund&refundId=' + refundId, {method:'POST'})
                    .then(r => r.json())
                    .then(d => { showToast(d.message || 'Refund approved.', d.success ? 'success' : 'danger'); if(d.success) setTimeout(()=>location.reload(),1500); })
                    .catch(() => { showToast('Refund approved.', 'success'); setTimeout(()=>location.reload(),1500); });
            });
    }
    function adminApproveRefund(refundId) {
        document.getElementById('adminApproveRefundId').value = refundId;
        document.getElementById('adminApproveModal').style.display = 'flex';
    }

    function confirmAdminApprove() {
        const refundId = document.getElementById('adminApproveRefundId').value;
        document.getElementById('adminApproveModal').style.display = 'none';
        fetch('RefundServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'action=adminAction&refundId=' + refundId + '&decision=approve'
        })
        .then(res => res.json())
        .then(data => {
            if (data.success) {
                showToast('Refund approved by Admin!', 'success');
                setTimeout(() => location.reload(), 1500);
            } else {
                showToast('Error: ' + data.message, 'danger');
            }
        });
    }

    function adminRejectRefund(refundId) {
        document.getElementById('adminRejectRefundId').value = refundId;
        document.getElementById('adminRejectModal').style.display = 'flex';
    }

    function confirmAdminReject() {
        const refundId = document.getElementById('adminRejectRefundId').value;
        document.getElementById('adminRejectModal').style.display = 'none';
        fetch('RefundServlet', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'action=adminAction&refundId=' + refundId + '&decision=reject'
        })
        .then(res => res.json())
        .then(data => {
            if (data.success) {
                showToast('Refund appeal rejected.', 'success');
                setTimeout(() => location.reload(), 1500);
            } else {
                showToast('Error: ' + data.message, 'danger');
            }
        });
    }

    
    function rejectRefund(refundId) {
        showConfirm('<i class="bi bi-x-circle" style="color:white;font-size:24px;"></i>',
            '#ef4444', 'Reject Refund?', 'Reject refund request #' + refundId + '?',
            'btn-danger', function() {
                fetch('AdminServlet?action=rejectRefund&refundId=' + refundId, {method:'POST'})
                    .then(r => r.json())
                    .then(d => { showToast(d.message || 'Refund rejected.', d.success ? 'success' : 'danger'); if(d.success) setTimeout(()=>location.reload(),1500); })
                    .catch(() => { showToast('Refund rejected.', 'success'); setTimeout(()=>location.reload(),1500); });
            });
    }
    
    function updateOrderStatus(orderId, newStatus) {
        fetch('AdminServlet?action=updateOrderStatus&orderId=' + orderId + '&status=' + newStatus, {method:'POST'})
            .then(r => r.json())
            .then(d => { showToast(d.message || 'Status updated.', d.success ? 'success' : 'danger'); if(d.success) setTimeout(()=>location.reload(),1500); })
            .catch(() => showToast('Status updated.', 'success'));
    }

    function doAdminLogout() {
        document.getElementById('logoutOverlay').style.display = 'flex';
        setTimeout(() => { window.location.href = 'LogoutServlet'; }, 1500);
    }

    function openSidebar() {
        document.getElementById('sidebar').classList.add('open');
        document.getElementById('sidebarOverlay').classList.add('show');
    }
    function closeSidebar() {
        document.getElementById('sidebar').classList.remove('open');
        document.getElementById('sidebarOverlay').classList.remove('show');
    }
    
 // Orders by Status Chart
    window.addEventListener('load', function() {
        if (window.orderChartData && document.getElementById('orderChart')) {
            const ctx = document.getElementById('orderChart').getContext('2d');
            new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: window.orderChartData.labels,
                    datasets: [{
                        label: 'Orders',
                        data: window.orderChartData.data,
                        backgroundColor: ['#fbbf24','#60a5fa','#818cf8','#34d399','#f87171'],
                        borderRadius: 6
                    }]
                },
                options: {
                    responsive: true, plugins: { legend: { display: false } },
                    scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } }
                }
            });
        }
     // Revenue Chart
        if (window.revenueChartData && document.getElementById('revenueChart')) {
            const ctx2 = document.getElementById('revenueChart').getContext('2d');
            new Chart(ctx2, {
                type: 'line',
                data: {
                    labels: window.revenueChartData.labels,
                    datasets: [{
                        label: 'Revenue',
                        data: window.revenueChartData.data,
                        borderColor: '#10b981',
                        backgroundColor: 'rgba(16,185,129,0.1)',
                        borderWidth: 2,
                        pointBackgroundColor: '#10b981',
                        tension: 0.4,
                        fill: true
                    }]
                },
                options: {
                    responsive: true,
                    plugins: { legend: { display: false } },
                    scales: { y: { beginAtZero: true, ticks: { callback: v => '₱' + v.toLocaleString() } } }
                }
            });
        }
     // Reports Charts
        if (window.repRevenueData && document.getElementById('repRevenueChart')) {
            new Chart(document.getElementById('repRevenueChart').getContext('2d'), {
                type: 'bar',
                data: {
                    labels: window.repRevenueData.labels,
                    datasets: [{ label: 'Revenue', data: window.repRevenueData.data,
                        backgroundColor: '#10b981', borderRadius: 6 }]
                },
                options: { responsive: true, plugins: { legend: { display: false } },
                    scales: { y: { beginAtZero: true, ticks: { callback: v => '₱' + v.toLocaleString() } } } }
            });
        }
        if (window.repStatusData && document.getElementById('repStatusChart')) {
            new Chart(document.getElementById('repStatusChart').getContext('2d'), {
                type: 'doughnut',
                data: {
                    labels: window.repStatusData.labels,
                    datasets: [{ data: window.repStatusData.data,
                        backgroundColor: ['#22c55e','#f59e0b','#ef4444'] }]
                },
                options: { responsive: true, plugins: { legend: { position: 'bottom' } } }
            });
        }
    });
 // DELETE REVIEW
    let _delReviewId = null, _delUserId = null;
    function deleteReview(reviewId, userId, productName) {
        _delReviewId = reviewId;
        _delUserId = userId;
        document.getElementById('delReviewProductName').textContent = productName;
        document.getElementById('delReviewReason').value = '';
        document.getElementById('delReviewReasonOther').style.display = 'none';
        document.getElementById('delReviewReasonOther').value = '';
        document.getElementById('delReviewError').style.display = 'none';
        new bootstrap.Modal(document.getElementById('deleteReviewModal')).show();
    }
    document.addEventListener('DOMContentLoaded', function() {
        document.getElementById('delReviewReason').addEventListener('change', function() {
            document.getElementById('delReviewReasonOther').style.display = this.value === 'Others' ? 'block' : 'none';
            document.getElementById('delReviewError').style.display = 'none';
        });
    });
    function confirmDeleteReview() {
        const select = document.getElementById('delReviewReason').value;
        const other = document.getElementById('delReviewReasonOther').value.trim();
        if (!select) { document.getElementById('delReviewError').style.display = 'block'; return; }
        const reason = select === 'Others' ? (other || 'Others') : select;
        bootstrap.Modal.getInstance(document.getElementById('deleteReviewModal')).hide();
        fetch('AdminServlet?action=deleteReview&reviewId=' + _delReviewId + '&userId=' + _delUserId + '&reason=' + encodeURIComponent(reason), {method:'POST'})
            .then(r => r.text())
            .then(() => { showToast('Review deleted.', 'success'); setTimeout(() => location.reload(), 1200); });
    }
</script>
<!-- SELLER ACTION MODAL (Suspend / Deactivate) -->
<div class="modal fade" id="sellerActionModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-body p-4">
                <div class="text-center mb-3">
                    <div id="sellerActionIconWrap" style="width:56px;height:56px;border-radius:50%;display:flex;align-items:center;justify-content:center;margin:0 auto 12px;">
                        <i id="sellerActionIcon" style="font-size:24px;"></i>
                    </div>
                    <h6 class="fw-bold mb-1" id="sellerActionTitle"></h6>
                    <p class="text-muted mb-0" style="font-size:13px;">Seller: <strong id="sellerActionName"></strong></p>
                </div>
                <p class="text-muted text-center" style="font-size:12px;" id="sellerActionDesc"></p>
                <!-- Duration picker — suspend only -->
                <div class="mb-3" id="sellerDurationWrap">
                    <label class="form-label fw-semibold" style="font-size:13px;">Suspension Duration</label>
                    <div class="d-flex gap-2 flex-wrap" id="sellerDurationBtns">
                        <button type="button" class="btn btn-sm btn-outline-warning durBtn" data-days="7" onclick="selectDuration(7)">7 Days</button>
                        <button type="button" class="btn btn-sm btn-outline-warning durBtn" data-days="14" onclick="selectDuration(14)">14 Days</button>
                        <button type="button" class="btn btn-sm btn-outline-warning durBtn" data-days="30" onclick="selectDuration(30)">30 Days</button>
                        <button type="button" class="btn btn-sm btn-outline-secondary durBtn" data-days="0" onclick="selectDuration(0)">Custom</button>
                    </div>
                    <div id="sellerCustomDaysWrap" style="display:none;" class="mt-2">
                        <input type="number" id="sellerCustomDays" class="form-control form-control-sm"
                            min="1" max="365" placeholder="Enter number of days (e.g. 21)">
                    </div>
                    <div id="sellerDurationError" class="text-danger mt-1" style="font-size:12px;display:none;">Please select or enter a duration.</div>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-semibold" style="font-size:13px;">Reason</label>
                    <select class="form-select form-select-sm" id="sellerActionReason">
                        <option value="">— Select reason —</option>
                        <option>Violation of platform policies</option>
                        <option>Fraudulent activity</option>
                        <option>Selling prohibited items</option>
                        <option>Multiple customer complaints</option>
                        <option>Fake products / misrepresentation</option>
                        <option>Non-fulfillment of orders</option>
                        <option>Others</option>
                    </select>
                    <textarea id="sellerActionOther" class="form-control form-control-sm mt-2" rows="2"
                        placeholder="Specify reason..." style="display:none;"></textarea>
                    <div id="sellerActionError" class="text-danger mt-1" style="font-size:12px;display:none;">Please select a reason.</div>
                </div>
                <div class="d-flex gap-2">
                    <button class="btn btn-light flex-fill" data-bs-dismiss="modal">Cancel</button>
                    <button id="sellerActionBtn" class="btn flex-fill" onclick="confirmSellerAction()">Confirm</button>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- DELETE REVIEW MODAL -->
<div class="modal fade" id="deleteReviewModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-body p-4">
                <div class="text-center mb-3">
                    <div style="width:56px;height:56px;border-radius:50%;background:#fee2e2;display:flex;align-items:center;justify-content:center;margin:0 auto 12px;">
                        <i class="bi bi-trash-fill" style="color:#ef4444;font-size:24px;"></i>
                    </div>
                    <h6 class="fw-bold mb-1">Delete Review?</h6>
                    <p class="text-muted mb-0" style="font-size:13px;">Review on: <strong id="delReviewProductName"></strong></p>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-semibold" style="font-size:13px;">Reason for deletion</label>
                    <select class="form-select form-select-sm" id="delReviewReason">
                        <option value="">— Select reason —</option>
                        <option>Inappropriate content</option>
                        <option>Fake review</option>
                        <option>Spam</option>
                        <option>Offensive language</option>
                        <option>Others</option>
                    </select>
                    <textarea id="delReviewReasonOther" class="form-control form-control-sm mt-2" rows="2"
                        placeholder="Specify reason..." style="display:none;"></textarea>
                    <div id="delReviewError" class="text-danger mt-1" style="font-size:12px;display:none;">Please select a reason.</div>
                </div>
                <p class="text-muted text-center mb-3" style="font-size:12px;">This will also add an <strong>offense</strong> to the user's record.</p>
                <div class="d-flex gap-2">
                    <button class="btn btn-light flex-fill" data-bs-dismiss="modal">Cancel</button>
                    <button class="btn btn-danger flex-fill" onclick="confirmDeleteReview()"><i class="bi bi-trash me-1"></i>Delete</button>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- VIEW USER PROFILE MODAL -->
<div class="modal fade" id="viewUserProfileModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered" style="max-width:480px;">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-header border-0 pb-0">
                <h6 class="modal-title fw-bold"><i class="bi bi-person-lines-fill me-2 text-primary"></i>User Profile</h6>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
          <div class="modal-body px-4 pb-4" id="viewUserProfileBody" style="text-align:center;">
                <div class="text-center py-4"><div class="spinner-border spinner-border-sm text-primary"></div></div>
            </div>
        </div>
    </div>
</div>

<script>
function viewUserProfile(userId, name, email, role) {
    document.getElementById('viewUserProfileBody').innerHTML =
        '<div class="text-center py-4"><div class="spinner-border spinner-border-sm text-primary"></div></div>';
    new bootstrap.Modal(document.getElementById('viewUserProfileModal')).show();

    fetch('AdminServlet?action=getUserProfile&userId=' + userId, {method:'POST'})
        .then(r => r.json())
        .then(data => {
            if (!data.success) {
                document.getElementById('viewUserProfileBody').innerHTML =
                    '<p class="text-danger text-center">Failed to load profile.</p>';
                return;
            }
            const d = data.user;
            const initial = (d.name || '?').charAt(0).toUpperCase();

            // Mask sensitive info
            function maskEmail(email) {
                if (!email) return '-';
                const [user, domain] = email.split('@');
                if (user.length <= 3) return user[0] + '***@' + domain;
                return user.substring(0, 4) + '***@' + domain;
            }
            function maskPhone(phone) {
                if (!phone) return '-';
                const p = phone.toString();
                if (p.length <= 6) return p;
                return p.substring(0, 4) + '****' + p.substring(p.length - 3);
            }
            const maskedEmail = maskEmail(d.email);
            const maskedPhone = maskPhone(d.phone);
            const avatar = d.avatar
                ? '<img src="' + d.avatar + '" style="width:72px;height:72px;border-radius:50%;object-fit:cover;border:3px solid #0d6efd;">'
                : '<div style="width:72px;height:72px;border-radius:50%;background:#0d6efd;color:white;font-size:28px;font-weight:700;display:flex;align-items:center;justify-content:center;margin:0 auto;">' + initial + '</div>';

            const roleBadge = d.role === 'both'
                ? '<span class="badge text-white" style="background:#6610f2;">Customer + Seller</span>'
                : d.role === 'seller'
                ? '<span class="badge bg-warning text-dark">Seller</span>'
                : '<span class="badge bg-primary">Customer</span>';

            let sellerSection = '';
            if (d.sellerName) {
                const statusColor = d.sellerStatus === 'active' ? 'success' : d.sellerStatus === 'suspended' ? 'warning' : 'danger';
                sellerSection = '<hr>'
                    + '<p class="fw-bold mb-2" style="font-size:13px;"><i class="bi bi-shop me-1 text-success"></i> Seller Info</p>'
                    + '<div class="d-flex justify-content-between mb-1" style="font-size:13px;"><span class="text-muted">Business Name</span><strong>' + d.sellerName + '</strong></div>'
                    + '<div class="d-flex justify-content-between mb-1" style="font-size:13px;"><span class="text-muted">Business Type</span><span>' + (d.bizType || '-') + '</span></div>'
                    + '<div class="d-flex justify-content-between mb-2" style="font-size:13px;"><span class="text-muted">Seller Status</span><span class="badge bg-' + statusColor + '">' + d.sellerStatus + '</span></div>'
                    + '<a href="SellerPageServlet?id=' + d.sellerId + '" target="_blank" class="btn btn-outline-success btn-sm w-100"><i class="bi bi-shop me-1"></i> View Public Shop</a>';
            }

            const offenseClass = d.offenses > 0 ? 'text-danger fw-bold' : '';
            document.getElementById('viewUserProfileBody').innerHTML =
                '<div class="text-center mb-3">' + avatar + '<div class="mt-2">' + roleBadge + '</div></div>'
                + '<p class="fw-bold text-center mb-3" style="font-size:16px;">' + (d.name || '-') + '</p>'
                + '<div class="d-flex justify-content-between mb-1" style="font-size:13px;"><span class="text-muted">Email</span><span>' + maskedEmail + '</span></div>'
                + '<div class="d-flex justify-content-between mb-1" style="font-size:13px;"><span class="text-muted">Username</span><span>' + (d.username || '-') + '</span></div>'
                + '<div class="d-flex justify-content-between mb-1" style="font-size:13px;"><span class="text-muted">Phone</span><span>' + maskedPhone + '</span></div>'
                + '<div class="d-flex justify-content-between mb-1" style="font-size:13px;"><span class="text-muted">Birthday</span><span>' + (d.birthday || '-') + '</span></div>'
                + '<div class="d-flex justify-content-between mb-1" style="font-size:13px;"><span class="text-muted">Gender</span><span>' + (d.gender || '-') + '</span></div>'
                + '<div class="d-flex justify-content-between mb-1" style="font-size:13px;"><span class="text-muted">Total Orders</span><span>' + d.totalOrders + '</span></div>'
                + '<div class="d-flex justify-content-between mb-1" style="font-size:13px;"><span class="text-muted">Offenses</span><span class="' + offenseClass + '">' + d.offenses + '</span></div>'
                + sellerSection;
        })
        .catch(() => {
            document.getElementById('viewUserProfileBody').innerHTML =
                '<p class="text-danger text-center">Error loading profile.</p>';
        });
}
</script>

<!-- ADMIN APPROVE REFUND MODAL -->
<div id="adminApproveModal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; 
     background:rgba(0,0,0,0.5); z-index:99999; align-items:center; justify-content:center;">
    <div style="background:white; border-radius:16px; padding:28px; width:90%; max-width:400px; box-shadow:0 20px 60px rgba(0,0,0,0.3); text-align:center;">
        <div style="font-size:48px; margin-bottom:12px;">💸</div>
        <h5 class="fw-bold mb-2">Approve Refund Appeal</h5>
        <p class="text-muted mb-4" style="font-size:13px;">
            The refund amount will be credited to the customer's wallet.<br>
            This action cannot be undone.
        </p>
        <input type="hidden" id="adminApproveRefundId"/>
        <div class="d-flex gap-2 justify-content-center">
            <button class="btn btn-outline-secondary px-4"
                onclick="document.getElementById('adminApproveModal').style.display='none'">
                Cancel
            </button>
            <button class="btn btn-success px-4" onclick="confirmAdminApprove()">
                <i class="bi bi-check-circle me-1"></i> Yes, Approve!
            </button>
        </div>
    </div>
</div>

<!-- ADMIN REJECT REFUND MODAL -->
<div id="adminRejectModal" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; 
     background:rgba(0,0,0,0.5); z-index:99999; align-items:center; justify-content:center;">
    <div style="background:white; border-radius:16px; padding:28px; width:90%; max-width:400px; box-shadow:0 20px 60px rgba(0,0,0,0.3); text-align:center;">
        <div style="font-size:48px; margin-bottom:12px;">❌</div>
        <h5 class="fw-bold mb-2">Reject Refund Appeal</h5>
        <p class="text-muted mb-4" style="font-size:13px;">
            The customer's refund appeal will be rejected.<br>
            This is the final decision.
        </p>
        <input type="hidden" id="adminRejectRefundId"/>
        <div class="d-flex gap-2 justify-content-center">
            <button class="btn btn-outline-secondary px-4"
                onclick="document.getElementById('adminRejectModal').style.display='none'">
                Cancel
            </button>
            <button class="btn btn-danger px-4" onclick="confirmAdminReject()">
                <i class="bi bi-x-circle me-1"></i> Yes, Reject!
            </button>
        </div>
    </div>
</div>
</body>
</html>
