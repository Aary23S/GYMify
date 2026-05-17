import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../models/member_model.dart';
import '../providers/members_provider.dart';
import '../../attendance/providers/attendance_provider.dart';

class MemberProfileScreen extends ConsumerWidget {
  final String memberId;

  const MemberProfileScreen({
    super.key,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(memberByIdProvider(memberId));

    if (member == null) {
      return const Scaffold(
        body: Center(child: Text('Member not found')),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: Column(
          children: [
            _buildHeroHeader(context, ref, member),
            const TabBar(
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Attendance'),
                Tab(text: 'Payments'),
                Tab(text: 'Workout'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(member: member),
                  _AttendanceTab(member: member),
                  _PaymentsTab(member: member),
                  _WorkoutTab(member: member),
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
                      onPressed: () => context.pop(),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () {},
                        ),
                        PopupMenuButton<String>(
                          icon:
                              const Icon(Icons.more_vert, color: Colors.white),
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
                                  Icon(Icons.logout,
                                      size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Logout',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
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
                    style:
                        AppTextStyles.caption.copyWith(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Extra space at bottom
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final Member member;

  const _OverviewTab({required this.member});

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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Reminder sent to ${member.name} ✓"),
                  backgroundColor: AppColors.success,
                ),
              );
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
          ] else if (role == UserRole.member) ...[
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
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.bold),
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

    // Filter attendance records for this specific member
    final memberRecords = attendanceState.todaysRecords
        .where((r) => r.memberId == member.id)
        .toList();

    // Sort records by time (newest first)
    memberRecords.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

    final presentDateSet = memberRecords
        .map((r) => DateTime(r.checkInTime.year, r.checkInTime.month, r.checkInTime.day))
        .toSet();

    final now = DateTime.now();
    final nowDate = DateTime(now.year, now.month, now.day);
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysElapsed = nowDate.difference(firstDayOfMonth).inDays + 1;

    final presentCount = presentDateSet
        .where((d) => d.year == now.year && d.month == now.month && !d.isAfter(nowDate))
        .length;
    final absentCount = (daysElapsed - presentCount) > 0 ? (daysElapsed - presentCount) : 0;
    final percentage = daysElapsed > 0 ? (presentCount / daysElapsed * 100).round() : 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 0,
            color: AppColors.primary.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Present $presentCount days | Absent $absentCount days | $percentage% attendance",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '🔥 Active Member',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          CalendarDatePicker2(
            config: CalendarDatePicker2Config(
              calendarType: CalendarDatePicker2Type.single,
              dayBuilder: ({
                required DateTime date,
                TextStyle? textStyle,
                BoxDecoration? decoration,
                bool? isSelected,
                bool? isDisabled,
                bool? isToday,
              }) {
                final isPresent = presentDateSet.contains(DateTime(date.year, date.month, date.day));
                final isPast = date.isBefore(nowDate);
                final isAbsent = isPast && !isPresent;

                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        date.day.toString(),
                        style: textStyle,
                      ),
                      if (isPresent)
                        const Icon(Icons.circle, size: 6, color: Colors.green)
                      else if (isAbsent)
                        const Icon(Icons.circle, size: 6, color: Colors.red)
                      else
                        const SizedBox(height: 6),
                    ],
                  ),
                );
              },
            ),
            value: const [],
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Attendance Log',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          if (memberRecords.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No attendance records found',
                  style: TextStyle(color: Colors.grey)),
            )
          else
            ...memberRecords.take(10).map((record) {
              final checkInStr = DateFormat('hh:mm a').format(record.checkInTime);
              // Generate dummy check-out time 75 minutes later
              final checkOutTime = record.checkInTime.add(const Duration(minutes: 75));
              final checkOutStr = checkOutTime.isAfter(DateTime.now()) ? "--" : DateFormat('hh:mm a').format(checkOutTime);

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat('EEEE, dd MMM yyyy').format(record.checkInTime),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Check-in: $checkInStr", style: AppTextStyles.caption),
                          Text("Check-out: $checkOutStr", style: AppTextStyles.caption.copyWith(color: checkOutStr == "--" ? Colors.grey : AppColors.textSecondary)),
                        ],
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            plan: 'Monthly Standard',
            amount: 2000,
            mode: 'UPI',
          ),
          _buildPaymentCard(
            date: DateTime(2026, 2, 5),
            plan: 'Monthly Standard',
            amount: 2000,
            mode: 'Cash',
          ),
          _buildPaymentCard(
            date: DateTime(2026, 1, 5),
            plan: 'Monthly Standard',
            amount: 2000,
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
              '₹$amount',
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

class _WorkoutTab extends StatelessWidget {
  final Member member;

  const _WorkoutTab({required this.member});

  @override
  Widget build(BuildContext context) {
    if (member.assignedTrainerName == null) {
      return const EmptyStateWidget(
        icon: Icons.fitness_center,
        title: 'No workout plan assigned',
        subtitle: 'Assign a trainer to create a workout plan',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Active Plan: Muscle Building v2',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildWorkoutDay(
          day: 'Day 1',
          target: 'Chest & Triceps',
          exercises: [
            'Bench Press (3 sets × 12 reps)',
            'Incline DB Press (3 sets × 10 reps)',
            'Cable Flyes (3 sets × 15 reps)',
            'Tricep Pushdowns (3 sets × 12 reps)',
          ],
        ),
        _buildWorkoutDay(
          day: 'Day 2',
          target: 'Back & Biceps',
          exercises: [
            'Lat Pulldowns (3 sets × 12 reps)',
            'Seated Rows (3 sets × 10 reps)',
            'Deadlifts (3 sets × 8 reps)',
            'Hammer Curls (3 sets × 12 reps)',
          ],
        ),
        _buildWorkoutDay(
          day: 'Day 3',
          target: 'Legs & Shoulders',
          exercises: [
            'Squats (3 sets × 10 reps)',
            'Leg Press (3 sets × 12 reps)',
            'Overhead Press (3 sets × 10 reps)',
            'Lateral Raises (3 sets × 15 reps)',
          ],
        ),
      ],
    );
  }

  Widget _buildWorkoutDay({
    required String day,
    required String target,
    required List<String> exercises,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ExpansionTile(
        title: Text('$day: $target',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        children: exercises
            .map((ex) => ListTile(
                  leading: const Icon(Icons.circle, size: 8),
                  title: Text(ex),
                  dense: true,
                ))
            .toList(),
      ),
    );
  }
}
