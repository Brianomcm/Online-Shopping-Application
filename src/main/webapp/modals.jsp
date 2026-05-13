<%
    String preErr   = request.getParameter("error") != null ? request.getParameter("error") : "";
    String preEmail = ("email_taken".equals(preErr)) ? "" : (request.getParameter("em") != null ? request.getParameter("em") : "");
    String prePhone = ("phone_taken".equals(preErr)) ? "" : (request.getParameter("ph") != null ? request.getParameter("ph") : "");
    String preUn    = ("username_taken".equals(preErr)) ? "" : (request.getParameter("un") != null ? request.getParameter("un") : "");
    String preFn    = request.getParameter("fn") != null ? request.getParameter("fn") : "";
    String preLn    = request.getParameter("ln") != null ? request.getParameter("ln") : "";
    String preMi    = request.getParameter("mi") != null ? request.getParameter("mi") : "";
%>
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
                       <button class="btn btn-outline-danger w-100 d-flex align-items-center justify-content-center gap-2" type="button" onclick="showComingSoon()" style="transition:0.3s;" onmouseover="this.style.background='#EA4335'; this.style.color='white';" onmouseout="this.style.background='white'; this.style.color='#EA4335';">  
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
                       
                      <button class="btn w-100 d-flex align-items-center justify-content-center gap-2" type="button" onclick="showComingSoon()" style="background:#1877F2; color:white; border:none; transition:0.3s;" onmouseover="this.style.background='#1558b0'" onmouseout="this.style.background='#1877F2'">
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
                       <a href="#" class="text-primary" style="font-size:13px;" data-bs-dismiss="modal" data-bs-toggle="modal" data-bs-target="#forgotPasswordModal">Forgot password?</a>
                    </div>
                    <div id="loginError" class="alert alert-danger py-2 mb-3" style="display:none; font-size:13px;">
                        <i class="bi bi-x-circle-fill"></i> <span id="loginErrorText">Invalid email or password.</span>
                    </div>
                  <button type="submit" id="loginSubmitBtn" class="btn btn-primary w-100 fw-bold py-2">
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

              

                <form action="RegisterServlet" method="post" id="registerForm">
                <!-- ACCOUNT TYPE SELECTOR -->
                <p class="fw-bold mb-2">Create Your Account</p>
                <div class="mb-3">
                    <div class="border rounded-3 p-3 text-center" style="border-color:#0d6efd !important; background:#e8f0fe;">
                        <i class="bi bi-person-fill fs-3 text-primary"></i>
                        <p class="mb-0 fw-bold mt-1">Customer Account</p>
                        <small class="text-muted">Start shopping and explore products. You can become a seller anytime later.</small>
                    </div>
                </div>

                <!-- SHARED FIELDS -->
                <div class="row g-2">
            <div class="col-md-5">
                        <label class="form-label fw-bold">Last Name</label>
                        <input type="text" name="last_name" class="form-control" placeholder="Dela Cruz" required value="<%= preLn %>">
                    </div>
                    <div class="col-md-5">
                        <label class="form-label fw-bold">First Name</label>
                        <input type="text" name="first_name" class="form-control" placeholder="Juan" required value="<%= preFn %>">
                    </div>
                    <div class="col-md-2">
                        <label class="form-label fw-bold">M.I. <small class="text-muted fw-normal">(optional)</small></label>
                        <input type="text" name="middle_initial" class="form-control" placeholder="A." maxlength="2" value="<%= preMi %>">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold">Username</label>
                        <input type="text" name="username" class="form-control" placeholder="Choose a username" required value="<%= preUn %>">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-bold">Email</label>
                  <input type="email" name="email" id="regEmail" class="form-control" placeholder="Enter your email" required oninput="validateEmail(this)" onkeyup="autoFillGmail(this, event)" autocomplete="off" value="<%= preEmail %>">
<div id="regEmailError" class="invalid-feedback" style="display:none; font-size:11px;"></div>
                    </div>
  <div class="col-md-4">
                        <label class="form-label fw-bold">Phone Number</label>
                        <div class="input-group">
                            <span class="input-group-text">+63</span>
                            <input type="tel" name="phone" id="regPhone" class="form-control" placeholder="9XX XXX XXXX" required maxlength="10" oninput="formatPHPhone(this)" value="<%= prePhone %>">
                        </div>
                        <div id="regPhoneError" class="invalid-feedback" style="display:none; font-size:11px;">
                            First digit must be 9 (e.g. 9171234567)
                        </div>
                    </div>
