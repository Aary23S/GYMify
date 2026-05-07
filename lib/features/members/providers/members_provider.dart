import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/member_model.dart';

class MembersNotifier extends StateNotifier<List<MemberModel>> {
  MembersNotifier() : super(dummyMembers);

  void addMember(MemberModel member) {
    state = [...state, member];
  }

  void updateMember(MemberModel updatedMember) {
    state = [
      for (final member in state)
        if (member.id == updatedMember.id) updatedMember else member
    ];
  }

  void deleteMember(String id) {
    state = state.where((member) => member.id != id).toList();
  }

  List<MemberModel> searchMembers(String query) {
    if (query.isEmpty) return state;
    return state.where((member) {
      final name = member.fullName.toLowerCase();
      final phone = member.phone;
      final email = member.email.toLowerCase();
      final search = query.toLowerCase();
      return name.contains(search) || phone.contains(search) || email.contains(search);
    }).toList();
  }
}

final membersProvider = StateNotifierProvider<MembersNotifier, List<MemberModel>>((ref) {
  return MembersNotifier();
});

final filteredMembersProvider = Provider.family<List<MemberModel>, String>((ref, query) {
  final members = ref.watch(membersProvider);
  if (query.isEmpty) return members;
  
  return members.where((member) {
    final name = member.fullName.toLowerCase();
    final search = query.toLowerCase();
    return name.contains(search);
  }).toList();
});
