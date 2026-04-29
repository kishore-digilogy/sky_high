import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class ExamDetailPage extends StatelessWidget {
  final Map<String, dynamic> exam;
  const ExamDetailPage({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExamMeta(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('About the Exam'),
                  const SizedBox(height: 10),
                  _buildDescription(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Syllabus Overview'),
                  const SizedBox(height: 15),
                  _buildSyllabusList(),
                  const SizedBox(height: 40),
                  _buildEnrollButton(context),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: exam['color'] as Color,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (exam['color'] as Color).withOpacity(0.8),
                    exam['color'] as Color,
                  ],
                ),
              ),
            ),
            Center(
              child: Icon(
                exam['icon'] as IconData,
                size: 80,
                color: Colors.white.withOpacity(0.2),
              ),
            ).animate().scale(duration: 1.seconds),
            Positioned(
              bottom: 40,
              left: 25,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam['title'] as String,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Target Year: 2026',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
          ],
        ),
      ),
    );
  }

  Widget _buildExamMeta() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetaItem(Icons.timer_outlined, '180 mins', 'Duration'),
        _buildMetaItem(Icons.help_outline_rounded, '100 Qs', 'Questions'),
        _buildMetaItem(Icons.star_outline_rounded, '4.8/5', 'Rating'),
      ],
    );
  }

  Widget _buildMetaItem(IconData icon, String val, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 20),
        const SizedBox(height: 8),
        Text(
          val,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      'This exam is conducted for recruitment to various civil services of the Government of India, including the IAS, IFS, and IPS. It is widely considered one of the most prestigious and difficult competitive examinations in the country.',
      style: GoogleFonts.outfit(
        fontSize: 15,
        color: const Color(0xFF64748B),
        height: 1.6,
      ),
    );
  }

  Widget _buildSyllabusList() {
    final topics = ['General Studies', 'CSAT', 'History & Culture', 'Geography', 'Economy'];
    return Column(
      children: topics.map((topic) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 15),
            Text(
              topic,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildEnrollButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Starting enrollment process...')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: Text(
          'Start Preparation',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).scale();
  }
}
