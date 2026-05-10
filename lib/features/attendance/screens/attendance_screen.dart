import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../members/providers/members_provider.dart';
import '../../members/models/member_model.dart';
import '../providers/attendance_provider.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceState = ref.watch(attendanceProvider);
    final totalMembersCount = 248; // Dummy total for percentage
    final checkInCount = attendanceState.todaysRecords.length;
    final attendancePercentage =
        (checkInCount / totalMembersCount * 100).toStringAsFixed(1);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Attendance'),
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                style: AppTextStyles.caption.copyWith(color: Colors.grey),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('QR scanning coming soon')),
                );
              },
              icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSummaryCard(
                checkInCount, totalMembersCount, attendancePercentage),
            TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              labelStyle: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: 'Checked In ($checkInCount)'),
                const Tab(text: 'Checked Out'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _CheckedInTab(),
                  _CheckedOutTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      int checkInCount, int totalMembers, String percentage) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF1A237E)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem("Today's Check-ins", checkInCount.toString(),
                  isBold: true),
              const SizedBox(
                height: 40,
                child: VerticalDivider(color: Colors.white30, thickness: 1),
              ),
              _buildSummaryItem("Total Members", totalMembers.toString()),
              const SizedBox(
                height: 40,
                child: VerticalDivider(color: Colors.white30, thickness: 1),
              ),
              _buildSummaryItem("Attendance", "$percentage%"),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: checkInCount / totalMembers,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isBold = false}) {
    return Column(
      children: [
        Text(label,
            style: AppTextStyles.caption.copyWith(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.displayMedium.copyWith(
            color: Colors.white,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 24,
          ),
        ),
      ],
    );
  }
}

class _CheckedInTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceProvider);
    final filteredRecords = state.todaysRecords
        .where((r) =>
            r.memberName
                .toLowerCase()
                .contains(state.searchQuery.toLowerCase()) ||
            r.memberCode
                .toLowerCase()
                .contains(state.searchQuery.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (val) =>
                ref.read(attendanceProvider.notifier).setSearch(val),
            decoration: InputDecoration(
              hintText: 'Search checked-in members...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: filteredRecords.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No results found',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Try a different name',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: filteredRecords.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final record = filteredRecords[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.04),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: Text(record.memberName[0],
                              style: const TextStyle(color: AppColors.primary)),
                        ),
                        title: Text(record.memberName,
                            style: AppTextStyles.bodyMedium),
                        subtitle: Text(
                            '${record.memberCode} · ${record.planName}',
                            style: AppTextStyles.caption),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('hh:mm a').format(record.checkInTime),
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold),
                            ),
                            const Text('Checked in',
                                style: TextStyle(
                                    color: AppColors.success, fontSize: 10)),
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

class _CheckedOutTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CheckedOutTab> createState() => _CheckedOutTabState();
}

class _CheckedOutTabState extends ConsumerState<_CheckedOutTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allMembers = ref.watch(membersProvider);
    final attendanceNotifier = ref.watch(attendanceProvider.notifier);
    final isCheckingIn = ref.watch(attendanceProvider).isCheckingIn;

    final results = _query.isEmpty
        ? <Member>[]
        : allMembers
            .where((m) =>
                m.name.toLowerCase().contains(_query.toLowerCase()) ||
                m.phone.contains(_query) ||
                m.memberCode.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.accent, size: 20),
                    const SizedBox(width: 8),
                    Text('Search a member and tap Check In',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.accent)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _query = val),
                decoration: InputDecoration(
                  hintText: 'Search by name, phone or member ID...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: results.isEmpty && _query.isNotEmpty
              ? const Center(child: Text('No members found'))
              : ListView.separated(
                  itemCount: results.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final member = results[index];
                    final isCheckedIn =
                        attendanceNotifier.isAlreadyCheckedIn(member.id);
                    final checkInTime =
                        attendanceNotifier.getCheckInTime(member.id);

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(member.initials),
                      ),
                      title: Text(member.name),
                      subtitle:
                          Text('${member.memberCode} · ${member.planName}'),
                      trailing: _buildTrailing(
                          member, isCheckedIn, checkInTime, isCheckingIn),
                      onTap: () {
                        if (isCheckedIn) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${member.name} already checked in today at $checkInTime'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        } else if (member.status == MemberStatus.expired) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Membership expired. Collect payment first.'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTrailing(Member member, bool isCheckedIn, String? checkInTime,
      bool isCheckingInGlobal) {
    if (isCheckedIn) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('✓ Checked In',
              style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          Text(checkInTime ?? '',
              style: AppTextStyles.caption.copyWith(color: AppColors.success)),
        ],
      );
    }

    if (member.status == MemberStatus.expired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('Expired',
            style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      );
    }

    return ElevatedButton(
      onPressed: isCheckingInGlobal ? null : () => _handleCheckIn(member),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minimumSize: const Size(0, 32),
        elevation: 0,
      ),
      child: const Text('Check In', style: TextStyle(fontSize: 12)),
    );
  }

  Future<void> _handleCheckIn(Member member) async {
    try {
      await ref.read(attendanceProvider.notifier).checkIn(member);
      if (mounted) {
        final time =
            ref.read(attendanceProvider.notifier).getCheckInTime(member.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${member.name} checked in at $time'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on AlreadyCheckedInException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${member.name} already checked in today at ${e.time}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}
