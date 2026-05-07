enum UserRole {
  superAdmin,
  admin,
  trainer,
  member;

  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Owner';
      case UserRole.admin:
        return 'Admin';
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
  UserRole.superAdmin: const UserModel(
    id: '1',
    name: 'John Doe',
    email: 'owner@gymflow.com',
    role: UserRole.superAdmin,
    gymName: 'Iron Paradise',
  ),
  UserRole.admin: const UserModel(
    id: '2',
    name: 'Jane Smith',
    email: 'admin@gymflow.com',
    role: UserRole.admin,
    gymName: 'Iron Paradise',
  ),
  UserRole.trainer: const UserModel(
    id: '3',
    name: 'Mike Ross',
    email: 'trainer@gymflow.com',
    role: UserRole.trainer,
    gymName: 'Iron Paradise',
  ),
  UserRole.member: const UserModel(
    id: '4',
    name: 'Alex Hunter',
    email: 'member@gymflow.com',
    role: UserRole.member,
    gymName: 'Iron Paradise',
  ),
};
