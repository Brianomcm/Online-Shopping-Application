<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.shopeasy.DBConnection" %>
<%
boolean hasPendingApplication = false;
boolean hasApprovedApplication = false;
int _navCartCountDB = 0;
Object navUserIdObj = session.getAttribute("userId");
if (navUserIdObj != null) {
    try {
        String navRole2 = (String) session.getAttribute("userRole");
        if ("customer".equals(navRole2) || "both".equals(navRole2)) {
            Integer navCustId = (Integer) session.getAttribute("customerId");
            if (navCustId == null) navCustId = (Integer) navUserIdObj instanceof Integer ? (Integer) navUserIdObj : Integer.parseInt(navUserIdObj.toString());
            java.sql.Connection cartConn = DBConnection.getConnection();
            java.sql.PreparedStatement cartPs = cartConn.prepareStatement(
                "SELECT COALESCE(SUM(ci.quantity),0) as cnt FROM cart c JOIN cartitem ci ON c.cart_id=ci.cart_id WHERE c.customer_id=?");
            cartPs.setInt(1, navCustId);
            java.sql.ResultSet cartRs = cartPs.executeQuery();
            if (cartRs.next()) _navCartCountDB = cartRs.getInt("cnt");
            cartRs.close(); cartPs.close(); cartConn.close();
        }
    } catch (Exception ex) {}
}
if (navUserIdObj != null) {
try {
    int navUserIdInt = (navUserIdObj instanceof Integer) 
        ? (Integer) navUserIdObj 
        : Integer.parseInt(navUserIdObj.toString());
    java.sql.Connection navConn = DBConnection.getConnection();
    java.sql.PreparedStatement navPs = navConn.prepareStatement(
        "SELECT status FROM seller_application WHERE user_id=? ORDER BY application_id DESC LIMIT 1");
    navPs.setInt(1, navUserIdInt);
        java.sql.ResultSet navRs = navPs.executeQuery();
        if (navRs.next()) {
            String appStatus = navRs.getString("status");
            hasPendingApplication = "pending".equals(appStatus);
            hasApprovedApplication = "approved".equals(appStatus);
        }
        navRs.close(); navPs.close(); navConn.close();
} catch(Exception ex) {}
}
%>
<%
String _navSellerStatus = null;
if (navUserIdObj != null) {
    try {
        int navUserIdInt2 = (navUserIdObj instanceof Integer)
            ? (Integer) navUserIdObj
            : Integer.parseInt(navUserIdObj.toString());
        java.sql.Connection selConn = DBConnection.getConnection();
        java.sql.PreparedStatement selPs = selConn.prepareStatement(
            "SELECT status FROM seller WHERE user_id=? LIMIT 1");
        selPs.setInt(1, navUserIdInt2);
        java.sql.ResultSet selRs = selPs.executeQuery();
        if (selRs.next()) {
            _navSellerStatus = selRs.getString("status");
            if ("suspended".equals(_navSellerStatus)) {
                java.sql.Timestamp suspUntil = selRs.getTimestamp("suspend_until");
                if (suspUntil != null && suspUntil.before(new java.util.Date())) {
                    java.sql.PreparedStatement reActPs = selConn.prepareStatement(
                        "UPDATE seller SET status='active', suspend_until=NULL WHERE user_id=?");
                    reActPs.setInt(1, navUserIdInt2);
                    reActPs.executeUpdate(); reActPs.close();
                    _navSellerStatus = "active";
                }
            }
        }
        selRs.close(); selPs.close(); selConn.close();
    } catch(Exception ex) {}
}
%>
<%--
    SHARED NAVBAR - navbar.jsp
    Exactly matches index.jsp navbar structure.

    Set BEFORE including:
    - navType: "full" (default, with search) or "simple" (no search, with back button)
    - navCartCount: int cart count (for full type)
    - navBackUrl: String (for simple type, default "index.jsp")
    - navBackLabel: String (for simple type, default "Shop")
    - navSearchValue: String (current search value, for full type)
