import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/providers/members_provider.dart';
import '../providers/payments_provider.dart';
import '../../../dummy_data/dummy_payments.dart';

class PlanOption {
  final String name;
  final double price;
  final String duration;
  final List<String> tags;

  PlanOption({required this.name, required this.price, required this.duration, required this.tags});
}

class MemberPaymentScreen extends ConsumerStatefulWidget {
  const MemberPaymentScreen({super.key});

  @override
  ConsumerState<MemberPaymentScreen> createState() => _MemberPaymentScreenState();
}

class _MemberPaymentScreenState extends ConsumerState<MemberPaymentScreen> {
  int _selectedPlanIndex = 1; // Monthly Standard default
  String _selectedMethod = 'upi'; // 'upi', 'card', 'cash', 'bank'
  bool _isLoading = false;

  final List<PlanOption> _plans = [
    PlanOption(name: "Monthly Basic", price: 1500, duration: "1 Month", tags: ["Gym Access", "Locker"]),
    PlanOption(name: "Monthly Standard", price: 2500, duration: "1 Month", tags: ["Gym Access", "Group Classes", "Sauna"]),
    PlanOption(name: "Quarterly Premium", price: 6500, duration: "3 Months", tags: ["All Access", "Personal Trainer 2x", "Diet Plan"]),
    PlanOption(name: "Annual Elite", price: 22000, duration: "12 Months", tags: ["VIP Access", "Unlimited Classes", "Free Guest Pass"]),
  ];

  void _handlePayment() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);

    final plan = _plans[_selectedPlanIndex];
    final member = ref.read(membersProvider).firstWhere(
      (m) => m.name == ref.read(authProvider).user?.name,
      orElse: () => ref.read(membersProvider).first,
    );

    // Record dummy payment in paymentsProvider
    final newRecord = PaymentRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      memberId: member.id,
      memberName: member.name,
      memberCode: member.memberCode,
      planName: plan.name,
      amount: plan.price,
      paymentMode: _selectedMethod == 'bank' ? 'bank_transfer' : _selectedMethod,
      paymentDate: DateTime.now(),
      invoiceNumber: 'INV-${Random().nextInt(9000) + 1000}',
    );
    ref.read(paymentsProvider.notifier).recordPayment(newRecord);

    context.push('/member/payment-success', extra: {
      'amount': plan.price,
      'planName': plan.name,
      'mode': _selectedMethod.toUpperCase(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plans[_selectedPlanIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pay My Fees', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Due Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Amount Due", style: AppTextStyles.label.copyWith(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text("₹${NumberFormat('#,##,000').format(plan.price)}", style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 36)),
                        const SizedBox(height: 8),
                        Text("${plan.name} Plan (${plan.duration})", style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Due Date: 31 May 2026", style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                              child: const Text("⚠️ 3 Days Left", style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Plan Renewal Selector
                  const SectionHeader(title: "Select Plan to Renew"),
                  const SizedBox(height: 16),
                  ...List.generate(_plans.length, (index) {
                    final p = _plans[index];
                    final isSelected = index == _selectedPlanIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPlanIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent.withValues(alpha: 0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? AppColors.accent : AppColors.border, width: isSelected ? 2 : 1),
                          boxShadow: [if (isSelected) BoxShadow(color: AppColors.accent.withValues(alpha: 0.1), blurRadius: 10)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(p.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? AppColors.accent : AppColors.textPrimary))),
                                Text("₹${NumberFormat('#,##,000').format(p.price)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isSelected ? AppColors.accent : AppColors.textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text("Duration: ${p.duration}", style: AppTextStyles.caption.copyWith(color: Colors.grey[600])),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: p.tags.map((tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                                child: Text(tag, style: TextStyle(fontSize: 10, color: isSelected ? AppColors.accent : Colors.grey[700], fontWeight: FontWeight.bold)),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 32),

                  // Payment Method Section
                  const SectionHeader(title: "Payment Method"),
                  const SizedBox(height: 16),
                  _buildMethodOption('upi', Icons.phone_android, "UPI / Google Pay / PhonePe"),
                  if (_selectedMethod == 'upi') _buildUpiSection(),

                  _buildMethodOption('card', Icons.credit_card, "Credit / Debit Card"),
                  if (_selectedMethod == 'card') _buildCardSection(),

                  _buildMethodOption('cash', Icons.money, "Cash at Counter"),
                  if (_selectedMethod == 'cash') _buildCashSection(),

                  _buildMethodOption('bank', Icons.account_balance, "Bank Transfer / NEFT"),
                  if (_selectedMethod == 'bank') _buildBankSection(context),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          // Fixed Bottom Pay Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, -5))],
            ),
            child: PrimaryButton(
              text: _isLoading ? "Processing Payment..." : "Pay ₹${NumberFormat('#,##,000').format(plan.price)} Now",
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _handlePayment,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodOption(String id, IconData icon, String label) {
    final isSel = _selectedMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSel ? AppColors.primary : AppColors.border, width: isSel ? 2 : 1),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: id,
              groupValue: _selectedMethod,
              onChanged: (val) => setState(() => _selectedMethod = val!),
              activeColor: AppColors.primary,
            ),
            Icon(icon, color: isSel ? AppColors.primary : Colors.grey[700]),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSel ? AppColors.primary : AppColors.textPrimary))),
          ],
        ),
      ),
    );
  }

  Widget _buildUpiSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.alternate_email, color: AppColors.primary),
              hintText: "yourname@upi",
              labelText: "Enter UPI ID",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          Text("Or scan QR code to pay", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            width: 140,
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accent, width: 2, style: BorderStyle.solid), // Dashed simulation
              borderRadius: BorderRadius.circular(16),
              color: AppColors.accent.withValues(alpha: 0.05),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_2, size: 80, color: AppColors.primary),
                const SizedBox(height: 4),
                Text("Scan & Pay", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: Column(
        children: [
          TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.credit_card, color: AppColors.primary),
              labelText: "Card Number",
              hintText: "0000 0000 0000 0000",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: "Expiry",
                    hintText: "MM/YY",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "CVV",
                    hintText: "•••",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text("Please visit the counter to complete your cash payment. Show this screen to the staff.", style: TextStyle(color: Colors.orange[900], fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCopyRow(context, "Account Name", "GymFlow Fitness Center"),
            const Divider(height: 24),
            _buildCopyRow(context, "Account No", "1234 5678 9012"),
            const Divider(height: 24),
            _buildCopyRow(context, "IFSC", "SBIN0001234"),
            const Divider(height: 24),
            _buildCopyRow(context, "Bank", "State Bank of India"),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 18, color: AppColors.primary),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Copied $label"), duration: const Duration(seconds: 1)));
          },
        ),
      ],
    );
  }
}

