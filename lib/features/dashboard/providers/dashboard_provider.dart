import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dummy_data/dummy_dashboard.dart';

class DashboardState {
  final int totalMembers;
  final int activeToday;
  final int expiringSoon;
  final double revenueToday;
  final List<WeeklyRevenue> weeklyRevenue;
  final List<int> last30DaysAttendance;
  final List<ExpiringMember> expiringMembers;

  DashboardState({
    required this.totalMembers,
    required this.activeToday,
    required this.expiringSoon,
    required this.revenueToday,
    required this.weeklyRevenue,
    required this.last30DaysAttendance,
    required this.expiringMembers,
  });
}

final dashboardProvider = Provider<DashboardState>((ref) {
  return DashboardState(
    totalMembers: DummyDashboardData.totalMembers,
    activeToday: DummyDashboardData.activeToday,
    expiringSoon: DummyDashboardData.expiringSoon,
    revenueToday: DummyDashboardData.revenueToday,
    weeklyRevenue: DummyDashboardData.weeklyRevenue,
    last30DaysAttendance: DummyDashboardData.last30DaysAttendance,
    expiringMembers: DummyDashboardData.expiringMembers,
  );
});
