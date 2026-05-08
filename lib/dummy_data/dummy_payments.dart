class PaymentRecord {
  final String id;
  final String memberId;
  final String memberName;
  final String memberCode;
  final String planName;
  final double amount;
  final String paymentMode; // 'cash', 'upi', 'card', 'bank_transfer'
  final DateTime paymentDate;
  final String? transactionRef;
  final String invoiceNumber;

  PaymentRecord({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.memberCode,
    required this.planName,
    required this.amount,
    required this.paymentMode,
    required this.paymentDate,
    this.transactionRef,
    required this.invoiceNumber,
  });
}

class PendingRenewal {
  final String memberId;
  final String memberName;
  final String memberCode;
  final String currentPlan;
  final DateTime expiryDate;
  final int daysUntilExpiry; // negative = already expired
  final double amount;

  PendingRenewal({
    required this.memberId,
    required this.memberName,
    required this.memberCode,
    required this.currentPlan,
    required this.expiryDate,
    required this.daysUntilExpiry,
    required this.amount,
  });
}

final List<PaymentRecord> dummyPayments = [
  PaymentRecord(
    id: '1',
    memberId: '1',
    memberName: 'Arjun Sharma',
    memberCode: 'GYM-2026-0001',
    planName: 'Annual Elite',
    amount: 15000,
    paymentMode: 'upi',
    paymentDate: DateTime.now().subtract(const Duration(days: 2)),
    transactionRef: 'UPI123456789',
    invoiceNumber: 'INV-2026-0001',
  ),
  PaymentRecord(
    id: '2',
    memberId: '2',
    memberName: 'Priya Patel',
    memberCode: 'GYM-2026-0002',
    planName: 'Monthly Standard',
    amount: 2000,
    paymentMode: 'cash',
    paymentDate: DateTime.now().subtract(const Duration(days: 5)),
    invoiceNumber: 'INV-2026-0002',
  ),
  PaymentRecord(
    id: '3',
    memberId: '3',
    memberName: 'Rohan Gupta',
    memberCode: 'GYM-2026-0003',
    planName: 'Quarterly Premium',
    amount: 5500,
    paymentMode: 'card',
    paymentDate: DateTime.now().subtract(const Duration(days: 10)),
    transactionRef: 'CARD987654',
    invoiceNumber: 'INV-2026-0003',
  ),
  PaymentRecord(
    id: '4',
    memberId: '5',
    memberName: 'Vikram Singh',
    memberCode: 'GYM-2026-0005',
    planName: 'Annual Elite',
    amount: 15000,
    paymentMode: 'upi',
    paymentDate: DateTime.now().subtract(const Duration(days: 15)),
    transactionRef: 'UPI998877',
    invoiceNumber: 'INV-2026-0004',
  ),
  PaymentRecord(
    id: '5',
    memberId: '7',
    memberName: 'Kabir Das',
    memberCode: 'GYM-2026-0007',
    planName: 'Quarterly Premium',
    amount: 5500,
    paymentMode: 'bank_transfer',
    paymentDate: DateTime.now().subtract(const Duration(days: 20)),
    transactionRef: 'TXN445566',
    invoiceNumber: 'INV-2026-0005',
  ),
  // Add more to reach 25
  ...List.generate(20, (index) {
    final names = ['Sanya Malhotra', 'Ishaan Khattar', 'Zoya Akhtar', 'Aditya Roy', 'Kriti Sanon', 'Varun Dhawan', 'Sara Ali Khan', 'Ranbir Kapoor', 'Deepika Padukone', 'Ayushmann Khurrana'];
    final plans = ['Monthly Basic', 'Monthly Standard', 'Quarterly Premium', 'Annual Elite'];
    final prices = [1500.0, 2000.0, 5500.0, 15000.0];
    final modes = ['upi', 'cash', 'card', 'bank_transfer'];
    
    final nameIndex = index % names.length;
    final planIndex = index % plans.length;
    final modeIndex = index % modes.length;

    return PaymentRecord(
      id: (index + 6).toString(),
      memberId: (index + 8).toString(),
      memberName: names[nameIndex],
      memberCode: 'GYM-2026-00${index + 8}',
      planName: plans[planIndex],
      amount: prices[planIndex],
      paymentMode: modes[modeIndex],
      paymentDate: DateTime.now().subtract(Duration(days: index + 1)),
      transactionRef: modes[modeIndex] != 'cash' ? 'REF${index + 1000}' : null,
      invoiceNumber: 'INV-2026-00${index + 6}',
    );
  }),
];

