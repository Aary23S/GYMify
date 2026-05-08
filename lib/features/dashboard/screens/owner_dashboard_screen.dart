import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(dashboardProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final role = authState.selectedRole;

    final bool isManagement =
        role == UserRole.superAdmin || role == UserRole.admin;
    final bool isTrainer = role == UserRole.trainer;
    final bool isMember = role == UserRole.member;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              context,
              user?.name ?? 'User',
              user?.gymName ?? 'GymFlow',
              role,
            ),

            // STATS CARDS (Conditional based on role)
            Transform.translate(
              offset: const Offset(0, -24),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
                child: Row(
                  children: [
                    if (isManagement) ...[
                      StatCard(
                        title: "Total Members",
                        value: dashboardData.totalMembers.toString(),
                        icon: Icons.people,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSizes.paddingM),
                      StatCard(
                        title: "Today's Check-ins",
                        value: dashboardData.activeToday.toString(),
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSizes.paddingM),
                      StatCard(
                        title: "Expiring Soon",
                        value: dashboardData.expiringSoon.toString(),
                        icon: Icons.schedule,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSizes.paddingM),
                      StatCard(
                        title: "Revenue Today",
                        value: "₹${dashboardData.revenueToday.toInt()}",
                        icon: Icons.currency_rupee,
                        color: AppColors.info,
                      ),
                    ],
                    if (isTrainer) ...[
                      StatCard(
                        title: "My Members",
                        value: "24",
                        icon: Icons.people,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSizes.paddingM),
                      StatCard(
                        title: "Today's Classes",
                        value: "3",
                        icon: Icons.calendar_month,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: AppSizes.paddingM),
                      StatCard(
                        title: "Pending Reviews",
                        value: "5",
                        icon: Icons.rate_review,
                        color: AppColors.warning,
                      ),
                    ],
                    if (isMember) ...[
                      StatCard(
                        title: "Days Left",
                        value: "18",
                        icon: Icons.timer,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: AppSizes.paddingM),
                      StatCard(
                        title: "Workouts",
                        value: "12",
                        icon: Icons.fitness_center,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSizes.paddingM),
                      StatCard(
                        title: "Calories Burnt",
                        value: "4.2K",
                        icon: Icons.local_fire_department,
                        color: AppColors.warning,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isManagement) ...[
                    const SectionHeader(title: "Revenue This Week"),
                    _buildRevenueChart(dashboardData.weeklyRevenue),
                  ],
                  const SectionHeader(title: "Attendance Trend (30 Days)"),
                  _buildAttendanceTrend(
                      List<int>.from(dashboardData.last30DaysAttendance)),
                  const SectionHeader(title: "Quick Actions"),
                  _buildQuickActions(context, ref, role),
                  if (isManagement) ...[
                    SectionHeader(
                      title: "Expiring Soon",
                      actionLabel: "View All",
                      onAction: () {},
                    ),
                    _buildExpiringMembersList(
                        List<dynamic>.from(dashboardData.expiringMembers)),
                  ],
                  if (isMember) ...[
                    const SectionHeader(title: "My Upcoming Classes"),
                    _buildUpcomingClasses(),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, String name, String gymName, UserRole role) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.paddingM,
        MediaQuery.of(context).padding.top + 16,
        AppSizes.paddingM,
        48,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Good Morning, $name 👋",
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textOnDark.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500),
                ),
                Text(
                  role == UserRole.member ? "Your Fitness Hub" : gymName,
                  style: AppTextStyles.heading2
                      .copyWith(color: AppColors.textOnDark),
                ),
              ],
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              return Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // Navigate to settings
                      context.push('/settings'); // Placeholder route
                    },
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white),
                    tooltip: 'Settings',
                  ),
                  IconButton(
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'Logout',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(List<dynamic> weeklyRevenue) {
    if (weeklyRevenue.isEmpty) {
      return const SizedBox(
          height: 200, child: Center(child: Text("No data available")));
    }

    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 20000,
            barTouchData: BarTouchData(enabled: false),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final int index = value.toInt();
                    if (index >= 0 && index < weeklyRevenue.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(weeklyRevenue[index].day.toString(),
                            style: AppTextStyles.label.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold)),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  reservedSize: 40,
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value % 5000 == 0) {
                      return Text('${(value / 1000).toInt()}K',
                          style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            barGroups: weeklyRevenue.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: (entry.value.amount as num).toDouble(),
                    color: AppColors.accent,
                    width: 16,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceTrend(List<int> attendance) {
    if (attendance.isEmpty) {
      return const SizedBox(
          height: 160, child: Center(child: Text("No data available")));
    }

    return SizedBox(
      height: 160,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  reservedSize: 32,
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.min || value == meta.max) {
                      return Text(value.toInt().toString(),
                          style: AppTextStyles.label.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: attendance
                    .asMap()
                    .entries
                    .map((entry) =>
                        FlSpot(entry.key.toDouble(), entry.value.toDouble()))
                    .toList(),
                isCurved: true,
                color: AppColors.primary,
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.25),
                      AppColors.primary.withOpacity(0.0)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _switchTabByPermission(
      BuildContext context, WidgetRef ref, AppPermission permission) {
    final authState = ref.read(authProvider);
    final List<AppPermission> orderedPermissions = [
      AppPermission.viewDashboard,
      AppPermission.manageMembers,
      AppPermission.viewAttendance,
      AppPermission.managePayments,
      AppPermission.manageClasses,
    ];

    int visibleIndex = 0;
    for (var p in orderedPermissions) {
      if (authState.hasPermission(p)) {
        if (p == permission) {
          ref.read(bottomNavIndexProvider.notifier).state = visibleIndex;
          return;
        }
        visibleIndex++;
      }
    }
  }

  Widget _buildQuickActions(
      BuildContext context, WidgetRef ref, UserRole role) {
    final List<Map<String, dynamic>> allActions = [
      {
        'label': 'Add Member',
        'icon': Icons.person_add,
        'route': '/members/add',
        'roles': [UserRole.superAdmin, UserRole.admin]
      },
      {
        'label': 'Attendance',
        'icon': Icons.qr_code_scanner,
        'route': '/attendance',
        'roles': [UserRole.superAdmin, UserRole.admin, UserRole.trainer]
      },
      {
        'label': 'Payment',
        'icon': Icons.account_balance_wallet,
        'route': '/payments',
        'roles': [UserRole.superAdmin, UserRole.admin]
      },
      {
        'label': 'Schedule',
        'icon': Icons.event_note,
        'route': '/classes',
        'roles': [
          UserRole.superAdmin,
          UserRole.admin,
          UserRole.trainer,
          UserRole.member
        ]
      },
      {
        'label': 'Add Trainer',
        'icon': Icons.sports,
        'route': '/trainers',
        'roles': [UserRole.superAdmin]
      },
      {
        'label': 'Reports',
        'icon': Icons.assessment,
        'route': '/reports',
        'roles': [UserRole.superAdmin, UserRole.admin]
      },
      {
        'label': 'Book Class',
        'icon': Icons.add_task,
        'route': '/classes',
        'roles': [UserRole.member]
      },
      {
        'label': 'My Progress',
        'icon': Icons.trending_up,
        'route': '/progress',
        'roles': [UserRole.member]
      },
      {
        'label': 'Assigned',
        'icon': Icons.assignment_ind,
        'route': '/assigned',
        'roles': [UserRole.trainer]
      },
    ];

    final roleActions = allActions
        .where((action) => (action['roles'] as List<UserRole>).contains(role))
        .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: roleActions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final action = roleActions[index];
        return Material(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            side: const BorderSide(color: AppColors.border, width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            onTap: () {
              final route = action['route'] as String?;
              if (route == null) return;

              if (route == '/attendance') {
                _switchTabByPermission(
                    context, ref, AppPermission.viewAttendance);
              } else if (route == '/members') {
                _switchTabByPermission(
                    context, ref, AppPermission.manageMembers);
              } else {
                context.push(route);
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action['icon'] as IconData,
                    color: AppColors.primary, size: 28),
                const SizedBox(height: 8),
                Text(action['label'] as String,
                    style: AppTextStyles.label.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpiringMembersList(List<dynamic> expiringMembers) {
    final List<Color> avatarColors = [
      Colors.blue.shade700,
      Colors.teal.shade700,
      AppColors.warning,
      Colors.purple.shade700,
      AppColors.danger
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expiringMembers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final member = expiringMembers[index];
        final color = avatarColors[index % avatarColors.length];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Text(
                  member.name.trim().isNotEmpty
                      ? member.name.trim()[0].toUpperCase()
                      : '?',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    Text("Expires: ${member.expiryDate}",
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${member.daysLeft} days",
                  style: AppTextStyles.label.copyWith(
                      color: AppColors.danger, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpcomingClasses() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fitness_center, color: AppColors.accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Morning Yoga Flow",
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                Text("Today, 08:30 AM • Trainer: Sarah",
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text("Details"),
          ),
        ],
      ),
    );
  }
}
