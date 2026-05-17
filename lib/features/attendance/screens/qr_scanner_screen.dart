import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/providers/members_provider.dart';
import '../providers/attendance_provider.dart';

// Phase 2 Note: Replace _simulateScan() with mobile_scanner widget
// MobileScanner(onDetect: (capture) { decode QR -> call same provider methods })

class QrScannerScreen extends ConsumerStatefulWidget {
  final String action; // 'checkin' or 'checkout'

  const QrScannerScreen({super.key, required this.action});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _simulateScan() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
    });

    // Simulate scanning time
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final authState = ref.read(authProvider);
    final allMembers = ref.read(membersProvider);
    final member = allMembers.firstWhere(
      (m) => m.name == authState.user?.name,
      orElse: () => allMembers.first,
    );

    final attendanceNotifier = ref.read(attendanceProvider.notifier);

    if (widget.action == 'checkin') {
      try {
        await attendanceNotifier.markCheckIn(member.id, member.name, member.memberCode, member.planName);
        if (!mounted) return;
        final time = attendanceNotifier.getTodayCheckInTime(member.id) ?? DateFormat('hh:mm a').format(DateTime.now());
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✓ Check-in recorded at $time"), backgroundColor: Colors.green),
        );
      } on AlreadyCheckedInException catch (e) {
        if (!mounted) return;
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Already checked in today at ${e.time}"), backgroundColor: Colors.orange),
        );
      }
    } else if (widget.action == 'checkout') {
      try {
        await attendanceNotifier.markCheckOut(member.id);
        if (!mounted) return;
        final recs = ref.read(attendanceProvider).todayRecords.where((r) => r.memberId == member.id).toList();
        String duration = "--";
        String time = DateFormat('hh:mm a').format(DateTime.now());
        if (recs.isNotEmpty && recs.first.checkOutTime != null) {
          final r = recs.first;
          time = DateFormat('hh:mm a').format(r.checkOutTime!);
          final diff = r.checkOutTime!.difference(r.checkInTime);
          final h = diff.inHours;
          final m = diff.inMinutes % 60;
          duration = h > 0 ? "${h}h ${m}m" : "${m}m";
        }
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✓ Check-out recorded at $time · Duration: $duration"), backgroundColor: Colors.green),
        );
      } on NotCheckedInException catch (_) {
        if (!mounted) return;
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No check-in found for today"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Scan QR Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Camera Viewfinder Box
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(color: AppColors.accent.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: 5),
                    ],
                  ),
                ),
                // Animated Scanning Line
                AnimatedBuilder(
                  animation: _scanAnimation,
                  builder: (context, child) {
                    return Positioned(
                      top: 280 * _scanAnimation.value,
                      child: Container(
                        width: 260,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.white, blurRadius: 8, spreadRadius: 2),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Center Crosshair
                const Icon(Icons.add, color: Colors.white54, size: 40),
                // Corner Decorators
                Positioned(top: 0, left: 0, child: _buildCornerAccent(isTop: true, isLeft: true)),
                Positioned(top: 0, right: 0, child: _buildCornerAccent(isTop: true, isLeft: false)),
                Positioned(bottom: 0, left: 0, child: _buildCornerAccent(isTop: false, isLeft: true)),
                Positioned(bottom: 0, right: 0, child: _buildCornerAccent(isTop: false, isLeft: false)),
              ],
            ),
            const SizedBox(height: 40),
            if (_isScanning) ...[
              const CircularProgressIndicator(color: AppColors.accent),
              const SizedBox(height: 16),
              const Text("Scanning QR...", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ] else ...[
              const Text("Point camera at member's QR code", style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 8),
              const Text("or", style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text("Simulate QR Scan ▶", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _simulateScan,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCornerAccent({required bool isTop, required bool isLeft}) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: AppColors.accent, width: 6) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: AppColors.accent, width: 6) : BorderSide.none,
          left: isLeft ? const BorderSide(color: AppColors.accent, width: 6) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: AppColors.accent, width: 6) : BorderSide.none,
        ),
      ),
    );
  }
}
