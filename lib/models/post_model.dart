// lib/models/post_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String uid;
  final String username;
  final String displayName;
  final String? photoUrl;
  final String content;
  final String? imageUrl;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final bool isLiked; // local UI state, not stored in Firestore

  const PostModel({
    required this.id,
    required this.uid,
    required this.username,
    required this.displayName,
    this.photoUrl,
    required this.content,
    this.imageUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    this.isLiked = false,
  });

  factory PostModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      username: data['username'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      content: data['content'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      likesCount: data['likesCount'] as int? ?? 0,
      commentsCount: data['commentsCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'username': username,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'content': content,
        'imageUrl': imageUrl,
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  PostModel copyWith({bool? isLiked, int? likesCount}) => PostModel(
        id: id,
        uid: uid,
        username: username,
        displayName: displayName,
        photoUrl: photoUrl,
        content: content,
        imageUrl: imageUrl,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount,
        createdAt: createdAt,
        isLiked: isLiked ?? this.isLiked,
      );
}