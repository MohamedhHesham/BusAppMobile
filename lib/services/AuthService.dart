import 'package:busapp/services/UserService.dart';
import 'package:busapp/models/User.dart';

class AuthService {
  final UserService _userService = UserService();

  // Register new user
  Future<void> register(AppUser user) async {
    await _userService.createUser(user);
  }

  // Login by email + password
  Future<AppUser?> login(String email, String password) async {
    final user = await _userService.getUserByEmail(email);
    if (user != null && user.password == password) {
      return user; // ✅ successful login
    }
    return null;
  }


  // Check if user is admin by userID (String)
  Future<bool> isAdmin(String userID) async {
    return await _userService.isAdmin(userID);
  }
}