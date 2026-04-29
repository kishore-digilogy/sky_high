import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _fathersNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _educationController = TextEditingController();
  final _languagesController = TextEditingController();
  final _communityController = TextEditingController();

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
        _dobController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
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
            _buildPricingCard().animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
            const SizedBox(height: 40),

            // Form Fields
            _buildLabel('Father\'s Name', isRequired: true).animate().fadeIn(delay: 300.ms),
            _buildTextField(
              controller: _fathersNameController,
              hintText: 'Father\'s Name',
              prefixIcon: Icons.person_outline_rounded,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),

            _buildLabel('Date of Birth', isRequired: true).animate().fadeIn(delay: 400.ms),
            _buildTextField(
              controller: _dobController,
              hintText: 'dd/mm/yyyy',
              suffixIcon: Icons.calendar_today_outlined,
              readOnly: true,
              onTap: () => _selectDate(context),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 24),

            _buildLabel('Educational Qualification', isRequired: true).animate().fadeIn(delay: 500.ms),
            _buildTextField(
              controller: _educationController,
              hintText: 'Educational Qualification',
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 24),

            _buildLabel('Languages Known', isRequired: true).animate().fadeIn(delay: 600.ms),
            _buildTextField(
              controller: _languagesController,
              hintText: 'Languages Known',
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 24),

            _buildLabel('Community (Optional)', isRequired: false).animate().fadeIn(delay: 700.ms),
            _buildTextField(
              controller: _communityController,
              hintText: 'Community (Optional)',
            ).animate().fadeIn(delay: 700.ms),

            const SizedBox(height: 40),
            
            // Payment Button
            _buildPaymentButton().animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),

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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BASE AMOUNT',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '₹1,000',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GST (18%)',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '₹180',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TOTAL AMOUNT',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '1,180',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Lifetime Access — One Time Payment',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {required bool isRequired}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: RichText(
        text: TextSpan(
          text: isRequired ? '* ' : '',
          style: GoogleFonts.inter(
            color: const Color(0xFFEF4444),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(
              text: text,
              style: GoogleFonts.inter(
                color: const Color(0xFF1E293B),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
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
              ? Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 20)
              : null,
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, color: const Color(0xFF1E293B), size: 20)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    return GestureDetector(
      onTap: () {
        // Handle Payment Gateway Here
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.credit_card_outlined, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(
              'Proceed to Payment — ₹1,180',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
        Row(
          children: [
            const Icon(Icons.verified_user_outlined, color: Color(0xFF64748B), size: 14),
            const SizedBox(width: 6),
            Text(
              'SAFE & SECURE PAYMENT',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Row(
          children: [
            const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 14),
            const SizedBox(width: 6),
            Text(
              'SSL ENCRYPTED',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
