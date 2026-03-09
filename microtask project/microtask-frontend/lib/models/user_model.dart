enum UserRole { taskUser, taskProvider }

class User {
  final String name;
  final String email;
  final int wallet;
  final UserRole role;
  final String location;

  User({
    required this.name,
    required this.email,
    required this.wallet,
    required this.role,
    this.location = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      email: json['email'],
      wallet: json['wallet'],
      role: json['role'] == 'taskProvider' ? UserRole.taskProvider : UserRole.taskUser,
      location: json['location'] ?? '',
    );
  }
}
