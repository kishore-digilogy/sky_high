import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sky_high/data/models/testimonial_model.dart';

class TestimonialCard extends StatelessWidget {
  final TestimonialModel testimonial;
  final int index;

  const TestimonialCard({
    super.key,
    required this.testimonial,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, Color>> themes = [
      {'bg': const Color(0xFFFEE2E2), 'text': const Color(0xFFEF4444)}, // Red
      {'bg': const Color(0xFFDBEAFE), 'text': const Color(0xFF3B82F6)}, // Blue
      {'bg': const Color(0xFFDCFCE7), 'text': const Color(0xFF22C55E)}, // Green
    ];
    final theme = themes[index % themes.length];

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 20, bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: index % 2 == 0
              ? Colors.transparent
              : const Color(0xFF6366F1).withOpacity(0.15),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: theme['bg'],
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  testimonial.userName.isNotEmpty
                      ? testimonial.userName[0].toUpperCase()
                      : 'U',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: theme['text'],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testimonial.userName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: i < testimonial.stars
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFE2E8F0),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.format_quote_rounded,
                size: 24,
                color: theme['text']!.withOpacity(0.2),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            testimonial.content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF475569),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (index % 2 == 0)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.thumb_up_rounded,
                    size: 12,
                    color: Color(0xFF6366F1),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sentiment_satisfied_alt_rounded,
                    size: 12,
                    color: Color(0xFF22C55E),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().scale(
      delay: (index * 100).ms,
      duration: 400.ms,
      curve: Curves.easeOutBack,
    );
  }
}
