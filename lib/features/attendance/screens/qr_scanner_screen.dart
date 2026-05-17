import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/providers/members_provider.dart';
import '../providers/attendance_provider.dart';
import '../../../core/utils/snackbar_helper.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  final String action; // 'checkin' or 'checkout'

  const QrScannerScreen({super.key, required this.action});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;
  bool _isDetected = false;
  bool _isProcessing = false;

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

    // Auto-simulate scan after 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _onQrDetected();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onQrDetected() async {
    if (_isProcessing) return;
    setState(() {
      _isDetected = true;
      _isProcessing = true;
    });

    // Pause briefly to show the green "QR Detected" border and banner
    await Future.delayed(const Duration(milliseconds: 800));

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
        context.go('/dashboard');
        SnackbarHelper.showSuccess(context, "Checked in successfully at $time ✓");
      } on AlreadyCheckedInException catch (e) {
        if (!mounted) return;
        context.go('/dashboard');
        SnackbarHelper.showWarning(context, "Already checked in today at ${e.time}");
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
        context.go('/dashboard');
        SnackbarHelper.showSuccess(context, "Checked out successfully at $time (Duration: $duration) ✓");
      } on NotCheckedInException catch (_) {
        if (!mounted) return;
        context.go('/dashboard');
        SnackbarHelper.showError(context, "No check-in record found for today.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBranch = ref.watch(authProvider).user?.currentBranch ?? 'Branch A';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text('Scan Gym QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isDetected)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                    const SizedBox(width: 10),
                    Text("QR Detected: $currentBranch Reception", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Text(
                  "Align reception QR code within frame",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            Stack(
              alignment: Alignment.center,
              children: [
                // Viewfinder Box
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: _isDetected ? Colors.green.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _isDetected ? Colors.green : Colors.white, width: _isDetected ? 4 : 2),
                    boxShadow: [
                      BoxShadow(
                        color: _isDetected ? Colors.green.withValues(alpha: 0.3) : AppColors.accent.withValues(alpha: 0.15),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
                // Animated Scanning Line (Hide when detected)
                if (!_isDetected)
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: 280 * _scanAnimation.value,
                        child: Container(
                          width: 260,
                          height: 3,
                          decoration: const BoxDecoration(
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
                if (!_isDetected) const Icon(Icons.add, color: Colors.white54, size: 40),
                // Corner Decorators
                Positioned(top: 0, left: 0, child: _buildCornerAccent(isTop: true, isLeft: true)),
                Positioned(top: 0, right: 0, child: _buildCornerAccent(isTop: true, isLeft: false)),
                Positioned(bottom: 0, left: 0, child: _buildCornerAccent(isTop: false, isLeft: true)),
                Positioned(bottom: 0, right: 0, child: _buildCornerAccent(isTop: false, isLeft: false)),
              ],
            ),
            const SizedBox(height: 40),
            if (_isDetected) ...[
              const CircularProgressIndicator(color: Colors.green),
              const SizedBox(height: 16),
              Text(widget.action == 'checkin' ? "Recording check-in..." : "Recording check-out...", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ] else ...[
              const CircularProgressIndicator(color: AppColors.accent),
              const SizedBox(height: 16),
              const Text("Searching for gym QR code...", style: TextStyle(color: Colors.white70, fontSize: 14)),
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
          top: isTop ? BorderSide(color: _isDetected ? Colors.green : AppColors.accent, width: 6) : BorderSide.none,
          bottom: !isTop ? BorderSide(color: _isDetected ? Colors.green : AppColors.accent, width: 6) : BorderSide.none,
          left: isLeft ? BorderSide(color: _isDetected ? Colors.green : AppColors.accent, width: 6) : BorderSide.none,
          right: !isLeft ? BorderSide(color: _isDetected ? Colors.green : AppColors.accent, width: 6) : BorderSide.none,
        ),
      ),
    );
  }
}
