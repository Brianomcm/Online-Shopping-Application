<!-- LOGIN MODAL -->
<div class="modal fade" id="loginModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered" style="max-width:420px; margin:auto;">
        <div class="modal-content rounded-4">
            <div class="modal-header border-0 pb-0">
                <h5 class="modal-title fw-bold">
                    <i class="bi bi-bag-heart-fill text-primary"></i> Login to ShopEasy
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body px-4 pb-4">

                <!-- SOCIAL LOGIN -->
                <p class="text-center fw-bold mb-2" style="font-size:13px;">Log in with</p>
                <div class="row g-2 mb-3">
                    <div class="col-6">
                        <button class="btn btn-outline-danger w-100 d-flex align-items-center justify-content-center gap-2" type="button" style="transition:0.3s;" onmouseover="this.style.background='#EA4335'; this.style.color='white';" onmouseout="this.style.background='white'; this.style.color='#EA4335';">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 48 48">
                                <path fill="#EA4335" d="M24 9.5c3.1 0 5.6 1.1 7.6 2.9l5.6-5.6C33.5 3.5 29 1.5 24 1.5 14.9 1.5 7.2 7.2 4.1 15.1l6.6 5.1C12.3 13.7 17.7 9.5 24 9.5z"/>
                                <path fill="#4285F4" d="M46.5 24.5c0-1.6-.1-3.1-.4-4.5H24v8.5h12.7c-.6 3-2.3 5.5-4.8 7.2l7.4 5.7c4.3-4 6.8-9.9 6.8-16.9z"/>
                                <path fill="#FBBC05" d="M10.7 28.8A14.6 14.6 0 0 1 9.5 24c0-1.7.3-3.3.8-4.8L3.7 14c-1.4 2.9-2.2 6.1-2.2 9.5s.8 6.6 2.2 9.5l7-5.2z"/>
                                <path fill="#34A853" d="M24 46.5c5 0 9.2-1.7 12.3-4.5l-7.4-5.7c-1.7 1.1-3.8 1.8-4.9 1.8-6.3 0-11.7-4.2-13.6-10l-6.6 5.1C7.2 40.8 14.9 46.5 24 46.5z"/>
                            </svg>
                            Google
                        </button>
                    </div>
                    <div class="col-6">
                        <button class="btn w-100 d-flex align-items-center justify-content-center gap-2" type="button" style="background:#1877F2; color:white; border:none; transition:0.3s;" onmouseover="this.style.background='#1558b0'" onmouseout="this.style.background='#1877F2'">
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="white" viewBox="0 0 16 16">
        <path d="M16 8.049c0-4.446-3.582-8.05-8-8.05C3.58 0-.002 3.603-.002 8.05c0 4.017 2.926 7.347 6.75 7.951v-5.625h-2.03V8.05H6.75V6.275c0-2.017 1.195-3.131 3.022-3.131.876 0 1.791.157 1.791.157v1.98h-1.009c-.993 0-1.303.621-1.303 1.258v1.51h2.218l-.354 2.326H9.25V16c3.824-.604 6.75-3.934 6.75-7.951z"/>
    </svg>
    Facebook
</button>
                    </div>
                </div>

                <!-- DIVIDER -->
                <div class="d-flex align-items-center mb-3">
                    <hr class="flex-grow-1">
                    <span class="px-2 text-muted" style="font-size:12px;">or login with email</span>
                    <hr class="flex-grow-1">
                </div>

                <!-- LOGIN FORM -->
                <form action="LoginServlet" method="post" autocomplete="off" id="loginForm" onsubmit="return handleLoginSubmit(event, this)">
                    <div class="mb-3">
                        <label class="form-label fw-bold">Email or Username</label>
                        <div class="input-group">
                            <span class="input-group-text bg-light"><i class="bi bi-person"></i></span>
                            <input type="text" name="email" id="loginEmail" class="form-control" placeholder="Enter email or username" required autocomplete="off" onfocus="this.removeAttribute('readonly')" readonly>
                        </div>
                    </div>
                    <div class="mb-2">
                        <label class="form-label fw-bold">Password</label>
                        <div class="input-group">
                            <span class="input-group-text bg-light"><i class="bi bi-lock"></i></span>
                            <input type="password" name="password" id="loginPassword" class="form-control" placeholder="Enter your password" required autocomplete="off">
                            
                            <button class="btn btn-outline-secondary" type="button" onclick="togglePassword('loginPassword', this)">
                                <i class="bi bi-eye"></i>
                            </button>
                        </div>
                    </div>
                    <div class="d-flex justify-content-between mb-3">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" id="rememberMe">
                            <label class="form-check-label" style="font-size:13px;" for="rememberMe">Remember me</label>
                        </div>
                        <a href="#" class="text-primary" style="font-size:13px;">Forgot password?</a>
                    </div>
                    <div id="loginError" class="alert alert-danger py-2 mb-3" style="display:none; font-size:13px;">
                        <i class="bi bi-x-circle-fill"></i> <span id="loginErrorText">Invalid email or password.</span>
                    </div>
                    <button type="submit" class="btn btn-primary w-100 fw-bold py-2">
                        <i class="bi bi-box-arrow-in-right"></i> Login
                    </button>
                </form>

                <p class="text-center mt-3 mb-0" style="font-size:14px;">
                    Don't have an account?
                    <a href="#" class="fw-bold text-primary" data-bs-dismiss="modal" data-bs-toggle="modal" data-bs-target="#registerModal">Register here</a>
                </p>
            </div>
        </div>
    </div>
