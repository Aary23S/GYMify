
class AttendanceRecord {
  final String id;
  final String memberId;
  final String memberName;
  final String memberCode;
  final String planName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final DateTime date;
  final String markedVia;

  AttendanceRecord({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.memberCode,
    required this.planName,
    required this.checkInTime,
    this.checkOutTime,
    required this.date,
    this.markedVia = 'qr_scan',
  });
}

List<AttendanceRecord> generateDummyAttendance() {
  final now = DateTime.now();
  final List<AttendanceRecord> records = [];
  int idCounter = 1000;

  final membersInfo = [
    ('1', 'Arjun Sharma', 'GYM-2026-0001', 'Annual Elite'),
    ('2', 'Priya Patel', 'GYM-2026-0002', 'Monthly Standard'),
    ('3', 'Rohan Gupta', 'GYM-2026-0003', 'Quarterly Premium'),
    ('4', 'Ananya Iyer', 'GYM-2026-0004', 'Monthly Basic'),
    ('5', 'Vikram Singh', 'GYM-2026-0005', 'Annual Elite'),
    ('6', 'Sanya Malhotra', 'GYM-2026-0006', 'Monthly Standard'),
    ('7', 'Kabir Das', 'GYM-2026-0007', 'Quarterly Premium'),
    ('8', 'Ishaan Khattar', 'GYM-2026-0008', 'Monthly Basic'),
    ('9', 'Zoya Akhtar', 'GYM-2026-0009', 'Annual Elite'),
    ('10', 'Aditya Roy', 'GYM-2026-0010', 'Monthly Standard'),
    ('11', 'Kriti Sanon', 'GYM-2026-0011', 'Quarterly Premium'),
    ('12', 'Varun Dhawan', 'GYM-2026-0012', 'Monthly Basic'),
    ('13', 'Sara Ali Khan', 'GYM-2026-0013', 'Annual Elite'),
    ('14', 'Ranbir Kapoor', 'GYM-2026-0014', 'Monthly Standard'),
    ('15', 'Deepika Padukone', 'GYM-2026-0015', 'Quarterly Premium'),
    ('16', 'Ayushmann Khurrana', 'GYM-2026-0016', 'Monthly Basic'),
    ('17', 'Alia Bhatt', 'GYM-2026-0017', 'Annual Elite'),
    ('18', 'Vicky Kaushal', 'GYM-2026-0018', 'Monthly Standard'),
    ('19', 'Taapsee Pannu', 'GYM-2026-0019', 'Quarterly Premium'),
    ('20', 'Rajkummar Rao', 'GYM-2026-0020', 'Monthly Basic'),
    ('21', 'Kiara Advani', 'GYM-2026-0021', 'Annual Elite'),
    ('22', 'Sidharth Malhotra', 'GYM-2026-0022', 'Monthly Standard'),
    ('23', 'Shraddha Kapoor', 'GYM-2026-0023', 'Quarterly Premium'),
    ('24', 'Tiger Shroff', 'GYM-2026-0024', 'Monthly Basic'),
    ('25', 'Anushka Sharma', 'GYM-2026-0025', 'Annual Elite'),
  ];

  // 1. Generate past 30 days history (excluding today)
  for (int dayOffset = 30; dayOffset >= 1; dayOffset--) {
    final date = now.subtract(Duration(days: dayOffset));
    final dateOnly = DateTime(date.year, date.month, date.day);

    for (int i = 0; i < membersInfo.length; i++) {
      final seed = (i + 1) * 37 + dayOffset * 13;
      if (seed % 10 < 7) { // 70% chance present
        final checkInHour = 6 + (seed % 5);
        final checkInMin = seed % 60;
        final durationMins = 60 + (seed % 61);

        final checkInTime = DateTime(date.year, date.month, date.day, checkInHour, checkInMin);
        final checkOutTime = checkInTime.add(Duration(minutes: durationMins));

        records.add(
          AttendanceRecord(
            id: 'rec_${idCounter++}',
            memberId: membersInfo[i].$1,
            memberName: membersInfo[i].$2,
            memberCode: membersInfo[i].$3,
            planName: membersInfo[i].$4,
            checkInTime: checkInTime,
            checkOutTime: checkOutTime,
            date: dateOnly,
            markedVia: seed % 3 == 0 ? 'qr_scan' : 'manual',
          ),
        );
      }
    }
  }

  // 2. Generate today's records: 5 checked out, 3 still inside
  final todayOnly = DateTime(now.year, now.month, now.day);

  for (int i = 0; i < 5; i++) {
    final m = membersInfo[i];
    final checkIn = DateTime(now.year, now.month, now.day, 6 + i, 15 * i % 60);
    final checkOut = checkIn.add(const Duration(minutes: 75));
    records.add(
      AttendanceRecord(
        id: 'rec_${idCounter++}',
        memberId: m.$1,
        memberName: m.$2,
        memberCode: m.$3,
        planName: m.$4,
        checkInTime: checkIn,
        checkOutTime: checkOut,
        date: todayOnly,
        markedVia: 'qr_scan',
      ),
    );
  }

  for (int i = 5; i < 9; i++) {
    final m = membersInfo[i];
    final checkIn = DateTime(now.year, now.month, now.day, now.hour > 2 ? now.hour - 1 : now.hour, 10 * i % 60);
    records.add(
      AttendanceRecord(
        id: 'rec_${idCounter++}',
        memberId: m.$1,
        memberName: m.$2,
        memberCode: m.$3,
        planName: m.$4,
        checkInTime: checkIn,
        checkOutTime: null,
        date: todayOnly,
        markedVia: 'qr_scan',
      ),
    );
  }

  return records;
}

final List<AttendanceRecord> initialDummyRecords = generateDummyAttendance();
