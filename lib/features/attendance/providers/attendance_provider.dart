import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../dummy_data/dummy_attendance.dart';
import '../../members/models/member_model.dart';

class AttendanceState {
  final List<AttendanceRecord> todaysRecords;
  final String searchQuery;
  final bool isCheckingIn;

  AttendanceState({
    required this.todaysRecords,
    this.searchQuery = '',
    this.isCheckingIn = false,
  });

  AttendanceState copyWith({
    List<AttendanceRecord>? todaysRecords,
    String? searchQuery,
    bool? isCheckingIn,
  }) {
    return AttendanceState(
      todaysRecords: todaysRecords ?? this.todaysRecords,
      searchQuery: searchQuery ?? this.searchQuery,
      isCheckingIn: isCheckingIn ?? this.isCheckingIn,
    );
  }
}

class AlreadyCheckedInException implements Exception {
  final String time;
  AlreadyCheckedInException(this.time);
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  AttendanceNotifier()
      : super(AttendanceState(todaysRecords: todaysAttendance));

  Future<void> checkIn(Member member) async {
    // 1. Check if member already in todaysRecords
    final existing = state.todaysRecords
        .where((r) => r.memberId == member.id)
        .toList();
    
    if (existing.isNotEmpty) {
      final time = DateFormat('hh:mm a').format(existing.first.checkInTime);
      throw AlreadyCheckedInException(time);
    }

    state = state.copyWith(isCheckingIn: true);
    
    // 2. Simulate check-in delay
    await Future.delayed(const Duration(milliseconds: 800));

    // 3. Add new record
    final newRecord = AttendanceRecord(
      memberId: member.id,
      memberName: member.name,
      memberCode: member.memberCode,
      planName: member.planName,
      checkInTime: DateTime.now(),
    );

    state = state.copyWith(
      todaysRecords: [...state.todaysRecords, newRecord],
      isCheckingIn: false,
    );
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  bool isAlreadyCheckedIn(String memberId) {
    return state.todaysRecords.any((r) => r.memberId == memberId);
  }

  String? getCheckInTime(String memberId) {
    try {
      final record = state.todaysRecords.firstWhere((r) => r.memberId == memberId);
      return DateFormat('hh:mm a').format(record.checkInTime);
    } catch (_) {
      return null;
    }
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  return AttendanceNotifier();
});
