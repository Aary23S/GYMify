import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/providers/members_provider.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../../classes/providers/classes_provider.dart';

class TrainerDashboardScreen extends ConsumerWidget {
  const TrainerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final allMembers = ref.watch(membersProvider);
    final allClasses = ref.watch(classesProvider);
    final attendanceNotifier = ref.read(attendanceProvider.notifier);

    final trainerUser = authState.user;
    final trainerId = trainerUser?.id ?? 'trn_001';
    final trainerName = trainerUser?.name ?? 'Sneha Kapoor';
    final firstName = trainerName.split(' ').first;

    // Get assigned trainees
    final myTrainees = allMembers.where(
      (m) => m.assignedTrainerId == trainerId || m.assignedTrainerName == trainerName,
    ).toList();

    // Check-in count today
    final presentCount = myTrainees.where((m) => attendanceNotifier.isCheckedInToday(m.id)).length;

    // Today's classes for this trainer
    final now = DateTime.now();
    final todayClasses = allClasses.where((c) {
      final isSameTrainer = c.trainerName == trainerName;
      final isToday = c.date.year == now.year && c.date.month == now.month && c.date.day == now.day;
      return isSameTrainer && isToday;
    }).toList();
    todayClasses.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                left: 24,
                right: 24,
                bottom: 32,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Good Morning, $firstName 💪",
                              style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 26),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "You have ${todayClasses.length} classes today",
                              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                        child: Text(
                          firstName.isNotEmpty ? firstName[0].toUpperCase() : 'T',
                          style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Stats Row (3 cards)
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: "My Trainees",
                          value: "${myTrainees.length}",
                          subtitle: "members",
                          icon: Icons.people_outline,
                          iconColor: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: "Classes Today",
                          value: "${todayClasses.length}",
                          subtitle: "classes",
                          icon: Icons.event_note,
                          iconColor: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: "Present Today",
                          value: "$presentCount/${myTrainees.length}",
                          subtitle: "checked in",
                          icon: Icons.check_circle_outline,
                          iconColor: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Today's Classes Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: "Today's Classes"),
                  const SizedBox(height: 16),
                  if (todayClasses.isNotEmpty)
                    ...todayClasses.map((c) => _buildClassCard(context, c, now))
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.event_busy, size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text("No classes scheduled for today", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // My Trainees Quick View Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SectionHeader(title: "My Trainees Today"),
                      TextButton(
                        onPressed: () => context.push('/trainer/members'),
                        child: const Text("View All →", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (myTrainees.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        children: myTrainees.map((m) {
                          final isPresent = attendanceNotifier.isCheckedInToday(m.id);
                          return _buildTraineeAvatarChip(context, m, isPresent);
                        }).toList(),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text("No trainees assigned to you yet", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, GymClassSession c, DateTime now) {
    String statusText;
    Color statusBg;
    Color statusFg;

    try {
      final format = DateFormat('hh:mm a');
      final start = format.parse(c.startTime);
      final end = format.parse(c.endTime);
      final startTime = DateTime(now.year, now.month, now.day, start.hour, start.minute);
      final endTime = DateTime(now.year, now.month, now.day, end.hour, end.minute);

      if (now.isAfter(endTime)) {
        statusText = "Completed";
        statusBg = AppColors.success.withValues(alpha: 0.1);
        statusFg = AppColors.success;
      } else if (now.isAfter(startTime) && now.isBefore(endTime)) {
        statusText = "In Progress •";
        statusBg = AppColors.accent.withValues(alpha: 0.15);
        statusFg = AppColors.accentDark;
      } else {
        final diff = startTime.difference(now);
        final hours = diff.inHours;
        final mins = diff.inMinutes % 60;
        if (hours > 0) {
          statusText = "Starting in ${hours}h ${mins}m";
        } else {
          statusText = "Starting in ${mins}m";
        }
        statusBg = AppColors.primary.withValues(alpha: 0.08);
        statusFg = AppColors.primaryLight;
      }
    } catch (_) {
      statusText = "Upcoming";
      statusBg = Colors.grey[200]!;
      statusFg = Colors.grey[700]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${c.startTime} – ${c.endTime}",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(statusText, style: TextStyle(color: statusFg, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(c.className, style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.room, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          c.location,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text("${c.bookedMemberIds.length}/${c.maxSpots} enrolled", style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraineeAvatarChip(BuildContext context, var m, bool isPresent) {
    return GestureDetector(
      onTap: () => context.push('/members/${m.id}'),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPresent ? AppColors.success : Colors.grey[300]!,
                  width: isPresent ? 3.0 : 2.0,
                ),
                color: isPresent ? AppColors.success.withValues(alpha: 0.1) : Colors.grey[100],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: isPresent ? AppColors.success.withValues(alpha: 0.15) : Colors.grey[200],
                child: Text(
                  m.initials,
                  style: TextStyle(
                    color: isPresent ? AppColors.success : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              m.name.split(' ').first,
              style: TextStyle(
                fontWeight: isPresent ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
                color: isPresent ? AppColors.textPrimary : Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPresent ? AppColors.success : Colors.grey[300],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.label.copyWith(color: Colors.white70, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 22),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
