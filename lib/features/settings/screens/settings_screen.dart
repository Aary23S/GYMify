import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/gym_logo_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/snackbar_helper.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: themeMode == ThemeMode.dark ? Colors.black : AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: themeMode == ThemeMode.dark ? Colors.black : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGymProfileCard(context),
            _SectionTitle(title: "Appearance"),
            _buildAppearanceSection(ref, themeMode),
            _SectionTitle(title: "Gym Management"),
            _buildGymManagementSection(context),
            _SectionTitle(title: "Notifications"),
            _buildNotificationsSection(),
            _SectionTitle(title: "Support & Legal"),
            _buildSupportSection(context),
            const SizedBox(height: 16),
            _buildLogoutCard(context, ref),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGymProfileCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const GymLogoWidget(size: 64),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("GymFlow Fitness Center", style: AppTextStyles.heading2),
                        Text("Nashik, Maharashtra", style: AppTextStyles.caption),
                        Text("📞 +91 98765 43210", style: AppTextStyles.caption),
                        Text("✉ info@gymflow.in", style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Text("Free Plan", style: AppTextStyles.caption.copyWith(color: Colors.grey.shade600)),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () {
                      SnackbarHelper.showInfo(context, "Edit profile coming soon");
                    },
                    child: const Text("Edit Profile"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(WidgetRef ref, ThemeMode themeMode) {
    return _SettingsTile(
      icon: Icons.dark_mode_outlined,
      iconColor: AppColors.primary,
      iconBgColor: AppColors.primary.withValues(alpha: 0.1),
      title: "Dark Mode",
      subtitle: "Switch between light and dark theme",
      trailing: Switch(
        value: themeMode == ThemeMode.dark,
        activeColor: AppColors.accent,
        onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
      ),
    );
  }

  Widget _buildGymManagementSection(BuildContext context) {
    return Column(
      children: [
        _SettingsTile(
          icon: Icons.storefront_outlined,
          iconColor: AppColors.primary,
          title: "Gym Profile",
          subtitle: "Name, logo, address, contact",
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () => _showComingSoon(context, "Gym profile editing"),
        ),
        _SettingsTile(
          icon: Icons.access_time_outlined,
          iconColor: Colors.teal,
          title: "Business Hours",
          subtitle: "Mon–Sat: 6:00 AM – 10:00 PM",
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () => _showComingSoon(context, "Business hours editing"),
        ),
        _SettingsTile(
          icon: Icons.card_membership_outlined,
          iconColor: Colors.purple,
          title: "Membership Plans",
          subtitle: "Manage your gym packages",
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBadge("4 plans"),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          onTap: () => _showComingSoon(context, "Plan management"),
        ),
        _SettingsTile(
          icon: Icons.people_outline,
          iconColor: Colors.indigo,
          title: "Staff Accounts",
          subtitle: "Manage admin and trainer accounts",
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBadge("5 staff"),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          onTap: () => _showStaffBottomSheet(context),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      children: [
        _SettingsTile(
          icon: Icons.notifications_outlined,
          iconColor: AppColors.warning,
          title: "Expiry Alerts",
          subtitle: "Alert when membership expires in 3 days",
          trailing: Switch(value: true, activeColor: AppColors.accent, onChanged: (_) {}),
        ),
        _SettingsTile(
          icon: Icons.payment_outlined,
          iconColor: AppColors.success,
          title: "Payment Reminders",
          subtitle: "Remind members of pending dues",
          trailing: Switch(value: true, activeColor: AppColors.accent, onChanged: (_) {}),
        ),
        _SettingsTile(
          icon: Icons.calendar_month_outlined,
          iconColor: Colors.blue,
          title: "Class Reminders",
          subtitle: "Notify members 1 hour before class",
          trailing: Switch(value: false, activeColor: AppColors.accent, onChanged: (_) {}),
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Column(
      children: [
        _SettingsTile(
          icon: Icons.help_outline,
          iconColor: Colors.teal,
          title: "Help & FAQ",
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () => _showComingSoon(context, "Help center"),
        ),
        _SettingsTile(
          icon: Icons.support_agent_outlined,
          iconColor: AppColors.primary,
          title: "Contact Support",
          subtitle: "support@gymflow.in",
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        ),
        _SettingsTile(
          icon: Icons.star_outline,
          iconColor: Colors.amber,
          title: "Rate GymFlow",
          subtitle: "Enjoying the app? Leave a review!",
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) => Icon(
              i < 4 ? Icons.star : Icons.star_outline,
              color: Colors.amber,
              size: 16,
            )),
          ),
        ),
        _SettingsTile(
          icon: Icons.description_outlined,
          iconColor: AppColors.textSecondary,
          title: "Terms of Service",
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        ),
        _SettingsTile(
          icon: Icons.privacy_tip_outlined,
          iconColor: AppColors.textSecondary,
          title: "Privacy Policy",
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        ),
        _SettingsTile(
          icon: Icons.info_outline,
          iconColor: AppColors.textSecondary,
          title: "App Version",
          trailing: Text("v1.0.0 (Phase 1)", style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _buildLogoutCard(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.danger.withValues(alpha: 0.1)),
        ),
        color: AppColors.danger.withValues(alpha: 0.02),
        child: ListTile(
          onTap: () => _showLogoutDialog(context, ref),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout, color: AppColors.danger, size: 20),
          ),
          title: Text("Logout", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger, fontWeight: FontWeight.bold)),
          subtitle: Text("You'll need to sign in again", style: AppTextStyles.caption),
          trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.danger, size: 16),
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    SnackbarHelper.showInfo(context, "$feature coming soon");
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.logout, color: AppColors.danger, size: 36),
        title: const Text("Logout?"),
        content: const Text("Are you sure you want to logout of GymFlow?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showStaffBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Staff Accounts", style: AppTextStyles.heading3),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _showComingSoon(context, "Adding staff"),
                icon: const Icon(Icons.add),
                label: const Text("Add Staff"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildStaffItem(context, "Priya Sharma", "Admin"),
                    _buildStaffItem(context, "Rahul Mehta", "Trainer"),
                    _buildStaffItem(context, "Sneha Kapoor", "Trainer"),
                    _buildStaffItem(context, "Vikram Singh", "Trainer"),
                    _buildStaffItem(context, "Meera Joshi", "Admin"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffItem(BuildContext context, String name, String role) {
    return ListTile(
      leading: CircleAvatar(child: Text(name[0])),
      title: Text(name),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: role == 'Admin' ? Colors.blue.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(role, style: TextStyle(fontSize: 10, color: role == 'Admin' ? Colors.blue : Colors.orange, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(radius: 3, backgroundColor: Colors.green),
          const SizedBox(width: 4),
          const Text("active", style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
      onTap: () => _showComingSoon(context, "Staff management"),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color? iconBgColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    this.iconBgColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconBgColor ?? iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: AppTextStyles.bodyMedium),
      subtitle: subtitle != null ? Text(subtitle!, style: AppTextStyles.caption) : null,
      trailing: trailing,
    );
  }
}
