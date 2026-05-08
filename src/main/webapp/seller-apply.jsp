<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
// Session check - must be logged in as customer
String userRole = (String) session.getAttribute("userRole");
Integer userId  = (Integer) session.getAttribute("userId");

if (userId == null) {
    response.sendRedirect("login.jsp");
    return;
}
if ("seller".equals(userRole) || "both".equals(userRole)) {
    response.sendRedirect("seller.jsp");
    return;
}

//Age check — must be 18+
String _sellerBday = (String) session.getAttribute("userBirthday");
if (_sellerBday == null || _sellerBday.isEmpty()) {
 response.sendRedirect("index.jsp?sellerBlocked=age");
 return;
}
java.time.LocalDate _sellerDob = java.time.LocalDate.parse(_sellerBday);
int _sellerAge = java.time.Period.between(_sellerDob, java.time.LocalDate.now()).getYears();
if (_sellerAge < 18) {
 response.sendRedirect("index.jsp?sellerBlocked=age");
 return;
}
String customerName  = (String) session.getAttribute("userName");
String customerEmail = (String) session.getAttribute("userEmail");
String customerAvatar = (String) session.getAttribute("userAvatar");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Become a Seller – ShopEasy</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Segoe UI', sans-serif;
            background: #f5f7fa;
            min-height: 100vh;
        }


        /* ── Main ── */
        .container {
            max-width: 680px;
            margin: 40px auto;
            padding: 0 16px 60px;
        }

        .page-header {
            text-align: center;
            margin-bottom: 32px;
        }
        .page-header .icon {
            width: 72px; height: 72px;
            background: linear-gradient(135deg, #0d6efd, #3d8bfd);
            border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            margin: 0 auto 16px;
            font-size: 30px; color: #fff;
            box-shadow: 0 4px 16px rgba(13,110,253,0.3);
        }
        .page-header h1 { font-size: 26px; font-weight: 700; color: #222; margin-bottom: 8px; }
        .page-header p  { color: #777; font-size: 14px; }

        /* benefits */
        .benefits {
            display: flex;
            gap: 12px;
            margin-bottom: 28px;
        }
        .benefit-item {
            flex: 1;
            background: #fff;
            border-radius: 10px;
            padding: 16px 12px;
            text-align: center;
            box-shadow: 0 2px 8px rgba(0,0,0,0.06);
        }
        .benefit-item i { font-size: 22px; color: #0d6efd; margin-bottom: 8px; display: block; }
        .benefit-item span { font-size: 12px; color: #555; font-weight: 500; }

        /* form card */
        .form-card {
            background: #fff;
            border-radius: 14px;
            padding: 32px;
            box-shadow: 0 2px 12px rgba(0,0,0,0.08);
            margin-bottom: 20px;
        }
        .form-card h2 {
            font-size: 15px;
            font-weight: 700;
            color: #0d6efd;
            margin-bottom: 22px;
            padding-bottom: 14px;
            border-bottom: 1px solid #e9ecef;
        }

        .form-group { margin-bottom: 18px; }
        .form-group label {
            display: block;
            font-size: 13px;
            font-weight: 600;
            color: #444;
            margin-bottom: 6px;
        }
        .form-group label .req { color: #dc3545; margin-left: 2px; }
        .form-group input,
        .form-group select,
        .form-group textarea {
            width: 100%;
            padding: 11px 14px;
            border: 1.5px solid #dee2e6;
            border-radius: 8px;
            font-size: 14px;
            color: #333;
            background: #fff;
            outline: none;
            transition: border-color 0.2s, box-shadow 0.2s;
        }
        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            border-color: #0d6efd;
            box-shadow: 0 0 0 3px rgba(13,110,253,0.1);
        }
        .form-group input[readonly] {
            background: #f8f9fa;
            color: #888;
            cursor: not-allowed;
        }
        .form-group textarea { resize: vertical; min-height: 100px; }
        .form-group .hint { font-size: 12px; color: #999; margin-top: 5px; }

        .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }

        /* terms */
        .terms-box {
            background: #f0f6ff;
            border: 1px solid #c6dcff;
            border-radius: 10px;
            padding: 16px 18px;
            margin-bottom: 22px;
        }
        .terms-box label {
            display: flex;
            align-items: center;
            gap: 12px;
            cursor: pointer;
            font-size: 13px;
            color: #555;
            line-height: 1.5;
        }
        .terms-box input[type="checkbox"] {
            accent-color: #0d6efd;
            width: 18px; height: 18px;
            flex-shrink: 0;
            cursor: pointer;
        }
        .terms-box a { color: #0d6efd; font-weight: 600; text-decoration: underline; }
        .terms-box a:hover { color: #0b5ed7; }

        /* submit */
        .btn-submit {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #0d6efd, #3d8bfd);
            color: #fff;
            border: none;
            border-radius: 10px;
            font-size: 15px;
            font-weight: 600;
            cursor: pointer;
            transition: opacity 0.2s, transform 0.1s;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }
        .btn-submit:hover { opacity: 0.9; }
        .btn-submit:active { transform: scale(0.99); }
        .btn-submit:disabled { background: #adb5bd; cursor: not-allowed; }

        /* alert */
        .alert {
            padding: 12px 16px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 13px;
            display: flex;
            align-items: center;
            gap: 8px;
            background: #fff3cd;
            color: #856404;
            border: 1px solid #ffc107;
        }

        /* ── Loading Overlay ── */
        #loadingOverlay {
            display: none;
            position: fixed;
            inset: 0;
            background: rgba(255,255,255,0.92);
            z-index: 9999;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 20px;
        }
        #loadingOverlay.show { display: flex; }
        .spinner {
            width: 56px; height: 56px;
            border: 5px solid #e9ecef;
            border-top-color: #0d6efd;
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        #loadingOverlay p {
            font-size: 16px;
            font-weight: 600;
            color: #0d6efd;
        }
        #loadingOverlay small { color: #888; font-size: 13px; }

        @media (max-width: 600px) {
            .form-row   { grid-template-columns: 1fr; }
            .benefits   { flex-direction: column; }
            .form-card  { padding: 20px; }
            .navbar     { padding: 12px 16px; }
        }
    </style>
</head>
<body>

<!-- ── Loading Overlay ── -->
<div id="loadingOverlay">
    <div class="spinner"></div>
    <p id="loadingText"><i class="fas fa-paper-plane"></i> Submitting application…</p>
    <small id="loadingSmall">Please wait a moment.</small>
</div>
<!-- ── Navbar ── -->
<%
request.setAttribute("navType", "simple");
request.setAttribute("navBackUrl", "index.jsp");
%>
<%@ include file="navbar.jsp" %>

<div class="container">

    <!-- Header -->
    <div class="page-header">
        <div class="icon"><i class="fas fa-store"></i></div>
        <h1>Open Your Shop on ShopEasy</h1>
        <p>Start selling today — free and instant!</p>
    </div>

    <!-- Benefits -->
    <div class="benefits">
        <div class="benefit-item">
            <i class="fas fa-bolt"></i>
            <span>Instant Activation</span>
        </div>
        <div class="benefit-item">
            <i class="fas fa-users"></i>
            <span>Reach More Buyers</span>
        </div>
        <div class="benefit-item">
            <i class="fas fa-chart-line"></i>
            <span>Track Your Sales</span>
        </div>
    </div>

    <!-- Error -->
    <% String error = request.getParameter("error"); %>
    <% if (error != null) { %>
    <div class="alert">
        <i class="fas fa-exclamation-circle"></i>
        <% if ("already".equals(error)) { %>
            You already have a seller account.
        <% } else { %>
            Something went wrong. Please try again.
        <% } %>
    </div>
    <% } %>

    <!-- ── SECTION 1: Basic Information ── -->
    <div class="form-card">
        <h2><i class="fas fa-circle-info" style="margin-right:8px;"></i>Basic Information</h2>

        <form action="BecomeSellerServlet" method="POST" id="sellerForm">

            <div class="form-row">
                <div class="form-group">
                    <label>Your Name</label>
                    <input type="text" value="<%= customerName != null ? customerName : "" %>" readonly>
                </div>
                <div class="form-group">
                    <label>Email Address</label>
                    <input type="text" value="<%= customerEmail != null ? customerEmail : "" %>" readonly>
                </div>
            </div>

            <div class="form-group">
                <label>Shop / Business Name <span class="req">*</span></label>
                <input type="text" name="businessName" placeholder="e.g. Maria's Clothing Store" required maxlength="100">
                <div class="hint">This will be displayed to buyers on your shop page.</div>
            </div>

            <div class="form-group">
                <label>Shop Description <span class="req">*</span></label>
                <textarea name="shopDescription" placeholder="Tell buyers what your shop is about, what you sell, and what makes you unique…" required maxlength="500"></textarea>
                <div class="hint">Minimum 20 characters.</div>
            </div>

    <!-- ── SECTION 2: Business Information ── -->
            <h2 style="font-size:15px; font-weight:700; color:#0d6efd; margin-top:10px; margin-bottom:22px; padding-bottom:14px; border-bottom:1px solid #e9ecef;">
                <i class="fas fa-briefcase" style="margin-right:8px;"></i>Business Information
            </h2>

            <div class="form-group">
                <label>Business Type <span class="req">*</span></label>
                <select name="businessType" required>
                    <option value="" disabled selected>Select business type</option>
                    <option value="Individual Seller">🧑 Individual Seller</option>
                    <option value="Small Business">🏪 Small Business</option>
                    <option value="Registered Business">🏢 Registered Business</option>
                </select>
                <div class="hint">Used for classification only — does not affect your products.</div>
            </div>

            <div class="form-group">
                <label>Primary Product Category <span class="req">*</span></label>
                <select name="primaryCategory" required>
                    <option value="" disabled selected>Select a category</option>
                    <option value="Electronics">📱 Electronics</option>
                    <option value="Fashion">👗 Fashion</option>
                    <option value="Home & Living">🏠 Home & Living</option>
                    <option value="Gaming">🎮 Gaming</option>
                    <option value="Health & Beauty">💄 Health & Beauty</option>
                    <option value="Sports & Outdoors">⚽ Sports & Outdoors</option>
                    <option value="Food & Beverage">🍔 Food & Beverage</option>
                    <option value="Arts & Crafts">🎨 Arts & Crafts</option>
                    <option value="Other">📦 Other</option>
                </select>
                <div class="hint">Choose the main category of what you will sell.</div>
            </div>

            <div class="form-group">
                <label>Shop Location / Address <span class="req">*</span></label>
                <input type="text" name="shopLocation" placeholder="e.g. Quezon City, Metro Manila" required maxlength="200">
                <div class="hint">Used for shipping reference and buyer trust.</div>
            </div>

           <!-- Terms -->
            <div class="terms-box">
                <label>
                    <input type="checkbox" id="termsCheck" required disabled>
                    I have read and agree to the
                    <a href="#" id="termsLink" onclick="openTerms(event)">Seller Terms &amp; Conditions</a>
                    — and confirm that all information provided is accurate and true.
                </label>
                <p id="termsHint" style="font-size:11px; color:#0d6efd; margin-top:8px; margin-left:30px;">
                    <i class="fas fa-info-circle"></i> Please click "Seller Terms & Conditions" to read and enable the checkbox.
                </p>
            </div>

            <!-- Terms Modal -->
            <div id="termsModal" style="display:none; position:fixed; inset:0; background:rgba(0,0,0,0.5); z-index:9998; align-items:center; justify-content:center;">
                <div style="background:#fff; border-radius:16px; max-width:540px; width:90%; max-height:80vh; overflow:hidden; display:flex; flex-direction:column; box-shadow:0 8px 32px rgba(0,0,0,0.2);">
                    <div style="padding:20px 24px; border-bottom:1px solid #e9ecef; display:flex; justify-content:space-between; align-items:center;">
                        <h3 style="margin:0; font-size:16px; font-weight:700; color:#0d6efd;"><i class="fas fa-file-contract" style="margin-right:8px;"></i>Seller Terms & Conditions</h3>
                        <button onclick="closeTerms()" style="background:none; border:none; font-size:20px; cursor:pointer; color:#888; line-height:1;">&times;</button>
                    </div>
                    <div style="padding:20px 24px; overflow-y:auto; font-size:13px; color:#444; line-height:1.8;">
                        <p><strong>Welcome to ShopEasy Seller Program.</strong> By registering as a seller, you agree to the following:</p>
                        <br>
                        <p><strong>1. Eligibility</strong><br>You must be at least 18 years old and legally allowed to sell products in your region.</p>
                        <br>
                        <p><strong>2. Accurate Information</strong><br>All information you provide — including shop name, description, and location — must be accurate and up to date.</p>
                        <br>
                        <p><strong>3. Product Listings</strong><br>You are responsible for the accuracy of your product listings. Prohibited items, counterfeit goods, and illegal products are strictly not allowed.</p>
                        <br>
                        <p><strong>4. Order Fulfillment</strong><br>As a seller, you are expected to fulfill orders promptly and maintain a good seller rating. Failure to fulfill orders may result in account suspension.</p>
                        <br>
                        <p><strong>5. Fees & Payments</strong><br>ShopEasy does not currently charge listing fees. Payment processing terms may apply as the platform grows.</p>
                        <br>
                        <p><strong>6. Account Suspension</strong><br>ShopEasy reserves the right to suspend or terminate any seller account that violates these terms.</p>
                        <br>
                        <p><strong>7. Changes to Terms</strong><br>ShopEasy may update these terms at any time. Continued use of the seller program constitutes acceptance of the updated terms.</p>
                        <br>
                        <p style="color:#888;">Last updated: May 2026</p>
                    </div>
                    <div style="padding:16px 24px; border-top:1px solid #e9ecef;">
                       <button type="button" onclick="acceptTerms()" style="width:100%; padding:12px; background:linear-gradient(135deg,#0d6efd,#3d8bfd); color:#fff; border:none; border-radius:8px; font-size:14px; font-weight:600; cursor:pointer;">
                            <i class="fas fa-check" style="margin-right:6px;"></i> I Agree & Accept
                        </button>
                    </div>
                </div>
            </div>

            <!-- Submit -->
            <button type="submit" class="btn-submit" id="submitBtn">
                <i class="fas fa-store"></i> Open My Shop Now
            </button>

        </form>
    </div>

</div>

<script>

//Terms modal
function openTerms(e) {
    e.preventDefault();
    const modal = document.getElementById('termsModal');
    modal.style.display = 'flex';
}
function closeTerms() {
    document.getElementById('termsModal').style.display = 'none';
}
function acceptTerms() {
    document.getElementById('termsCheck').disabled = false;
    document.getElementById('termsCheck').checked = true;
    document.getElementById('termsLink').style.color = '#198754';
    document.getElementById('termsHint').innerHTML =
        '<i class="fas fa-check-circle" style="color:#198754;"></i> <span style="color:#198754;">Terms accepted!</span>';
    closeTerms();
}
// Close modal on outside click
document.getElementById('termsModal').addEventListener('click', function(e) {
    if (e.target === this) closeTerms();
});

    // Toggle dropdown
    function toggleDropdown() {
        document.getElementById('navDropdown').classList.toggle('open');
    }
 // Logout with loading overlay
    function doLogout() {
        document.getElementById('loadingOverlay').querySelector('p').innerHTML =
            '<i class="fas fa-sign-out-alt"></i> Logging out…';
        document.getElementById('loadingOverlay').querySelector('small').textContent =
            'See you next time!';
        document.getElementById('loadingOverlay').classList.add('show');
        setTimeout(function() {
            window.location.href = 'LogoutServlet';
        }, 1200);
    }
 
    document.addEventListener('click', function(e) {
        const profile = document.querySelector('.nav-profile');
        if (!profile.contains(e.target)) {
            document.getElementById('navDropdown').classList.remove('open');
        }
    });

 // Form submit — show loading overlay with steps
 document.getElementById('sellerForm').addEventListener('submit', function(e) {
        e.preventDefault(); // STOP normal submit

        const desc = document.querySelector('textarea[name="shopDescription"]').value.trim();
        if (desc.length < 20) {
            alert('Shop description must be at least 20 characters.');
            return;
        }

        // Show overlay — step 1
        document.getElementById('loadingOverlay').classList.add('show');
        document.getElementById('submitBtn').disabled = true;
        document.getElementById('submitBtn').innerHTML = '<i class="fas fa-spinner fa-spin"></i> Processing…';

        // Submit via fetch in background
        const formData = new FormData(document.getElementById('sellerForm'));
        fetch('BecomeSellerServlet', {
            method: 'POST',
            body: new URLSearchParams(formData)
        }).then(() => {
            // Servlet done — now run the animation steps
        });

        // Animation steps (independent of servlet)
        setTimeout(function() {
            document.getElementById('loadingText').innerHTML = '<i class="fas fa-spinner fa-spin"></i> Reviewing your application…';
            document.getElementById('loadingSmall').textContent = 'Almost there, please wait…';
        }, 2000);

        setTimeout(function() {
            document.getElementById('loadingText').innerHTML = '<i class="fas fa-check-circle" style="color:#198754;"></i> Application approved!';
            document.getElementById('loadingSmall').textContent = 'Setting up your seller account…';
        }, 5000);

        setTimeout(function() {
            document.getElementById('loadingText').innerHTML = '<i class="fas fa-store" style="color:#198754;"></i> Opening your shop…';
            document.getElementById('loadingSmall').textContent = 'Redirecting you to the homepage…';
        }, 7000);

        // Redirect after 9s
        setTimeout(function() {
            window.location.href = 'index.jsp?sellerWelcome=true';
        }, 9000);
    });
    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    </body>
</html>
