// lib/widgets/post_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../providers/providers.dart';

class PostCard extends ConsumerWidget {
  final PostModel post;
  final String currentUid;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUid,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLiked = ref.watch(feedLikesProvider)[post.id] ?? false;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.07),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar ────────────────────────────────────────────────────────
          _Avatar(photoUrl: post.photoUrl, displayName: post.displayName),
          const SizedBox(width: 12),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '@${post.username}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            ' · ${_timeAgo(post.createdAt)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Options menu (for own posts)
                    if (post.uid == currentUid)
                      _PostMenu(
                        onDelete: () => ref
                            .read(postServiceProvider)
                            .deletePost(post.id),
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Post content
                Text(
                  post.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),

                // Post image
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      post.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Action row
                Row(
                  children: [
                    // Like
                    _ActionButton(
                      icon: isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: post.likesCount > 0
                          ? post.likesCount.toString()
                          : '',
                      color: isLiked
                          ? const Color(0xFFE0245E)
                          : Colors.white.withOpacity(0.45),
                      onTap: () => ref
                          .read(feedLikesProvider.notifier)
                          .toggleLike(post.id),
                    ),
                    const SizedBox(width: 28),

                    // Comment (placeholder for now)
                    _ActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: post.commentsCount > 0
                          ? post.commentsCount.toString()
                          : '',
                      color: Colors.white.withOpacity(0.45),
                      onTap: () {},
                    ),
                    const SizedBox(width: 28),

                    // Share (placeholder)
                    _ActionButton(
                      icon: Icons.repeat_rounded,
                      label: '',
                      color: Colors.white.withOpacity(0.45),
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String displayName;

  const _Avatar({this.photoUrl, required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1D9BF0).withOpacity(0.2),
        image: photoUrl != null
            ? DecorationImage(
                image: NetworkImage(photoUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: photoUrl == null
          ? Center(
              child: Text(
                displayName.isNotEmpty
                    ? displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Color(0xFF1D9BF0),
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            )
          : null,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(color: color, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _PostMenu extends StatelessWidget {
  final VoidCallback onDelete;

  const _PostMenu({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz,
          color: Colors.white.withOpacity(0.4), size: 18),
      color: const Color(0xFF16161E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            const Icon(Icons.delete_outline,
                color: Color(0xFFE0245E), size: 18),
            const SizedBox(width: 10),
            Text('Delete post',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9), fontSize: 14)),
          ]),
        ),
      ],
    );
  }
}