--%>
<%
    String _navUserName   = (String) session.getAttribute("userName");
    String _navRole       = (String) session.getAttribute("userRole");
    String _navEmail      = (String) session.getAttribute("userEmail");
    String _navAvatar     = (String) session.getAttribute("userAvatar");
    if (_navAvatar == null || _navAvatar.isEmpty())
        _navAvatar = (String) session.getAttribute("userProfilePicture");
    String _navBizName    = (String) session.getAttribute("userBusinessName");

    String _navFirstName = (String) session.getAttribute("userFirstName");
    String _navLastName  = (String) session.getAttribute("userLastName");
    String _navMI        = (String) session.getAttribute("userMiddleInitial");
    if (_navFirstName == null) _navFirstName = "";
    if (_navLastName  == null) _navLastName  = "";
    if (_navMI        == null) _navMI        = "";

    // Button label — First name lang
    String _navDisplayName = !_navFirstName.isEmpty() ? _navFirstName : (_navUserName != null ? _navUserName : "");
    if ("seller".equals(_navRole) && _navBizName != null && !_navBizName.isEmpty())
        _navDisplayName = _navBizName;

    // Dropdown header — Last, First MI format
    String _navFullDisplay = !_navLastName.isEmpty()
        ? _navLastName + ", " + _navFirstName + (!_navMI.isEmpty() ? " " + _navMI + "." : "")
        : _navUserName != null ? _navUserName : "";

    String _navInitial = (_navDisplayName != null && !_navDisplayName.isEmpty())
        ? String.valueOf(_navDisplayName.charAt(0)).toUpperCase() : "?";

    boolean _navLoggedIn   = _navUserName != null;
    boolean _navIsCustomer = _navLoggedIn && ("customer".equals(_navRole) || "both".equals(_navRole));
    boolean _navIsSeller   = _navLoggedIn && ("seller".equals(_navRole)   || "both".equals(_navRole));

    String _navType = request.getAttribute("navType") != null
        ? (String) request.getAttribute("navType") : "full";
    Object _navCartCountAttr = request.getAttribute("navCartCount");
    int _navCartCount = (_navCartCountAttr != null) ? (Integer) _navCartCountAttr : _navCartCountDB;
    String _navBackUrl = request.getAttribute("navBackUrl") != null
        ? (String) request.getAttribute("navBackUrl") : "index.jsp";
    String _navBackLabel = request.getAttribute("navBackLabel") != null
        ? (String) request.getAttribute("navBackLabel") : "Shop";
    String _navSearchVal = request.getAttribute("navSearchValue") != null
        ? (String) request.getAttribute("navSearchValue") : "";
%>

