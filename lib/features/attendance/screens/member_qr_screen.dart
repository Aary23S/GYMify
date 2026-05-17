import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/providers/members_provider.dart';
import '../providers/attendance_provider.dart';

class MemberQrScreen extends ConsumerWidget {
  const MemberQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final allMembers = ref.watch(membersProvider);
    final attendanceNotifier = ref.watch(attendanceProvider.notifier);

    // Get current logged in member full details
    final member = allMembers.firstWhere(
      (m) => m.name == authState.user?.name,
      orElse: () => allMembers.first,
    );

    final isCheckedIn = attendanceNotifier.isCheckedInToday(member.id);
    final isCheckedOut = attendanceNotifier.isCheckedOutToday(member.id);
    final checkInTime = attendanceNotifier.getTodayCheckInTime(member.id);
    final checkOutTime = attendanceNotifier.getTodayCheckOutTime(member.id);

    final qrData = jsonEncode({
      "memberId": member.id,
      "memberCode": member.memberCode,
      "memberName": member.name,
      "planName": member.planName,
      "timestamp": DateTime.now().toIso8601String(),
    });

    final daysRemaining = member.planExpiry.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysRemaining <= 7 && daysRemaining >= 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Gym QR Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Member info header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    member.initials,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name, style: AppTextStyles.heading2),
                      const SizedBox(height: 2),
                      Text(member.memberCode, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                StatusBadge(status: member.status),
              ],
            ),
            const SizedBox(height: 32),

            // Framed QR Code
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary, width: 2),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: QrImageView(
                      data: qrData,
                      size: 220,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primary),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.primary),
                    ),
                  ),
                  // Top Left L
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _buildCornerAccent(isTop: true, isLeft: true),
                  ),
                  // Top Right L
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildCornerAccent(isTop: true, isLeft: false),
                  ),
                  // Bottom Left L
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _buildCornerAccent(isTop: false, isLeft: true),
                  ),
                  // Bottom Right L
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _buildCornerAccent(isTop: false, isLeft: false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text("Show this QR at the gym entrance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text("Valid for: Today only", style: AppTextStyles.caption.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 32),

            // Check-in / Check-out actions
            if (!isCheckedIn) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text("Scan to Check In", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  onPressed: () {
                    context.push('/scan-qr?action=checkin');
                  },
                ),
              ),
            ] else if (isCheckedIn && !isCheckedOut) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text("✓ Checked in at ${checkInTime ?? ''}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text("Scan to Check Out", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    context.push('/scan-qr?action=checkout');
                  },
                ),
              ),
            ] else if (isCheckedIn && isCheckedOut) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text("Attendance Completed Today", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("In: ${checkInTime ?? ''} · Out: ${checkOutTime ?? ''}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text("See you tomorrow! 💪", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
            ],

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 16),

            // Plan Info
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(member.planName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: isExpiringSoon ? Colors.orange.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text("$daysRemaining days left", style: TextStyle(color: isExpiringSoon ? Colors.orange[800] : Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text("Expires on: ${DateFormat('dd MMM yyyy').format(member.planExpiry)}", style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  if (isExpiringSoon) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange)),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(child: Text("Your plan expires soon! Please renew.", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        context.push('/member/pay-fees');
                      },
                      child: const Text("Pay My Fees", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerAccent({required bool isTop, required bool isLeft}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
          left: isLeft ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
        ),
      ),
    );
  }
}
