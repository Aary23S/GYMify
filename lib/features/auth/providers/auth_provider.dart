import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

enum LoginMethod {
  phoneOtp,
}

enum AppPermission {
  viewDashboard,
  manageMembers,
  manageTrainers,
  viewAttendance,
  manageAttendance,
  managePayments,
  viewReports,
  manageClasses,
  manageSettings,
  viewAnalytics,
  manageUsers,
  manageGym,
}

class AuthState {
  final UserRole selectedRole;
  final bool isLoggedIn;
  final UserModel? user;
  final LoginMethod loginMethod;
  final String? enteredPhone;
  final bool isLoading;

  AuthState({
    required this.selectedRole,
    required this.isLoggedIn,
    this.user,
    this.loginMethod = LoginMethod.phoneOtp,
    this.enteredPhone,
    this.isLoading = false,
  });

  UserRole get role => selectedRole;

  Set<AppPermission> get permissions {
    switch (selectedRole) {
      case UserRole.owner:
        return AppPermission.values.toSet();
      case UserRole.trainer:
        return {
          AppPermission.viewDashboard,
          AppPermission.manageMembers, // Assigned members only (logic in UI)
          AppPermission.viewAttendance,
          AppPermission.manageAttendance,
          AppPermission.manageClasses,
          AppPermission.manageSettings, // Profile settings
        };
      case UserRole.member:
        return {
          AppPermission.viewDashboard, // Personal dashboard
          AppPermission.viewAttendance, // Personal history
          AppPermission.manageClasses, // Booking
          AppPermission.manageSettings, // Profile settings
        };
    }
  }

  bool hasPermission(AppPermission permission) =>
      permissions.contains(permission);

  AuthState copyWith({
    UserRole? selectedRole,
    bool? isLoggedIn,
    UserModel? user,
    LoginMethod? loginMethod,
    String? enteredPhone,
    bool? isLoading,
  }) {
    return AuthState(
      selectedRole: selectedRole ?? this.selectedRole,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: user ?? this.user,
      loginMethod: loginMethod ?? this.loginMethod,
      enteredPhone: enteredPhone ?? this.enteredPhone,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier()
      : super(AuthState(
          selectedRole: UserRole.owner,
          isLoggedIn: false,
        ));

  void setRole(UserRole role) {
    state = state.copyWith(selectedRole: role);
  }

  void setLoginMethod(LoginMethod method) {
    state = state.copyWith(loginMethod: method);
  }

  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, enteredPhone: phone);
    await Future.delayed(const Duration(milliseconds: 1500));
    state = state.copyWith(isLoading: false);
    return true;
  }

  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1000));

    if (otp == '1234') {
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        user: dummyUsers[state.selectedRole],
      );
      return true;
    } else {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1500));
    state = state.copyWith(
      isLoading: false,
      isLoggedIn: true,
      user: dummyUsers[state.selectedRole],
    );
  }

  void logout() {
    state = state.copyWith(
      isLoggedIn: false,
      user: null,
    );
  }

  void loginAsNewMember(UserModel newUser) {
    state = state.copyWith(
      selectedRole: UserRole.member,
      isLoggedIn: true,
      user: newUser,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final permissionsProvider = Provider<Set<AppPermission>>((ref) {
  return ref.watch(authProvider).permissions;
});
