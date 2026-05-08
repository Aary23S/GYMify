import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymflow/features/auth/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../providers/members_provider.dart';
import '../models/member_model.dart';
import '../widgets/member_card.dart';

class MembersListScreen extends ConsumerStatefulWidget {
  const MembersListScreen({super.key});

  @override
  ConsumerState<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends ConsumerState<MembersListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(filteredMembersProvider);
    final filter = ref.watch(membersFilterProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Members'),
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
        actions: [
          IconButton(
            onPressed: () {}, // Filter action
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: () => context.push('/members/add'),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(membersFilterProvider.notifier).update(
                      (state) => state.copyWith(searchQuery: value),
                    );
              },
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(membersFilterProvider.notifier).update(
                                (state) => state.copyWith(searchQuery: ''),
                              );
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected:
                      filter.statusFilter == null && !filter.expiringSoon,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(membersFilterProvider.notifier).update(
                            (state) => state.copyWith(
                              clearStatus: true,
                              expiringSoon: false,
                            ),
                          );
                    }
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Active',
                  isSelected: filter.statusFilter == MemberStatus.active &&
                      !filter.expiringSoon,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(membersFilterProvider.notifier).update(
                            (state) => state.copyWith(
                              statusFilter: MemberStatus.active,
                              expiringSoon: false,
                              clearStatus: false,
                            ),
                          );
                    }
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Expired',
                  isSelected: filter.statusFilter == MemberStatus.expired &&
                      !filter.expiringSoon,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(membersFilterProvider.notifier).update(
                            (state) => state.copyWith(
                              statusFilter: MemberStatus.expired,
                              expiringSoon: false,
                              clearStatus: false,
                            ),
                          );
                    }
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Expiring Soon',
                  isSelected: filter.expiringSoon,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(membersFilterProvider.notifier).update(
                            (state) => state.copyWith(
                              clearStatus: true,
                              expiringSoon: true,
                            ),
                          );
                    }
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Paused',
                  isSelected: filter.statusFilter == MemberStatus.paused &&
                      !filter.expiringSoon,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(membersFilterProvider.notifier).update(
                            (state) => state.copyWith(
                              statusFilter: MemberStatus.paused,
                              expiringSoon: false,
                              clearStatus: false,
                            ),
                          );
                    }
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Inactive',
                  isSelected: filter.statusFilter == MemberStatus.inactive &&
                      !filter.expiringSoon,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(membersFilterProvider.notifier).update(
                            (state) => state.copyWith(
                              statusFilter: MemberStatus.inactive,
                              expiringSoon: false,
                              clearStatus: false,
                            ),
                          );
                    }
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Showing ${members.length} members',
              style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
            ),
          ),

          Expanded(
            child: members.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.people_outline,
                    title: 'No members found',
                    subtitle: 'Try adjusting your search or filters',
                  )
                : ListView.separated(
                    itemCount: members.length,
                    separatorBuilder: (context, index) => const Divider(
                      indent: 72,
                      height: 1,
                      color: AppColors.border,
                    ),
                    itemBuilder: (context, index) {
                      return MemberCard(member: members[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/members/add'),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.primary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.primary),
      ),
      showCheckmark: false,
    );
  }
}