<nav class="navbar navbar-light bg-white shadow-sm py-2 sticky-top">
    <div class="container-fluid px-4">

        <!-- LOGO -->
        <a class="navbar-brand fw-bold text-primary" href="index.jsp" style="font-size:1.5rem;">
            <i class="bi bi-bag-heart-fill"></i> ShopEasy
        </a>

     <% if ("full".equals(_navType)) { %>
        <!-- DESKTOP SEARCH BAR -->
        <form class="d-none d-md-flex mx-3 flex-grow-1" action="index.jsp" method="get">
            <div class="input-group">
                <input type="text" class="form-control" name="search"
                       placeholder="Search products..." value="<%= _navSearchVal %>">
                <button class="btn btn-primary px-3" type="submit">
                    <i class="bi bi-search"></i>
                </button>
            </div>
        </form>
    <% } else if ("simple".equals(_navType)) { %>
        <span class="flex-grow-1"></span>
        <% } else if ("logo-only".equals(_navType)) { %>
        <!-- LOGO ONLY — spacer lang -->
        <span class="flex-grow-1"></span>
        <% } else { %>
        <!-- CHECKOUT — spacer lang para ma-push right ang profile -->
        <span class="flex-grow-1"></span>
        <% } %>

        <!-- RIGHT SIDE -->
        <div class="d-flex gap-2 align-items-center">
        <% if (_navLoggedIn) { %>

      <!-- HOME + CART ICON -->
         
     <% if (_navIsCustomer) { %>
     <% if ("simple".equals(_navType)) { %>
       <a href="index.jsp" class="btn btn-outline-secondary d-flex align-items-center gap-1 d-none d-md-flex">
                <i class="bi bi-house"></i> Home
            </a>
            <% } %>
            <a href="CartServlet" class="btn btn-outline-secondary position-relative">
                <i class="bi bi-cart3 fs-5"></i>
                <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger"
                      id="cartBadge" style="font-size:9px;"><%= _navCartCount > 0 ? _navCartCount : "0" %></span>
            </a>
            <% } %>
            <!-- PROFILE DROPDOWN -->
            <div class="dropdown">
                <button class="btn btn-light border d-flex align-items-center gap-2 px-2 py-1 rounded-pill"
                        type="button" data-bs-toggle="dropdown" aria-expanded="false"
                        style="font-size:13px;">
                    <% if (_navAvatar != null && !_navAvatar.isEmpty()) { %>
                        <img src="<%= _navAvatar %>"
                             style="width:28px; height:28px; border-radius:50%; object-fit:cover;">
                    <% } else { %>
                        <div style="width:28px; height:28px; border-radius:50%; background:#0d6efd;
                                    color:white; font-size:12px; font-weight:700;
                                    display:flex; align-items:center; justify-content:center;">
                            <%= _navInitial %>
                        </div>
                    <% } %>
                    <span class="d-none d-sm-inline fw-semibold">
                        <%= _navDisplayName.split(" ")[0] %>
                    </span>
                    <i class="bi bi-chevron-down" style="font-size:10px;"></i>
                </button>

                <ul class="dropdown-menu dropdown-menu-end shadow border-0"
                    style="min-width:200px; border-radius:12px; margin-top:6px;">
                    <!-- HEADER -->
                    <li class="px-3 py-2 border-bottom">
                        <div class="d-flex align-items-center gap-2">
                            <% if (_navAvatar != null && !_navAvatar.isEmpty()) { %>
                                <img src="<%= _navAvatar %>"
                                     style="width:38px; height:38px; border-radius:50%; object-fit:cover; flex-shrink:0;">
                            <% } else { %>
                                <div style="width:38px; height:38px; border-radius:50%; background:#0d6efd;
                                            color:white; font-size:14px; font-weight:700;
                                            display:flex; align-items:center; justify-content:center; flex-shrink:0;">
                                    <%= _navInitial %>
                                </div>
                            <% } %>
                            <div>
            <p class="mb-0 fw-bold" style="font-size:13px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; max-width:140px;"><%= _navFullDisplay %></p>
                                <p class="mb-0 text-muted" style="font-size:11px;">
                                    <%= _navEmail != null ? _navEmail : "" %>
                                </p>
                            </div>
                        </div>
                    </li>

                    <% if (_navIsCustomer) { %>
                    <li><a class="dropdown-item py-2" href="customer.jsp" style="font-size:13px;">
                        <i class="bi bi-person me-2 text-primary"></i>My Profile</a></li>
                    <li><a class="dropdown-item py-2" href="customer.jsp?tab=orders" style="font-size:13px;">
                        <i class="bi bi-bag me-2 text-primary"></i>My Orders</a></li>
                    <% } %>

                    <% if (_navIsSeller) { %>
                    <li><hr class="dropdown-divider my-1"></li>
                   <li><a class="dropdown-item py-2 text-success fw-semibold" href="#" onclick="goToSellerCenter()" style="font-size:13px;">
    <i class="bi bi-shop me-2"></i>Seller Center</a></li>
                    <% } else if (_navIsCustomer) { %>
                    <li><hr class="dropdown-divider my-1"></li>
                    <li><a class="dropdown-item py-2 text-success fw-semibold" href="#" onclick="goToBecomeSeller()" style="font-size:13px;">
    <i class="bi bi-shop-window me-2"></i>Become a Seller</a></li>
                    <% } %>

                    <li><hr class="dropdown-divider my-1"></li>
                 <li><a class="dropdown-item py-2 text-danger" href="#" onclick="doLogout()" style="font-size:13px;">
    <i class="bi bi-box-arrow-right me-2"></i>Logout</a></li>
                </ul>
            </div>

        <% } else { %>
            <a href="#" class="btn btn-outline-secondary position-relative" data-bs-toggle="modal" data-bs-target="#loginModal">
                <i class="bi bi-cart3 fs-5"></i>
                <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger"
                      id="cartBadge" style="font-size:9px;"><%= _navCartCount > 0 ? _navCartCount : "0" %></span>
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
</nav>
<%-- Seller Suspension / Deactivation Banner --%>
<% if ("suspended".equals(_navSellerStatus)) { %>
<div id="sellerSuspendBanner" style="background:#fef3c7; border-bottom:2px solid #f59e0b; padding:10px 20px; display:flex; align-items:center; gap:10px; font-size:13px;">
    <i class="bi bi-exclamation-triangle-fill" style="color:#d97706; font-size:18px; flex-shrink:0;"></i>
    <div>
        <strong style="color:#92400e;">Your Seller Center is temporarily suspended.</strong>
        <span style="color:#78350f;"> You cannot access your seller dashboard at this time. Please contact support for assistance.</span>
    </div>
    <button onclick="dismissSuspendBanner()" style="margin-left:auto;background:none;border:none;cursor:pointer;font-size:18px;color:#92400e;">✕</button>
</div>
<script>
if (sessionStorage.getItem('suspendBannerDismissed')) {
    document.getElementById('sellerSuspendBanner').style.display = 'none';
}
function dismissSuspendBanner() {
    document.getElementById('sellerSuspendBanner').style.display = 'none';
    sessionStorage.setItem('suspendBannerDismissed', '1');
}
</script>
<% } else if ("deactivated".equals(_navSellerStatus)) { %>
<div style="background:#fee2e2; border-bottom:2px solid #ef4444; padding:10px 20px; display:flex; align-items:center; gap:10px; font-size:13px;">
    <i class="bi bi-slash-circle-fill" style="color:#dc2626; font-size:18px; flex-shrink:0;"></i>
    <div>
        <strong style="color:#991b1b;">Your Seller Center has been permanently deactivated.</strong>
        <span style="color:#7f1d1d;"> Your seller account is no longer active. Please contact support for more information.</span>
    </div>
</div>
<% } %>
<% if ("full".equals(_navType)) { %>
<!-- MOBILE SEARCH BAR -->
<form class="container-fluid px-3 d-md-none mt-2 mb-1" action="index.jsp" method="get">
    <div class="input-group">
        <input type="text" class="form-control" name="search"
               placeholder="Search products..." value="<%= _navSearchVal %>">
        <button class="btn btn-primary" type="submit">
            <i class="bi bi-search"></i>
        </button>
    </div>
</form>
<% } %>

<!-- Seller Center Loading Overlay -->
<div id="sellerCenterOverlay" style="display:none; position:fixed; inset:0; background:rgba(255,255,255,0.95);
     z-index:9999; flex-direction:column; align-items:center; justify-content:center; gap:16px;">
    <div style="width:56px; height:56px; border:5px solid #e9ecef; border-top-color:#198754;
         border-radius:50%; animation:scSpin 0.8s linear infinite;"></div>
    <p style="font-size:16px; font-weight:600; color:#198754; margin:0;">
        <i class="bi bi-shop me-2"></i>Opening Seller Center...
    </p>
    <small style="color:#888; font-size:13px;">Please wait...</small>
</div>
<style>
@keyframes scSpin { to { transform: rotate(360deg); } }
</style>
<!-- LOGOUT OVERLAY -->
<div id="logoutOverlay" style="display:none; position:fixed; inset:0; background:rgba(255,255,255,0.95);
     z-index:9999; flex-direction:column; align-items:center; justify-content:center; gap:16px;">
    <div style="width:56px; height:56px; border:5px solid #e9ecef; border-top-color:#dc3545;
         border-radius:50%; animation:scSpin 0.8s linear infinite;"></div>
    <p style="font-size:16px; font-weight:600; color:#dc3545; margin:0;">Logging out...</p>
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

<!-- BIRTHDAY REQUIRED MODAL -->
<div class="modal fade" id="birthdayRequiredModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-body text-center p-4">
                <div class="mb-3" style="font-size:3rem;">🎂</div>
                <h5 class="fw-bold mb-2">Birthday Required</h5>
                <p class="text-muted mb-4" style="font-size:14px;">Please fill in your birthday in your profile before becoming a seller.</p>
                <a href="customer.jsp" class="btn btn-primary rounded-pill px-4">
                    <i class="bi bi-person-fill me-1"></i> Go to My Profile
                </a>
                <button type="button" class="btn btn-outline-secondary rounded-pill px-4 ms-2" data-bs-dismiss="modal">Cancel</button>
            </div>
        </div>
    </div>
</div>


<!-- APPLICATION APPROVED MODAL -->
<div class="modal fade" id="applicationApprovedModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-body text-center p-4">
                <div class="mb-3" style="font-size:3rem;">🎉</div>
                <h5 class="fw-bold mb-2">You're Already a Seller!</h5>
                <p class="text-muted mb-4" style="font-size:14px;">
                    Your application has been approved! Please log out and log back in to access your Seller Center.
                </p>
                <div class="d-flex gap-2 justify-content-center">
                    <button type="button" class="btn btn-outline-secondary rounded-pill px-4" data-bs-dismiss="modal">
                        Cancel
                    </button>
                    <a href="LogoutServlet" class="btn btn-success rounded-pill px-4 fw-bold">
                        <i class="bi bi-box-arrow-right me-1"></i> Log out now
                    </a>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- APPLICATION PENDING MODAL -->
<div class="modal fade" id="applicationPendingModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-body text-center p-4">
                <div class="mb-3" style="font-size:3rem;">⏳</div>
                <h5 class="fw-bold mb-2">Application Under Review</h5>
                <p class="text-muted mb-4" style="font-size:14px;">
                    Your seller application is currently being reviewed by our admin team.
                    We'll notify you once it's approved!
                </p>
                <button type="button" class="btn btn-primary rounded-pill px-4" data-bs-dismiss="modal">
                    Got it!
                </button>
            </div>
        </div>
    </div>
</div>
<script>
function goToSellerCenter() {
    document.getElementById('sellerCenterOverlay').style.display = 'flex';
    setTimeout(function() {
        window.location.href = 'seller.jsp';
    }, 1500);
}
function goToBecomeSeller() {
    <% if (hasApprovedApplication) { %>
    new bootstrap.Modal(document.getElementById('applicationApprovedModal')).show();
    return;
    <% } %>
    <% if (hasPendingApplication) { %>
    new bootstrap.Modal(document.getElementById('applicationPendingModal')).show();
    return;
    <% } %>
    const birthday = '<%= session.getAttribute("userBirthday") != null ? session.getAttribute("userBirthday") : "" %>';
    if (!birthday || birthday.trim() === '') {
        new bootstrap.Modal(document.getElementById('birthdayRequiredModal')).show();
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
function doLogout() {
    new bootstrap.Modal(document.getElementById('logoutConfirmModal')).show();
}
function confirmLogout() {
    bootstrap.Modal.getInstance(document.getElementById('logoutConfirmModal')).hide();
    document.getElementById('logoutOverlay').style.display = 'flex';
    setTimeout(() => { window.location.href = 'LogoutServlet'; }, 1500);
}

//Global push notification polling — runs on every page
(function() {
    if (!('Notification' in window)) return;
    if (Notification.permission !== 'granted') return;

    let lastId = parseInt(localStorage.getItem('lastNotifId') || '0');

    function checkNotifs() {
        fetch('NotificationServlet?action=getNew&since=' + lastId)
            .then(r => r.json())
            .then(data => {
                if (data.notifications && data.notifications.length > 0) {
                    data.notifications.forEach(n => {
                        new Notification('ShopEasy', {
                            body: n.message,
                            icon: '/Online_Shopping/favicon.ico'
                        });
                        lastId = Math.max(lastId, n.id);
                    });
                    localStorage.setItem('lastNotifId', lastId);
                }
            })
            .catch(() => {});
    }
 // Check after 0.5 seconds ng page load
    setTimeout(checkNotifs, 500);
    // Then every 30 seconds
    setInterval(checkNotifs, 30000);
})();


</script>
