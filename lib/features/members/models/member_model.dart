import 'package:flutter/material.dart';

enum MembershipStatus {
  active,
  expired,
  paused,
  inactive;

  String get displayName {
    switch (this) {
      case MembershipStatus.active:
        return 'Active';
      case MembershipStatus.expired:
        return 'Expired';
      case MembershipStatus.paused:
        return 'Paused';
      case MembershipStatus.inactive:
        return 'Inactive';
    }
  }

  Color get color {
    switch (this) {
      case MembershipStatus.active:
        return const Color(0xFF2ECC71);
      case MembershipStatus.expired:
        return const Color(0xFFE74C3C);
      case MembershipStatus.paused:
        return const Color(0xFFF39C12);
      case MembershipStatus.inactive:
        return const Color(0xFF9CA3AF);
    }
  }
}

class MemberModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String planName;
  final MembershipStatus status;
  final DateTime joinDate;
  final DateTime expiryDate;
  final String? profileImageUrl;

  const MemberModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.planName,
    required this.status,
    required this.joinDate,
    required this.expiryDate,
    this.profileImageUrl,
  });

  String get fullName => '$firstName $lastName';
  String get initials {
    final f = firstName.trim().isNotEmpty ? firstName.trim()[0] : '?';
    final l = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';
    return '$f$l'.toUpperCase();
  }
}

final dummyMembers = [
  MemberModel(
    id: '1',
    firstName: 'Rahul',
    lastName: 'Sharma',
    email: 'rahul@example.com',
    phone: '+91 9876543210',
    planName: 'Monthly Pro',
    status: MembershipStatus.active,
    joinDate: DateTime(2024, 1, 15),
    expiryDate: DateTime.now().add(const Duration(days: 2)),
  ),
  MemberModel(
    id: '2',
    firstName: 'Anjali',
    lastName: 'Gupta',
    email: 'anjali@example.com',
    phone: '+91 9876543211',
    planName: 'Quarterly Basic',
    status: MembershipStatus.active,
    joinDate: DateTime(2023, 11, 20),
    expiryDate: DateTime.now().add(const Duration(days: 45)),
  ),
  MemberModel(
    id: '3',
    firstName: 'Vikram',
    lastName: 'Singh',
    email: 'vikram@example.com',
    phone: '+91 9876543212',
    planName: 'Yearly Gold',
    status: MembershipStatus.expired,
    joinDate: DateTime(2023, 5, 10),
    expiryDate: DateTime.now().subtract(const Duration(days: 1)),
  ),
  MemberModel(
    id: '4',
    firstName: 'Sneha',
    lastName: 'Reddy',
    email: 'sneha@example.com',
    phone: '+91 9876543213',
    planName: 'Monthly Basic',
    status: MembershipStatus.paused,
    joinDate: DateTime(2024, 2, 5),
    expiryDate: DateTime.now().add(const Duration(days: 7)),
  ),
  MemberModel(
    id: '5',
    firstName: 'Amit',
    lastName: 'Kumar',
    email: 'amit@example.com',
    phone: '+91 9876543214',
    planName: 'Monthly Pro',
    status: MembershipStatus.active,
    joinDate: DateTime(2024, 3, 1),
    expiryDate: DateTime.now().add(const Duration(days: 20)),
  ),
  MemberModel(
    id: '6',
    firstName: 'Priya',
    lastName: 'Das',
    email: 'priya@example.com',
    phone: '+91 9876543215',
    planName: 'Monthly Basic',
    status: MembershipStatus.active,
    joinDate: DateTime(2024, 4, 10),
    expiryDate: DateTime.now().add(const Duration(days: 15)),
  ),
];
