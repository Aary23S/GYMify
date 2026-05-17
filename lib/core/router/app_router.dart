import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/otp_verify_screen.dart';
import '../../features/dashboard/screens/main_shell.dart';
import '../../features/members/screens/add_member_screen.dart';
import '../../features/members/screens/member_profile_screen.dart';
import '../../features/attendance/screens/member_attendance_detail_screen.dart';
import '../../features/attendance/screens/member_qr_screen.dart';
import '../../features/attendance/screens/qr_scanner_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/payments/screens/member_payment_screen.dart';
import '../../features/auth/providers/auth_provider.dart';

CustomTransitionPage<void> _fadeTransitionPage({
  required GoRouterState state,
  required Widget child,
  Duration duration = const Duration(milliseconds: 200),
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

CustomTransitionPage<void> _slideTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        pageBuilder: (context, state) => _fadeTransitionPage(state: state, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => _fadeTransitionPage(state: state, child: const OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _fadeTransitionPage(state: state, child: const LoginScreen(), duration: const Duration(milliseconds: 400)),
      ),
      GoRoute(
        path: '/otp-verify',
        name: 'otp-verify',
        pageBuilder: (context, state) => _slideTransitionPage(state: state, child: const OtpVerifyScreen()),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        pageBuilder: (context, state) => _fadeTransitionPage(state: state, child: const MainShell()),
      ),
      GoRoute(
        path: '/attendance',
        name: 'attendance',
        pageBuilder: (context, state) => _fadeTransitionPage(state: state, child: const MainShell()),
      ),
      GoRoute(
        path: '/payments',
        name: 'payments',
        pageBuilder: (context, state) => _fadeTransitionPage(state: state, child: const MainShell()),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => _slideTransitionPage(state: state, child: const SettingsScreen()),
      ),
      GoRoute(
        path: '/members',
        name: 'members',
        pageBuilder: (context, state) => _fadeTransitionPage(state: state, child: const MainShell()),
      ),
      GoRoute(
        path: '/trainer/members',
        name: 'trainer-members',
        pageBuilder: (context, state) => _fadeTransitionPage(state: state, child: const MainShell()),
      ),
      GoRoute(
        path: '/members/add',
        name: 'add-member',
        pageBuilder: (context, state) => _slideTransitionPage(state: state, child: const AddMemberScreen()),
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
        pageBuilder: (context, state) {
          final memberId = state.pathParameters['memberId']!;
          return _slideTransitionPage(state: state, child: MemberProfileScreen(memberId: memberId));
        },
      ),
      GoRoute(
        path: '/member/pay-fees',
        name: 'member-pay-fees',
        pageBuilder: (context, state) => _slideTransitionPage(state: state, child: const MemberPaymentScreen()),
      ),
      GoRoute(
        path: '/member/payment-success',
        name: 'payment-success',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final amount = (extra['amount'] as num?)?.toDouble() ?? 2500.0;
          final planName = extra['planName'] as String? ?? 'Monthly Standard';
          final mode = extra['mode'] as String? ?? 'UPI';
          return _slideTransitionPage(state: state, child: PaymentSuccessScreen(amount: amount, planName: planName, mode: mode));
        },
      ),
      GoRoute(
        path: '/member/classes',
        name: 'member-classes',
        pageBuilder: (context, state) => _fadeTransitionPage(state: state, child: const MainShell()),
      ),
      GoRoute(
        path: '/attendance/:memberId',
        name: 'member-attendance-detail',
        pageBuilder: (context, state) {
          final memberId = state.pathParameters['memberId']!;
          return _slideTransitionPage(state: state, child: MemberAttendanceDetailScreen(memberId: memberId));
        },
      ),
      GoRoute(
        path: '/my-qr',
        name: 'my-qr',
        pageBuilder: (context, state) => _slideTransitionPage(state: state, child: const MemberQrScreen()),
      ),
      GoRoute(
        path: '/scan-qr',
        name: 'scan-qr',
        pageBuilder: (context, state) {
          final action = state.uri.queryParameters['action'] ?? 'checkin';
          return _slideTransitionPage(state: state, child: QrScannerScreen(action: action));
        },
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        pageBuilder: (context, state) => _slideTransitionPage(state: state, child: const SignupScreen()),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/otp-verify' || state.matchedLocation == '/signup';
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
