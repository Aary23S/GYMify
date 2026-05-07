import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/screens/members_list_screen.dart';
import 'owner_dashboard_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

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
      AppPermission.manageClasses: const NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month_rounded),
        label: 'Classes',
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
      AppPermission.manageClasses:
          const Center(child: Text('Classes Screen Placeholder')),
      AppPermission.viewReports:
          const Center(child: Text('Reports Screen Placeholder')),
      AppPermission.manageSettings:
          const Center(child: Text('Settings Screen Placeholder')),
    };

    // Filter based on role permissions
    final List<NavigationDestination> destinations = [];
    final List<Widget> screens = [];

    // Order matters for the bottom nav
    final List<AppPermission> orderedPermissions = [
      AppPermission.viewDashboard,
      AppPermission.manageMembers,
      AppPermission.manageClasses,
      AppPermission.viewReports,
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
    final safeIndex = _selectedIndex >= screens.length ? 0 : _selectedIndex;

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          indicatorColor: AppColors.accent.withOpacity(0.2),
          backgroundColor: Colors.white,
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: destinations,
        ),
      ),
    );
  }
}
