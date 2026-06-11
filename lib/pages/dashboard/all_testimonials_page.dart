import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sky_high/data/models/testimonial_model.dart';
import 'package:sky_high/pages/dashboard/widgets/testimonials_section.dart';

class AllTestimonialsPage extends StatelessWidget {
  final List<TestimonialModel> testimonials;

  const AllTestimonialsPage({super.key, required this.testimonials});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Student Testimonials',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: testimonials.length,
        itemBuilder: (context, index) {
          final testimonial = testimonials[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: TestimonialCard(testimonial: testimonial, index: index),
          );
        },
      ),
    );
  }
}