<div class="col-md-4">
                        <label class="form-label fw-bold">Password</label>
                        <div class="input-group">
                            <input type="password" name="password" id="regPassword" class="form-control" placeholder="Create a password" required oninput="checkPasswordStrength(this.value)">
                            <button class="btn btn-outline-secondary" type="button" onclick="togglePassword('regPassword', this)">
                                <i class="bi bi-eye"></i>
                            </button>
                        </div>
                        <div id="passStrengthWrap" class="mt-1 px-1">
                            <div class="progress" style="height:5px; border-radius:4px;">
                                <div id="passStrengthBar" class="progress-bar" style="width:0%; transition:0.3s;"></div>
                            </div>
                            <small id="passStrengthText" style="font-size:11px;"></small>
                        </div>
                    </div>
    <div class="col-md-4">
                        <label class="form-label fw-bold">Confirm Password</label>
                        <div class="input-group">
                            <input type="password" id="confirmPassword" class="form-control" placeholder="Repeat your password">
                            <button class="btn btn-outline-secondary" type="button" onclick="togglePassword('confirmPassword', this)">
                                <i class="bi bi-eye"></i>
                            </button>
                        </div>
                        <div id="regValidationError" class="alert alert-danger py-2 mt-2" style="display:none; font-size:13px;"></div>
                    </div>
                </div>


                <div class="mt-3">
                    <div class="form-check mb-3">
                        <input class="form-check-input" type="checkbox" id="agreeTerms" required disabled>
                        <label class="form-check-label" for="agreeTerms" style="font-size:13px;">
I agree to the <a href="#" class="text-primary" data-bs-toggle="modal" data-bs-target="#termsPrivacyModal">Terms and Conditions & Privacy Policy</a>
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
                 <button class="btn btn-outline-danger w-100" type="button" onclick="showComingSoon()">
    <i class="bi bi-google"></i> Google
</button>
                    </div>
                    <div class="col-6">
               <button class="btn w-100 d-flex align-items-center justify-content-center gap-2" type="button" onclick="showComingSoon()" style="background:#1877F2; color:white; border:none; transition:0.3s;" onmouseover="this.style.background='#1558b0'" onmouseout="this.style.background='#1877F2'">
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


<!-- FORGOT PASSWORD MODAL -->
<div class="modal fade" id="forgotPasswordModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered" style="max-width:420px;">
        <div class="modal-content rounded-4">
            <div class="modal-header border-0 pb-0">
                <h5 class="modal-title fw-bold">
                    <i class="bi bi-shield-lock-fill text-primary"></i> Reset Password
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body px-4 pb-4">

                <!-- STEP 1: Verify Identity -->
                <div id="forgotStep1">
                    <p class="text-muted mb-3" style="font-size:13px;">Enter your email and username to verify your identity.</p>
                    <div class="mb-3">
                        <label class="form-label fw-bold">Email</label>
                        <div class="input-group">
                            <span class="input-group-text bg-light"><i class="bi bi-envelope"></i></span>
                          <input type="email" id="forgotEmail" class="form-control" placeholder="Enter your email" autocomplete="new-password">
                        </div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-bold">Username</label>
                        <div class="input-group">
                            <span class="input-group-text bg-light"><i class="bi bi-person"></i></span>
                          <input type="text" id="forgotUsername" class="form-control" placeholder="Enter your username" autocomplete="new-password">
                        </div>
                    </div>
                    <div id="forgotError" class="alert alert-danger py-2 mb-3" style="display:none; font-size:13px;">
                        <i class="bi bi-x-circle-fill"></i> <span id="forgotErrorText">Email or username not found.</span>
                    </div>
                    <button class="btn btn-primary w-100 fw-bold py-2" id="verifyBtn" onclick="verifyForgotIdentity()">
                        <i class="bi bi-search"></i> Verify Identity
                    </button>
                </div>

                <!-- STEP 2: Set New Password -->
                <div id="forgotStep2" style="display:none;">
                    <div class="alert alert-success py-2 mb-3" style="font-size:13px;">
                        <i class="bi bi-check-circle-fill"></i> Identity verified! Set your new password.
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-bold">New Password</label>
                        <div class="input-group">
                            <span class="input-group-text bg-light"><i class="bi bi-lock"></i></span>
                            <input type="password" id="forgotNewPass" class="form-control" placeholder="Enter new password">
                            <button class="btn btn-outline-secondary" type="button" onclick="togglePassword('forgotNewPass', this)"><i class="bi bi-eye"></i></button>
                        </div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-bold">Confirm New Password</label>
                        <div class="input-group">
                            <span class="input-group-text bg-light"><i class="bi bi-lock"></i></span>
                            <input type="password" id="forgotConfirmPass" class="form-control" placeholder="Confirm new password">
                            <button class="btn btn-outline-secondary" type="button" onclick="togglePassword('forgotConfirmPass', this)"><i class="bi bi-eye"></i></button>
                        </div>
                    </div>
                    <div id="forgotPassError" class="alert alert-danger py-2 mb-3" style="display:none; font-size:13px;">
                        <i class="bi bi-x-circle-fill"></i> <span id="forgotPassErrorText">Passwords do not match.</span>
                    </div>
                    <button class="btn btn-success w-100 fw-bold py-2" onclick="submitForgotPassword()">
                        <i class="bi bi-shield-check"></i> Update Password
                    </button>
                </div>

                <!-- STEP 3: Success -->
                <div id="forgotStep3" style="display:none;">
                    <div class="text-center py-3">
                        <i class="bi bi-check-circle-fill text-success" style="font-size:3rem;"></i>
                        <h5 class="fw-bold mt-3">Password Updated!</h5>
                        <p class="text-muted" style="font-size:13px;">Your password has been successfully reset.</p>
                        <button class="btn btn-primary w-100 fw-bold" data-bs-dismiss="modal" data-bs-toggle="modal" data-bs-target="#loginModal">
                            <i class="bi bi-box-arrow-in-right"></i> Back to Login
                        </button>
                    </div>
                </div>

            </div>
        </div>
    </div>
