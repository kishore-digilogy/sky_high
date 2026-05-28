import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sky_high/core/services/notification_service.dart';
import 'package:sky_high/core/services/localization_service.dart';
import 'package:sky_high/core/utils/localization_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();
  final LocalizationService _l10n = LocalizationService();
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  String _selectedUrgency = 'all';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading =
          _notifications.isEmpty; // Only show full screen loader first time
    });
    final notifications = await _notificationService.getActiveNotifications();
    if (mounted) {
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredNotifications {
    if (_selectedUrgency == 'all') {
      return _notifications;
    }
    return _notifications.where((notif) {
      final urgency = notif['urgency']?.toString().toLowerCase() ?? 'medium';
      return urgency == _selectedUrgency;
    }).toList();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return '';

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final localTime = parsed.toLocal();
    final day = localTime.day.toString().padLeft(2, '0');
    final monthStr = months[localTime.month - 1];
    final year = localTime.year;

    final hour24 = localTime.hour;
    final amPm = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minuteStr = localTime.minute.toString().padLeft(2, '0');

    return '$day $monthStr $year at $hour12:$minuteStr $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _l10n.tr('notifications'),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                _buildFilterChips(),
                Expanded(
                  child: filtered.isEmpty
                      ? _buildFilteredEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadNotifications,
                          color: const Color(0xFF00897B),
                          backgroundColor: Colors.white,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final notif =
                                  filtered[index] as Map<String, dynamic>;

                              final title = LocalizationHelper.getLocalized(
                                notif,
                                'title',
                              );
                              final description =
                                  LocalizationHelper.getLocalized(
                                    notif,
                                    'description',
                                  );
                              final examName = LocalizationHelper.getLocalized(
                                notif,
                                'exam_name',
                              );
                              final categoryName =
                                  notif['category_name']?.toString() ?? '';
                              final subcategoryName =
                                  notif['subcategory_name']?.toString() ?? '';
                              final companyName =
                                  notif['company_name']?.toString() ?? '';
                              final dateRange = LocalizationHelper.getLocalized(
                                notif,
                                'date_range',
                              );
                              final urgency =
                                  notif['urgency']?.toString().toLowerCase() ??
                                  'medium';
                              final createdAt = notif['created_at']?.toString();
                              final totalVacancy = notif['total_vacancy']
                                  ?.toString();
                              final isJob =
                                  notif['job_id'] != null ||
                                  (totalVacancy != null &&
                                      totalVacancy.isNotEmpty);

                              // Design attributes based on type / urgency
                              Color themeColor;
                              Color bgLight;
                              IconData iconData;

                              if (isJob) {
                                themeColor = const Color(
                                  0xFF10B981,
                                ); // Emerald Green
                                bgLight = const Color(0xFFECFDF5);
                                iconData = Icons.work_outline_rounded;
                              } else {
                                switch (urgency) {
                                  case 'high':
                                    themeColor = const Color(0xFFEF4444); // Red
                                    bgLight = const Color(0xFFFEF2F2);
                                    iconData = Icons.campaign_rounded;
                                    break;
                                  case 'low':
                                    themeColor = const Color(
                                      0xFF6C63FF,
                                    ); // Blue/Indigo
                                    bgLight = const Color(0xFFEEF2FF);
                                    iconData = Icons.notifications_rounded;
                                    break;
                                  case 'medium':
                                  default:
                                    themeColor = const Color(
                                      0xFFF59E0B,
                                    ); // Amber
                                    bgLight = const Color(0xFFFFFBEB);
                                    iconData =
                                        Icons.notifications_active_rounded;
                                    break;
                                }
                              }

                              return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFF1F5F9),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF0F172A,
                                          ).withOpacity(0.02),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Beautiful status icon
                                        Container(
                                          height: 48,
                                          width: 48,
                                          decoration: BoxDecoration(
                                            color: bgLight,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: Icon(
                                            iconData,
                                            color: themeColor,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Title
                                              Text(
                                                title.isNotEmpty
                                                    ? title
                                                    : '${_l10n.tr('notification')} ${index + 1}',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(
                                                    0xFF1E293B,
                                                  ),
                                                  height: 1.3,
                                                ),
                                              ),

                                              // Description (if present)
                                              if (description.isNotEmpty) ...[
                                                const SizedBox(height: 6),
                                                Text(
                                                  description,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    color: const Color(
                                                      0xFF475569,
                                                    ),
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],

                                              // Date range or timestamp
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.access_time_rounded,
                                                    size: 12,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _formatDate(createdAt),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: const Color(
                                                        0xFF94A3B8,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              // Tags section (Wrap for pills)
                                              if (isJob ||
                                                  examName.isNotEmpty ||
                                                  companyName.isNotEmpty ||
                                                  categoryName.isNotEmpty ||
                                                  subcategoryName.isNotEmpty ||
                                                  dateRange.isNotEmpty) ...[
                                                const SizedBox(height: 12),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    // Job tag
                                                    if (isJob &&
                                                        totalVacancy != null &&
                                                        totalVacancy.isNotEmpty)
                                                      _buildBadge(
                                                        '💼 $totalVacancy Vacancies',
                                                        const Color(0xFF10B981),
                                                        const Color(0xFFECFDF5),
                                                      ),
                                                    // Date range tag
                                                    if (dateRange.isNotEmpty)
                                                      _buildBadge(
                                                        '📅 $dateRange',
                                                        const Color(0xFFF59E0B),
                                                        const Color(0xFFFFFBEB),
                                                      ),
                                                    // Exam Name tag
                                                    if (examName.isNotEmpty)
                                                      _buildBadge(
                                                        '🎓 $examName',
                                                        const Color(0xFF6C63FF),
                                                        const Color(0xFFEEF2FF),
                                                      ),
                                                    // Company Name tag
                                                    if (companyName.isNotEmpty)
                                                      _buildBadge(
                                                        '🏢 $companyName',
                                                        const Color(0xFF475569),
                                                        const Color(0xFFF1F5F9),
                                                      ),
                                                    // Category Name tag
                                                    if (categoryName.isNotEmpty)
                                                      _buildBadge(
                                                        '🏷️ $categoryName',
                                                        const Color(0xFF0D9488),
                                                        const Color(0xFFF0FDFA),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(
                                    delay: (index * 80).ms,
                                    duration: 400.ms,
                                  )
                                  .slideY(begin: 0.05, curve: Curves.easeOut);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'high', 'label': 'High'},
      {'key': 'medium', 'label': 'Medium'},
      {'key': 'low', 'label': 'Low'},
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final key = filter['key']!;
          final label = filter['label']!;
          final isSelected = _selectedUrgency == key;

          Color activeColor;
          Color activeBg;
          switch (key) {
            case 'high':
              activeColor = const Color(0xFFEF4444);
              activeBg = const Color(0xFFFEF2F2);
              break;
            case 'low':
              activeColor = const Color(0xFF6C63FF);
              activeBg = const Color(0xFFEEF2FF);
              break;
            case 'medium':
              activeColor = const Color(0xFFF59E0B);
              activeBg = const Color(0xFFFFFBEB);
              break;
            default:
              activeColor = const Color(0xFF00897B);
              activeBg = const Color(0xFFE0F2F1);
              break;
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedUrgency = key;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected ? activeBg : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? activeColor.withOpacity(0.3)
                      : const Color(0xFFF1F5F9),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? activeColor : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadge(String label, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFilteredEmptyState() {
    final capitalized =
        _selectedUrgency[0].toUpperCase() + _selectedUrgency.substring(1);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.filter_list_off_rounded,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No $capitalized Urgency Notifications',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting another filter level above',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 72,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _l10n.tr('no_active_notifications'),
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
