import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/screens/members_list_screen.dart';
import '../../attendance/screens/attendance_screen.dart';
import '../../payments/screens/payments_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/providers/navigation_provider.dart';
import 'owner_dashboard_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    // Initialize the index based on the current route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncIndexWithRoute();
    });
  }

  void _syncIndexWithRoute() {
    final location = GoRouterState.of(context).matchedLocation;
    final authState = ref.read(authProvider);

    final List<AppPermission> orderedPermissions = [
      AppPermission.viewDashboard,
      AppPermission.manageMembers,
      AppPermission.viewAttendance,
      AppPermission.managePayments,
      AppPermission.manageSettings,
    ];

    AppPermission? targetPermission;
    if (location == '/attendance') {
      targetPermission = AppPermission.viewAttendance;
    } else if (location == '/payments') {
      targetPermission = AppPermission.managePayments;
    } else if (location == '/settings') {
      targetPermission = AppPermission.manageSettings;
    } else if (location == '/members') {
      targetPermission = AppPermission.manageMembers;
    } else if (location == '/dashboard') {
      targetPermission = AppPermission.viewDashboard;
    }

    if (targetPermission != null) {
      int visibleIndex = 0;
      for (var p in orderedPermissions) {
        if (authState.hasPermission(p)) {
          if (p == targetPermission) {
            ref.read(bottomNavIndexProvider.notifier).state = visibleIndex;
            break;
          }
          visibleIndex++;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final selectedIndex = ref.watch(bottomNavIndexProvider);

    // Define all potential destinations
    final Map<AppPermission, NavigationDestination> allDestinations = {
      AppPermission.viewDashboard: const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      AppPermission.manageMembers: const NavigationDestination(
        icon: Icon(Icons.people_outlined),
        selectedIcon: Icon(Icons.people_rounded),
        label: 'Members',
      ),
      AppPermission.viewAttendance: const NavigationDestination(
        icon: Icon(Icons.check_circle_outline),
        selectedIcon: Icon(Icons.check_circle_rounded),
        label: 'Attendance',
      ),
      AppPermission.manageClasses: const NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month_rounded),
        label: 'Classes',
      ),
      AppPermission.managePayments: const NavigationDestination(
        icon: Icon(Icons.currency_rupee_outlined),
        selectedIcon: Icon(Icons.currency_rupee_rounded),
        label: 'Payments',
      ),
      AppPermission.viewReports: const NavigationDestination(
        icon: Icon(Icons.bar_chart_outlined),
        selectedIcon: Icon(Icons.bar_chart_rounded),
        label: 'Reports',
      ),
      AppPermission.manageSettings: const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings_rounded),
        label: 'Settings',
      ),
    };

    // Define all potential screens
    final Map<AppPermission, Widget> allScreens = {
      AppPermission.viewDashboard: const OwnerDashboardScreen(),
      AppPermission.manageMembers: const MembersListScreen(),
      AppPermission.viewAttendance: const AttendanceScreen(),
      AppPermission.manageClasses:
          const Center(child: Text('Classes Screen Placeholder')),
      AppPermission.managePayments: const PaymentsScreen(),
      AppPermission.viewReports:
          const Center(child: Text('Reports Screen Placeholder')),
      AppPermission.manageSettings: const SettingsScreen(),
    };

    // Filter based on role permissions
    final List<NavigationDestination> destinations = [];
    final List<Widget> screens = [];

    // Order matters for the bottom nav - Maximum 5 items to prevent congestion
    final List<AppPermission> orderedPermissions = [
      AppPermission.viewDashboard,
      AppPermission.manageMembers,
      AppPermission.viewAttendance,
      AppPermission.managePayments,
      AppPermission.manageSettings,
    ];

    for (var permission in orderedPermissions) {
      if (authState.hasPermission(permission)) {
        if (allDestinations.containsKey(permission)) {
          destinations.add(allDestinations[permission]!);
          screens.add(allScreens[permission]!);
        }
      }
    }

    // Safety check for index out of bounds when role changes
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
