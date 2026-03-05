import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String usersCollection = 'users';
  static const String usernamesCollection = 'usernames';

  /// Stream the current user's profile document in real-time
  Stream<UserModel?> streamUser(String uid) {
    return _firestore
        .collection(usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromDoc(doc);
    });
  }

  /// Check if a username is already taken
  Future<bool> isUsernameTaken(String username) async {
    final normalizedUsername = username.toLowerCase();
    final doc = await _firestore
        .collection(usernamesCollection)
        .doc(normalizedUsername)
        .get();
    return doc.exists;
  }

  /// Create a new user document in Firestore
  Future<void> createUser(UserModel user) async {
    final normalizedUsername = user.username.toLowerCase();
    
    // Atomically create user doc and reserve username
    await _firestore.runTransaction((transaction) async {
      // Check if username is still available
      final usernameDoc = _firestore
          .collection(usernamesCollection)
          .doc(normalizedUsername);
      final snapshot = await transaction.get(usernameDoc);
      
      if (snapshot.exists) {
        throw Exception('Username is already taken');
      }

      // Create user document
      final userDoc = _firestore.collection(usersCollection).doc(user.uid);
      transaction.set(userDoc, user.toMap());

      // Reserve username
      transaction.set(usernameDoc, {'uid': user.uid});
    });
  }

  /// Upload a profile photo to Firebase Storage
  Future<String> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final ref = _storage.ref().child('profile_photos').child('$uid.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: mimeType));
    final url = await ref.getDownloadURL();
    
    // Update user's photoUrl in Firestore
    await _firestore.collection(usersCollection).doc(uid).update({
      'photoUrl': url,
    });
    
    return url;
  }

  /// Get a user by UID
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection(usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  /// Get a user by username
  Future<UserModel?> getUserByUsername(String username) async {
    final normalizedUsername = username.toLowerCase();
    final querySnapshot = await _firestore
        .collection(usersCollection)
        .where('username', isEqualTo: normalizedUsername)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isEmpty) return null;
    return UserModel.fromDoc(querySnapshot.docs.first);
  }

  /// Update user profile
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection(usersCollection).doc(uid).update(data);
  }

  /// Delete a user and their username reservation
  Future<void> deleteUser(String uid) async {
    final user = await getUser(uid);
    if (user != null) {
      await _firestore.runTransaction((transaction) async {
        transaction.delete(_firestore.collection(usersCollection).doc(uid));
        transaction.delete(_firestore
            .collection(usernamesCollection)
            .doc(user.username.toLowerCase()));
      });
    }
  }
}
