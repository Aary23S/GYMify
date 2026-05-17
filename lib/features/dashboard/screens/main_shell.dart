import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../../members/providers/members_provider.dart';
import '../../members/screens/members_list_screen.dart';
import '../../members/screens/member_profile_screen.dart';
import '../../attendance/screens/attendance_screen.dart';
import '../../attendance/screens/member_qr_screen.dart';
import '../../payments/screens/payments_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../classes/screens/member_classes_screen.dart';
import '../../../core/providers/navigation_provider.dart';
import 'owner_dashboard_screen.dart';
import 'member_dashboard_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncIndexWithRoute();
    });
  }

  void _syncIndexWithRoute() {
    final location = GoRouterState.of(context).matchedLocation;
    final authState = ref.read(authProvider);
    final role = authState.selectedRole;

    if (role == UserRole.member) {
      if (location == '/dashboard') {
        ref.read(bottomNavIndexProvider.notifier).state = 0;
      } else if (location == '/member/classes') {
        ref.read(bottomNavIndexProvider.notifier).state = 1;
      } else if (location == '/my-qr') {
        ref.read(bottomNavIndexProvider.notifier).state = 2;
      } else if (location.startsWith('/members/')) {
        ref.read(bottomNavIndexProvider.notifier).state = 3;
      }
    } else if (role == UserRole.trainer) {
      if (location == '/dashboard') {
        ref.read(bottomNavIndexProvider.notifier).state = 0;
      } else if (location.startsWith('/members') || location.startsWith('/trainer/members')) {
        ref.read(bottomNavIndexProvider.notifier).state = 1;
      } else if (location == '/attendance') {
        ref.read(bottomNavIndexProvider.notifier).state = 2;
      } else if (location == '/settings') {
        ref.read(bottomNavIndexProvider.notifier).state = 3;
      }
    } else {
      // Owner
      if (location == '/dashboard') {
        ref.read(bottomNavIndexProvider.notifier).state = 0;
      } else if (location.startsWith('/members')) {
        ref.read(bottomNavIndexProvider.notifier).state = 1;
      } else if (location == '/attendance') {
        ref.read(bottomNavIndexProvider.notifier).state = 2;
      } else if (location == '/payments') {
        ref.read(bottomNavIndexProvider.notifier).state = 3;
      } else if (location == '/settings') {
        ref.read(bottomNavIndexProvider.notifier).state = 4;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final selectedIndex = ref.watch(bottomNavIndexProvider);
    final role = authState.selectedRole;

    List<NavigationDestination> destinations;
    List<Widget> screens;

    if (role == UserRole.member) {
      final allMembers = ref.watch(membersProvider);
      final member = allMembers.firstWhere(
        (m) => m.name == authState.user?.name,
        orElse: () => allMembers.first,
      );

      destinations = const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Classes'),
        NavigationDestination(icon: Icon(Icons.qr_code_outlined), selectedIcon: Icon(Icons.qr_code_rounded), label: 'My QR'),
        NavigationDestination(icon: Icon(Icons.person_outlined), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
      ];

      screens = [
        const MemberDashboardScreen(),
        const MemberClassesScreen(),
        const MemberQrScreen(),
        MemberProfileScreen(memberId: member.id),
      ];
    } else if (role == UserRole.trainer) {
      destinations = const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people_rounded), label: 'My Members'),
        NavigationDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle_rounded), label: 'Attendance'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
      ];

      screens = [
        const OwnerDashboardScreen(),
        const MembersListScreen(),
        const AttendanceScreen(),
        const SettingsScreen(),
      ];
    } else {
      // Owner
      destinations = const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people_rounded), label: 'Members'),
        NavigationDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle_rounded), label: 'Attendance'),
        NavigationDestination(icon: Icon(Icons.currency_rupee_outlined), selectedIcon: Icon(Icons.currency_rupee_rounded), label: 'Payments'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
      ];

      screens = [
        const OwnerDashboardScreen(),
        const MembersListScreen(),
        const AttendanceScreen(),
        const PaymentsScreen(),
        const SettingsScreen(),
      ];
    }

    final safeIndex = selectedIndex >= screens.length ? 0 : selectedIndex;

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: (index) {
            ref.read(bottomNavIndexProvider.notifier).state = index;
          },
          indicatorColor: AppColors.accent.withValues(alpha: 0.2),
          backgroundColor: Colors.white,
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: destinations,
        ),
      ),
    );
  }
}
