// lib/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String displayName;
  final String bio;
  final String? photoUrl;
  final int followersCount;
  final int followingCount;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.displayName,
    required this.bio,
    this.photoUrl,
    this.followersCount = 0,
    this.followingCount = 0,
    required this.createdAt,
  });

  /// Create from Firestore document snapshot
  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      username: data['username'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      followersCount: data['followersCount'] as int? ?? 0,
      followingCount: data['followingCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'displayName': displayName,
      'bio': bio,
      'photoUrl': photoUrl,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? username,
    String? displayName,
    String? bio,
    String? photoUrl,
    int? followersCount,
    int? followingCount,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      createdAt: createdAt,
    );
  }
}