import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/core/services/payment_service.dart';
import 'package:sky_high/core/services/api_service.dart';
import 'dart:async';
import 'package:sky_high/core/services/localization_service.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const LoginDialog(),
    );
  }

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _isOtpLogin = true;
  Timer? _resendTimer;
  int _resendSeconds = 0;
  bool _obscurePassword = true;
  final LocalizationService _l10n = LocalizationService();

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _resendSeconds = 60);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        _resendTimer?.cancel();
      }
    });
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar(_l10n.tr('enter_email'));
      return;
    }

    // Save email to local storage for suggestions
    await GetIt.I<StorageService>().saveEmail(_emailController.text);

    if (_isOtpLogin) {
      if (!_otpSent) {
        await _sendOtp();
      } else {
        await _verifyOtpAndLogin();
      }
    } else {
      if (_passwordController.text.isEmpty) {
        _showSnackBar(_l10n.tr('enter_password'));
        return;
      }
      await _loginWithPassword();
    }
  }

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);
    try {
      final dio = ApiService().dio;
      await dio.post(
        '${ApiService.baseUrl}/auth/send-otp',
        data: {'email': _emailController.text.trim()},
      );
      setState(() {
        _otpSent = true;
        _isLoading = false;
      });
      _startResendTimer();
      _showSnackBar(_l10n.tr('otp_sent_success'));
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(_l10n.tr('otp_send_failed'));
    }
  }

  Future<void> _verifyOtpAndLogin() async {
    if (_otpController.text.isEmpty) {
      _showSnackBar(_l10n.tr('enter_otp'));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final dio = ApiService().dio;
      // Step 1: Verify OTP
      final response = await dio.post(
        '${ApiService.baseUrl}/auth/verify-otp',
        data: {
          'email': _emailController.text.trim(),
          'otp': _otpController.text.trim(),
          'device_fingerprint': 'SkyHighApp_Mobile_Client_v1.0',
        },
      );

      if (response.statusCode == 200) {
        final verifyData = response.data;
        final resetToken = verifyData['resetToken'];

        if (resetToken != null) {
          // Step 2: Login with OTP using the resetToken
          final loginResponse = await dio.post(
            '${ApiService.baseUrl}/auth/login-with-otp',
            data: {
              'email': _emailController.text.trim(),
              'resetToken': resetToken,
              'device_fingerprint': 'SkyHighApp_Mobile_Client_v1.0',
            },
          );

          if (loginResponse.statusCode == 200) {
            final data = loginResponse.data;
            _finalizeLogin(data['token'], data['user']);
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(_l10n.tr('invalid_otp_failed'));
    }
  }

  Future<void> _loginWithPassword() async {
    setState(() => _isLoading = true);
    try {
      final dio = ApiService().dio;
      final response = await dio.post(
        '${ApiService.baseUrl}/auth/login',
        data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        _finalizeLogin(response.data['token'], response.data['user']);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(_l10n.tr('invalid_credentials'));
    }
  }

  Future<void> _finalizeLogin(String? token, dynamic user) async {
    if (token != null) {
      final storage = GetIt.I<StorageService>();
      await storage.setToken(token);
      if (user != null) {
        await storage.setUserData(user);
      }
      PaymentService().checkAndVerifyPendingPayment();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF0F172A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with Title and Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Login to Continue',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Please sign in to your account to access free exams and track your progress.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Login Method Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildMethodTab(
                        _l10n.tr('otp_login'),
                        _isOtpLogin,
                        () {
                          setState(() {
                            _isOtpLogin = true;
                            _otpSent = false;
                          });
                        },
                      ),
                      _buildMethodTab(
                        _l10n.tr('password_tab'),
                        !_isOtpLogin,
                        () {
                          setState(() {
                            _isOtpLogin = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Email field with Autocomplete
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: RawAutocomplete<String>(
                    textEditingController: _emailController,
                    focusNode: _emailFocusNode,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final storage = GetIt.I<StorageService>();
                      final List<String> saved = storage.getSavedEmails();
                      if (textEditingValue.text.isEmpty) {
                        return saved;
                      }
                      return saved.where(
                        (email) => email.contains(
                          textEditingValue.text.toLowerCase(),
                        ),
                      );
                    },
                    onSelected: (String selection) {
                      _emailController.text = selection;
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 8.0,
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          child: Container(
                            width: 320,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.history_rounded,
                                          color: Color(0xFF94A3B8),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            option,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: const Color(0xFF0F172A),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    fieldViewBuilder: (
                      context,
                      controller,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0F172A),
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: _l10n.tr('email_address'),
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 15,
                          ),
                          prefixIcon: const Icon(
                            Icons.alternate_email_rounded,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Password or OTP field
                if (_isOtpLogin && _otpSent) ...[
                  _buildModernInput(
                    controller: _otpController,
                    hint: _l10n.tr('otp_hint'),
                    icon: Icons.security_rounded,
                    keyboardType: TextInputType.number,
                  ).animate().fadeIn().slideY(begin: 0.1),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _resendSeconds == 0 ? _sendOtp : null,
                      child: Text(
                        _resendSeconds > 0
                            ? "${_l10n.tr('resend_otp_in')} ${_resendSeconds}s"
                            : _l10n.tr('resend_otp'),
                        style: GoogleFonts.inter(
                          color: _resendSeconds > 0
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF3B82F6),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(),
                ] else if (!_isOtpLogin)
                  _buildModernInput(
                    controller: _passwordController,
                    hint: _l10n.tr('password_hint'),
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                  ).animate().fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 24),

                // Main Action Button
                GestureDetector(
                  onTap: _isLoading ? null : _handleLogin,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF3B82F6),
                          Color(0xFF2563EB),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isOtpLogin
                                ? (_otpSent
                                    ? _l10n.tr('activate_session')
                                    : _l10n.tr('get_otp_code'))
                                : _l10n.tr('sign_in'),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodTab(String title, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF94A3B8),
            fontSize: 15,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
