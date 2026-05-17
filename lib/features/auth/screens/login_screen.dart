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
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
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
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textOnDark.withValues(alpha: 0.9)),
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
                      _buildPhoneLoginForm(authState),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: () => context.push('/signup'),
                          child: RichText(
                            text: TextSpan(
                              text: "New to GymFlow? ",
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.textSecondary),
                              children: [
                                TextSpan(
                                  text: "Sign Up",
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildPhoneLoginForm(AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Login',
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
