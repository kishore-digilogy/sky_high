import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:sky_high/core/services/storage_service.dart';
import 'package:sky_high/pages/dashboard/dashboard_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import 'dart:math' as math;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

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
        final data = response.data;
        final token = data['token'];
        final user = data['user'];

        final storage = GetIt.I<StorageService>();
        await storage.setToken(token);
        await storage.setUserData(user);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardPage()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Invalid credentials')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      body: Stack(
        children: [
          // Elegant Background Decorations (same as onboarding for consistency)
          const Positioned.fill(child: _BackgroundDecor()),

          SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 100),
                  // Premium Logo Presentation
                  Center(
                    child:
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF9A826).withOpacity(0.1),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: SvgPicture.asset(
                            'assets/Images/app_logo.svg',
                            width: 80,
                            height: 80,
                          ),
                        ).animate().scale(
                          duration: 800.ms,
                          curve: Curves.easeOutBack,
                        ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Welcome Back',
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A2E),
                      letterSpacing: -1,
                    ),
                  ).animate().fadeIn(delay: 200.ms).moveX(begin: -30, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'Elevate your learning experience with SkyHigh.',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.blueGrey[400],
                      fontWeight: FontWeight.w400,
                    ),
                  ).animate().fadeIn(delay: 400.ms).moveX(begin: -20, end: 0),
                  const SizedBox(height: 48),

                  // Login Form
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ).animate().fadeIn(delay: 600.ms).moveY(begin: 30, end: 0),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    onTogglePassword: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ).animate().fadeIn(delay: 800.ms).moveY(begin: 30, end: 0),

                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFF9A826),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 900.ms),

                  const SizedBox(height: 32),
                  // Premium Login Button
                  GestureDetector(
                    onTap: _isLoading ? null : _login,
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF9A826), Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF9A826).withOpacity(0.3),
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
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Sign In',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ).animate().fadeIn(delay: 1.seconds).scale(),

                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.outfit(
                            color: Colors.blueGrey[400],
                            fontSize: 15,
                          ),
                          children: [
                            const TextSpan(text: "Don't have an account? "),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: GestureDetector(
                                onTap: () {},
                                child: Text(
                                  'Join SkyHigh',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFF9A826),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 1.2.seconds),
                ],
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1A1A2E),
                  size: 20,
                ),
              ),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardPage()),
                  );
                }
              },
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isPasswordVisible,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(
          fontSize: 16,
          color: const Color(0xFF1A1A2E),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(
            color: Colors.blueGrey[300],
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFFF9A826), size: 22),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.blueGrey[200],
                    size: 20,
                  ),
                  onPressed: onTogglePassword,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
        ),
      ),
    );
  }
}

// Background Decoration Widget (identical to Onboarding for brand consistency)
class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -50,
          child:
              Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB347).withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .moveX(
                    begin: 0,
                    end: 20,
                    duration: 4.seconds,
                    curve: Curves.easeInOut,
                  )
                  .moveY(
                    begin: 0,
                    end: 20,
                    duration: 5.seconds,
                    curve: Curves.easeInOut,
                  ),
        ),
        Positioned(
          bottom: -150,
          right: -100,
          child:
              Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .moveX(
                    begin: 0,
                    end: -30,
                    duration: 6.seconds,
                    curve: Curves.easeInOut,
                  )
                  .moveY(
                    begin: 0,
                    end: -20,
                    duration: 4.seconds,
                    curve: Curves.easeInOut,
                  ),
        ),
        ...List.generate(15, (index) {
          final random = math.Random(index);
          return Positioned(
                top: random.nextDouble() * 800,
                left: random.nextDouble() * 400,
                child: Icon(
                  Icons.circle,
                  size: random.nextDouble() * 6 + 2,
                  color: Colors.grey.withOpacity(0.08),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(duration: 3.seconds)
              .fadeOut(delay: 3.seconds, duration: 3.seconds);
        }),
      ],
    );
  }
}
