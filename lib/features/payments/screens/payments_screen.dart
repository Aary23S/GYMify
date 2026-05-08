import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../members/models/member_model.dart';
import '../../members/providers/members_provider.dart';
import '../providers/payments_provider.dart';
import '../../../dummy_data/dummy_payments.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _collectFormKey = GlobalKey<FormState>();
  
  // Collect Tab State
  Member? _selectedMember;
  String? _selectedPlan;
  final _amountController = TextEditingController();
  String _paymentMode = 'cash';
  final _refController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _prePopulateCollect(PendingRenewal renewal) {
    final members = ref.read(membersProvider);
    final member = members.firstWhere((m) => m.id == renewal.memberId);
    
    setState(() {
      _selectedMember = member;
      _selectedPlan = renewal.currentPlan;
      _amountController.text = renewal.amount.toInt().toString();
      _tabController.animateTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Payments & Billing'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(140),
          child: Column(
            children: [
              _buildRevenueSummary(state),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.accent,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.accent,
                tabs: [
                  const Tab(text: 'Collect'),
                  Tab(text: 'Pending (${state.pendingRenewals.length})'),
                  const Tab(text: 'History'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CollectPaymentTab(
            formKey: _collectFormKey,
            selectedMember: _selectedMember,
            onMemberSelected: (m) => setState(() {
              _selectedMember = m;
              _selectedPlan = m.planName;
              _amountController.text = m.planPrice.toInt().toString();
            }),
            selectedPlan: _selectedPlan,
            onPlanChanged: (p, price) => setState(() {
              _selectedPlan = p;
              _amountController.text = price.toInt().toString();
            }),
            amountController: _amountController,
            paymentMode: _paymentMode,
            onModeChanged: (m) => setState(() => _paymentMode = m),
            refController: _refController,
            paymentDate: _paymentDate,
            onDateTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _paymentDate,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _paymentDate = picked);
            },
            notesController: _notesController,
            onSubmit: _handleRecordPayment,
            isRecording: state.isRecordingPayment,
          ),
          _PendingRenewalsTab(
            renewals: state.pendingRenewals,
            onCollect: _prePopulateCollect,
          ),
          _PaymentHistoryTab(
            payments: state.payments,
            selectedMode: state.selectedMode,
            onModeFilter: (mode) => ref.read(paymentsProvider.notifier).setModeFilter(mode),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSummary(PaymentsState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _SummaryCard(
            label: 'Today',
            value: '₹${state.stats.todayTotal.toInt()}',
            subtitle: '${state.stats.todayTransactions} transactions',
            icon: Icons.currency_rupee,
            iconColor: Colors.green,
            accentColor: AppColors.success,
          ),
          _SummaryCard(
            label: 'This Month',
            value: '₹${NumberFormat('#,##,000').format(state.stats.monthTotal)}',
            subtitle: '${state.stats.monthTransactions} transactions',
            icon: Icons.calendar_month,
            iconColor: Colors.blue,
            accentColor: AppColors.primary,
          ),
          _SummaryCard(
            label: 'Pending',
            value: '${state.stats.pendingCount} members',
            subtitle: 'Need renewal',
            icon: Icons.schedule,
            iconColor: Colors.orange,
            accentColor: AppColors.warning,
            onTap: () => _tabController.animateTo(1),
          ),
        ],
      ),
    );
  }

  void _handleRecordPayment() async {
    if (_collectFormKey.currentState!.validate()) {
      final selectedPlanData = _plans.firstWhere((p) => p['name'] == _selectedPlan);
      
      final record = PaymentRecord(
        id: const Uuid().v4(),
        memberId: _selectedMember!.id,
        memberName: _selectedMember!.name,
        memberCode: _selectedMember!.memberCode,
        planName: _selectedPlan!,
        amount: double.parse(_amountController.text),
        paymentMode: _paymentMode,
        paymentDate: _paymentDate,
        transactionRef: _refController.text.isNotEmpty ? _refController.text : null,
        invoiceNumber: 'INV-2026-${(ref.read(paymentsProvider).payments.length + 1).toString().padLeft(4, '0')}',
      );

      await ref.read(paymentsProvider.notifier).recordPayment(record);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Payment of ₹${record.amount.toInt()} recorded for ${record.memberName}'),
            backgroundColor: AppColors.success,
          ),
        );
        _showInvoiceBottomSheet(record);
        _resetCollectForm();
      }
    }
  }

  void _resetCollectForm() {
    setState(() {
      _selectedMember = null;
      _selectedPlan = null;
      _amountController.clear();
      _paymentMode = 'cash';
      _refController.clear();
      _paymentDate = DateTime.now();
      _notesController.clear();
    });
  }

  void _showInvoiceBottomSheet(PaymentRecord record) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _InvoiceBottomSheet(record: record),
    );
  }

  final List<Map<String, dynamic>> _plans = [
    {'name': 'Monthly Basic', 'price': 1500.0},
    {'name': 'Monthly Standard', 'price': 2500.0},
    {'name': 'Quarterly Premium', 'price': 6500.0},
    {'name': 'Annual Elite', 'price': 22000.0},
  ];
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color accentColor;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: accentColor, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: iconColor.withValues(alpha: 0.1),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                const SizedBox(width: 8),
                Text(label, style: AppTextStyles.caption.copyWith(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.heading3.copyWith(fontSize: 18)),
            Text(subtitle, style: AppTextStyles.caption.copyWith(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _CollectPaymentTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final Member? selectedMember;
  final Function(Member) onMemberSelected;
  final String? selectedPlan;
  final Function(String, double) onPlanChanged;
  final TextEditingController amountController;
  final String paymentMode;
  final Function(String) onModeChanged;
  final TextEditingController refController;
  final DateTime paymentDate;
  final VoidCallback onDateTap;
  final TextEditingController notesController;
  final VoidCallback onSubmit;
  final bool isRecording;

  const _CollectPaymentTab({
    required this.formKey,
    required this.selectedMember,
    required this.onMemberSelected,
    required this.selectedPlan,
    required this.onPlanChanged,
    required this.amountController,
    required this.paymentMode,
    required this.onModeChanged,
    required this.refController,
    required this.paymentDate,
    required this.onDateTap,
    required this.notesController,
    required this.onSubmit,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MemberSearchField(onSelected: onMemberSelected),
            if (selectedMember != null) ...[
              const SizedBox(height: 16),
              _SelectedMemberCard(member: selectedMember!),
              const SizedBox(height: 24),
              _buildPaymentForm(),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: selectedPlan,
          decoration: const InputDecoration(labelText: 'Select Plan *', prefixIcon: Icon(Icons.fitness_center)),
          items: [
            {'name': 'Monthly Basic', 'price': 1500.0},
            {'name': 'Monthly Standard', 'price': 2500.0},
            {'name': 'Quarterly Premium', 'price': 6500.0},
            {'name': 'Annual Elite', 'price': 22000.0},
          ].map((p) => DropdownMenuItem(
            value: p['name'] as String,
            child: Text('${p['name']} - ₹${(p['price'] as double).toInt()}'),
          )).toList(),
          onChanged: (val) {
            if (val != null) {
              final price = [
                {'name': 'Monthly Basic', 'price': 1500.0},
                {'name': 'Monthly Standard', 'price': 2500.0},
                {'name': 'Quarterly Premium', 'price': 6500.0},
                {'name': 'Annual Elite', 'price': 22000.0},
              ].firstWhere((p) => p['name'] == val)['price'] as double;
              onPlanChanged(val, price);
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (₹) *', prefixIcon: Icon(Icons.currency_rupee)),
        ),
        const SizedBox(height: 24),
        const Text('Payment Mode *', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _ModeChips(selectedMode: paymentMode, onModeChanged: onModeChanged),
        if (paymentMode != 'cash') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: refController,
            decoration: const InputDecoration(labelText: 'Transaction ID / Ref (optional)', prefixIcon: Icon(Icons.tag)),
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          readOnly: true,
          onTap: onDateTap,
          decoration: const InputDecoration(labelText: 'Payment Date', prefixIcon: Icon(Icons.calendar_today)),
          controller: TextEditingController(text: DateFormat('dd MMM yyyy').format(paymentDate)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: notesController,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Notes (optional)'),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          text: 'Record Payment ₹${amountController.text}',
          onPressed: onSubmit,
          isLoading: isRecording,
        ),
      ],
    );
  }
}

class _MemberSearchField extends ConsumerWidget {
  final Function(Member) onSelected;

  const _MemberSearchField({required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Autocomplete<Member>(
      displayStringForOption: (m) => m.name,
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<Member>.empty();
        final members = ref.read(membersProvider);
        return members.where((m) => m.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) || 
                                   m.memberCode.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Select Member',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 32,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final m = options.elementAt(index);
                  return ListTile(
                    title: Text(m.name),
                    subtitle: Text(m.memberCode),
                    onTap: () => onSelected(m),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SelectedMemberCard extends StatelessWidget {
  final Member member;

  const _SelectedMemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(child: Text(member.initials)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${member.memberCode} · ${member.planName}', style: AppTextStyles.caption),
              ],
            ),
          ),
          StatusBadge(status: member.status),
        ],
      ),
    );
  }
}

class _ModeChips extends StatelessWidget {
  final String selectedMode;
  final Function(String) onModeChanged;

  const _ModeChips({required this.selectedMode, required this.onModeChanged});

  @override
  Widget build(BuildContext context) {
    final modes = [
      {'id': 'cash', 'label': 'Cash', 'icon': '💵'},
      {'id': 'upi', 'label': 'UPI', 'icon': '📱'},
      {'id': 'card', 'label': 'Card', 'icon': '💳'},
      {'id': 'bank_transfer', 'label': 'Bank', 'icon': '🏦'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: modes.map((m) {
        final isSelected = selectedMode == m['id'];
        return Expanded(
          child: GestureDetector(
            onTap: () => onModeChanged(m['id']!),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? AppColors.accent : AppColors.primary),
                boxShadow: isSelected ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))] : null,
              ),
              child: Column(
                children: [
                  Text(m['icon']!, style: const TextStyle(fontSize: 16)),
                  Text(m['label']!, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : AppColors.primary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PendingRenewalsTab extends StatelessWidget {
  final List<PendingRenewal> renewals;
  final Function(PendingRenewal) onCollect;

  const _PendingRenewalsTab({required this.renewals, required this.onCollect});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: renewals.length,
      itemBuilder: (context, index) {
        final r = renewals[index];
        final isExpired = r.daysUntilExpiry < 0;
        final isCritical = r.daysUntilExpiry <= 1;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: isExpired ? AppColors.danger.withValues(alpha: 0.06) : isCritical ? AppColors.warning.withValues(alpha: 0.06) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isExpired ? AppColors.danger.withValues(alpha: 0.1) : isCritical ? AppColors.warning.withValues(alpha: 0.1) : AppColors.border),
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: isExpired ? AppColors.danger : isCritical ? AppColors.warning : AppColors.primary, width: 4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(child: Text(r.memberName[0])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.memberName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${r.memberCode} · ${r.currentPlan}', style: AppTextStyles.caption),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(isExpired ? Icons.error : Icons.schedule, size: 14, color: isExpired ? AppColors.danger : isCritical ? AppColors.warning : Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              isExpired ? 'Expired ${r.daysUntilExpiry.abs()} days ago' : r.daysUntilExpiry == 0 ? 'Expires today' : r.daysUntilExpiry == 1 ? 'Expires tomorrow' : 'Expires in ${r.daysUntilExpiry} days',
                              style: AppTextStyles.caption.copyWith(color: isExpired ? AppColors.danger : isCritical ? AppColors.warning : Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${r.amount.toInt()}', style: AppTextStyles.heading3.copyWith(fontSize: 16, color: isExpired ? AppColors.danger : null)),
                      const SizedBox(height: 4),
                      OutlinedButton(
                        onPressed: () => onCollect(r),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isExpired ? AppColors.danger : isCritical ? AppColors.warning : AppColors.primary,
                          side: BorderSide(color: isExpired ? AppColors.danger : isCritical ? AppColors.warning : AppColors.primary),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text('Collect', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PaymentHistoryTab extends StatelessWidget {
  final List<PaymentRecord> payments;
  final String? selectedMode;
  final Function(String?) onModeFilter;

  const _PaymentHistoryTab({required this.payments, required this.selectedMode, required this.onModeFilter});

  @override
  Widget build(BuildContext context) {
    final filtered = selectedMode == null ? payments : payments.where((p) => p.paymentMode == selectedMode).toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              FilterChip(label: const Text('All'), selected: selectedMode == null, onSelected: (_) => onModeFilter(null)),
              const SizedBox(width: 8),
              FilterChip(label: const Text('Cash'), selected: selectedMode == 'cash', onSelected: (_) => onModeFilter('cash')),
              const SizedBox(width: 8),
              FilterChip(label: const Text('UPI'), selected: selectedMode == 'upi', onSelected: (_) => onModeFilter('upi')),
              const SizedBox(width: 8),
              FilterChip(label: const Text('Card'), selected: selectedMode == 'card', onSelected: (_) => onModeFilter('card')),
              const SizedBox(width: 8),
              FilterChip(label: const Text('Bank'), selected: selectedMode == 'bank_transfer', onSelected: (_) => onModeFilter('bank_transfer')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Showing ${filtered.length} payments · Total: ₹${filtered.fold(0.0, (sum, p) => sum + p.amount).toInt()}', style: AppTextStyles.caption),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No payments found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
                      child: ListTile(
                        title: Text(p.memberName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${p.memberCode} · ${p.planName}', style: AppTextStyles.caption),
                            Text(DateFormat('dd MMM yyyy, hh:mm a').format(p.paymentDate), style: AppTextStyles.caption.copyWith(fontSize: 10)),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${p.amount.toInt()}', style: AppTextStyles.heading3.copyWith(fontSize: 16)),
                            const SizedBox(height: 4),
                            _ModeBadge(mode: p.paymentMode),
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
}

class _ModeBadge extends StatelessWidget {
  final String mode;
  const _ModeBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (mode) {
      case 'cash': color = Colors.green; label = 'Cash'; break;
      case 'upi': color = Colors.blue; label = 'UPI'; break;
      case 'card': color = Colors.purple; label = 'Card'; break;
      default: color = Colors.teal; label = 'Bank'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _InvoiceBottomSheet extends StatelessWidget {
  final PaymentRecord record;
  const _InvoiceBottomSheet({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 64),
          const SizedBox(height: 16),
          const Text('Payment Recorded ✓', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(record.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(DateFormat('dd MMM yyyy').format(record.paymentDate)),
                  ],
                ),
                const Divider(height: 32),
                _InvoiceRow(label: 'Member', value: '${record.memberName} (${record.memberCode})'),
                const SizedBox(height: 12),
                _InvoiceRow(label: 'Plan', value: record.planName),
                const SizedBox(height: 12),
                _InvoiceRow(label: 'Mode', value: record.paymentMode.toUpperCase()),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontSize: 16)),
                    Text('₹${record.amount.toInt()}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))),
              const SizedBox(width: 16),
              Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('Share Invoice'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final String label;
  final String value;
  const _InvoiceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
