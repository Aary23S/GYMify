import 'package:flutter/material.dart';

enum MemberStatus {
  active,
  expired,
  paused,
  inactive;

  String get displayName {
    switch (this) {
      case MemberStatus.active:
        return 'Active';
      case MemberStatus.expired:
        return 'Expired';
      case MemberStatus.paused:
        return 'Paused';
      case MemberStatus.inactive:
        return 'Inactive';
    }
  }

  Color get color {
    switch (this) {
      case MemberStatus.active:
        return const Color(0xFF2ECC71);
      case MemberStatus.expired:
        return const Color(0xFFE74C3C);
      case MemberStatus.paused:
        return const Color(0xFFF39C12);
      case MemberStatus.inactive:
        return const Color(0xFF9CA3AF);
    }
  }
}

class Member {
  final String id;
  final String memberCode; // GYM-2026-XXXX
  final String name;
  final String phone;
  final String email;
  final DateTime dateOfBirth;
  final String gender;
  final String? photoUrl;
  final String planName;
  final double planPrice;
  final MemberStatus status;
  final DateTime joinDate;
  final DateTime planExpiry;
  final String? assignedTrainerId;
  final String? assignedTrainerName;
  final String? bloodGroup;
  final String? address;
  final String emergencyContactName;
  final String emergencyContactPhone;

  const Member({
    required this.id,
    required this.memberCode,
    required this.name,
    required this.phone,
    required this.email,
    required this.dateOfBirth,
    required this.gender,
    this.photoUrl,
    required this.planName,
    required this.planPrice,
    required this.status,
    required this.joinDate,
    required this.planExpiry,
    this.assignedTrainerId,
    this.assignedTrainerName,
    this.bloodGroup,
    this.address,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
  });

  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
