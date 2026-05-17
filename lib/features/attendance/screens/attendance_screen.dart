import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymflow/features/auth/models/user_model.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/providers/members_provider.dart';
import '../../members/models/member_model.dart';
import '../providers/attendance_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool _showSearchBar = false;
  bool _showAllBranches = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final role = authState.selectedRole;
    final currentUser = authState.user;
    final currentBranch = currentUser?.currentBranch ?? 'Branch A';

    final allMembers = ref.watch(membersProvider);
    final membersMap = {for (var m in allMembers) m.id: m};

    final attendanceState = ref.watch(attendanceProvider);
    final todayRecords = attendanceState.todayRecords;

    // Filter today's records based on role and branch toggle
    final filteredTodayRecords = todayRecords.where((r) {
      if (role != UserRole.trainer || _showAllBranches) return true;
      final m = membersMap[r.memberId];
      return m != null && m.branch == currentBranch;
    }).toList();

    final branchMembersCount = allMembers.where((m) {
      if (role != UserRole.trainer || _showAllBranches) return true;
      return m.branch == currentBranch;
    }).length;

    final presentToday = filteredTodayRecords.length;
    final checkedOut =
        filteredTodayRecords.where((r) => r.checkOutTime != null).length;
    final stillInside = presentToday - checkedOut;
    final totalMembers = branchMembersCount > 0 ? branchMembersCount : 1;
    final double percentage =
        (presentToday / totalMembers * 100).toDouble().clamp(0.0, 100.0);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Attendance',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.textPrimary)),
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  _showSearchBar = !_showSearchBar;
                });
              },
              icon: Icon(_showSearchBar ? Icons.search_off : Icons.search,
                  color: AppColors.primary),
            ),
          ],
        ),
        body: Column(
          children: [
            // Trainer Banner
            if (role == UserRole.trainer)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  border: Border(
                      bottom: BorderSide(
                          color: Colors.blue.withValues(alpha: 0.2))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _showAllBranches
                            ? "Showing check-ins across All Branches"
                            : "Showing check-ins for $currentBranch (Your assigned branch)",
                        style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("All Branches",
                            style: TextStyle(
                                color: Colors.blue[900],
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Switch(
                          value: _showAllBranches,
                          onChanged: (val) =>
                              setState(() => _showAllBranches = val),
                          activeThumbColor: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            if (_showSearchBar)
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: (val) =>
                      ref.read(attendanceProvider.notifier).setSearch(val),
                  decoration: InputDecoration(
                    hintText: 'Search across logs...',
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        ref.read(attendanceProvider.notifier).setSearch('');
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            _buildSummaryCard(presentToday, checkedOut, stillInside, percentage,
                totalMembers),
            Container(
              color: Colors.white,
              child: TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                labelStyle: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "Today's Log"),
                  Tab(text: "Search Member"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _TodayLogTab(
                    records: filteredTodayRecords,
                    membersMap: membersMap,
                    showBranch: role == UserRole.owner || _showAllBranches,
                  ),
                  _SearchMemberTab(
                    role: role,
                    currentBranch: currentBranch,
                    showAllBranches: _showAllBranches,
                    membersMap: membersMap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int presentToday, int checkedOut, int stillInside,
      double percentage, int totalMembers) {
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
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem("Present Today", presentToday.toString(),
                  isBold: true),
              const SizedBox(
                height: 40,
                child: VerticalDivider(color: Colors.white30, thickness: 1),
              ),
              _buildSummaryItem("Checked Out", checkedOut.toString()),
              const SizedBox(
                height: 40,
                child: VerticalDivider(color: Colors.white30, thickness: 1),
              ),
              _buildSummaryItem("Still Inside", stillInside.toString()),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text("Attendance Rate: ${percentage.toStringAsFixed(0)}%",
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              Text("$presentToday / $totalMembers Members",
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
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
        TweenAnimationBuilder<double>(
          key: ValueKey(value),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          builder: (context, anim, child) {
            final scale =
                anim < 0.5 ? 1.0 + (anim * 0.4) : 1.2 - ((anim - 0.5) * 0.4);
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Text(
            value,
            style: AppTextStyles.displayMedium.copyWith(
              color: Colors.white,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: 24,
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayLogTab extends ConsumerStatefulWidget {
  final List<dynamic> records;
  final Map<String, Member> membersMap;
  final bool showBranch;

  const _TodayLogTab(
      {required this.records,
      required this.membersMap,
      required this.showBranch});

  @override
  ConsumerState<_TodayLogTab> createState() => _TodayLogTabState();
}

class _TodayLogTabState extends ConsumerState<_TodayLogTab> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceProvider);

    // Filter by search query
    var filtered = widget.records
        .where((r) =>
            r.memberName
                .toLowerCase()
                .contains(state.searchQuery.toLowerCase()) ||
            r.memberCode
                .toLowerCase()
                .contains(state.searchQuery.toLowerCase()))
        .toList();

    // Filter by chips
    if (_selectedFilter == 'Checked In') {
      filtered = filtered.toList();
    } else if (_selectedFilter == 'Checked Out') {
      filtered = filtered.where((r) => r.checkOutTime != null).toList();
    } else if (_selectedFilter == 'Still Inside') {
      filtered = filtered.where((r) => r.checkOutTime == null).toList();
    }

    // Sort most recent check-in first
    filtered.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

    final filters = ['All', 'Checked In', 'Checked Out', 'Still Inside'];
    final now = DateTime.now();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: filters.map((f) {
              final isSelected = _selectedFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f,
                      style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary)),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                        color:
                            isSelected ? AppColors.primary : AppColors.border),
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedFilter = f;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.event_busy,
                  title: 'No check-ins recorded',
                  subtitle:
                      'No attendance logs match your active filters or search.',
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  padding:
                      const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final record = filtered[index];
                    final member = widget.membersMap[record.memberId];
                    final branchStr = member?.branch ?? 'Branch A';
                    final isStillInside = record.checkOutTime == null;

                    final checkInStr =
                        DateFormat('hh:mm a').format(record.checkInTime);
                    final checkOutStr = isStillInside
                        ? "Still inside"
                        : DateFormat('hh:mm a').format(record.checkOutTime!);

                    final isNew = record.checkInTime
                        .isAfter(now.subtract(const Duration(seconds: 4)));

                    Widget card = Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      color: isStillInside
                          ? Colors.orange.withValues(alpha: 0.08)
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: isStillInside
                                ? Colors.orange.withValues(alpha: 0.3)
                                : AppColors.border),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                              record.memberName.isNotEmpty
                                  ? record.memberName[0]
                                  : 'M',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(record.memberName,
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          widget.showBranch
                              ? '${record.memberCode} · $branchStr'
                              : '${record.memberCode} · ${record.planName}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.login,
                                    size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(checkInStr,
                                    style: AppTextStyles.caption.copyWith(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (!isStillInside)
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.logout,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(checkOutStr,
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold)),
                              ])
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.circle,
                                      size: 8, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(checkOutStr,
                                      style: AppTextStyles.caption.copyWith(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );

                    if (isNew) {
                      return TweenAnimationBuilder<Offset>(
                        key: ValueKey(record.id),
                        tween: Tween<Offset>(
                            begin: const Offset(1, 0), end: Offset.zero),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        builder: (context, offset, child) {
                          return FractionalTranslation(
                            translation: offset,
                            child: child,
                          );
                        },
                        child: card,
                      );
                    }

                    return card;
                  },
                ),
        ),
      ],
    );
  }
}

class _SearchMemberTab extends ConsumerStatefulWidget {
  final UserRole role;
  final String currentBranch;
  final bool showAllBranches;
  final Map<String, Member> membersMap;

  const _SearchMemberTab({
    required this.role,
    required this.currentBranch,
    required this.showAllBranches,
    required this.membersMap,
  });

  @override
  ConsumerState<_SearchMemberTab> createState() => _SearchMemberTabState();
}

class _SearchMemberTabState extends ConsumerState<_SearchMemberTab> {
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
    final attendanceState = ref.watch(attendanceProvider);

    final filteredMembers = allMembers.where((m) {
      if (widget.role != UserRole.trainer || widget.showAllBranches)
        return true;
      return m.branch == widget.currentBranch;
    }).toList();

    final results = _query.isEmpty
        ? filteredMembers
        : filteredMembers
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
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.info, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          'Search any member to view their attendance history',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.info)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _query = val),
                decoration: InputDecoration(
                  hintText: 'Search by name, phone or member ID...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
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
          child: results.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.search_off,
                  title: 'No members found',
                  subtitle: 'Try searching with a different name or member ID.',
                )
              : ListView.separated(
                  itemCount: results.length,
                  padding:
                      const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final member = results[index];

                    final memberRecs = attendanceState.allRecords
                        .where((r) => r.memberId == member.id)
                        .toList();
                    final presentDays = memberRecs
                        .map((r) => r.date.toIso8601String())
                        .toSet()
                        .length;
                    const totalMonthDays = 22; // Working days
                    final absentDays = (totalMonthDays - presentDays) > 0
                        ? (totalMonthDays - presentDays)
                        : 0;
                    final rate = ((presentDays / totalMonthDays) * 100)
                        .round()
                        .clamp(0, 100);

                    return Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          context.push('/attendance/${member.id}');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    child: Text(member.initials,
                                        style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(member.name,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                        Text(
                                            '${member.memberCode} · ${member.branch}',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                    color:
                                                        AppColors.textMuted)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: member.status ==
                                              MemberStatus.active
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      member.status.name.toUpperCase(),
                                      style: TextStyle(
                                        color:
                                            member.status == MemberStatus.active
                                                ? Colors.green
                                                : Colors.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right,
                                      color: Colors.grey),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Text("Present: $presentDays days",
                                      style: AppTextStyles.caption.copyWith(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold)),
                                  Text("Absent: $absentDays days",
                                      style: AppTextStyles.caption.copyWith(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold)),
                                  Text("Attendance: $rate%",
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
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
