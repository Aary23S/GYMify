import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/gym_logo_widget.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authProvider.notifier).login(
            _emailController.text,
            _passwordController.text,
          );
      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  Future<void> _handleSendOtp() async {
    if (_formKey.currentState!.validate()) {
      final success =
          await ref.read(authProvider.notifier).sendOtp(_phoneController.text);
      if (success && mounted) {
        context.push('/otp-verify');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isEmailLogin = authState.loginMethod == LoginMethod.emailPassword;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          // TOP SECTION (35%)
          Expanded(
            flex: 35,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const GymLogoWidget(size: 80),
                  const SizedBox(height: 16),
                  Text('GymFlow',
                      style: AppTextStyles.displayMedium
                          .copyWith(color: AppColors.textOnDark)),
                  Text(
                    'Your Fitness Journey Starts Here',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textOnDark.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
          ),

          // BOTTOM SECTION (65%)
          Expanded(
            flex: 65,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LOGIN METHOD TOGGLE
                      _buildMethodToggle(isEmailLogin),
                      const SizedBox(height: 32),

                      if (isEmailLogin)
                        _buildEmailLoginForm(authState)
                      else
                        _buildPhoneLoginForm(authState),

                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Expanded(
                              child: Divider(
                                  color: AppColors.border, thickness: 1.5)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('DEMO ROLE',
                                style: AppTextStyles.label.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const Expanded(
                              child: Divider(
                                  color: AppColors.border, thickness: 1.5)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildRoleSelector(authState),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodToggle(bool isEmailLogin) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment:
                isEmailLogin ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: (MediaQuery.of(context).size.width - 56) / 2,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => ref
                      .read(authProvider.notifier)
                      .setLoginMethod(LoginMethod.emailPassword),
                  child: Center(
                    child: Text(
                      'Email',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color:
                            isEmailLogin ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => ref
                      .read(authProvider.notifier)
                      .setLoginMethod(LoginMethod.phoneOtp),
                  child: Center(
                    child: Text(
                      'Phone',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: !isEmailLogin
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmailLoginForm(AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome Back',
            style:
                AppTextStyles.heading2.copyWith(color: AppColors.textPrimary)),
        Text('Sign in to your account',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        TextFormField(
          controller: _emailController,
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'owner@gymflow.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) {
            if (value == null || !value.contains('@') || !value.contains('.')) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility),
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          validator: (value) {
            if (value == null || value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: Text('Forgot Password?',
                style: AppTextStyles.label.copyWith(
                    color: AppColors.accent, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          text: 'Sign In',
          isLoading: state.isLoading,
          onPressed: _handleEmailLogin,
        ),
      ],
    );
  }

  Widget _buildPhoneLoginForm(AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phone Login',
            style:
                AppTextStyles.heading2.copyWith(color: AppColors.textPrimary)),
        Text('Enter your number to receive OTP',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Center(
                child: Text('+91',
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '9876543210',
                ),
                validator: (value) {
                  if (value == null ||
                      value.length != 10 ||
                      !RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
                    return 'Enter a valid 10-digit number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          text: 'Send OTP',
          isLoading: state.isLoading,
          onPressed: _handleSendOtp,
        ),
      ],
    );
  }

  Widget _buildRoleSelector(AuthState state) {
    return Center(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: UserRole.values.map((role) {
          final isSelected = state.selectedRole == role;
          return ChoiceChip(
            label: Text(role.displayName),
            selected: isSelected,
            onSelected: (_) => ref.read(authProvider.notifier).setRole(role),
            selectedColor: AppColors.accent,
            backgroundColor: Colors.white,
            checkmarkColor: Colors.white,
            labelStyle: AppTextStyles.label.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.bold,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? AppColors.accent : AppColors.border,
                width: 1.5,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
