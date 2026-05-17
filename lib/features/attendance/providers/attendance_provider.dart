import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../dummy_data/dummy_attendance.dart';
import '../../members/models/member_model.dart';

class AttendanceState {
  final List<AttendanceRecord> allRecords;
  final List<AttendanceRecord> todayRecords;
  final String searchQuery;
  final DateTime selectedDate;
  final bool isCheckingIn;

  // Backwards compatibility getter
  List<AttendanceRecord> get todaysRecords => todayRecords;

  AttendanceState({
    required this.allRecords,
    required this.todayRecords,
    this.searchQuery = '',
    required this.selectedDate,
    this.isCheckingIn = false,
  });

  AttendanceState copyWith({
    List<AttendanceRecord>? allRecords,
    List<AttendanceRecord>? todayRecords,
    String? searchQuery,
    DateTime? selectedDate,
    bool? isCheckingIn,
  }) {
    return AttendanceState(
      allRecords: allRecords ?? this.allRecords,
      todayRecords: todayRecords ?? this.todayRecords,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDate: selectedDate ?? this.selectedDate,
      isCheckingIn: isCheckingIn ?? this.isCheckingIn,
    );
  }
}

class AlreadyCheckedInException implements Exception {
  final String time;
  AlreadyCheckedInException(this.time);
}

class NotCheckedInException implements Exception {
  final String message;
  NotCheckedInException(this.message);
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  AttendanceNotifier() : super(_initialState());

  static AttendanceState _initialState() {
    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final all = List<AttendanceRecord>.from(initialDummyRecords);
    final today = all.where((r) => r.date.isAtSameMomentAs(todayOnly)).toList();

    return AttendanceState(
      allRecords: all,
      todayRecords: today,
      selectedDate: todayOnly,
    );
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  Future<void> markCheckIn(String memberId, String memberName, String memberCode, String planName, {String markedVia = 'qr_scan'}) async {
    if (isCheckedInToday(memberId)) {
      final time = getTodayCheckInTime(memberId) ?? '';
      throw AlreadyCheckedInException(time);
    }

    state = state.copyWith(isCheckingIn: true);
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final newRec = AttendanceRecord(
      id: 'rec_${now.millisecondsSinceEpoch}',
      memberId: memberId,
      memberName: memberName,
      memberCode: memberCode,
      planName: planName,
      checkInTime: now,
      checkOutTime: null,
      date: todayOnly,
      markedVia: markedVia,
    );

    state = state.copyWith(
      allRecords: [newRec, ...state.allRecords],
      todayRecords: [newRec, ...state.todayRecords],
      isCheckingIn: false,
    );
  }

  Future<void> markCheckOut(String memberId) async {
    final todayRecs = state.todayRecords.where((r) => r.memberId == memberId).toList();
    if (todayRecs.isEmpty) {
      throw NotCheckedInException("No check-in record found for today.");
    }

    final currentRec = todayRecs.first;
    if (currentRec.checkOutTime != null) {
      return; // Already checked out
    }

    final now = DateTime.now();
    final updatedRec = AttendanceRecord(
      id: currentRec.id,
      memberId: currentRec.memberId,
      memberName: currentRec.memberName,
      memberCode: currentRec.memberCode,
      planName: currentRec.planName,
      checkInTime: currentRec.checkInTime,
      checkOutTime: now,
      date: currentRec.date,
      markedVia: currentRec.markedVia,
    );

    final allUpdated = state.allRecords.map((r) => r.id == updatedRec.id ? updatedRec : r).toList();
    final todayUpdated = state.todayRecords.map((r) => r.id == updatedRec.id ? updatedRec : r).toList();

    state = state.copyWith(
      allRecords: allUpdated,
      todayRecords: todayUpdated,
    );
  }

  // Backwards compatibility for older manual calls
  Future<void> checkIn(Member member) => markCheckIn(member.id, member.name, member.memberCode, member.planName, markedVia: 'manual');

  bool isAlreadyCheckedIn(String memberId) => isCheckedInToday(memberId);
  String? getCheckInTime(String memberId) => getTodayCheckInTime(memberId);

  List<AttendanceRecord> getRecordsForMember(String memberId) {
    return state.allRecords.where((r) => r.memberId == memberId).toList();
  }

  List<AttendanceRecord> getAttendanceForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return state.allRecords.where((r) => r.date.isAtSameMomentAs(targetDate)).toList();
  }

  bool isCheckedInToday(String memberId) {
    return state.todayRecords.any((r) => r.memberId == memberId);
  }

  bool isCheckedOutToday(String memberId) {
    final recs = state.todayRecords.where((r) => r.memberId == memberId).toList();
    if (recs.isEmpty) return false;
    return recs.first.checkOutTime != null;
  }

  String? getTodayCheckInTime(String memberId) {
    final recs = state.todayRecords.where((r) => r.memberId == memberId).toList();
    if (recs.isEmpty) return null;
    return DateFormat('hh:mm a').format(recs.first.checkInTime);
  }

  String? getTodayCheckOutTime(String memberId) {
    final recs = state.todayRecords.where((r) => r.memberId == memberId).toList();
    if (recs.isEmpty || recs.first.checkOutTime == null) return null;
    return DateFormat('hh:mm a').format(recs.first.checkOutTime!);
  }
}

final attendanceProvider = StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  return AttendanceNotifier();
});
