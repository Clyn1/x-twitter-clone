// lib/services/user_service.dart

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── Collection reference ────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // ── Read ────────────────────────────────────────────────────────────────────

  /// Fetch a single user document. Returns null if it doesn't exist yet.
  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  /// Stream a user document in real time.
  Stream<UserModel?> streamUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromDoc(doc);
    });
  }

  /// Check if a username is already taken (case-insensitive).
  Future<bool> isUsernameTaken(String username) async {
    final query = await _users
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // ── Write ───────────────────────────────────────────────────────────────────

  /// Create the initial Firestore user document after registration.
  Future<void> createUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap());
  }

  /// Update profile fields (username, displayName, bio).
  Future<void> updateProfile({
    required String uid,
    required String username,
    required String displayName,
    required String bio,
  }) async {
    await _users.doc(uid).update({
      'username': username.toLowerCase(),
      'displayName': displayName,
      'bio': bio,
    });
  }

  /// Upload a profile photo to Firebase Storage and return the download URL.
  Future<String> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final ext = mimeType.contains('png') ? 'png' : 'jpg';
    final ref = _storage.ref().child('profile_photos/$uid/avatar.$ext');

    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: mimeType),
    );

    final url = await uploadTask.ref.getDownloadURL();

    // Persist URL to Firestore
    await _users.doc(uid).update({'photoUrl': url});

    return url;
  }
}