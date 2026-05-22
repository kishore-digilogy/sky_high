import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sky_high/core/services/localization_service.dart';

class AboutUsSection extends StatelessWidget {
  const AboutUsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFFF8FAFF)),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      child: Column(
        children: [
          // Footer Logo
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF6366F1),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E293B),
                    letterSpacing: 1.2,
                  ),
                  children: const [
                    TextSpan(text: 'SKY '),
                    TextSpan(
                      text: 'HIGH',
                      style: TextStyle(color: Color(0xFF6366F1)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tr('about_platform_desc'),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          // Contact Grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildFooterCard(
                context,
                icon: Icons.email_outlined,
                title: l10n.tr('email'),
                subtitle: 'support@skyhigh.com',
                color: const Color(0xFF6366F1),
              ),
              _buildFooterCard(
                context,
                icon: Icons.phone_outlined,
                title: l10n.tr('call'),
                subtitle: '+91 98765 43210',
                color: const Color(0xFF8B5CF6),
              ),
              _buildFooterCard(
                context,
                icon: Icons.location_on_outlined,
                title: l10n.tr('address'),
                subtitle: 'Delhi, India',
                color: const Color(0xFFEC4899),
              ),
              _buildFooterCard(
                context,
                icon: Icons.facebook_rounded,
                title: l10n.tr('facebook'),
                subtitle: '/skyhighlearning',
                color: const Color(0xFF3B82F6),
              ),
            ],
          ),
          const SizedBox(height: 60),
          // Copyright
          Text(
            l10n.tr('copyright_text'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFooterCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 70) / 2,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
