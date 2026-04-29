import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sky_high/pages/exams/exam_detail_page.dart';

class ExamListPage extends StatefulWidget {
  final String categoryName;
  const ExamListPage({super.key, required this.categoryName});

  @override
  State<ExamListPage> createState() => _ExamListPageState();
}

class _ExamListPageState extends State<ExamListPage> {
  final List<Map<String, dynamic>> _exams = [
    {
      'title': 'UPSC Civil Services 2026',
      'date': 'June 15, 2026',
      'difficulty': 'Hard',
      'icon': Icons.account_balance,
      'color': const Color(0xFF6366F1),
    },
    {
      'title': 'SSC CGL Tier 1',
      'date': 'July 20, 2026',
      'difficulty': 'Medium',
      'icon': Icons.assignment,
      'color': const Color(0xFFEC4899),
    },
    {
      'title': 'IBPS PO Prelims',
      'date': 'August 05, 2026',
      'difficulty': 'Medium',
      'icon': Icons.account_balance_wallet,
      'color': const Color(0xFFF59E0B),
    },
    {
      'title': 'RRB NTPC Phase 1',
      'date': 'September 12, 2026',
      'difficulty': 'Easy',
      'icon': Icons.train,
      'color': const Color(0xFF10B981),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _exams.length,
        itemBuilder: (context, index) {
          final exam = _exams[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExamDetailPage(exam: exam),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: (exam['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(exam['icon'] as IconData, color: exam['color'] as Color),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam['title'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                            const SizedBox(width: 5),
                            Text(
                              exam['date'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (exam['color'] as Color).withOpacity(0.05),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                exam['difficulty'] as String,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: exam['color'] as Color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFE2E8F0)),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1);
        },
      ),
    );
  }
}
