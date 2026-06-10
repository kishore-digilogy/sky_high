import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sky_high/core/services/localization_service.dart';

class AboutUsSection extends StatelessWidget {
  const AboutUsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationService();
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 800;

    return Container(
      width: double.infinity,
      color: const Color(0xFFF9F9FB), // Light gray background behind the card
      // Increased bottom padding to 110 to clear the floating bottom nav bar completely
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.6)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.03),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40 : 24,
              vertical: 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left brand and description section
                      Expanded(
                        flex: 4,
                        child: _buildBrandSection(context, l10n),
                      ),
                      const SizedBox(width: 60),
                      // Right link and contact columns
                      Expanded(
                        flex: 5,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildCompanyColumn(l10n),
                            _buildContactColumn(l10n),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  // Mobile stack layout
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBrandSection(context, l10n),
                      const SizedBox(height: 32),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 40,
                        runSpacing: 32,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: _buildCompanyColumn(l10n),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: _buildContactColumn(l10n),
                          ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 40),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 30),
                // Bottom Copyright & Links
                if (isDesktop)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.tr('copyright_text'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          _buildBottomLink('Privacy Policy'),
                          _buildBottomSeparator(),
                          _buildBottomLink('Terms of Service'),
                          _buildBottomSeparator(),
                          _buildBottomLink('Cookies Settings'),
                        ],
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tr('copyright_text'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _buildBottomLink('Privacy Policy'),
                          _buildBottomLink('Terms of Service'),
                          _buildBottomLink('Cookies Settings'),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandSection(BuildContext context, LocalizationService l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand logo
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Color(0xFF6366F1),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E293B),
                  letterSpacing: 1.0,
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
          ],
        ),
        const SizedBox(height: 16),
        // Description
        Text(
          l10n.tr('about_platform_desc'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        // Social icons
        Row(
          children: [
            _buildSocialIcon(Icons.facebook_rounded),
            const SizedBox(width: 8),
            _buildSocialIcon(Icons.camera_alt_outlined), // Instagram
            const SizedBox(width: 8),
            _buildSocialIcon(Icons.business_center_rounded), // LinkedIn
            const SizedBox(width: 8),
            _buildSocialIcon(Icons.play_arrow_rounded), // YouTube
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Icon(
        icon,
        size: 18,
        color: const Color(0xFF64748B),
      ),
    );
  }

  Widget _buildCompanyColumn(LocalizationService l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Company',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        // About Us Link with Indigo Theme
        _buildCompanyLink(
          l10n.tr('about_us'),
          Icons.info_outline_rounded,
          const Color(0xFF6366F1),
        ),
        // Terms & Conditions with Amber Theme
        _buildCompanyLink(
          'Terms & Conditions',
          Icons.description_outlined,
          const Color(0xFFF59E0B),
        ),
        // Privacy Policy with Emerald Theme
        _buildCompanyLink(
          'Privacy Policy',
          Icons.security_outlined,
          const Color(0xFF10B981),
        ),
        // Cookies Settings with Pink Theme
        _buildCompanyLink(
          'Cookies settings',
          Icons.cookie_outlined,
          const Color(0xFFEC4899),
        ),
      ],
    );
  }

  Widget _buildCompanyLink(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 15,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactColumn(LocalizationService l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        _buildContactItem(
          Icons.alternate_email_rounded,
          l10n.tr('email'),
          'support@skyhigh.com',
        ),
        const SizedBox(height: 14),
        _buildContactItem(
          Icons.phone_rounded,
          l10n.tr('call'),
          '+91 98765 43210',
        ),
        const SizedBox(height: 14),
        _buildContactItem(
          Icons.location_on_rounded,
          l10n.tr('address'),
          'Delhi, India',
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 14,
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomLink(String text) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF64748B),
          decoration: TextDecoration.underline,
          decorationColor: const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  Widget _buildBottomSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: 4,
        height: 4,
        decoration: const BoxDecoration(
          color: Color(0xFFCBD5E1),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
