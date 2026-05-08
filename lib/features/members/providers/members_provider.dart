import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/member_model.dart';
import '../../../dummy_data/dummy_members.dart';

class MembersFilter {
  final String searchQuery;
  final MemberStatus? statusFilter;
  final String? planFilter;
  final bool expiringSoon;

  MembersFilter({
    this.searchQuery = '',
    this.statusFilter,
    this.planFilter,
    this.expiringSoon = false,
  });

  MembersFilter copyWith({
    String? searchQuery,
    MemberStatus? statusFilter,
    String? planFilter,
    bool? expiringSoon,
    bool clearStatus = false,
    bool clearPlan = false,
  }) {
    return MembersFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
      planFilter: clearPlan ? null : (planFilter ?? this.planFilter),
      expiringSoon: expiringSoon ?? this.expiringSoon,
    );
  }
}

class MembersNotifier extends StateNotifier<List<Member>> {
  MembersNotifier() : super(dummyMembers);

  void addMember(Member member) {
    state = [...state, member];
  }

  int get nextMemberNumber => state.length + 1;

  void updateMember(Member updatedMember) {
    state = [
      for (final member in state)
        if (member.id == updatedMember.id) updatedMember else member
    ];
  }

  void deleteMember(String id) {
    state = state.where((member) => member.id != id).toList();
  }
}

final membersProvider =
    StateNotifierProvider<MembersNotifier, List<Member>>((ref) {
  return MembersNotifier();
});

final membersFilterProvider =
    StateProvider<MembersFilter>((ref) => MembersFilter());

final filteredMembersProvider = Provider<List<Member>>((ref) {
  final members = ref.watch(membersProvider);
  final filter = ref.watch(membersFilterProvider);

  return members.where((member) {
    final matchesSearch =
        member.name.toLowerCase().contains(filter.searchQuery.toLowerCase()) ||
            member.memberCode
                .toLowerCase()
                .contains(filter.searchQuery.toLowerCase()) ||
            member.phone.contains(filter.searchQuery);

    final matchesStatus =
        filter.statusFilter == null || member.status == filter.statusFilter;

    final matchesPlan =
        filter.planFilter == null || member.planName == filter.planFilter;

    bool matchesExpiringSoon = true;
    if (filter.expiringSoon) {
      final daysUntilExpiry =
          member.planExpiry.difference(DateTime.now()).inDays;
      matchesExpiringSoon = daysUntilExpiry >= 0 && daysUntilExpiry <= 7;
    }

    return matchesSearch && matchesStatus && matchesPlan && matchesExpiringSoon;
  }).toList();
});

final memberByIdProvider = Provider.family<Member?, String>((ref, id) {
  final members = ref.watch(membersProvider);
  return members.firstWhere((member) => member.id == id,
      orElse: () => throw Exception('Member not found'));
});
