import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/models/member_model.dart';
import '../../members/providers/members_provider.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../../members/widgets/member_card.dart';

class TrainerMembersScreen extends ConsumerStatefulWidget {
  const TrainerMembersScreen({super.key});

  @override
  ConsumerState<TrainerMembersScreen> createState() => _TrainerMembersScreenState();
}

class _TrainerMembersScreenState extends ConsumerState<TrainerMembersScreen> {
  final _traineeSearchController = TextEditingController();
  final _allSearchController = TextEditingController();

  String _traineeSearchQuery = '';
  String _allSearchQuery = '';

  String _traineeFilter = 'All'; // All, Present Today, Absent Today, Expiring Soon
  String _allFilter = 'All'; // All, Active, Expired

  @override
  void dispose() {
    _traineeSearchController.dispose();
    _allSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final allMembers = ref.watch(membersProvider);
    final attendanceNotifier = ref.read(attendanceProvider.notifier);

    final trainerUser = authState.user;
    final trainerId = trainerUser?.id ?? 'trn_001';
    final trainerName = trainerUser?.name ?? 'Sneha Kapoor';

    // Total Assigned Trainees
    final assignedTrainees = allMembers.where(
      (m) => m.assignedTrainerId == trainerId || m.assignedTrainerName == trainerName,
    ).toList();

    // Filtered Trainees (Tab 1)
    final filteredTrainees = assignedTrainees.where((m) {
      final matchesSearch = m.name.toLowerCase().contains(_traineeSearchQuery.toLowerCase()) ||
          m.memberCode.toLowerCase().contains(_traineeSearchQuery.toLowerCase()) ||
          m.phone.contains(_traineeSearchQuery);

      bool matchesChip = true;
      if (_traineeFilter == 'Present Today') {
        matchesChip = attendanceNotifier.isCheckedInToday(m.id);
      } else if (_traineeFilter == 'Absent Today') {
        matchesChip = !attendanceNotifier.isCheckedInToday(m.id);
      } else if (_traineeFilter == 'Expiring Soon') {
        final days = m.planExpiry.difference(DateTime.now()).inDays;
        matchesChip = days >= 0 && days <= 7;
      }

      return matchesSearch && matchesChip;
    }).toList();

    // Filtered All Members (Tab 2)
    final filteredAllMembers = allMembers.where((m) {
      final matchesSearch = m.name.toLowerCase().contains(_allSearchQuery.toLowerCase()) ||
          m.memberCode.toLowerCase().contains(_allSearchQuery.toLowerCase()) ||
          m.phone.contains(_allSearchQuery);

      bool matchesChip = true;
      if (_allFilter == 'Active') {
        matchesChip = m.status == MemberStatus.active;
      } else if (_allFilter == 'Expired') {
        matchesChip = m.status == MemberStatus.expired;
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
              Tab(text: "My Trainees (${assignedTrainees.length})"),
              Tab(text: "All Members (${allMembers.length})"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: MY TRAINEES
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _traineeSearchController,
                    onChanged: (val) => setState(() => _traineeSearchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search your assigned trainees...",
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _traineeSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _traineeSearchController.clear();
                                setState(() => _traineeSearchQuery = '');
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
                    children: ['All', 'Present Today', 'Absent Today', 'Expiring Soon'].map((chip) {
                      final isSel = _traineeFilter == chip;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(chip),
                          selected: isSel,
                          onSelected: (_) => setState(() => _traineeFilter = chip),
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
                    "Showing ${filteredTrainees.length} trainees",
                    style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
                  ),
                ),
                Expanded(
                  child: filteredTrainees.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.people_outline,
                          title: "No trainees found",
                          subtitle: _traineeSearchQuery.isNotEmpty || _traineeFilter != 'All'
                              ? "Try clearing your search or filter"
                              : "You don't have any assigned trainees yet.",
                        )
                      : ListView.separated(
                          itemCount: filteredTrainees.length,
                          separatorBuilder: (context, index) => const Divider(indent: 72, height: 1, color: AppColors.border),
                          itemBuilder: (context, index) => MemberCard(member: filteredTrainees[index]),
                        ),
                ),
              ],
            ),

            // TAB 2: ALL MEMBERS
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
                          "Viewing all gym members. You can view profiles and send reminders.",
                          style: TextStyle(color: Colors.blue[900], fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _allSearchController,
                    onChanged: (val) => setState(() => _allSearchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search all gym members...",
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _allSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _allSearchController.clear();
                                setState(() => _allSearchQuery = '');
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
                    children: ['All', 'Active', 'Expired'].map((chip) {
                      final isSel = _allFilter == chip;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(chip),
                          selected: isSel,
                          onSelected: (_) => setState(() => _allFilter = chip),
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
                    "Showing ${filteredAllMembers.length} members",
                    style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
                  ),
                ),
                Expanded(
                  child: filteredAllMembers.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.people_outline,
                          title: "No members found",
                          subtitle: "Try adjusting your search or filters",
                        )
                      : ListView.separated(
                          itemCount: filteredAllMembers.length,
                          separatorBuilder: (context, index) => const Divider(indent: 72, height: 1, color: AppColors.border),
                          itemBuilder: (context, index) => MemberCard(member: filteredAllMembers[index]),
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
