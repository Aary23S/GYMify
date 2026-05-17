import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/gym_logo_widget.dart';
import '../../members/models/member_model.dart';
import '../../members/providers/members_provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _pageController = PageController();
  int _currentStep = 1; // 1: Personal, 2: Contact, 3: Plan
  bool _isLoading = false;

  // Form Keys
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  // Step 1 Controllers & State
  final _nameController = TextEditingController();
  DateTime? _dob;
  String? _gender;
  String _bloodGroup = 'Unknown';

  // Step 2 Controllers & State
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  // Step 3 State
  int? _selectedPlanIndex;

  final List<Map<String, dynamic>> _plans = [
    {
      'name': 'Monthly Basic',
      'price': 1500,
      'duration': 30,
      'durationText': '1 Month',
      'features': ['General Floor Access', 'Locker Usage', 'Basic Equipment']
    },
    {
      'name': 'Monthly Standard',
      'price': 2500,
      'duration': 30,
      'durationText': '1 Month',
      'features': ['All Equipment Access', 'Group Yoga Sessions', 'Free Health Consultation']
    },
    {
      'name': 'Quarterly Premium',
      'price': 6500,
      'duration': 90,
      'durationText': '3 Months',
      'features': ['Access to HIIT & Zumba', '1-on-1 Trainer Assessment', 'Priority Booking']
    },
    {
      'name': 'Annual Elite',
      'price': 22000,
      'duration': 365,
      'durationText': '12 Months',
      'features': ['Unlimited Studio Classes', 'Personal Locker Included', 'Free Dietician Session']
    },
  ];

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroupOptions = [
    'Unknown',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (!_formKey1.currentState!.validate()) return;
      if (_dob == null || _gender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter Date of Birth and Gender")),
        );
        return;
      }
    } else if (_currentStep == 2) {
      if (!_formKey2.currentState!.validate()) return;
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedPlanIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a membership plan to continue.")),
      );
      return;
    }

    // Final complete validation
    if (!_formKey1.currentState!.validate() || !_formKey2.currentState!.validate() || _dob == null || _gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all required fields correctly in previous steps.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    final nextNum = ref.read(membersProvider.notifier).nextMemberNumber;
    final memberCode = 'GYM-2026-${nextNum.toString().padLeft(4, '0')}';
    final selectedPlan = _plans[_selectedPlanIndex!];
    final now = DateTime.now();

    final newMember = Member(
      id: 'usr_mem_${DateTime.now().millisecondsSinceEpoch}',
      memberCode: memberCode,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? 'member@gymflow.com' : _emailController.text.trim(),
      dateOfBirth: _dob!,
      gender: _gender!,
      planName: selectedPlan['name'],
      planPrice: selectedPlan['price'].toDouble(),
      status: MemberStatus.active,
      joinDate: now,
      planExpiry: now.add(Duration(days: selectedPlan['duration'])),
      assignedTrainerId: null,
      assignedTrainerName: null,
      bloodGroup: _bloodGroup == 'Unknown' ? null : _bloodGroup,
      emergencyContactName: _emergencyNameController.text.trim().isEmpty ? 'Emergency Contact' : _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim().isEmpty ? _phoneController.text.trim() : _emergencyPhoneController.text.trim(),
    );

    final newUserModel = UserModel(
      id: newMember.id,
      name: newMember.name,
      email: newMember.email,
      role: UserRole.member,
      gymName: 'GymFlow Fitness Center',
    );

    ref.read(membersProvider.notifier).addMember(newMember);
    ref.read(authProvider.notifier).loginAsNewMember(newUserModel);

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Welcome to GymFlow, ${newMember.name}! 🎉"),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
      context.go('/dashboard');
    }
  }

  Future<void> _selectDob(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 80)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 12)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dob) {
      setState(() => _dob = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const GymLogoWidget(size: 70),
                    const SizedBox(height: 12),
                    Text('GymFlow', style: AppTextStyles.displayMedium.copyWith(color: AppColors.textOnDark, fontSize: 28)),
                    const SizedBox(height: 4),
                    Text(
                      'Join Your Fitness Journey',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textOnDark.withValues(alpha: 0.9), fontSize: 14),
                    ),
                  ],
                ),
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Create Account", style: AppTextStyles.heading1.copyWith(color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text("Fill in your details to get started", style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 24),

                    // STEP INDICATOR
                    _buildStepIndicator(),
                    const SizedBox(height: 32),

                    // STEP PAGES
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStep1Personal(),
                          _buildStep2Contact(),
                          _buildStep3Plan(),
                        ],
                      ),
                    ),

                    // FIXED BOTTOM NAVIGATION BUTTONS
                    const SizedBox(height: 16),
                    _buildBottomButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepItem(1, "Personal"),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep > 1 ? AppColors.success : Colors.grey[200],
          ),
        ),
        _buildStepItem(2, "Contact"),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep > 2 ? AppColors.success : Colors.grey[200],
          ),
        ),
        _buildStepItem(3, "Membership"),
      ],
    );
  }

  Widget _buildStepItem(int stepNum, String title) {
    final isCompleted = _currentStep > stepNum;
    final isActive = _currentStep == stepNum;

    Color bg;
    Color fg;
    Widget inner;

    if (isCompleted) {
      bg = AppColors.success;
      fg = Colors.white;
      inner = const Icon(Icons.check, size: 16, color: Colors.white);
    } else if (isActive) {
      bg = AppColors.accent;
      fg = Colors.white;
      inner = Text("$stepNum", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14));
    } else {
      bg = Colors.white;
      fg = Colors.grey[400]!;
      inner = Text("$stepNum", style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 14));
    }

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
            border: isCompleted || isActive ? null : Border.all(color: fg, width: 2),
          ),
          child: Center(child: inner),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppColors.textPrimary : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStep1Personal() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration("Full Name *", Icons.person_outline),
              validator: (val) => val == null || val.trim().isEmpty ? "Full name is required" : null,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDob(context),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: TextEditingController(text: _dob != null ? DateFormat('dd MMM yyyy').format(_dob!) : ''),
                        decoration: _inputDecoration("Date of Birth *", Icons.cake_outlined),
                        validator: (val) => _dob == null ? "Required" : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: _inputDecoration("Gender *", Icons.wc_outlined),
                    items: _genderOptions
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) => setState(() => _gender = val),
                    validator: (val) => val == null ? "Required" : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _bloodGroup,
              decoration: _inputDecoration("Blood Group (Optional)", Icons.water_drop_outlined),
              items: _bloodGroupOptions
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (val) => setState(() => _bloodGroup = val!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Contact() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: _inputDecoration("Mobile Number *", Icons.phone_outlined).copyWith(counterText: ""),
              validator: (val) {
                if (val == null || val.isEmpty) return "Required";
                if (val.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(val)) return "Enter a valid 10-digit number";
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration("Email Address (Optional)", Icons.email_outlined),
              validator: (val) {
                if (val != null && val.isNotEmpty) {
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) return "Invalid email";
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emergencyNameController,
                    decoration: _inputDecoration("Emergency Contact", Icons.health_and_safety_outlined),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _emergencyPhoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: _inputDecoration("Emergency Phone", Icons.phone_callback_outlined).copyWith(counterText: ""),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3Plan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select Your Membership Plan", style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: _plans.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final plan = _plans[index];
              final isSel = _selectedPlanIndex == index;

              return GestureDetector(
                onTap: () => setState(() => _selectedPlanIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.accent.withValues(alpha: 0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSel ? AppColors.accent : AppColors.border,
                      width: isSel ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      if (isSel)
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(plan['name'], style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary)),
                          ),
                          if (isSel)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
                              child: const Icon(Icons.check, size: 14, color: Colors.white),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text("₹${NumberFormat('#,##0').format(plan['price'])}", style: AppTextStyles.heading1.copyWith(color: AppColors.primary)),
                          Text(" / ${plan['durationText']}", style: AppTextStyles.caption.copyWith(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      ...(plan['features'] as List<String>).map((feat) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                                const SizedBox(width: 8),
                                Expanded(child: Text(feat, style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.danger, width: 2)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.arrow_back),
          label: Text(_currentStep == 1 ? "Login" : "Back"),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _isLoading ? null : _prevStep,
        ),
        const Spacer(),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _isLoading ? null : (_currentStep < 3 ? _nextStep : _handleSubmit),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_currentStep < 3 ? "Next" : "Create Account", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (_currentStep < 3) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