</div>

<!-- TERMS & PRIVACY COMBINED MODAL -->
<div class="modal fade" id="termsPrivacyModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content rounded-4">
            <div class="modal-header border-0">
                <h5 class="modal-title fw-bold"><i class="bi bi-file-text-fill text-primary"></i> Terms & Privacy Policy</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body px-4">
                <!-- TABS -->
                <ul class="nav nav-tabs mb-3" id="termsPrivacyTabs">
                    <li class="nav-item">
                        <button class="nav-link active fw-bold" id="terms-tab" data-bs-toggle="tab" data-bs-target="#termsContent">
                            <i class="bi bi-file-text me-1"></i> Terms and Conditions
                        </button>
                    </li>
                    <li class="nav-item">
                        <button class="nav-link fw-bold" id="privacy-tab" data-bs-toggle="tab" data-bs-target="#privacyContent">
                            <i class="bi bi-shield-check me-1"></i> Privacy Policy
                        </button>
                    </li>
                </ul>
                <div class="tab-content" style="max-height:55vh; overflow-y:auto;">
                    <!-- TERMS TAB -->
                    <div class="tab-pane fade show active" id="termsContent">
                        <p class="text-muted" style="font-size:13px;">Last updated: May 2025</p>
                        <h6 class="fw-bold">1. Acceptance of Terms</h6>
                        <p style="font-size:13px;">By accessing and using ShopEasy, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use our platform.</p>
                        <h6 class="fw-bold">2. User Accounts</h6>
                        <p style="font-size:13px;">You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.</p>
                        <h6 class="fw-bold">3. Products and Services</h6>
                        <p style="font-size:13px;">ShopEasy serves as a platform connecting buyers and sellers. We do not guarantee the quality, safety, or legality of items advertised.</p>
                        <h6 class="fw-bold">4. Orders and Payments</h6>
                        <p style="font-size:13px;">All orders are subject to availability. Prices are subject to change without notice. Payment must be completed before orders are processed.</p>
                        <h6 class="fw-bold">5. Returns and Refunds</h6>
                        <p style="font-size:13px;">Refund requests must be submitted within 7 days of receiving the item. Items must be in original condition. Shipping costs for returns are the buyer's responsibility.</p>
                        <h6 class="fw-bold">6. Prohibited Activities</h6>
                        <p style="font-size:13px;">Users must not engage in fraudulent activities, post false information, or violate any applicable laws while using ShopEasy.</p>
                        <h6 class="fw-bold">7. Limitation of Liability</h6>
                        <p style="font-size:13px;">ShopEasy shall not be liable for any indirect, incidental, or consequential damages arising from the use of our platform.</p>
                        <h6 class="fw-bold">8. Changes to Terms</h6>
                        <p style="font-size:13px;">We reserve the right to modify these terms at any time. Continued use of ShopEasy after changes constitutes acceptance of the new terms.</p>
                    </div>
                    <!-- PRIVACY TAB -->
                    <div class="tab-pane fade" id="privacyContent">
                        <p class="text-muted" style="font-size:13px;">Last updated: May 2025</p>
                        <h6 class="fw-bold">1. Information We Collect</h6>
                        <p style="font-size:13px;">We collect information you provide when creating an account, such as your name, email address, phone number, and password.</p>
                        <h6 class="fw-bold">2. How We Use Your Information</h6>
                        <p style="font-size:13px;">Your information is used to process orders, provide customer support, send important updates, and improve our services.</p>
                        <h6 class="fw-bold">3. Information Sharing</h6>
                        <p style="font-size:13px;">We do not sell or rent your personal information to third parties. We may share information with sellers only as necessary to fulfill your orders.</p>
                        <h6 class="fw-bold">4. Data Security</h6>
                        <p style="font-size:13px;">We implement appropriate security measures to protect your personal information from unauthorized access, alteration, or disclosure.</p>
                        <h6 class="fw-bold">5. Cookies</h6>
                        <p style="font-size:13px;">ShopEasy uses cookies to enhance your browsing experience. You may disable cookies in your browser settings, but some features may not function properly.</p>
                        <h6 class="fw-bold">6. Your Rights</h6>
                        <p style="font-size:13px;">You have the right to access, correct, or delete your personal information at any time through your account settings.</p>
                        <h6 class="fw-bold">7. Contact Us</h6>
                        <p style="font-size:13px;">If you have questions about this Privacy Policy, please contact us at support@shopeasy.com.</p>
                    </div>
                </div>
            </div>
            <div class="modal-footer border-0">
                <button type="button" class="btn btn-primary px-4" onclick="acceptTermsPrivacy()">
                    <i class="bi bi-check-circle"></i> I Understand & Agree
                </button>
            </div>
        </div>
    </div>
