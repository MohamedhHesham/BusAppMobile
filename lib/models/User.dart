class AppUser {
  final String userID;
  final String name;
  final String email;
  final String password;
  final String role;

  AppUser({
    required this.userID,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  // Firestore → AppUser
  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    return AppUser(
      userID: data['userID'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      role: data['role'] ?? 'user',
    );
  }

  // AppUser → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userID': userID,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
  }
}