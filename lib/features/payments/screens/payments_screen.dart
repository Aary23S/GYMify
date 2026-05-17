import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../dummy_data/dummy_payments.dart';
import '../providers/payments_provider.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentsProvider);

    // Calculate dynamic values for top summary cards
    final dueThisWeekList = state.pendingRenewals.where((r) => r.daysUntilExpiry <= 7).toList();
    final expectedAmount = dueThisWeekList.fold(0.0, (sum, r) => sum + r.amount);

    final collected30Days = state.payments.fold(0.0, (sum, p) => sum + p.amount);
    final txnCount = state.payments.length;

    final expiring7DaysCount = state.pendingRenewals.where((r) => r.daysUntilExpiry >= 0 && r.daysUntilExpiry <= 7).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payments Overview', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(150),
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _SummaryCard(
                        title: "Due This Week",
                        value: "${dueThisWeekList.length} members",
                        icon: Icons.schedule,
                        iconColor: Colors.orange,
                        subtext: "₹${NumberFormat('#,##,000').format(expectedAmount)} expected",
                      ),
                      _SummaryCard(
                        title: "Collected (30 days)",
                        value: "₹${NumberFormat('#,##,000').format(collected30Days)}",
                        icon: Icons.currency_rupee,
                        iconColor: Colors.green,
                        subtext: "$txnCount transactions",
                      ),
                      _SummaryCard(
                        title: "Expiring (7 days)",
                        value: "$expiring7DaysCount members",
                        icon: Icons.event_busy,
                        iconColor: Colors.red,
                        subtext: "Renew reminders sent: 3",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.accent,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: AppColors.accent,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Due & Expiring'),
                      Tab(text: '30-Day History'),
                      Tab(text: 'Analytics'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DueAndExpiringTab(renewals: state.pendingRenewals),
          _HistoryTab(
            payments: state.payments,
            selectedMode: state.selectedMode,
            onModeFilter: (mode) => ref.read(paymentsProvider.notifier).setModeFilter(mode),
          ),
          _AnalyticsTab(payments: state.payments),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String subtext;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.caption.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.heading3.copyWith(fontSize: 18, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(subtext, style: AppTextStyles.caption.copyWith(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 1: DUE & EXPIRING
// ==========================================
class _DueAndExpiringTab extends StatelessWidget {
  final List<PendingRenewal> renewals;

  const _DueAndExpiringTab({required this.renewals});

  @override
  Widget build(BuildContext context) {
    final overdueList = renewals.where((r) => r.daysUntilExpiry < 0).toList();
    overdueList.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));

    final expiringThisWeek = renewals.where((r) => r.daysUntilExpiry >= 0 && r.daysUntilExpiry <= 7).toList();
    expiringThisWeek.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));

    final expiringNextWeek = renewals.where((r) => r.daysUntilExpiry >= 8 && r.daysUntilExpiry <= 14).toList();
    expiringNextWeek.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (overdueList.isNotEmpty) ...[
            _buildSectionHeader("Overdue (already expired)", Colors.red[700]!, Icons.error_outline),
            const SizedBox(height: 12),
            ...overdueList.map((r) => _RenewalCard(renewal: r, type: _RenewalType.overdue)),
            const SizedBox(height: 24),
          ],
          if (expiringThisWeek.isNotEmpty) ...[
            _buildSectionHeader("Expiring This Week", Colors.orange[800]!, Icons.warning_amber),
            const SizedBox(height: 12),
            ...expiringThisWeek.map((r) => _RenewalCard(renewal: r, type: _RenewalType.expiringThisWeek)),
            const SizedBox(height: 24),
          ],
          if (expiringNextWeek.isNotEmpty) ...[
            _buildSectionHeader("Expiring Next Week", Colors.amber[700]!, Icons.schedule),
            const SizedBox(height: 12),
            ...expiringNextWeek.map((r) => _RenewalCard(renewal: r, type: _RenewalType.expiringNextWeek)),
            const SizedBox(height: 24),
          ],
          if (overdueList.isEmpty && expiringThisWeek.isEmpty && expiringNextWeek.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: Center(child: Text("No upcoming dues or expirations 🎉", style: TextStyle(color: Colors.grey[600], fontSize: 16))),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

enum _RenewalType { overdue, expiringThisWeek, expiringNextWeek }

class _RenewalCard extends StatelessWidget {
  final PendingRenewal renewal;
  final _RenewalType type;

  const _RenewalCard({required this.renewal, required this.type});

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color statusBgColor;
    Color statusTextColor;
    String statusText;

    switch (type) {
      case _RenewalType.overdue:
        borderColor = Colors.red[700]!;
        statusBgColor = Colors.red.withValues(alpha: 0.1);
        statusTextColor = Colors.red[800]!;
        statusText = "Expired ${renewal.daysUntilExpiry.abs()} days ago";
        break;
      case _RenewalType.expiringThisWeek:
        borderColor = Colors.orange[800]!;
        statusBgColor = Colors.orange.withValues(alpha: 0.1);
        statusTextColor = Colors.orange[900]!;
        statusText = renewal.daysUntilExpiry == 0 ? "Expires today" : "Expires in ${renewal.daysUntilExpiry} days";
        break;
      case _RenewalType.expiringNextWeek:
        borderColor = Colors.amber[600]!;
        statusBgColor = Colors.amber.withValues(alpha: 0.15);
        statusTextColor = Colors.amber[900]!;
        statusText = "Expires in ${renewal.daysUntilExpiry} days";
        break;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: borderColor, width: 5)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: borderColor.withValues(alpha: 0.1),
              child: Text(
                renewal.memberName.trim().isNotEmpty ? renewal.memberName.trim()[0].toUpperCase() : '?',
                style: TextStyle(color: borderColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(renewal.memberName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text("${renewal.memberCode} · ${renewal.currentPlan}", style: AppTextStyles.caption.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(6)),
                    child: Text(statusText, style: TextStyle(color: statusTextColor, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${NumberFormat('#,##,000').format(renewal.amount)}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: type == _RenewalType.overdue ? Colors.red[700] : AppColors.textPrimary),
                ),
                if (type == _RenewalType.overdue)
                  Text("DUE", style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 12))
                else
                  Text("Expected", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 2: 30-DAY HISTORY
// ==========================================
class _HistoryTab extends StatelessWidget {
  final List<PaymentRecord> payments;
  final String? selectedMode;
  final Function(String?) onModeFilter;

  const _HistoryTab({required this.payments, required this.selectedMode, required this.onModeFilter});

  @override
  Widget build(BuildContext context) {
    final filtered = selectedMode == null ? payments : payments.where((p) => p.paymentMode == selectedMode).toList();

    final totalAmount = filtered.fold(0.0, (sum, p) => sum + p.amount);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip('All', null),
                const SizedBox(width: 8),
                _buildChip('UPI', 'upi'),
                const SizedBox(width: 8),
                _buildChip('Cash', 'cash'),
                const SizedBox(width: 8),
                _buildChip('Card', 'card'),
                const SizedBox(width: 8),
                _buildChip('Bank', 'bank_transfer'),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${filtered.length} payments", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
              Text("₹${NumberFormat('#,##,000').format(totalAmount)} total", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16)),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text('No payment records found', style: TextStyle(color: Colors.grey[600])))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.border)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(p.memberName[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(p.memberName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            const Icon(Icons.verified, color: Colors.green, size: 16),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text("${p.memberCode} · ${p.planName}", style: AppTextStyles.caption.copyWith(color: Colors.grey[600])),
                            const SizedBox(height: 4),
                            Text(DateFormat('dd MMM yyyy, hh:mm a').format(p.paymentDate), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${NumberFormat('#,##,000').format(p.amount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                            const SizedBox(height: 6),
                            _buildModeBadge(p.paymentMode),
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

  Widget _buildChip(String label, String? mode) {
    final isSelected = selectedMode == mode;
    return FilterChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) => onModeFilter(mode),
      backgroundColor: Colors.grey[100],
      selectedColor: AppColors.accent,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.accent : AppColors.border)),
    );
  }

  Widget _buildModeBadge(String mode) {
    Color bg;
    Color fg;
    String text;

    switch (mode) {
      case 'upi':
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue[800]!;
        text = 'UPI';
        break;
      case 'cash':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green[800]!;
        text = 'Cash';
        break;
      case 'card':
        bg = Colors.purple.withValues(alpha: 0.15);
        fg = Colors.purple[800]!;
        text = 'Card';
        break;
      default:
        bg = Colors.teal.withValues(alpha: 0.15);
        fg = Colors.teal[800]!;
        text = 'Bank';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

// ==========================================
// TAB 3: ANALYTICS
// ==========================================
class _AnalyticsTab extends StatelessWidget {
  final List<PaymentRecord> payments;

  const _AnalyticsTab({required this.payments});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue Trend Chart
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Revenue Trend (Last 12 Months)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const months = ['Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May'];
                              final index = value.toInt();
                              if (index >= 0 && index < months.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(months[index], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            reservedSize: 36,
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Text('${(value / 1000).toInt()}k', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey));
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        _buildBar(0, 80000),
                        _buildBar(1, 95000),
                        _buildBar(2, 110000),
                        _buildBar(3, 105000),
                        _buildBar(4, 120000),
                        _buildBar(5, 115000),
                        _buildBar(6, 130000),
                        _buildBar(7, 125000),
                        _buildBar(8, 140000),
                        _buildBar(9, 135000),
                        _buildBar(10, 150000),
                        _buildBar(11, 124000),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Plan Distribution Pie Chart
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Plan Revenue Contribution", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 35,
                          sections: [
                            PieChartSectionData(color: Colors.blue[700], value: 40, title: '40%', radius: 35, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            PieChartSectionData(color: AppColors.accent, value: 30, title: '30%', radius: 35, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            PieChartSectionData(color: Colors.teal[600], value: 20, title: '20%', radius: 35, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            PieChartSectionData(color: Colors.purple[600], value: 10, title: '10%', radius: 35, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem(Colors.blue[700]!, "Annual Elite", "40%"),
                          const SizedBox(height: 8),
                          _buildLegendItem(AppColors.accent, "Quarterly Premium", "30%"),
                          const SizedBox(height: 8),
                          _buildLegendItem(Colors.teal[600]!, "Monthly Standard", "20%"),
                          const SizedBox(height: 8),
                          _buildLegendItem(Colors.purple[600]!, "Monthly Basic", "10%"),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Collection Rate Segmented Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Collection Rate", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 16,
                    child: Row(
                      children: [
                        Expanded(flex: 78, child: Container(color: Colors.green)),
                        Expanded(flex: 15, child: Container(color: Colors.orange)),
                        Expanded(flex: 7, child: Container(color: Colors.red)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Collected on time: 78%", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text("Late: 15%", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text("Pending: 7%", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  BarChartGroupData _buildBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.accent,
          width: 14,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, String pct) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        Text(pct, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }
}