// ==========================================
// PAYMENT SUCCESS SCREEN
// ==========================================
class PaymentSuccessScreen extends StatefulWidget {
  final double amount;
  final String planName;
  final String mode;

  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    required this.planName,
    required this.mode,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  bool _showCheck = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showCheck = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final refStr = 'TXN${Random().nextInt(900000000) + 100000000}';
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final expiryDateStr = DateFormat('dd MMM yyyy').format(DateTime.now().add(const Duration(days: 30)));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Checkmark
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                width: _showCheck ? 90 : 0,
                height: _showCheck ? 90 : 0,
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: _showCheck ? const Icon(Icons.check, size: 50, color: Colors.green) : null,
              ),
              const SizedBox(height: 24),
              Text("Payment Successful! 🎉", style: AppTextStyles.heading1.copyWith(fontSize: 28, color: AppColors.textPrimary), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text("₹${NumberFormat('#,##,000').format(widget.amount)} paid via ${widget.mode}", style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text("Your plan is renewed until $expiryDateStr", style: TextStyle(fontSize: 13, color: Colors.green[700], fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 36),

              // Transaction Details Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Transaction Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildRow("Amount", "₹${NumberFormat('#,##,000').format(widget.amount)}"),
                    const SizedBox(height: 12),
                    _buildRow("Plan", widget.planName),
                    const SizedBox(height: 12),
                    _buildRow("Mode", widget.mode),
                    const SizedBox(height: 12),
                    _buildRow("Date", dateStr),
                    const SizedBox(height: 12),
                    _buildRow("Reference", refStr),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.download),
                label: const Text("Download Receipt", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Receipt download coming soon")));
                },
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: "Back to Home",
                onPressed: () => context.go('/dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
      ],
    );
  }
}