</div>


<!-- REGISTER MODAL -->
<div class="modal fade" id="registerModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content rounded-4">
            <div class="modal-header border-0 pb-0">
                <h5 class="modal-title fw-bold">
                    <i class="bi bi-bag-heart-fill text-primary"></i> Create a ShopEasy Account
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body px-4 pb-4">

                <!-- LOADING OVERLAY -->
                <div id="loadingOverlay" style="display:none; position:absolute; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.85); z-index:999; border-radius:16px; flex-direction:column; align-items:center; justify-content:center;">
                    <div class="spinner-border text-primary mb-2" role="status" style="width:3rem; height:3rem;">
                        <span class="visually-hidden">Loading...</span>
                    </div>
                    <p class="fw-bold text-primary mb-0" id="loadingText">Loading...</p>
                </div>

                <form action="RegisterServlet" method="post" id="registerForm">
                <!-- ACCOUNT TYPE SELECTOR -->
                <p class="fw-bold mb-2">Select Account Type:</p>
                <div class="row g-2 mb-3">
                    <div class="col-6">
                        <div class="account-type-card border rounded-3 p-3 text-center" id="customerCard" onclick="selectTypeWithMessage('customer', 'Setting up Customer account...')" style="cursor:pointer; border-color:#0d6efd !important; background:#e8f0fe;">
                            <i class="bi bi-person-fill fs-3 text-primary"></i>
                            <p class="mb-0 fw-bold mt-1">Customer</p>
                            <small class="text-muted">I want to shop</small>
                        </div>
                    </div>
                    <div class="col-6">
                        <div class="account-type-card border rounded-3 p-3 text-center" id="sellerCard" onclick="selectTypeWithMessage('seller', 'Setting up Business account...')" style="cursor:pointer;">
                            <i class="bi bi-shop fs-3 text-secondary"></i>
                            <p class="mb-0 fw-bold mt-1">Business / Seller</p>
                            <small class="text-muted">I want to sell</small>
                        </div>
                    </div>
                </div>

                <!-- SHARED FIELDS -->
                <div class="row g-2">
                    <div class="col-md-6">
                        <label class="form-label fw-bold">Full Name</label>
                        <input type="text" name="fullname" class="form-control" placeholder="Enter your full name" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold">Username</label>
                        <input type="text" name="username" class="form-control" placeholder="Choose a username" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold">Email</label>
                        <input type="email" name="email" class="form-control" placeholder="Enter your email" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold">Phone Number</label>
                        <div class="input-group">
                            <span class="input-group-text">+63</span>
                            <input type="tel" name="phone" class="form-control" placeholder="9XX XXX XXXX" required>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold">Password</label>
                        <div class="input-group">
    <input type="password" name="password" id="regPassword" class="form-control" placeholder="Create a password" required>
    <button class="btn btn-outline-secondary" type="button" onclick="togglePassword('regPassword', this)">
        <i class="bi bi-eye"></i>
    </button>
</div>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold">Confirm Password</label>
                        <div class="input-group">
    <input type="password" id="confirmPassword" class="form-control" placeholder="Repeat your password">
    <button class="btn btn-outline-secondary" type="button" onclick="togglePassword('confirmPassword', this)">
        <i class="bi bi-eye"></i>
    </button>
