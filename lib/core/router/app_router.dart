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
        builder: (context, state) => const MainShell(),
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
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/trainer/members',
        name: 'trainer-members',
        builder: (context, state) => const MainShell(),
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
        builder: (context, state) => const MemberPaymentScreen(),
      ),
      GoRoute(
        path: '/member/payment-success',
        name: 'payment-success',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final amount = (extra['amount'] as num?)?.toDouble() ?? 2500.0;
          final planName = extra['planName'] as String? ?? 'Monthly Standard';
          final mode = extra['mode'] as String? ?? 'UPI';
          return PaymentSuccessScreen(amount: amount, planName: planName, mode: mode);
        },
      ),
      GoRoute(
        path: '/member/classes',
        name: 'member-classes',
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/attendance/:memberId',
        name: 'member-attendance-detail',
        builder: (context, state) {
          final memberId = state.pathParameters['memberId']!;
          return MemberAttendanceDetailScreen(memberId: memberId);
        },
      ),
      GoRoute(
        path: '/my-qr',
        name: 'my-qr',
        builder: (context, state) => const MemberQrScreen(),
      ),
      GoRoute(
        path: '/scan-qr',
        name: 'scan-qr',
        builder: (context, state) {
          final action = state.uri.queryParameters['action'] ?? 'checkin';
          return QrScannerScreen(action: action);
        },
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
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
