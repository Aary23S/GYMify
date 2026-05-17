import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_verify_screen.dart';
import '../../features/dashboard/screens/main_shell.dart';
import '../../features/members/screens/add_member_screen.dart';
import '../../features/members/screens/members_list_screen.dart';
import '../../features/members/screens/member_profile_screen.dart';
import '../../features/attendance/screens/attendance_screen.dart';
import '../../features/payments/screens/payments_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/auth/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp-verify',
        name: 'otp-verify',
        builder: (context, state) => const OtpVerifyScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/attendance',
        name: 'attendance',
        builder: (context, state) =>
            const MainShell(), // Opens shell where Attendance is a tab
      ),
      GoRoute(
        path: '/payments',
        name: 'payments',
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/members',
        name: 'members',
        builder: (context, state) =>
            const MainShell(), // Should ideally navigate to the members tab in MainShell
      ),
      GoRoute(
        path: '/members/add',
        name: 'add-member',
        builder: (context, state) => const AddMemberScreen(),
        redirect: (context, state) {
          final authState = ref.read(authProvider);
          if (!authState.hasPermission(AppPermission.manageMembers)) {
            return '/dashboard';
          }
          return null;
        },
      ),
      GoRoute(
        path: '/members/:memberId',
        name: 'member-profile',
        builder: (context, state) {
          final memberId = state.pathParameters['memberId']!;
          return MemberProfileScreen(memberId: memberId);
        },
      ),
      GoRoute(
        path: '/member/pay-fees',
        name: 'member-pay-fees',
        builder: (context, state) => const MainShell(),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/otp-verify';
      final inSplash = state.matchedLocation == '/';
      final inOnboarding = state.matchedLocation == '/onboarding';

      if (!authState.isLoggedIn && !loggingIn && !inSplash && !inOnboarding) {
        return '/login';
      }

      if (authState.isLoggedIn && (loggingIn || inOnboarding)) {
        return '/dashboard';
      }

      return null;
    },
  );
});