</div>
                    </div>
                </div>

                <!-- SELLER EXTRA FIELDS -->
                <div id="sellerFields" style="display:none;">
                    <hr>
                    <p class="fw-bold mb-2"><i class="bi bi-shop text-primary"></i> Business Information</p>
                    <div class="row g-2">
                        <div class="col-md-6">
                            <label class="form-label fw-bold">Business Name</label>
                            <input type="text" name="businessName" class="form-control" placeholder="Enter your business name">
                        </div>
                        <div class="col-md-6">
                            <label class="form-label fw-bold">Business Type</label>
                            <select name="businessType" class="form-select">
                                <option value="">Select type</option>
                                <option>Retail</option>
                                <option>Wholesale</option>
                                <option>Food & Beverage</option>
                                <option>Fashion & Apparel</option>
                                <option>Electronics</option>
                                <option>Others</option>
                            </select>
                        </div>
                        <div class="col-12">
                            <label class="form-label fw-bold">Business Address</label>
                            <input type="text" name="businessAddress" class="form-control" placeholder="Enter your business address">
                        </div>
                    </div>
                </div>

                <div class="mt-3">
                    <div class="form-check mb-3">
                        <input class="form-check-input" type="checkbox" id="agreeTerms" required>
                        <label class="form-check-label" for="agreeTerms" style="font-size:13px;">
                            I agree to the <a href="#" class="text-primary">Terms and Conditions</a> and <a href="#" class="text-primary">Privacy Policy</a>
                        </label>
                    </div>
                    <input type="hidden" name="accountType" id="accountTypeInput" value="customer">
                    <button type="submit" class="btn btn-primary w-100 fw-bold py-2">
                        <i class="bi bi-person-check"></i> Create Account
                    </button>
                </div>
                </form>

                <hr>
                <p class="text-center fw-bold mb-2" style="font-size:13px;">Or sign up with</p>
                <div class="row g-2">
                    <div class="col-6">
                        <button class="btn btn-outline-danger w-100" type="button">
                            <i class="bi bi-google"></i> Google
                        </button>
                    </div>
                    <div class="col-6">
                        <button class="btn w-100 d-flex align-items-center justify-content-center gap-2" type="button" style="background:#1877F2; color:white; border:none; transition:0.3s;" onmouseover="this.style.background='#1558b0'" onmouseout="this.style.background='#1877F2'">
                            <i class="bi bi-facebook"></i> Facebook
                        </button>
                    </div>
                </div>

                <p class="text-center mt-3 mb-0" style="font-size:14px;">
                    Already have an account? 
                    <a href="#" class="fw-bold text-primary" data-bs-dismiss="modal" data-bs-toggle="modal" data-bs-target="#loginModal">Login here</a>
                </p>
            </div>
        </div>
    </div>
</div>

<!-- LOGIN LOADING OVERLAY -->
<div id="loginLoadingOverlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.95); z-index:9999; flex-direction:column; align-items:center; justify-content:center;">
    <div class="spinner-border text-primary mb-3" style="width:3.5rem; height:3.5rem;" role="status"></div>
    <p class="fw-bold text-primary fs-5">Logging in...</p>
    <p class="text-muted" style="font-size:13px;">Please wait a moment</p>
</div>

<!-- REGISTER LOADING OVERLAY -->
<div id="registerLoadingOverlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.95); z-index:9999; flex-direction:column; align-items:center; justify-content:center;">
    <div class="spinner-border text-primary mb-3" style="width:3.5rem; height:3.5rem;" role="status"></div>
    <p class="fw-bold text-primary fs-5">Creating Account...</p>
    <p class="text-muted" style="font-size:13px;">Please wait a moment</p>
</div>

<!-- LOGOUT OVERLAY -->
<div id="logoutOverlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(255,255,255,0.9); z-index:9999; flex-direction:column; align-items:center; justify-content:center;">
    <div class="spinner-border text-primary mb-3" style="width:3rem; height:3rem;" role="status"></div>
    <p class="fw-bold text-primary fs-5">Logging out...</p>
</div>

<script>
function togglePassword(fieldId, btn) {
    const field = document.getElementById(fieldId);
    const icon = btn.querySelector('i');
    if (field.type === 'password') {
        field.type = 'text';
        icon.className = 'bi bi-eye-slash';
    } else {
        field.type = 'password';
        icon.className = 'bi bi-eye';
    }
}

function selectTypeWithMessage(type, message) {
    const customerCard = document.getElementById('customerCard');
    const sellerCard = document.getElementById('sellerCard');
    const sellerFields = document.getElementById('sellerFields');
    const overlay = document.getElementById('loadingOverlay');
    const loadingText = document.getElementById('loadingText');
    loadingText.textContent = message;
    overlay.style.display = 'flex';
    setTimeout(() => {
        if (type === 'customer') {
            customerCard.style.background = '#e8f0fe';
            customerCard.style.borderColor = '#0d6efd';
            customerCard.querySelector('i').className = 'bi bi-person-fill fs-3 text-primary';
            sellerCard.style.background = 'white';
            sellerCard.style.borderColor = '#dee2e6';
            sellerCard.querySelector('i').className = 'bi bi-shop fs-3 text-secondary';
            sellerFields.style.display = 'none';
            document.getElementById('accountTypeInput').value = 'customer';
        } else {
            sellerCard.style.background = '#e8f0fe';
            sellerCard.style.borderColor = '#0d6efd';
            sellerCard.querySelector('i').className = 'bi bi-shop fs-3 text-primary';
            customerCard.style.background = 'white';
            customerCard.style.borderColor = '#dee2e6';
            customerCard.querySelector('i').className = 'bi bi-person-fill fs-3 text-secondary';
            sellerFields.style.display = 'block';
            document.getElementById('accountTypeInput').value = 'seller';
        }
        overlay.style.display = 'none';
    }, 800);
}

function handleLoginSubmit(e, form) {
    e.preventDefault();
    var modal = bootstrap.Modal.getInstance(document.getElementById('loginModal'));
    if (modal) modal.hide();
    setTimeout(() => {
        document.getElementById('loginLoadingOverlay').style.display = 'flex';
        setTimeout(() => { form.submit(); }, 1500);
    }, 300);
    return false;
}
</script>