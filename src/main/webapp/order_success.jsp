<%@ page session="true" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    if(session.getAttribute("userId") == null) {
        response.sendRedirect("index.jsp");
        return;
    }
    String orderId = request.getParameter("orderId");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Order Placed - ShopEasy</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css">
    <style>
        body { background: #f8f9fa; font-family: 'Segoe UI', sans-serif; }
        .success-card { background: white; border-radius: 20px; box-shadow: 0 4px 24px rgba(0,0,0,0.08); padding: 48px 32px; text-align: center; max-width: 480px; margin: 80px auto; }
        .success-icon { font-size: 72px; color: #198754; animation: pop 0.5s ease; }
        @keyframes pop { 0% { transform: scale(0); } 80% { transform: scale(1.2); } 100% { transform: scale(1); } }
    </style>
</head>
<body>
<div class="container">
    <div class="success-card">
        <div class="success-icon mb-3"><i class="bi bi-check-circle-fill"></i></div>
        <h4 class="fw-bold text-success mb-2">Order Placed Successfully!</h4>
        <p class="text-muted mb-1">Your order has been received.</p>
        <p class="fw-bold mb-4">Order ID: <span class="text-primary">#SE-<%= orderId %></span></p>
        <div class="d-flex gap-2 justify-content-center flex-wrap">
            <a href="customer.jsp?tab=orders" class="btn btn-outline-primary">
    <i class="bi bi-bag"></i> View My Orders
</a>
            <a href="index.jsp" class="btn btn-primary">
                <i class="bi bi-shop"></i> Continue Shopping
            </a>
        </div>
    </div>
</div>
</body>
</html>