</div>
<script>
document.getElementById('forgotPasswordModal').addEventListener('shown.bs.modal', function() {
    setTimeout(() => {
        document.getElementById('forgotEmail').value = '';
        document.getElementById('forgotUsername').value = '';
        document.getElementById('forgotNewPass').value = '';
        document.getElementById('forgotConfirmPass').value = '';
    }, 500);
    document.getElementById('forgotError').style.display = 'none';
    document.getElementById('forgotPassError').style.display = 'none';
    document.getElementById('forgotStep1').style.display = 'block';
    document.getElementById('forgotStep2').style.display = 'none';
    document.getElementById('forgotStep3').style.display = 'none';
});

function verifyForgotIdentity() {
        const email = document.getElementById('forgotEmail').value.trim();
        const username = document.getElementById('forgotUsername').value.trim();
        if (!email || !username) {
            document.getElementById('forgotErrorText').textContent = 'Please fill in all fields.';
            document.getElementById('forgotError').style.display = 'block';
            return;
        }

        // Show loading
        const btn = document.getElementById('verifyBtn');
        btn.disabled = true;
        btn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span> Finding your account...';
        document.getElementById('forgotError').style.display = 'none';

        setTimeout(() => {
            fetch('ForgotPasswordServlet', {
                method: 'POST',
                headers: {'Content-Type': 'application/x-www-form-urlencoded'},
                body: 'action=verify&email=' + encodeURIComponent(email) + '&username=' + encodeURIComponent(username)
            })
            .then(r => r.json())
            .then(data => {
                btn.disabled = false;
                btn.innerHTML = '<i class="bi bi-search"></i> Verify Identity';
                if (data.success) {
                    document.getElementById('forgotError').style.display = 'none';
                    document.getElementById('forgotStep1').style.display = 'none';
                    document.getElementById('forgotStep2').style.display = 'block';
                } else {
                    document.getElementById('forgotErrorText').textContent = data.message || 'Email or username not found.';
                    document.getElementById('forgotError').style.display = 'block';
                }
            })
            .catch(() => {
                btn.disabled = false;
                btn.innerHTML = '<i class="bi bi-search"></i> Verify Identity';
                document.getElementById('forgotErrorText').textContent = 'Server error. Please try again.';
                document.getElementById('forgotError').style.display = 'block';
            });
        }, 1500);
    }

