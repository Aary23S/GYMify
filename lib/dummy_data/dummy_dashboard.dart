class WeeklyRevenue {
  final String day;
  final double amount;

  const WeeklyRevenue(this.day, this.amount);
}

class ExpiringMember {
  final String name;
  final String plan;
  final int daysLeft;
  final String expiryDate;

  const ExpiringMember(this.name, this.plan, this.daysLeft, this.expiryDate);
}

class DummyDashboardData {
  static const int totalMembers = 248;
  static const int activeToday = 43;
  static const int expiringSoon = 12;
  static const double revenueToday = 4500.0;

  static const List<WeeklyRevenue> weeklyRevenue = [
    WeeklyRevenue('Mon', 8500),
    WeeklyRevenue('Tue', 12000),
    WeeklyRevenue('Wed', 7800),
    WeeklyRevenue('Thu', 15200),
    WeeklyRevenue('Fri', 9200),
    WeeklyRevenue('Sat', 18500),
    WeeklyRevenue('Sun', 11000),
  ];

  static final List<int> last30DaysAttendance = [
    32,
    45,
    38,
    52,
    48,
    55,
    42,
    35,
    40,
    58,
    44,
    39,
    51,
    47,
    53,
    46,
    33,
    41,
    56,
    49,
    37,
    50,
    43,
    36,
    54,
    48,
    34,
    42,
    59,
    45
  ];

  static const List<ExpiringMember> expiringMembers = [
    ExpiringMember('Rahul Sharma', 'Monthly Pro', 2, '09 May 2026'),
    ExpiringMember('Anjali Gupta', 'Quarterly', 5, '12 May 2026'),
    ExpiringMember('Vikram Singh', 'Yearly Gold', 1, '08 May 2026'),
    ExpiringMember('Sneha Reddy', 'Monthly Basic', 7, '14 May 2026'),
    ExpiringMember('Amit Kumar', 'Monthly Pro', 3, '10 May 2026'),
    ExpiringMember('Karan Johar', 'Quarterly', 4, '11 May 2026'),
    ExpiringMember('Pooja Hegde', 'Monthly Pro', 2, '09 May 2026'),
    ExpiringMember('Tiger Shroff', 'Yearly Gold', 6, '13 May 2026'),
    ExpiringMember('Disha Patani', 'Monthly Basic', 1, '08 May 2026'),
    ExpiringMember('Shahid Kapoor', 'Monthly Pro', 5, '12 May 2026'),
    ExpiringMember('Kiara Advani', 'Quarterly', 3, '10 May 2026'),
    ExpiringMember('Siddharth Malhotra', 'Yearly Gold', 7, '14 May 2026'),
  ];
}
