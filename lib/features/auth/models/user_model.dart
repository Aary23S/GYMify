enum UserRole {
  owner,
  trainer,
  member;

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.trainer:
        return 'Trainer';
      case UserRole.member:
        return 'Member';
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String gymName;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.gymName,
  });
}

final dummyUsers = {
  UserRole.owner: const UserModel(
    id: 'usr_owner',
    name: 'Rajesh Kumar',
    email: 'owner@gymflow.com',
    role: UserRole.owner,
    gymName: 'GymFlow Fitness Center',
  ),
  UserRole.trainer: const UserModel(
    id: 'usr_trainer',
    name: 'Sneha Kapoor',
    email: 'trainer@gymflow.com',
    role: UserRole.trainer,
    gymName: 'GymFlow Fitness Center',
  ),
  UserRole.member: const UserModel(
    id: 'usr_member',
    name: 'Arjun Sharma',
    email: 'member@gymflow.com',
    role: UserRole.member,
    gymName: 'GymFlow Fitness Center',
  ),
};