function submitForgotPassword() {
    const email = document.getElementById('forgotEmail').value.trim();
    const newPass = document.getElementById('forgotNewPass').value;
    const confirmPass = document.getElementById('forgotConfirmPass').value;
    if (newPass !== confirmPass) {
        document.getElementById('forgotPassErrorText').textContent = 'Passwords do not match.';
        document.getElementById('forgotPassError').style.display = 'block';
        return;
    }
    if (newPass.length < 6) {
        document.getElementById('forgotPassErrorText').textContent = 'Password must be at least 6 characters.';
        document.getElementById('forgotPassError').style.display = 'block';
        return;
    }
    fetch('ForgotPasswordServlet', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'action=reset&email=' + encodeURIComponent(email) + '&newPassword=' + encodeURIComponent(newPass)
    })
    .then(r => r.json())
    .then(data => {
        if (data.success) {
            document.getElementById('forgotStep2').style.display = 'none';
            document.getElementById('forgotStep3').style.display = 'block';
        } else {
            document.getElementById('forgotPassErrorText').textContent = data.message || 'Failed to update password.';
            document.getElementById('forgotPassError').style.display = 'block';
        }
    })
    .catch(() => {
        document.getElementById('forgotPassErrorText').textContent = 'Server error. Please try again.';
        document.getElementById('forgotPassError').style.display = 'block';
    });
}
</script>
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



function handleLoginSubmit(e, form) {
    e.preventDefault();
    // Save guest cart to hidden field before submitting
    const guestCart = localStorage.getItem('guestCart') || '[]';
    let cartInput = document.getElementById('guestCartInput');
    if (!cartInput) {
        cartInput = document.createElement('input');
        cartInput.type = 'hidden';
        cartInput.name = 'guestCart';
        cartInput.id = 'guestCartInput';
        form.appendChild(cartInput);
    }
    cartInput.value = guestCart;

    var modal = bootstrap.Modal.getInstance(document.getElementById('loginModal'));
    if (modal) modal.hide();
    setTimeout(() => {
        document.getElementById('loginLoadingOverlay').style.display = 'flex';
        setTimeout(() => { form.submit(); }, 1500);
    }, 300);
    return false;
}

</script>

<script>
function acceptTermsPrivacy() {
    const modal = bootstrap.Modal.getInstance(document.getElementById('termsPrivacyModal'));
    if (modal) modal.hide();
    document.getElementById('termsPrivacyModal').addEventListener('hidden.bs.modal', function handler() {
        document.getElementById('termsPrivacyModal').removeEventListener('hidden.bs.modal', handler);
        new bootstrap.Modal(document.getElementById('registerModal')).show();
        const checkbox = document.getElementById('agreeTerms');
        checkbox.disabled = false;
        checkbox.checked = true;
    });
}

function checkPasswordStrength(val) {
    const bar = document.getElementById('passStrengthBar');
    const text = document.getElementById('passStrengthText');
    if (!bar) return;
    let score = 0;
    if (val.length >= 4) score++;
    if (val.length >= 8) score++;
    if (/[A-Z]/.test(val)) score++;
    if (/[0-9]/.test(val)) score++;
    if (/[^A-Za-z0-9]/.test(val)) score++;

    const submitBtn = document.querySelector('#registerForm button[type="submit"]');

    if (val.length === 0) {
        bar.style.width = '0%'; bar.className = 'progress-bar';
        text.textContent = '';
        if (submitBtn) { submitBtn.disabled = true; submitBtn.title = ''; }
    } else if (score <= 2) {
        bar.style.width = '33%'; bar.className = 'progress-bar bg-danger';
        text.innerHTML = '<span class="text-danger">Weak - password too simple</span>';
        if (submitBtn) { submitBtn.disabled = true; submitBtn.title = 'Password is too weak'; }
    } else if (score === 3) {
        bar.style.width = '66%'; bar.className = 'progress-bar bg-warning';
        text.innerHTML = '<span class="text-warning">Medium - acceptable but could be stronger</span>';
        if (submitBtn) { submitBtn.disabled = false; }
    } else {
        bar.style.width = '100%'; bar.className = 'progress-bar bg-success';
        text.innerHTML = '<span class="text-success">Strong - great password!</span>';
        if (submitBtn) { submitBtn.disabled = false; }
    }
}

