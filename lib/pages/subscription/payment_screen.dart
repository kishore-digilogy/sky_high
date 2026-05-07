import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/pages/auth/login_page.dart';
import 'package:dio/dio.dart';
import 'package:sky_high/pages/dashboard/dashboard_page.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:confetti/confetti.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _communityController = TextEditingController();
  final _fathersNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _educationController = TextEditingController();
  final _languagesController = TextEditingController();

  late Razorpay _razorpay;
  late ConfettiController _confettiController;
  bool _isProcessing = false;
  String? _currentOrderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    _confettiController.dispose();
    _fathersNameController.dispose();
    _dobController.dispose();
    _educationController.dispose();
    _languagesController.dispose();
    _communityController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _verifyPayment(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isProcessing = false);
    _showStatusScreen(
      success: false,
      message: response.message ?? "Payment Failed",
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Optional: Handle external wallet
  }

  Future<void> _verifyPayment(PaymentSuccessResponse response) async {
    setState(() => _isProcessing = true);

    // Format DOB to YYYY-MM-DD
    String dobFormatted = "";
    if (_dobController.text.isNotEmpty) {
      final parts = _dobController.text.split('/');
      if (parts.length == 3) {
        dobFormatted = "${parts[2]}-${parts[1]}-${parts[0]}";
      }
    }

    final payload = {
      "razorpay_order_id": _currentOrderId ?? response.orderId ?? "",
      "razorpay_payment_id": response.paymentId ?? "",
      "razorpay_signature": response.signature ?? "",
      "user_details": {
        "father_name": _fathersNameController.text.trim(),
        "dob": dobFormatted,
        "qualification": _educationController.text.trim(),
        "languages_known": _languagesController.text.trim(),
      },
    };

    debugPrint("--- VERIFY PAYMENT START ---");
    debugPrint("URL: https://skyhighapi.digilogy.dev/api/payment/verify");
    debugPrint("Payload: $payload");

    try {
      final dio = Dio();
      final token = GetIt.I<StorageService>().getToken();

      final apiResponse = await dio.post(
        'https://skyhighapi.digilogy.dev/api/payment/verify',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint("Verify Response Status: ${apiResponse.statusCode}");
      debugPrint("Verify Response Data: ${apiResponse.data}");

      if (apiResponse.statusCode == 200 &&
          apiResponse.data['success'] == true) {
        // Refresh local user data if needed
        final storage = GetIt.I<StorageService>();
        final userData = storage.getUserData();
        if (userData != null) {
          userData['subscription_status'] = 'paid';
          await storage.setUserData(userData);
        }

        _showStatusScreen(success: true);
      } else {
        _showStatusScreen(
          success: false,
          message: "Verification failed. Please contact support.",
        );
      }
    } catch (e) {
      debugPrint("--- VERIFY PAYMENT ERROR ---");
      if (e is DioException) {
        debugPrint("Verify Error Status: ${e.response?.statusCode}");
        debugPrint("Verify Error Data: ${e.response?.data}");
        debugPrint("Verify Error Message: ${e.message}");
      } else {
        debugPrint("General Verify Error: $e");
      }
      _showStatusScreen(success: false, message: "Error verifying payment: $e");
    } finally {
      debugPrint("--- VERIFY PAYMENT END ---");
      setState(() => _isProcessing = false);
    }
  }

  void _showStatusScreen({required bool success, String? message}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentStatusScreen(
          success: success,
          message: message,
          confettiController: _confettiController,
        ),
      ),
    );
  }

  Future<void> _startPayment() async {
    if (_fathersNameController.text.isEmpty ||
        _dobController.text.isEmpty ||
        _educationController.text.isEmpty ||
        _languagesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final dio = Dio();
      final token = GetIt.I<StorageService>().getToken();
      final receiptId = "receipt_${DateTime.now().millisecondsSinceEpoch}";

      final orderResponse = await dio.post(
        'https://skyhighapi.digilogy.dev/api/payment/create-order',
        data: {'amount': 1180, 'currency': 'INR', 'receipt': receiptId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (orderResponse.statusCode == 200) {
        _currentOrderId = orderResponse.data['id'];
        final razorpayAmount = orderResponse.data['amount'];
        final userData = GetIt.I<StorageService>().getUserData();

        final options = {
          'key': 'rzp_test_SDCzPYcvdghetb',
          'amount': razorpayAmount,
          'name': 'Sky High Elite',
          'description': 'One Year Access — Annual Payment',
          'prefill': {
            'contact': userData?['phone'] ?? '',
            'email': userData?['email'] ?? '',
          },
          'external': {
            'wallets': ['paytm'],
          },
        };
        _razorpay.open(options);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      debugPrint('Error starting Razorpay: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB), // Blue
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBFD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Text(
              'Upgrade to Elite',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
            const SizedBox(height: 8),
            Text(
              'Join the elite circle of top performers',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1),
            const SizedBox(height: 32),

            // Pricing Card
            _buildPricingCard()
                .animate()
                .fadeIn(delay: 200.ms)
                .scale(begin: const Offset(0.95, 0.95)),
            const SizedBox(height: 40),

            // Form Fields
            _buildLabel(
              'Father\'s Name',
              isRequired: true,
            ).animate().fadeIn(delay: 300.ms),
            _buildTextField(
              controller: _fathersNameController,
              hintText: 'Father\'s Name',
              prefixIcon: Icons.person_outline_rounded,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),

            _buildLabel(
              'Date of Birth',
              isRequired: true,
            ).animate().fadeIn(delay: 400.ms),
            _buildTextField(
              controller: _dobController,
              hintText: 'dd/mm/yyyy',
              suffixIcon: Icons.calendar_today_outlined,
              readOnly: true,
              onTap: () => _selectDate(context),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 24),

            _buildLabel(
              'Educational Qualification',
              isRequired: true,
            ).animate().fadeIn(delay: 500.ms),
            _buildTextField(
              controller: _educationController,
              hintText: 'Educational Qualification',
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 24),

            _buildLabel(
              'Languages Known',
              isRequired: true,
            ).animate().fadeIn(delay: 600.ms),
            _buildTextField(
              controller: _languagesController,
              hintText: 'Languages Known',
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 24),

            _buildLabel(
              'Community (Optional)',
              isRequired: false,
            ).animate().fadeIn(delay: 700.ms),
            _buildTextField(
              controller: _communityController,
              hintText: 'Community (Optional)',
            ).animate().fadeIn(delay: 700.ms),

            const SizedBox(height: 40),

            // Payment Button
            _buildPaymentButton()
                .animate()
                .fadeIn(delay: 800.ms)
                .slideY(begin: 0.2),

            const SizedBox(height: 24),

            // Security Badges
            _buildSecurityBadges().animate().fadeIn(delay: 900.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ELITE ACCESS',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'One Year Membership',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '1,180',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'ANNUAL',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1E3A8A),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white.withOpacity(0.9),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Unlock all premium modules',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {required bool isRequired}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155),
            ),
          ),
          if (isRequired) ...[
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onTap: onTap,
        readOnly: readOnly,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: const Color(0xFF1E293B),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF94A3B8),
            fontSize: 15,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: const Color(0xFF64748B), size: 20)
              : null,
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, color: const Color(0xFF64748B), size: 20)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    return GestureDetector(
      onTap: () {
        final token = GetIt.I<StorageService>().getToken();
        if (token != null && token.isNotEmpty) {
          if (!_isProcessing) {
            _startPayment();
          }
        } else {
          _showLoginDialog(context);
        }
      },
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _isProcessing
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.security_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Complete Payment',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSecurityBadges() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildBadge(Icons.verified_user_rounded, 'SECURE'),
        const SizedBox(width: 24),
        _buildBadge(Icons.lock_rounded, 'SSL'),
        const SizedBox(width: 24),
        _buildBadge(Icons.shield_rounded, 'RAZORPAY'),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF94A3B8), size: 14),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.outfit(
            color: const Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  void _showLoginDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final otpController = TextEditingController();
    bool isLoading = false;
    bool isOtpLogin = false;
    bool otpSent = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFEAEBF0),
            surfaceTintColor: Colors.transparent,
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.only(left: 24, top: 20, right: 16),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Login Required',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF64748B),
                    size: 22,
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Please sign in to proceed with your\npayment.',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: emailController,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: const Color(0xFF1E293B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Email Address',
                      hintStyle: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontSize: 15,
                      ),
                      prefixIcon: const Icon(
                        Icons.mail_outline_rounded,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF94A3B8),
                          width: 0.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF94A3B8),
                          width: 0.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFF9A826),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isOtpLogin)
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: const Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: GoogleFonts.outfit(
                          color: const Color(0xFF64748B),
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF94A3B8),
                            width: 0.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF94A3B8),
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFF9A826),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    )
                  else if (otpSent)
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: const Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter 6-digit OTP',
                        hintStyle: GoogleFonts.outfit(
                          color: const Color(0xFF64748B),
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.security_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF94A3B8),
                            width: 0.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF94A3B8),
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFF9A826),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        isOtpLogin = !isOtpLogin;
                        otpSent = false;
                      });
                    },
                    child: Text(
                      isOtpLogin ? 'Use Password Login' : 'Login with OTP',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFF9A826),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9A826),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (isOtpLogin) {
                                if (otpSent) {
                                  // Verify OTP
                                  if (otpController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please enter the OTP'),
                                      ),
                                    );
                                    return;
                                  }
                                  setDialogState(() => isLoading = true);
                                  try {
                                    final dio = Dio();
                                    final response = await dio.post(
                                      'https://skyhighapi.digilogy.dev/api/auth/verify-otp',
                                      data: {
                                        'email': emailController.text.trim(),
                                        'otp': otpController.text.trim(),
                                        'device_fingerprint':
                                            'SkyHighApp_Mobile_Client_v1.0',
                                      },
                                    );
                                    if (response.statusCode == 200) {
                                      final verifyData = response.data;
                                      final resetToken =
                                          verifyData['resetToken'];

                                      if (resetToken != null) {
                                        // Step 2: Login with OTP using the resetToken
                                        final loginResponse = await dio.post(
                                          'https://skyhighapi.digilogy.dev/api/auth/login-with-otp',
                                          data: {
                                            'email': emailController.text
                                                .trim(),
                                            'resetToken': resetToken,
                                            'device_fingerprint':
                                                'SkyHighApp_Mobile_Client_v1.0',
                                          },
                                        );

                                        if (loginResponse.statusCode == 200) {
                                          final data = loginResponse.data;
                                          final token = data['token'];
                                          final user = data['user'];

                                          if (token != null) {
                                            final storage =
                                                GetIt.I<StorageService>();
                                            await storage.setToken(token);
                                            if (user != null) {
                                              await storage.setUserData(user);
                                            }

                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              setState(() {});
                                            }
                                          }
                                        }
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Invalid OTP or verification failed.',
                                          ),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (context.mounted)
                                      setDialogState(() => isLoading = false);
                                  }
                                } else {
                                  // Send OTP
                                  if (emailController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter your email',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  setDialogState(() => isLoading = true);
                                  try {
                                    final dio = Dio();
                                    await dio.post(
                                      'https://skyhighapi.digilogy.dev/api/auth/send-otp',
                                      data: {
                                        'email': emailController.text.trim(),
                                      },
                                    );
                                    setDialogState(() => otpSent = true);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Failed to send OTP'),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (context.mounted)
                                      setDialogState(() => isLoading = false);
                                  }
                                }
                              } else {
                                // Password Login
                                if (emailController.text.isEmpty ||
                                    passwordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter email and password',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() => isLoading = true);

                                try {
                                  final dio = Dio();
                                  final response = await dio.post(
                                    'https://skyhighapi.digilogy.dev/api/auth/login',
                                    data: {
                                      'email': emailController.text.trim(),
                                      'password': passwordController.text,
                                    },
                                  );

                                  if (response.statusCode == 200) {
                                    final token = response.data['token'];
                                    final user = response.data['user'];

                                    final storage = GetIt.I<StorageService>();
                                    await storage.setToken(token);
                                    await storage.setUserData(user);

                                    if (context.mounted) {
                                      Navigator.pop(context); // Close dialog
                                      setState(
                                        () {},
                                      ); // Refresh PaymentScreen state
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Invalid credentials'),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setDialogState(() => isLoading = false);
                                  }
                                }
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isOtpLogin
                                  ? (otpSent ? 'Verify & Login' : 'Send OTP')
                                  : 'Sign In',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PaymentStatusScreen extends StatefulWidget {
  final bool success;
  final String? message;
  final ConfettiController confettiController;

  const PaymentStatusScreen({
    super.key,
    required this.success,
    this.message,
    required this.confettiController,
  });

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.success) {
      widget.confettiController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Animation
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: widget.success
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFEF4444).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.success
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    size: 80,
                    color: widget.success
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                ),
                const SizedBox(height: 32),

                // Status Text
                Text(
                  widget.success ? 'Payment Successful!' : 'Payment Failed',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                const SizedBox(height: 16),

                Text(
                  widget.success
                      ? 'Welcome to the Elite circle. You now have access to all premium modules for one year.'
                      : (widget.message ??
                            'Something went wrong while processing your payment. Please try again.'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                const SizedBox(height: 48),

                // Primary Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.success) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DashboardPage(),
                          ),
                          (route) => false,
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.success
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.success ? 'Go to Dashboard' : 'Try Again',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

                if (widget.success) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DashboardPage(),
                        ),
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Explore Courses',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ],
            ),
          ),

          // Confetti
          if (widget.success)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: widget.confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                ],
                numberOfParticles: 20,
                gravity: 0.1,
              ),
            ),
        ],
      ),
    );
  }
}