final List<PendingRenewal> dummyPendingRenewals = [
  // Already expired
  PendingRenewal(
    memberId: '19',
    memberName: 'Taapsee Pannu',
    memberCode: 'GYM-2026-0019',
    currentPlan: 'Quarterly Premium',
    expiryDate: DateTime.now().subtract(const Duration(days: 5)),
    daysUntilExpiry: -5,
    amount: 5500,
  ),
  PendingRenewal(
    memberId: '20',
    memberName: 'Rajkummar Rao',
    memberCode: 'GYM-2026-0020',
    currentPlan: 'Monthly Basic',
    expiryDate: DateTime.now().subtract(const Duration(days: 3)),
    daysUntilExpiry: -3,
    amount: 1500,
  ),
  PendingRenewal(
    memberId: '12',
    memberName: 'Varun Dhawan',
    memberCode: 'GYM-2026-0012',
    currentPlan: 'Monthly Basic',
    expiryDate: DateTime.now().subtract(const Duration(days: 2)),
    daysUntilExpiry: -2,
    amount: 1500,
  ),
  PendingRenewal(
    memberId: '4',
    memberName: 'Ananya Iyer',
    memberCode: 'GYM-2026-0004',
    currentPlan: 'Monthly Basic',
    expiryDate: DateTime.now().subtract(const Duration(days: 1)),
    daysUntilExpiry: -1,
    amount: 1500,
  ),
  // Expiring today/tomorrow
  PendingRenewal(
    memberId: '10',
    memberName: 'Aditya Roy',
    memberCode: 'GYM-2026-0010',
    currentPlan: 'Monthly Standard',
    expiryDate: DateTime.now(),
    daysUntilExpiry: 0,
    amount: 2000,
  ),
  PendingRenewal(
    memberId: '6',
    memberName: 'Sanya Malhotra',
    memberCode: 'GYM-2026-0006',
    currentPlan: 'Monthly Standard',
    expiryDate: DateTime.now().add(const Duration(days: 1)),
    daysUntilExpiry: 1,
    amount: 2000,
  ),
  // Expiring soon
  PendingRenewal(
    memberId: '11',
    memberName: 'Kriti Sanon',
    memberCode: 'GYM-2026-0011',
    currentPlan: 'Quarterly Premium',
    expiryDate: DateTime.now().add(const Duration(days: 3)),
    daysUntilExpiry: 3,
    amount: 5500,
  ),
  PendingRenewal(
    memberId: '15',
    memberName: 'Deepika Padukone',
    memberCode: 'GYM-2026-0015',
    currentPlan: 'Quarterly Premium',
    expiryDate: DateTime.now().add(const Duration(days: 5)),
    daysUntilExpiry: 5,
    amount: 5500,
  ),
  PendingRenewal(
    memberId: '16',
    memberName: 'Ayushmann Khurrana',
    memberCode: 'GYM-2026-0016',
    currentPlan: 'Monthly Basic',
    expiryDate: DateTime.now().add(const Duration(days: 6)),
    daysUntilExpiry: 6,
    amount: 1500,
  ),
  PendingRenewal(
    memberId: '18',
    memberName: 'Vicky Kaushal',
    memberCode: 'GYM-2026-0018',
    currentPlan: 'Monthly Standard',
    expiryDate: DateTime.now().add(const Duration(days: 7)),
    daysUntilExpiry: 7,
    amount: 2000,
  ),
];
