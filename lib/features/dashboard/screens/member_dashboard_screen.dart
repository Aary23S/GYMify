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
import '../../workout/providers/workout_provider.dart';

class MemberDashboardScreen extends ConsumerWidget {
  const MemberDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final allMembers = ref.watch(membersProvider);
    final attendanceState = ref.watch(attendanceProvider);
    final workoutPlans = ref.watch(workoutPlansProvider);

    // Get current logged-in member details
    final member = allMembers.firstWhere(
      (m) => m.name == authState.user?.name,
      orElse: () => allMembers.first,
    );

    final workoutPlan = workoutPlans.where((p) => p.memberId == member.id || p.memberName == member.name).firstOrNull;

    // Plan info calculations
    final now = DateTime.now();
    final nowDate = DateTime(now.year, now.month, now.day);
    final daysLeft = member.planExpiry.difference(nowDate).inDays;
    final totalPlanDays = member.planExpiry.difference(member.joinDate).inDays > 0
        ? member.planExpiry.difference(member.joinDate).inDays
        : 30;
    final progressVal = (daysLeft / totalPlanDays).clamp(0.0, 1.0);

    // Progress calculations
    final memberRecs = attendanceState.allRecords.where((r) => r.memberId == member.id || r.memberName == member.name).toList();
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

            // My Workout Routine Quick Preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: "My Workout Routine"),
                  const SizedBox(height: 16),
                  if (workoutPlan != null)
                    Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border, width: 1.5)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => context.push('/my-profile'),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                                child: const Icon(Icons.fitness_center, color: AppColors.accent, size: 32),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("${workoutPlan.planName} — ${_formatGoal(workoutPlan.goal)}", style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary)),
                                    const SizedBox(height: 4),
                                    Text("${workoutPlan.days.length} workout days · Tap to view full routine", style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border, width: 1.5)),
                      child: Column(
                        children: [
                          Icon(Icons.assignment_add, size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text("No workout plan assigned yet. Ask your trainer or create one.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            text: "Create Routine",
                            onPressed: () => context.push('/member/workout'),
                          ),
                        ],
                      ),
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

  String _formatGoal(String goal) {
    if (goal == 'muscle_gain') return "Muscle Gain";
    if (goal == 'weight_loss') return "Weight Loss";
    return "General Fitness";
  }

  Widget _buildMiniCalendarStrip(DateTime now, Set<DateTime> presentDates) {
    final int weekday = now.weekday;
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
