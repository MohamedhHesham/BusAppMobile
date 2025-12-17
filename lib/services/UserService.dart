import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:busapp/models/User.dart';

class UserService {
  final CollectionReference users =
  FirebaseFirestore.instance.collection('users');

  // Create a new user
  Future<void> createUser(AppUser user) async {
    await users.add(user.toFirestore());
  }

  // Get user by userID (String)
  Future<AppUser?> getUserByUserID(String userID) async {
    final snapshot = await users.where('userID', isEqualTo: userID).get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return AppUser.fromFirestore(doc.data() as Map<String, dynamic>);
  }

  // Get user by email
  Future<AppUser?> getUserByEmail(String email) async {
    final snapshot = await users.where('email', isEqualTo: email).get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return AppUser.fromFirestore(doc.data() as Map<String, dynamic>);
  }

  // Update user data by userID (String)
  Future<void> updateUser(String userID, Map<String, dynamic> data) async {
    final snapshot = await users.where('userID', isEqualTo: userID).get();
    if (snapshot.docs.isEmpty) return;
    await snapshot.docs.first.reference.update(data);
  }

  // Promote user to admin by userID (String)
  Future<void> makeAdmin(String userID) async {
    final snapshot = await users.where('userID', isEqualTo: userID).get();
    if (snapshot.docs.isEmpty) return;
    await snapshot.docs.first.reference.update({'role': 'admin'});
  }

  // Check if user is admin by userID (String)
  Future<bool> isAdmin(String userID) async {
    final snapshot = await users.where('userID', isEqualTo: userID).get();
    if (snapshot.docs.isEmpty) return false;
    return (snapshot.docs.first.data() as Map<String, dynamic>)['role'] == 'admin';
  }

  // Delete user by userID (String)
  Future<void> deleteUser(String userID) async {
    final snapshot = await users.where('userID', isEqualTo: userID).get();
    if (snapshot.docs.isEmpty) return;
    await snapshot.docs.first.reference.delete();
  }

  // Generate a unique userID (String) - Using UUID-like format
  Future<String> generateUniqueUserID() async {
    // Generate a unique ID using timestamp + random component
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + DateTime.now().microsecond).toString();
    String userID = 'USER_$random';

    // Check if it already exists (very unlikely, but safe)
    final existing = await getUserByUserID(userID);
    if (existing != null) {
      // If somehow it exists, append more randomness
      userID = 'USER_${DateTime.now().microsecondsSinceEpoch}';
    }

    return userID;
  }
}