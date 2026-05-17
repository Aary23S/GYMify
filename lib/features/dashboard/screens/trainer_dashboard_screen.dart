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

class TrainerDashboardScreen extends ConsumerWidget {
  const TrainerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final allMembers = ref.watch(membersProvider);
    final attendanceState = ref.watch(attendanceProvider);

    final trainerUser = authState.user;
    final trainerName = trainerUser?.name ?? 'Sneha Kapoor';
    final firstName = trainerName.split(' ').first;
    final currentBranch = trainerUser?.currentBranch ?? 'Branch A';

    // Map of all members for quick lookup
    final membersMap = {for (var m in allMembers) m.id: m};

    // Filter members in trainer's current branch
    final branchMembers = allMembers.where((m) => m.branch == currentBranch).toList();

    // Checked in today (branch A)
    final presentTodayMemberIds = attendanceState.todayRecords
        .where((r) {
          final m = membersMap[r.memberId];
          return m != null && m.branch == currentBranch;
        })
        .map((r) => r.memberId)
        .toSet();

    // Currently inside gym right now (branch A & checkOutTime == null)
    final currentlyInsideRecords = attendanceState.todayRecords.where((r) {
      if (r.checkOutTime != null) return false;
      final m = membersMap[r.memberId];
      if (m == null) return false;
      return m.branch == currentBranch;
    }).toList();

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
                              "Assigned to $currentBranch",
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
                          title: "$currentBranch Members",
                          value: "${branchMembers.length}",
                          subtitle: "total enrolled",
                          icon: Icons.people_outline,
                          iconColor: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: "Present Today",
                          value: "${presentTodayMemberIds.length}",
                          subtitle: "checked in",
                          icon: Icons.check_circle_outline,
                          iconColor: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: "Currently Inside",
                          value: "${currentlyInsideRecords.length}",
                          subtitle: "active in gym",
                          icon: Icons.run_circle_outlined,
                          iconColor: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Currently In Gym Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: "Currently In Gym — $currentBranch"),
                  const SizedBox(height: 4),
                  Text(
                    "Members checked in but not yet checked out",
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  if (currentlyInsideRecords.isNotEmpty)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentlyInsideRecords.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final record = currentlyInsideRecords[index];
                        final member = membersMap[record.memberId];
                        final checkInStr = DateFormat('hh:mm a').format(record.checkInTime);
                        final durationStr = _formatDuration(record.checkInTime);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                member?.initials ?? 'M',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              record.memberName,
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            subtitle: Text(
                              record.memberCode,
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "In since $checkInStr",
                                  style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  durationStr,
                                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            onTap: member != null ? () => context.push('/members/${member.id}') : null,
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.fitness_center, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text("No members currently in gym", style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                        ],
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

  String _formatDuration(DateTime checkInTime) {
    final diff = DateTime.now().difference(checkInTime);
    if (diff.inHours > 0) {
      final mins = diff.inMinutes % 60;
      return "${diff.inHours}h ${mins}m ago";
    }
    return "${diff.inMinutes}m ago";
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
