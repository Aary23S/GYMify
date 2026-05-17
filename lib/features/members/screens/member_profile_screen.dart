import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../models/member_model.dart';
import '../providers/members_provider.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../../workout/providers/workout_provider.dart';

class MemberProfileScreen extends ConsumerWidget {
  final String memberId;

  const MemberProfileScreen({
    super.key,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(memberByIdProvider(memberId));
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final role = authState.selectedRole;

    if (member == null) {
      return const Scaffold(
        body: Center(child: Text('Member not found')),
      );
    }

    final bool isOwnProfile = role == UserRole.member &&
        (currentUser?.name == member.name || currentUser?.id == member.id);

    final int tabLength = isOwnProfile ? 3 : 4;

    return DefaultTabController(
      length: tabLength,
      child: Scaffold(
        body: Column(
          children: [
            _buildHeroHeader(context, ref, member),
            TabBar(
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: [
                const Tab(text: 'Overview'),
                if (!isOwnProfile) const Tab(text: 'Attendance'),
                const Tab(text: 'Payments'),
                const Tab(text: 'Workout'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(member: member, isOwnProfile: isOwnProfile),
                  if (!isOwnProfile) _AttendanceTab(member: member),
                  _PaymentsTab(member: member),
                  _WorkoutTab(member: member, isOwnProfile: isOwnProfile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, WidgetRef ref, Member member) {
    return Stack(
      children: [
        Container(
          height: 320,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, Color(0xFF1A237E)],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/dashboard');
                        }
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'logout') {
                          ref.read(authProvider.notifier).logout();
                          context.go('/login');
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'deactivate',
                          child: Text('Deactivate'),
                        ),
                        const PopupMenuItem(
                          value: 'notes',
                          child: Text('Notes'),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Logout', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white24,
                child: Text(
                  member.initials,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                member.name,
                style: AppTextStyles.heading2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                member.memberCode,
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StatusBadge(status: member.status),
                  const SizedBox(width: 8),
                  Text(
                    member.planName,
                    style: AppTextStyles.caption.copyWith(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final Member member;
  final bool isOwnProfile;

  const _OverviewTab({required this.member, required this.isOwnProfile});

  void _showSendNotificationDialog(BuildContext context, Member member) {
    final firstName = member.name.split(' ').first;
    final expiryFormatted = DateFormat('dd MMM yyyy').format(member.planExpiry);
    final daysLeft = member.planExpiry.difference(DateTime.now()).inDays;
    final displayDays = daysLeft >= 0 ? daysLeft : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Send Due Reminder"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Send a payment reminder to ${member.name}?", style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hi $firstName! Your GymFlow membership expires in $displayDays days on $expiryFormatted. Please renew soon to continue your fitness journey! 💪",
                    style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "This message will be sent as a push notification",
                    style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              SnackbarHelper.showSuccess(context, "Reminder sent to ${member.name} ✓");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("Send Notification"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).role;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            title: 'Personal Information',
            items: [
              _InfoItem(
                  label: 'DOB',
                  value: DateFormat('dd MMM yyyy').format(member.dateOfBirth)),
              _InfoItem(label: 'Phone', value: member.phone, isLink: true),
              _InfoItem(label: 'Email', value: member.email),
              _InfoItem(label: 'Gender', value: member.gender),
              _InfoItem(
                  label: 'Blood Group',
                  value: member.bloodGroup ?? 'Not specified'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Membership Details',
            items: [
              _InfoItem(label: 'Branch', value: member.branch),
              _InfoItem(label: 'Plan', value: member.planName),
              _InfoItem(
                  label: 'Join Date',
                  value: DateFormat('dd MMM yyyy').format(member.joinDate)),
              _InfoItem(
                  label: 'Expiry Date',
                  value: DateFormat('dd MMM yyyy').format(member.planExpiry)),
              _InfoItem(
                  label: 'Trainer',
                  value: member.assignedTrainerName ?? 'Not assigned'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Emergency Contact',
            items: [
              _InfoItem(label: 'Name', value: member.emergencyContactName),
              _InfoItem(
                  label: 'Phone',
                  value: member.emergencyContactPhone,
                  isLink: true),
            ],
          ),
          if (role == UserRole.trainer) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.notification_add_outlined),
                label: const Text("Send Due Reminder"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showSendNotificationDialog(context, member),
              ),
            ),
          ] else if (isOwnProfile) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/member/pay-fees'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Pay My Fees", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      {required String title, required List<_InfoItem> items}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ...items,
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isLink;

  const _InfoItem({
    required this.label,
    required this.value,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isLink ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isLink ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceTab extends ConsumerWidget {
  final Member member;

  const _AttendanceTab({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceState = ref.watch(attendanceProvider);

    // Filter all records for this specific member
    final memberRecords = attendanceState.allRecords
        .where((r) => r.memberId == member.id || r.memberName == member.name)
        .toList();

    memberRecords.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

    final now = DateTime.now();
    final thisMonthRecords = memberRecords
        .where((r) => r.checkInTime.year == now.year && r.checkInTime.month == now.month)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Summary Row
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_month, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "This Month: ${thisMonthRecords.length} Check-ins",
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Consistent activity tracked at ${member.branch}",
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Attendance Log',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (memberRecords.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No attendance records found', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...memberRecords.take(10).map((record) {
              final dateStr = DateFormat('EEE, dd MMM yyyy').format(record.checkInTime);
              final checkInStr = DateFormat('hh:mm a').format(record.checkInTime);
              final checkOutStr = record.checkOutTime != null ? DateFormat('hh:mm a').format(record.checkOutTime!) : "--";
              final durationStr = _calculateDuration(record.checkInTime, record.checkOutTime);

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: record.checkOutTime == null ? AppColors.accent.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          record.checkOutTime == null ? Icons.run_circle : Icons.check_circle,
                          color: record.checkOutTime == null ? AppColors.accent : AppColors.success,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text("In: $checkInStr • Out: $checkOutStr", style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          durationStr,
                          style: AppTextStyles.label.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _calculateDuration(DateTime inTime, DateTime? outTime) {
    if (outTime == null) return "In Gym";
    final diff = outTime.difference(inTime);
    if (diff.inHours > 0) {
      return "${diff.inHours}h ${diff.inMinutes % 60}m";
    }
    return "${diff.inMinutes}m";
  }
}

class _PaymentsTab extends StatelessWidget {
  final Member member;

  const _PaymentsTab({required this.member});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 0,
            color: Colors.green.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Lifetime Total Paid',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '₹18,000',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Payment History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 12),
          _buildPaymentCard(
            date: DateTime(2026, 3, 5),
            plan: member.planName,
            amount: member.planPrice.toDouble(),
            mode: 'UPI',
          ),
          _buildPaymentCard(
            date: DateTime(2026, 2, 5),
            plan: member.planName,
            amount: member.planPrice.toDouble(),
            mode: 'Cash',
          ),
          _buildPaymentCard(
            date: DateTime(2026, 1, 5),
            plan: member.planName,
            amount: member.planPrice.toDouble(),
            mode: 'UPI',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard({
    required DateTime date,
    required String plan,
    required double amount,
    required String mode,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        title: Text(plan, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('dd MMM yyyy').format(date)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${amount.toInt()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                mode,
                style: const TextStyle(fontSize: 10, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutTab extends ConsumerWidget {
  final Member member;
  final bool isOwnProfile;

  const _WorkoutTab({required this.member, required this.isOwnProfile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(workoutPlansProvider);
    final plan = plans.where((p) => p.memberId == member.id || p.memberName == member.name).firstOrNull;

    if (plan == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EmptyStateWidget(
              icon: Icons.fitness_center,
              title: 'No workout plan assigned',
              subtitle: 'A custom workout routine has not been created yet.',
            ),
            if (isOwnProfile || ref.watch(authProvider).role == UserRole.trainer) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Create Workout Plan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => context.push('/member/workout'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                _getGoalBadge(plan.goal),
                style: const TextStyle(color: AppColors.accentDark, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            if (plan.isCreatedByMember)
              Chip(
                label: const Text("Created by Member", style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                side: BorderSide.none,
              ),
          ],
        ),
        if (isOwnProfile) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit, size: 16),
              label: const Text("Edit Plan"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => context.push('/member/workout'),
            ),
          ),
        ],
        const SizedBox(height: 20),
        ...plan.days.map((day) {
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            child: ExpansionTile(
              title: Text(day.dayLabel, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              children: day.exercises.map((ex) {
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.fitness_center, size: 18, color: AppColors.primary),
                  ),
                  title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "${ex.sets} sets × ${ex.reps} reps • Rest: ${ex.restSeconds}s" + (ex.notes != null ? "\nNotes: ${ex.notes}" : ""),
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, height: 1.3),
                    ),
                  ),
                  isThreeLine: ex.notes != null,
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

  String _getGoalBadge(String goal) {
    if (goal == 'muscle_gain') return "💪 Muscle Gain";
    if (goal == 'weight_loss') return "🔥 Weight Loss";
    return "🎯 General Fitness";
  }
}
