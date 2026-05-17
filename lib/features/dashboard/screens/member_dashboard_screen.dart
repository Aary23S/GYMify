import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/providers/members_provider.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../../classes/providers/classes_provider.dart';
import '../../../core/utils/snackbar_helper.dart';

class MemberDashboardScreen extends ConsumerWidget {
  const MemberDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final allMembers = ref.watch(membersProvider);
    final allClasses = ref.watch(classesProvider);
    final attendanceState = ref.watch(attendanceProvider);

    // Get current logged-in member details
    final member = allMembers.firstWhere(
      (m) => m.name == authState.user?.name,
      orElse: () => allMembers.first,
    );

    // Plan info calculations
    final now = DateTime.now();
    final nowDate = DateTime(now.year, now.month, now.day);
    final daysLeft = member.planExpiry.difference(nowDate).inDays;
    final totalPlanDays = member.planExpiry.difference(member.joinDate).inDays > 0
        ? member.planExpiry.difference(member.joinDate).inDays
        : 30;
    final progressVal = (daysLeft / totalPlanDays).clamp(0.0, 1.0);

    // Progress calculations
    final memberRecs = attendanceState.allRecords.where((r) => r.memberId == member.id).toList();
    final presentDates = memberRecs.map((r) => DateTime(r.date.year, r.date.month, r.date.day)).toSet();

    // Workouts this month
    final workoutsCount = presentDates.where((d) => d.year == now.year && d.month == now.month).length;

