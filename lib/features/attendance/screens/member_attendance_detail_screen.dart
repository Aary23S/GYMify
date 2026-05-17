import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../dummy_data/dummy_attendance.dart';
import '../../members/providers/members_provider.dart';
import '../providers/attendance_provider.dart';

class MemberAttendanceDetailScreen extends ConsumerStatefulWidget {
  final String memberId;

  const MemberAttendanceDetailScreen({super.key, required this.memberId});

  @override
  ConsumerState<MemberAttendanceDetailScreen> createState() => _MemberAttendanceDetailScreenState();
}

class _MemberAttendanceDetailScreenState extends ConsumerState<MemberAttendanceDetailScreen> {
  DateTime _currentMonthView = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final member = ref.watch(memberByIdProvider(widget.memberId));
    final attendanceState = ref.watch(attendanceProvider);

    if (member == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member Attendance')),
        body: const Center(child: Text('Member not found')),
      );
    }

    final allMemberRecords = attendanceState.allRecords.where((r) => r.memberId == widget.memberId).toList();
    final presentDateSet = allMemberRecords.map((r) => DateTime(r.date.year, r.date.month, r.date.day)).toSet();

    final now = DateTime.now();
    final nowDate = DateTime(now.year, now.month, now.day);

    // Calculate this month stats
    final firstOfThisMonth = DateTime(now.year, now.month, 1);
    final daysElapsedThisMonth = nowDate.difference(firstOfThisMonth).inDays + 1;
    final presentThisMonth = presentDateSet.where((d) => d.year == now.year && d.month == now.month && !d.isAfter(nowDate)).length;
    final rateThisMonth = daysElapsedThisMonth > 0 ? ((presentThisMonth / daysElapsedThisMonth) * 100).round() : 100;

    // Calculate this year stats
    final firstOfThisYear = DateTime(now.year, 1, 1);
    final daysElapsedThisYear = nowDate.difference(firstOfThisYear).inDays + 1;
    final presentThisYear = presentDateSet.where((d) => d.year == now.year && !d.isAfter(nowDate)).length;
    final rateThisYear = daysElapsedThisYear > 0 ? ((presentThisYear / daysElapsedThisYear) * 100).round() : 100;

    // Calculate streak
    int streak = 0;
    DateTime checkDate = nowDate;
    while (presentDateSet.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    if (streak == 0) {
      // Check if yesterday was present
      DateTime yesterday = nowDate.subtract(const Duration(days: 1));
      if (presentDateSet.contains(yesterday)) {
        int tempStreak = 1;
        DateTime d = yesterday.subtract(const Duration(days: 1));
        while (presentDateSet.contains(d)) {
          tempStreak++;
          d = d.subtract(const Duration(days: 1));
        }
        streak = tempStreak;
      }
    }

    // Days in currently viewed month
    final firstOfViewMonth = DateTime(_currentMonthView.year, _currentMonthView.month, 1);
    final nextMonth = DateTime(_currentMonthView.year, _currentMonthView.month + 1, 1);
    final daysInViewMonth = nextMonth.subtract(const Duration(days: 1)).day;

    final joinDateOnly = DateTime(member.joinDate.year, member.joinDate.month, member.joinDate.day);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/attendance');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
            Text(member.memberCode, style: AppTextStyles.caption.copyWith(color: Colors.grey[600])),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _buildStatBox("This Month", "$presentThisMonth/${daysElapsedThisMonth > 22 ? 22 : daysElapsedThisMonth} d", "($rateThisMonth%)")),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox("This Year", "$presentThisYear/${daysElapsedThisYear > 240 ? 240 : daysElapsedThisYear} d", "($rateThisYear%)")),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox("Streak", "$streak days", "🔥", isHighlight: true)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: CalendarDatePicker2(
                config: CalendarDatePicker2Config(
                  calendarType: CalendarDatePicker2Type.multi,
                  selectedDayHighlightColor: AppColors.primary,
                  dayBuilder: ({
                    required DateTime date,
                    TextStyle? textStyle,
                    BoxDecoration? decoration,
                    bool? isSelected,
                    bool? isDisabled,
                    bool? isToday,
                  }) {
                    final dOnly = DateTime(date.year, date.month, date.day);
                    final isPresent = presentDateSet.contains(dOnly);
                    final isPast = dOnly.isBefore(nowDate);
                    final isAfterJoin = !dOnly.isBefore(joinDateOnly);
                    final isAbsent = isPast && isAfterJoin && !isPresent;
                    final isCurrentToday = dOnly.isAtSameMomentAs(nowDate);

                    Color? bgColor;
                    Color txtColor = AppColors.textPrimary;

                    if (isPresent) {
                      bgColor = Colors.green.withValues(alpha: 0.2);
                      txtColor = Colors.green[800]!;
                    } else if (isAbsent) {
                      bgColor = Colors.red.withValues(alpha: 0.2);
                      txtColor = Colors.red[800]!;
                    } else if (isCurrentToday) {
                      bgColor = AppColors.primary;
                      txtColor = Colors.white;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        date.day.toString(),
                        style: textStyle?.copyWith(color: txtColor, fontWeight: bgColor != null ? FontWeight.bold : FontWeight.normal),
                      ),
                    );
                  },
                ),
                value: presentDateSet.toList(),
                onDisplayedMonthChanged: (newMonth) {
                  setState(() {
                    _currentMonthView = newMonth;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Attendance Log — ${DateFormat('MMMM yyyy').format(_currentMonthView)}",
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildMonthLog(daysInViewMonth, firstOfViewMonth, allMemberRecords, presentDateSet, joinDateOnly, nowDate),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String value, String sub, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.accent.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isHighlight ? AppColors.accent : AppColors.border),
        boxShadow: [
          if (!isHighlight) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: AppTextStyles.caption.copyWith(color: isHighlight ? AppColors.accentDark : Colors.grey[600], fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isHighlight ? AppColors.accentDark : AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 12, color: isHighlight ? AppColors.accentDark : AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMonthLog(int daysInMonth, DateTime firstOfMonth, List<AttendanceRecord> records, Set<DateTime> presentDateSet, DateTime joinDate, DateTime nowDate) {
    final List<Widget> rows = [];

    for (int day = daysInMonth; day >= 1; day--) {
      final date = DateTime(firstOfMonth.year, firstOfMonth.month, day);
      if (date.isAfter(nowDate) || date.isBefore(joinDate)) continue;

      final isPresent = presentDateSet.contains(date);
      final recs = records.where((r) => r.date.isAtSameMomentAs(date)).toList();
      recs.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

      final dateFormatted = DateFormat('EEE, d MMMM yyyy').format(date);

      if (isPresent && recs.isNotEmpty) {
        for (final r in recs) {
          final checkInStr = DateFormat('hh:mm a').format(r.checkInTime);
          final checkOutStr = r.checkOutTime != null ? DateFormat('hh:mm a').format(r.checkOutTime!) : "--";
          String durationStr = "--";
          if (r.checkOutTime != null) {
            final diff = r.checkOutTime!.difference(r.checkInTime);
            final h = diff.inHours;
            final m = diff.inMinutes % 60;
            durationStr = h > 0 ? "${h}h ${m}m" : "${m}m";
          }

          rows.add(
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.green, size: 18),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dateFormatted, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text("In: $checkInStr", style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 12),
                              Text("Out: $checkOutStr", style: TextStyle(color: checkOutStr == "--" ? Colors.grey : AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                      child: Text(durationStr, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      } else {
        // Absent row
        rows.add(
          Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            color: Colors.red.withValues(alpha: 0.03),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.withValues(alpha: 0.2))),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.red, size: 18),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(dateFormatted, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text("Absent", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(child: Text("No attendance history for this month", style: TextStyle(color: Colors.grey[600]))),
      );
    }

    return Column(children: rows);
  }
}
