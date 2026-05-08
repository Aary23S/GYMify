class AttendanceRecord {
  final String memberId;
  final String memberName;
  final String memberCode;
  final String planName;
  final DateTime checkInTime;
  final String checkInMethod;

  AttendanceRecord({
    required this.memberId,
    required this.memberName,
    required this.memberCode,
    required this.planName,
    required this.checkInTime,
    this.checkInMethod = 'manual',
  });
}

final List<AttendanceRecord> todaysAttendance = [
  AttendanceRecord(
    memberId: '1',
    memberName: 'Arjun Sharma',
    memberCode: 'GYM-2026-0001',
    planName: 'Annual Elite',
    checkInTime: DateTime(2026, 5, 6, 6, 5),
  ),
  AttendanceRecord(
    memberId: '2',
    memberName: 'Priya Patel',
    memberCode: 'GYM-2026-0002',
    planName: 'Monthly Standard',
    checkInTime: DateTime(2026, 5, 6, 6, 23),
  ),
  AttendanceRecord(
    memberId: '3',
    memberName: 'Rohan Gupta',
    memberCode: 'GYM-2026-0003',
    planName: 'Quarterly Premium',
    checkInTime: DateTime(2026, 5, 6, 7, 1),
  ),
  AttendanceRecord(
    memberId: '5',
    memberName: 'Vikram Singh',
    memberCode: 'GYM-2026-0005',
    planName: 'Annual Elite',
    checkInTime: DateTime(2026, 5, 6, 7, 15),
  ),
  AttendanceRecord(
    memberId: '7',
    memberName: 'Kabir Das',
    memberCode: 'GYM-2026-0007',
    planName: 'Quarterly Premium',
    checkInTime: DateTime(2026, 5, 6, 7, 44),
  ),
  AttendanceRecord(
    memberId: '9',
    memberName: 'Zoya Akhtar',
    memberCode: 'GYM-2026-0009',
    planName: 'Annual Elite',
    checkInTime: DateTime(2026, 5, 6, 8, 2),
  ),
  AttendanceRecord(
    memberId: '10',
    memberName: 'Aditya Roy',
    memberCode: 'GYM-2026-0010',
    planName: 'Monthly Standard',
    checkInTime: DateTime(2026, 5, 6, 8, 30),
  ),
  AttendanceRecord(
    memberId: '11',
    memberName: 'Kriti Sanon',
    memberCode: 'GYM-2026-0011',
    planName: 'Quarterly Premium',
    checkInTime: DateTime(2026, 5, 6, 9, 10),
  ),
  AttendanceRecord(
    memberId: '13',
    memberName: 'Sara Ali Khan',
    memberCode: 'GYM-2026-0013',
    planName: 'Annual Elite',
    checkInTime: DateTime(2026, 5, 6, 9, 45),
  ),
  AttendanceRecord(
    memberId: '14',
    memberName: 'Ranbir Kapoor',
    memberCode: 'GYM-2026-0014',
    planName: 'Monthly Standard',
    checkInTime: DateTime(2026, 5, 6, 10, 20),
  ),
  AttendanceRecord(
    memberId: '15',
    memberName: 'Deepika Padukone',
    memberCode: 'GYM-2026-0015',
    planName: 'Quarterly Premium',
    checkInTime: DateTime(2026, 5, 6, 11, 0),
  ),
  AttendanceRecord(
    memberId: '18',
    memberName: 'Vicky Kaushal',
    memberCode: 'GYM-2026-0018',
    planName: 'Monthly Standard',
    checkInTime: DateTime(2026, 5, 6, 11, 28),
  ),
  // Historical data for testing calendar in profile
  AttendanceRecord(
    memberId: '14',
    memberName: 'Ranbir Kapoor',
    memberCode: 'GYM-2026-0014',
    planName: 'Monthly Standard',
    checkInTime: DateTime(2026, 5, 5, 8, 30),
  ),
  AttendanceRecord(
    memberId: '14',
    memberName: 'Ranbir Kapoor',
    memberCode: 'GYM-2026-0014',
    planName: 'Monthly Standard',
    checkInTime: DateTime(2026, 5, 4, 7, 45),
  ),
  AttendanceRecord(
    memberId: '14',
    memberName: 'Ranbir Kapoor',
    memberCode: 'GYM-2026-0014',
    planName: 'Monthly Standard',
    checkInTime: DateTime(2026, 5, 2, 9, 15),
  ),
  AttendanceRecord(
    memberId: '14',
    memberName: 'Ranbir Kapoor',
    memberCode: 'GYM-2026-0014',
    planName: 'Monthly Standard',
    checkInTime: DateTime(2026, 5, 1, 6, 50),
  ),
  AttendanceRecord(
    memberId: '14',
    memberName: 'Ranbir Kapoor',
    memberCode: 'GYM-2026-0014',
    planName: 'Monthly Standard',
    checkInTime: DateTime(2026, 4, 30, 8, 10),
  ),
];
