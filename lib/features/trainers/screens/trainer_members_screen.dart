import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/models/member_model.dart';
import '../../members/providers/members_provider.dart';
import '../../members/widgets/member_card.dart';

class TrainerMembersScreen extends ConsumerStatefulWidget {
  const TrainerMembersScreen({super.key});

  @override
  ConsumerState<TrainerMembersScreen> createState() => _TrainerMembersScreenState();
}

class _TrainerMembersScreenState extends ConsumerState<TrainerMembersScreen> {
  final _branchSearchController = TextEditingController();
  final _otherSearchController = TextEditingController();

  String _branchSearchQuery = '';
  String _otherSearchQuery = '';

  String _branchFilter = 'All'; // All, Active, Expired, Expiring Soon
  String _otherFilter = 'All'; // All, Branch A, Branch B

  @override
  void dispose() {
    _branchSearchController.dispose();
    _otherSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final allMembers = ref.watch(membersProvider);

    final trainerUser = authState.user;
    final currentBranch = trainerUser?.currentBranch ?? 'Branch A';

    // 1. Branch matching trainer
    final branchMembers = allMembers.where((m) => m.branch == currentBranch).toList();

    // 2. Other branches
    final otherBranchMembers = allMembers.where((m) => m.branch != currentBranch).toList();

    // Filtered Branch Members (Tab 1)
    final filteredBranchMembers = branchMembers.where((m) {
      final matchesSearch = m.name.toLowerCase().contains(_branchSearchQuery.toLowerCase()) ||
          m.memberCode.toLowerCase().contains(_branchSearchQuery.toLowerCase()) ||
          m.phone.contains(_branchSearchQuery);

      bool matchesChip = true;
      if (_branchFilter == 'Active') {
        matchesChip = m.status == MemberStatus.active;
      } else if (_branchFilter == 'Expired') {
        matchesChip = m.status == MemberStatus.expired;
      } else if (_branchFilter == 'Expiring Soon') {
        final days = m.planExpiry.difference(DateTime.now()).inDays;
        matchesChip = days >= 0 && days <= 7;
      }

      return matchesSearch && matchesChip;
    }).toList();

    // Filtered Other Branches (Tab 2)
    final filteredOtherMembers = otherBranchMembers.where((m) {
      final matchesSearch = m.name.toLowerCase().contains(_otherSearchQuery.toLowerCase()) ||
          m.memberCode.toLowerCase().contains(_otherSearchQuery.toLowerCase()) ||
          m.phone.contains(_otherSearchQuery);

      bool matchesChip = true;
      if (_otherFilter == 'Branch A') {
        matchesChip = m.branch == 'Branch A';
      } else if (_otherFilter == 'Branch B') {
        matchesChip = m.branch == 'Branch B';
      }

      return matchesSearch && matchesChip;
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Members', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey[500],
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: [
              Tab(text: "$currentBranch Members (${branchMembers.length})"),
              Tab(text: "Other Branches (${otherBranchMembers.length})"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: BRANCH MATCHING TRAINER
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _branchSearchController,
                    onChanged: (val) => setState(() => _branchSearchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search $currentBranch members...",
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _branchSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _branchSearchController.clear();
                                setState(() => _branchSearchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: ['All', 'Active', 'Expired', 'Expiring Soon'].map((chip) {
                      final isSel = _branchFilter == chip;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(chip),
                          selected: isSel,
                          onSelected: (_) => setState(() => _branchFilter = chip),
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.primary, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.primary)),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    "Showing ${filteredBranchMembers.length} members",
                    style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
                  ),
                ),
                Expanded(
                  child: filteredBranchMembers.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.people_outline,
                          title: "No members found",
                          subtitle: _branchSearchQuery.isNotEmpty || _branchFilter != 'All'
                              ? "Try clearing your search or filter"
                              : "No members enrolled in $currentBranch.",
                        )
                      : ListView.separated(
                          itemCount: filteredBranchMembers.length,
                          separatorBuilder: (context, index) => const Divider(indent: 72, height: 1, color: AppColors.border),
                          itemBuilder: (context, index) => MemberCard(member: filteredBranchMembers[index]),
                        ),
                ),
              ],
            ),

            // TAB 2: OTHER BRANCHES
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.08), border: Border(bottom: BorderSide(color: Colors.blue.withValues(alpha: 0.2)))),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Viewing members from other branches (Read-only access).",
                          style: TextStyle(color: Colors.blue[900], fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _otherSearchController,
                    onChanged: (val) => setState(() => _otherSearchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search other branches...",
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _otherSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _otherSearchController.clear();
                                setState(() => _otherSearchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: ['All', 'Branch A', 'Branch B'].map((chip) {
                      final isSel = _otherFilter == chip;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(chip),
                          selected: isSel,
                          onSelected: (_) => setState(() => _otherFilter = chip),
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.primary, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.primary)),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    "Showing ${filteredOtherMembers.length} members",
                    style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
                  ),
                ),
                Expanded(
                  child: filteredOtherMembers.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.people_outline,
                          title: "No members found",
                          subtitle: "Try adjusting your search or filters",
                        )
                      : ListView.separated(
                          itemCount: filteredOtherMembers.length,
                          separatorBuilder: (context, index) => const Divider(indent: 72, height: 1, color: AppColors.border),
                          itemBuilder: (context, index) => MemberCard(member: filteredOtherMembers[index]),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