function autoFillGmail(input, e) {
    const val = input.value;
    const atIndex = val.indexOf('@');
    if (atIndex !== -1 && val.length === atIndex + 1) {
        // Just typed @, auto-suggest gmail.com
        const suggestion = val + 'gmail.com';
        input.value = suggestion;
        // Select only "gmail.com" part so they can overwrite if gusto nila
        input.setSelectionRange(atIndex + 1, suggestion.length);
    }
}

function validateEmail(input) {
    const val = input.value.trim();
    const err = document.getElementById('regEmailError');
    const allowed = ['@gmail.com', '@yahoo.com', '@outlook.com', '@hotmail.com', '@icloud.com'];
    const hasFullDomain = allowed.some(domain => val.toLowerCase().endsWith(domain));
    const valid = hasFullDomain && val.indexOf('@') > 0;
    // Only show error if they finished typing (not still typing after @)
    const stillTyping = val.includes('@') && !val.includes('.', val.indexOf('@'));
    if (val.length > 0 && !valid && !stillTyping) {
        input.classList.add('is-invalid');
        if (err) { err.style.display = 'block'; err.textContent = 'Please use a valid email (e.g. @gmail.com, @yahoo.com)'; }
    } else {
        input.classList.remove('is-invalid');
        if (err) err.style.display = 'none';
    }
}

function formatPHPhone(input) {
    let val = input.value.replace(/\D/g, ''); // remove non-digits
    if (val.startsWith('0')) val = val.substring(1); // remove leading 0
    if (val.length > 10) val = val.substring(0, 10); // max 10 digits
    input.value = val;

    const err = document.getElementById('regPhoneError');
    if (val.length > 0 && !val.startsWith('9')) {
        input.classList.add('is-invalid');
        if (err) err.style.display = 'block';
    } else {
        input.classList.remove('is-invalid');
        if (err) err.style.display = 'none';
    }
}

function showComingSoon() {
    const toast = document.createElement('div');
    toast.style.cssText = 'position:fixed; top:20px; left:50%; transform:translateX(-50%); background:#1a1a2e; color:white; padding:12px 28px; border-radius:12px; font-size:14px; font-weight:600; z-index:99999; box-shadow:0 4px 16px rgba(0,0,0,0.2);';
    toast.innerHTML = '<i class="bi bi-clock me-2"></i>Social login coming soon!';
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 2500);
}

//── Show register modal + error on redirect back ──
window.addEventListener('DOMContentLoaded', function() {
    const params = new URLSearchParams(window.location.search);
    const err = params.get('error');
    if (err === 'email_taken' || err === 'username_taken' || err === 'phone_taken') {
        const msg = err === 'email_taken'
            ? 'Email is already registered. Please use a different email.'
            : err === 'username_taken'
            ? 'Username is already taken. Please choose another.'
            : 'Phone number is already registered. Please use a different number.';
        const regModal = new bootstrap.Modal(document.getElementById('registerModal'));
        regModal.show();
        setTimeout(function() {
            const cb = document.getElementById('agreeTerms');
            if (cb) { cb.disabled = false; cb.checked = false; }
            let errDiv = document.getElementById('regDupeError');
            if (!errDiv) {
                errDiv = document.createElement('div');
                errDiv.id = 'regDupeError';
                errDiv.className = 'alert alert-danger py-2 px-3 mb-2';
                errDiv.style.fontSize = '13px';
                const form = document.getElementById('registerForm');
                form.prepend(errDiv);
            }
            errDiv.innerHTML = '<i class="bi bi-exclamation-circle me-1"></i>' + msg;
        }, 600);
    }
});
</script>

<!-- ===== SELLER BLOCKED MODAL (no birthday / underage) ===== -->
<div class="modal fade" id="sellerBlockedModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content rounded-4 border-0 shadow">
            <div class="modal-body text-center p-4">
                <div class="mb-3" style="width:64px; height:64px; border-radius:50%; background:#fee2e2; display:flex; align-items:center; justify-content:center; margin:0 auto;">
    <i class="bi bi-x-lg" style="font-size:28px; color:#dc3545;"></i>
</div>
                <h5 class="fw-bold mb-2">Not Eligible</h5>
                <p class="text-muted mb-4" style="font-size:14px;">
                    You must be <strong>18 years old or above</strong> to become a seller.<br>
                    Please come back when you meet the age requirement.
                </p>
                <button type="button" class="btn btn-primary rounded-pill px-4"
                        data-bs-dismiss="modal">Okay</button>
            </div>
        </div>
    </div>
</div>