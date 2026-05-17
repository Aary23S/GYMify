import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../models/member_model.dart';
import '../providers/members_provider.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({super.key});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _healthNotesController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  // Form State
  DateTime? _dob;
  String? _gender;
  String _bloodGroup = 'Unknown';
  String? _selectedPlan;
  DateTime _joinDate = DateTime.now();
  String? _assignedTrainer;

  bool _isFormDirty = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _plans = [
    {'name': 'Monthly Basic', 'price': 1500, 'duration': 30},
    {'name': 'Monthly Standard', 'price': 2500, 'duration': 30},
    {'name': 'Quarterly Premium', 'price': 6500, 'duration': 90},
    {'name': 'Annual Elite', 'price': 22000, 'duration': 365},
  ];

  final List<String> _trainers = [
    'None',
    'Sneha Kapoor',
    'Rahul Mehta',
    'Vikram Singh',
    'Priya Nair'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _healthNotesController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isFormDirty) {
      setState(() => _isFormDirty = true);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isFormDirty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
            'You have unsaved member information. Are you sure you want to go back?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Editing'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Discard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _selectDate(BuildContext context,
      {required DateTime initialDate,
      required DateTime firstDate,
      required DateTime lastDate,
      required Function(DateTime) onSelected}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        onSelected(picked);
        _markDirty();
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Fake loading
      await Future.delayed(const Duration(milliseconds: 1500));

      final membersNotifier = ref.read(membersProvider.notifier);
      final nextNumber = membersNotifier.nextMemberNumber;
      final memberCode = 'GYM-2026-${nextNumber.toString().padLeft(4, '0')}';

      final selectedPlanData =
          _plans.firstWhere((p) => p['name'] == _selectedPlan);
      final expiryDate =
          _joinDate.add(Duration(days: selectedPlanData['duration']));

      final newMember = Member(
        id: const Uuid().v4(),
        memberCode: memberCode,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        dateOfBirth: _dob!,
        gender: _gender!,
        planName: _selectedPlan!,
        planPrice: (selectedPlanData['price'] as int).toDouble(),
        status: MemberStatus.active,
        joinDate: _joinDate,
        planExpiry: expiryDate,
        assignedTrainerId: _assignedTrainer == 'None' ? null : (_assignedTrainer == 'Sneha Kapoor' ? 'usr_trainer' : 'trn_other'),
        assignedTrainerName:
            _assignedTrainer == 'None' ? null : _assignedTrainer,
        bloodGroup: _bloodGroup == 'Unknown' ? null : _bloodGroup,
        address: _addressController.text.trim(),
        emergencyContactName: _emergencyNameController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim(),
      );

      membersNotifier.addMember(newMember);

      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showSuccess(context, '✓ ${newMember.name} added successfully! ID: ${newMember.memberCode}');
        context.go('/members/${newMember.id}');
      }
    } else {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Add New Member', style: AppTextStyles.heading3),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/dashboard');
                  }
                }
              }
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(
                height: 1, color: AppColors.border.withValues(alpha: 0.5)),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Form(
                key: _formKey,
                onChanged: _markDirty,
                child: Column(
                  children: [
                    _buildPhotoSection(),
                    const SizedBox(height: 24),
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 16),
                    _buildMembershipSection(),
                    const SizedBox(height: 16),
                    _buildEmergencySection(),
                    const SizedBox(height: 16),
                    _buildAdditionalSection(),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              SnackbarHelper.showInfo(context, 'Photo upload available in next version');
            },
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.person,
                      size: 50,
                      color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.accent,
                    child: const Icon(Icons.camera_alt,
                        size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Tap to add photo (optional)',
              style: AppTextStyles.caption.copyWith(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      {required IconData icon,
      required String title,
      required Widget child}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.heading4),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSectionCard(
      icon: Icons.person_outline,
      title: 'Personal Information',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 380;

          final phoneField = TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration:
                _inputDecoration('Mobile Number *', Icons.phone_outlined)
                    .copyWith(counterText: ""),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (value.length != 10) return 'Exactly 10 digits';
              if (!RegExp(r'^[6-9]').hasMatch(value)) {
                return 'Must start with 6-9';
              }
              return null;
            },
          );

          final emailField = TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration:
                _inputDecoration('Email (optional)', Icons.email_outlined),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Invalid email';
                }
              }
              return null;
            },
          );

          final dobField = TextFormField(
            readOnly: true,
            onTap: () => _selectDate(
              context,
              initialDate:
                  DateTime.now().subtract(const Duration(days: 365 * 25)),
              firstDate:
                  DateTime.now().subtract(const Duration(days: 365 * 80)),
              lastDate:
                  DateTime.now().subtract(const Duration(days: 365 * 13)),
              onSelected: (date) => _dob = date,
            ),
            decoration:
                _inputDecoration('Date of Birth *', Icons.cake_outlined),
            controller: TextEditingController(
              text: _dob != null
                  ? DateFormat('dd MMM yyyy').format(_dob!)
                  : '',
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
          );

          final genderField = DropdownButtonFormField<String>(
            initialValue: _gender,
            isExpanded: true,
            decoration: _inputDecoration('Gender *', Icons.wc_outlined),
            items: ['Male', 'Female', 'Other']
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (val) => setState(() => _gender = val),
            validator: (val) => val == null ? 'Required' : null,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Full Name *', Icons.badge_outlined),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Full name is required';
                  if (value.length < 2) return 'Min 2 characters';
                  if (RegExp(r'[0-9]').hasMatch(value)) return 'Numbers not allowed';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (isSmall) ...[
                phoneField,
                const SizedBox(height: 16),
                emailField,
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: phoneField),
                    const SizedBox(width: 12),
                    Expanded(child: emailField),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (isSmall) ...[
                dobField,
                const SizedBox(height: 16),
                genderField,
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: dobField),
                    const SizedBox(width: 12),
                    Expanded(child: genderField),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _bloodGroup,
                isExpanded: true,
                decoration: _inputDecoration('Blood Group', Icons.bloodtype_outlined),
                items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown']
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (val) => setState(() => _bloodGroup = val!),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMembershipSection() {
    return _buildSectionCard(
      icon: Icons.card_membership,
      title: 'Membership Details',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedPlan,
            decoration:
                _inputDecoration('Membership Plan *', Icons.fitness_center),
            isExpanded: true,
            items: _plans.map((p) {
              return DropdownMenuItem<String>(
                value: p['name'],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p['name'] as String, style: AppTextStyles.bodyMedium),
                    Text(
                        '₹${p['price']} / ${p['duration'] == 30 ? 'month' : p['duration'] == 90 ? '3 months' : 'year'}',
                        style:
                            AppTextStyles.caption.copyWith(color: Colors.grey)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedPlan = val),
            validator: (val) => val == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            readOnly: true,
            onTap: () => _selectDate(
              context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
              onSelected: (date) => _joinDate = date,
            ),
            decoration:
                _inputDecoration('Join Date *', Icons.calendar_today_outlined),
            controller: TextEditingController(
              text: DateFormat('dd MMM yyyy').format(_joinDate),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _assignedTrainer ?? 'None',
            isExpanded: true,
            decoration: _inputDecoration(
                'Assign Personal Trainer', Icons.person_pin_outlined),
            items: _trainers
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (val) => setState(() => _assignedTrainer = val),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySection() {
    return _buildSectionCard(
      icon: Icons.emergency,
      title: 'Emergency Contact',
      child: Column(
        children: [
          TextFormField(
            controller: _emergencyNameController,
            decoration:
                _inputDecoration('Contact Person Name', Icons.person_outline),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emergencyPhoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration:
                _inputDecoration('Contact Phone Number', Icons.phone_outlined)
                    .copyWith(counterText: ""),
            validator: (value) {
              if (value != null && value.isNotEmpty && value.length != 10) {
                return 'Must be 10 digits';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalSection() {
    return _buildSectionCard(
      icon: Icons.more_horiz,
      title: 'Additional Details',
      child: Column(
        children: [
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            decoration: _inputDecoration('Address', Icons.location_on_outlined),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _healthNotesController,
            maxLines: 3,
            decoration: _inputDecoration('Health Conditions / Notes',
                    Icons.medical_information_outlined)
                .copyWith(hintText: "e.g., knee injury, diabetes, allergies..."),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -4),
              blurRadius: 10)
        ],
      ),
      child: PrimaryButton(
        text: 'Add Member',
        onPressed: _submitForm,
        isLoading: _isLoading,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      labelStyle: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
      floatingLabelStyle:
          AppTextStyles.caption.copyWith(color: AppColors.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
