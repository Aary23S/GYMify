import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_verify_screen.dart';
import '../../features/dashboard/screens/main_shell.dart';
import '../../features/members/screens/add_member_screen.dart';
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
        path: '/members/add',
        name: 'add-member',
        builder: (context, state) {
          final authState = ref.read(authProvider);
          if (authState.hasPermission(AppPermission.manageMembers)) {
            return const AddMemberScreen();
          }
          return const MainShell(); // Simple redirect for Phase 1
        },
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
