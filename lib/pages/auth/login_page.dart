import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/pages/dashboard/dashboard_page.dart';
import 'dart:math' as math;
import 'dart:async';

class LoginPage extends StatefulWidget {
  final bool returnToPreviousPage;
  const LoginPage({super.key, this.returnToPreviousPage = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpLogin = true;
  bool _otpSent = false;
  bool _obscurePassword = true;
  Timer? _resendTimer;
  int _resendSeconds = 0;

  @override
  void dispose() {
    _emailController.dispose();
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
      _showSnackBar('Please enter your email');
      return;
    }

    if (_isOtpLogin) {
      if (!_otpSent) {
        await _sendOtp();
      } else {
        await _verifyOtpAndLogin();
      }
    } else {
      if (_passwordController.text.isEmpty) {
        _showSnackBar('Please enter your password');
        return;
      }
      await _loginWithPassword();
    }
  }

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);
    try {
      final dio = Dio();
      await dio.post(
        'https://skyhighapi.digilogy.dev/api/auth/send-otp',
        data: {'email': _emailController.text.trim()},
      );
      setState(() {
        _otpSent = true;
        _isLoading = false;
      });
      _startResendTimer();
      _showSnackBar('OTP sent to your email');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to send OTP. Please check your email.');
    }
  }

  Future<void> _verifyOtpAndLogin() async {
    if (_otpController.text.isEmpty) {
      _showSnackBar('Please enter the OTP');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final dio = Dio();
      // Step 1: Verify OTP
      final response = await dio.post(
        'https://skyhighapi.digilogy.dev/api/auth/verify-otp',
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
            'https://skyhighapi.digilogy.dev/api/auth/login-with-otp',
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
      _showSnackBar('Invalid OTP or login failed');
    }
  }

  Future<void> _loginWithPassword() async {
    setState(() => _isLoading = true);
    try {
      final dio = Dio();
      final response = await dio.post(
        'https://skyhighapi.digilogy.dev/api/auth/login',
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
      _showSnackBar('Invalid email or password');
    }
  }

  Future<void> _finalizeLogin(String? token, dynamic user) async {
    if (token != null) {
      final storage = GetIt.I<StorageService>();
      await storage.setToken(token);
      if (user != null) {
        await storage.setUserData(user);
      }
      if (mounted) {
        if (widget.returnToPreviousPage) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardPage()),
          );
        }
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Subtle Light Background Orbs
          const _LightBackground(),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.08),

                      // Premium Logo Icon
                      Container(
                        width: screenWidth * 0.25,
                        height: screenWidth * 0.25,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.05),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: const Color(0xFFF9A826),
                          size: screenWidth * 0.12,
                        ),
                      ).animate().scale(
                        duration: 800.ms,
                        curve: Curves.easeInOut,
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      Text(
                        'Sky High Elite',
                        style: GoogleFonts.inter(
                          fontSize: screenWidth * 0.085,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                      SizedBox(height: screenHeight * 0.01),

                      Text(
                        'Access your premium learning journey',
                        style: GoogleFonts.inter(
                          fontSize: screenWidth * 0.038,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                      SizedBox(height: screenHeight * 0.06),

                      // Login Method Toggle
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            _buildMethodTab('OTP LOGIN', _isOtpLogin, () {
                              setState(() {
                                _isOtpLogin = true;
                                _otpSent = false;
                              });
                            }),
                            _buildMethodTab('PASSWORD', !_isOtpLogin, () {
                              setState(() {
                                _isOtpLogin = false;
                              });
                            }),
                          ],
                        ),
                      ).animate().fadeIn(delay: 600.ms),

                      SizedBox(height: screenHeight * 0.04),

                      // Form Section
                      Column(
                        children: [
                          _buildModernInput(
                            controller: _emailController,
                            hint: 'Email Address',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          if (_isOtpLogin && _otpSent) ...[
                            _buildModernInput(
                              controller: _otpController,
                              hint: '6-digit OTP Code',
                              icon: Icons.security_rounded,
                              keyboardType: TextInputType.number,
                            ).animate().fadeIn().slideY(begin: 0.1),
                            SizedBox(height: screenHeight * 0.015),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: _resendSeconds == 0 ? _sendOtp : null,
                                child: Text(
                                  _resendSeconds > 0
                                      ? "Resend OTP in ${_resendSeconds}s"
                                      : "Resend OTP",
                                  style: GoogleFonts.inter(
                                    color: _resendSeconds > 0
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF3B82F6),
                                    fontWeight: FontWeight.w700,
                                    fontSize: screenWidth * 0.035,
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 200.ms),
                          ] else if (!_isOtpLogin)
                            _buildModernInput(
                              controller: _passwordController,
                              hint: 'Password',
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                            ).animate().fadeIn().slideY(begin: 0.1),
                        ],
                      ).animate().fadeIn(delay: 800.ms),

                      SizedBox(height: screenHeight * 0.05),

                      // Main Action Button
                      GestureDetector(
                        onTap: _isLoading ? null : _handleLogin,
                        child: Container(
                          height: screenHeight * 0.078,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  _isOtpLogin
                                      ? (_otpSent
                                            ? 'ACTIVATE SESSION'
                                            : 'GET OTP CODE')
                                      : 'SIGN IN',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.042,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ).animate().fadeIn(delay: 1.seconds).slideY(begin: 0.2),

                      SizedBox(height: screenHeight * 0.04),

                      // Alternative Action
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8),
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              "Create Profile",
                              style: GoogleFonts.inter(
                                color: const Color(0xFFF9A826),
                                fontWeight: FontWeight.w700,
                                fontSize: screenWidth * 0.038,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 1.2.seconds),

                      SizedBox(height: screenHeight * 0.06),
                    ],
                  ),
                );
              },
            ),
          ),

          // Floating Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF0F172A),
                  size: 18,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.5),
        ],
      ),
    );
  }

  Widget _buildMethodTab(String title, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.5,
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
            vertical: 20,
          ),
        ),
      ),
    );
  }
}

class _LightBackground extends StatelessWidget {
  const _LightBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Subtle Blue Glow 1
        Positioned(
          top: -100,
          right: -50,
          child:
              Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF3B82F6).withOpacity(0.05),
                          const Color(0xFF3B82F6).withOpacity(0),
                        ],
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .moveY(
                    begin: -20,
                    end: 20,
                    duration: 6.seconds,
                    curve: Curves.easeInOut,
                  ),
        ),

        // Subtle Indigo Glow 2
        Positioned(
          bottom: 100,
          left: -100,
          child:
              Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.03),
                          const Color(0xFF6366F1).withOpacity(0),
                        ],
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .moveX(
                    begin: -30,
                    end: 30,
                    duration: 8.seconds,
                    curve: Curves.easeInOut,
                  ),
        ),
      ],
    );
  }
}