    // Streak calculation
    int streak = 0;
    DateTime checkDate = nowDate;
    while (presentDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    if (streak == 0) {
      DateTime yesterday = nowDate.subtract(const Duration(days: 1));
      if (presentDates.contains(yesterday)) {
        int tempStreak = 1;
        DateTime d = yesterday.subtract(const Duration(days: 1));
        while (presentDates.contains(d)) {
          tempStreak++;
          d = d.subtract(const Duration(days: 1));
        }
        streak = tempStreak;
      }
    }

    final estimatedCalories = workoutsCount * 450;
    final caloriesFormatted = estimatedCalories > 1000 ? "${(estimatedCalories / 1000).toStringAsFixed(1)}K" : estimatedCalories.toString();

    // Classes schedule
    final memberClasses = allClasses.where((c) => c.isBookedBy(member.id)).toList();
    memberClasses.sort((a, b) => a.date.compareTo(b.date));

    final todayClasses = memberClasses.where((c) => c.date.year == now.year && c.date.month == now.month && c.date.day == now.day).toList();
    final upcomingClasses = memberClasses.where((c) => c.date.isAfter(nowDate) || (c.date.isAtSameMomentAs(nowDate) && _isUpcomingTime(c.startTime, now))).take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section + Plan Status Card Overlap
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24, left: 24, right: 24, bottom: 90),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Good Morning,", style: AppTextStyles.caption.copyWith(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text("${member.name} 👋", style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 24)),
                        ],
                      ),
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Text(member.initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 2)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Plan Status Card
                Positioned(
                  top: 130,
                  left: 20,
                  right: 20,
                  child: Card(
                    elevation: 8,
                    shadowColor: Colors.black.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(member.planName, style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule_outlined, color: AppColors.accent, size: 16),
                                      const SizedBox(width: 4),
                                      Text("$daysLeft days remaining", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("₹${NumberFormat('#,##,000').format(member.planPrice)}", style: AppTextStyles.heading2.copyWith(color: AppColors.primary)),
                                  Text("next renewal", style: AppTextStyles.caption.copyWith(color: Colors.grey[600])),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressVal,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              color: AppColors.accent,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Joined: ${DateFormat('d MMM').format(member.joinDate)}", style: AppTextStyles.caption.copyWith(color: Colors.grey[600])),
                              Text("Expires: ${DateFormat('d MMM yyyy').format(member.planExpiry)}", style: AppTextStyles.caption.copyWith(color: daysLeft <= 7 ? Colors.red[700] : Colors.grey[600], fontWeight: FontWeight.bold)),
                            ],
                          ),
                          if (daysLeft <= 7) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text("Your plan expires soon! Renew to keep access.", style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              text: "Pay My Fees Now",
                              onPressed: () => context.push('/member/pay-fees'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: daysLeft <= 7 ? 240 : 160),

            // My Progress Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: "My Progress This Month"),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ProgressCard(
                          icon: Icons.fitness_center,
                          iconBgColor: AppColors.accent,
                          value: workoutsCount.toString(),
                          label: "Workouts",
                          subtext: "days attended",
                          valColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ProgressCard(
                          icon: Icons.local_fire_department,
                          iconBgColor: Colors.deepOrange,
                          value: streak.toString(),
                          label: "Day Streak",
                          emoji: "🔥",
                          valColor: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ProgressCard(
                          icon: Icons.bolt,
                          iconBgColor: Colors.amber[700]!,
                          value: caloriesFormatted,
                          label: "Cal Burned",
                          subtext: "estimated",
                          valColor: Colors.amber[800]!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Today's Schedule Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Today's Classes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
                      TextButton(
                        onPressed: () => context.push('/member/classes'),
                        child: const Text("Book More →", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (todayClasses.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        children: todayClasses.map((c) => _buildTodayClassCard(context, c, now)).toList(),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                      child: Column(
                        children: [
                          Icon(Icons.event_busy, size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text("No classes booked today", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.accent, side: const BorderSide(color: AppColors.accent)),
                            onPressed: () => context.push('/member/classes'),
                            child: const Text("Browse & Book Classes"),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Upcoming Classes Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: "Upcoming Bookings"),
                  const SizedBox(height: 16),
                  if (upcomingClasses.isNotEmpty)
                    ...upcomingClasses.map((c) => _buildUpcomingRow(context, ref, c, member.id))
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text("No upcoming bookings for the week", style: TextStyle(color: Colors.grey[600]))),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Attendance Quick View
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("This Month's Attendance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                        TextButton(
                          onPressed: () => context.push('/my-qr'),
                          child: const Text("Full Log →", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildMiniCalendarStrip(now, presentDates),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        "$workoutsCount present · 82% attendance rate",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  bool _isUpcomingTime(String startTimeStr, DateTime now) {
    try {
      final format = DateFormat('hh:mm a');
      final start = format.parse(startTimeStr);
      final todayStart = DateTime(now.year, now.month, now.day, start.hour, start.minute);
      return todayStart.isAfter(now);
    } catch (_) {
      return true;
    }
  }

  Widget _buildTodayClassCard(BuildContext context, GymClassSession c, DateTime now) {
    Color typeBg;
    switch (c.category) {
      case 'Yoga':
        typeBg = Colors.teal;
        break;
      case 'HIIT':
        typeBg = Colors.orange;
        break;
      case 'Zumba':
        typeBg = Colors.pink;
        break;
      case 'CrossFit':
        typeBg = Colors.red[700]!;
        break;
      default:
        typeBg = Colors.blue;
        break;
    }

    bool isDone = !_isUpcomingTime(c.startTime, now);

    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 8, decoration: BoxDecoration(color: typeBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(16)))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: typeBg.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text(c.category, style: TextStyle(color: typeBg, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    if (isDone)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: const Text("Completed ✓", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: const Text("Upcoming", style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(c.className, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text("${c.startTime} – ${c.endTime}", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(radius: 10, backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: const Icon(Icons.person, size: 12, color: AppColors.primary)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c.trainerName, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.bold))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingRow(BuildContext context, WidgetRef ref, GymClassSession c, String memberId) {
    final dayStr = DateFormat('EEE').format(c.date).toUpperCase();
    final numStr = DateFormat('dd').format(c.date);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.border)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              children: [
                Text(dayStr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 2),
                Text(numStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary)),
              ],
            ),
            const SizedBox(width: 16),
            Container(width: 1, height: 40, color: AppColors.border),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.className, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text("${c.startTime} · ${c.trainerName}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: "Cancel Booking",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Cancel Booking"),
                    content: Text("Are you sure you want to cancel your booking for ${c.className}?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("No")),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        onPressed: () {
                          ref.read(classesProvider.notifier).cancelBooking(c.id, memberId);
                          Navigator.pop(ctx);
                          SnackbarHelper.showError(context, "Cancelled ${c.className}");
                        },
                        child: const Text("Yes, Cancel"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCalendarStrip(DateTime now, Set<DateTime> presentDates) {
    // Current week (Monday to Sunday)
    final int weekday = now.weekday; // 1=Mon .. 7=Sun
    final startOfWeek = now.subtract(Duration(days: weekday - 1));

    final List<Widget> days = [];
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);
      final isToday = dateOnly.isAtSameMomentAs(DateTime(now.year, now.month, now.day));
      final isFuture = dateOnly.isAfter(DateTime(now.year, now.month, now.day));
      final isPresent = presentDates.contains(dateOnly);

      Color bg;
      Color fg = AppColors.textPrimary;
      Border? border;

      if (isToday) {
        border = Border.all(color: AppColors.primary, width: 2);
      }

      if (isPresent) {
        bg = AppColors.accent.withValues(alpha: 0.2);
        fg = Colors.deepOrange[900]!;
      } else if (isFuture) {
        bg = Colors.grey[100]!;
        fg = Colors.grey[400]!;
      } else {
        bg = Colors.red.withValues(alpha: 0.1);
        fg = Colors.red[800]!;
      }

      days.add(
        Expanded(
          child: Column(
            children: [
              Text(DateFormat('E').format(date).substring(0, 1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Container(
                height: 40,
                width: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: border),
                child: Text(date.day.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: fg, fontSize: 14)),
              ),
            ],
          ),
        ),
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: days);
  }
}

class _ProgressCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String value;
  final String label;
  final String? subtext;
  final String? emoji;
  final Color valColor;

  const _ProgressCard({
    required this.icon,
    required this.iconBgColor,
    required this.value,
    required this.label,
    this.subtext,
    this.emoji,
    required this.valColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconBgColor.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, size: 24, color: iconBgColor),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: valColor)),
              if (emoji != null) ...[
                const SizedBox(width: 4),
                Text(emoji!, style: const TextStyle(fontSize: 18)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
          if (subtext != null)
            Text(subtext!, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
