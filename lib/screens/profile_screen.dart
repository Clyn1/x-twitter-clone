// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';
import '../widgets/post_card.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String uid;
  const ProfileScreen({super.key, required this.uid});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _followLoading = false;

  Future<void> _toggleFollow({
    required bool isFollowing,
    required String currentUid,
  }) async {
    setState(() => _followLoading = true);
    try {
      final svc = ref.read(followServiceProvider);
      if (isFollowing) {
        await svc.unfollow(followerId: currentUid, followingId: widget.uid);
      } else {
        await svc.follow(followerId: currentUid, followingId: widget.uid);
      }
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider(widget.uid));
    final postsAsync = ref.watch(userPostsProvider(widget.uid));
    final currentUser = ref.watch(currentUserProvider).value;
    final currentUid = currentUser?.uid ?? '';
    final isOwnProfile = currentUid == widget.uid;
    final isFollowing = ref.watch(isFollowingProvider(widget.uid)).value ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1D9BF0), strokeWidth: 2),
        ),
        error: (_, __) => const Center(
          child: Text('Could not load profile',
              style: TextStyle(color: Colors.white54)),
        ),
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('User not found',
                  style: TextStyle(color: Colors.white54)),
            );
          }
          return _buildBody(
            context,
            user: user,
            postsAsync: postsAsync,
            currentUid: currentUid,
            isOwnProfile: isOwnProfile,
            isFollowing: isFollowing,
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required UserModel user,
    required AsyncValue<List<dynamic>> postsAsync,
    required String currentUid,
    required bool isOwnProfile,
    required bool isFollowing,
  }) {
    const double coverHeight = 140.0;
    const double avatarRadius = 42.0;
    const double avatarBorder = 4.0;
    const double avatarTotalRadius = avatarRadius + avatarBorder;

    return CustomScrollView(
      slivers: [
        // ── App bar ──────────────────────────────────────────────────────────
        SliverAppBar(
          backgroundColor: const Color(0xFF0A0A14).withOpacity(0.95),
          elevation: 0,
          pinned: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 15),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            user.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),

        // ── Cover + Avatar block ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Cover photo
              Container(
                height: coverHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1D9BF0).withOpacity(0.5),
                      const Color(0xFF794BC4).withOpacity(0.4),
                    ],
                  ),
                ),
              ),

              // Avatar — positioned to straddle the cover bottom edge
              Positioned(
                bottom: -(avatarTotalRadius),
                left: 16,
                child: Container(
                  width: avatarTotalRadius * 2,
                  height: avatarTotalRadius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A1A2E),
                    border: Border.all(
                      color: const Color(0xFF0A0A14),
                      width: avatarBorder,
                    ),
                    image: user.photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(user.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: user.photoUrl == null
                      ? Center(
                          child: Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Color(0xFF1D9BF0),
                              fontWeight: FontWeight.w800,
                              fontSize: 32,
                            ),
                          ),
                        )
                      : null,
                ),
              ),

              // Follow / Edit button — top right, aligned with bottom of cover
              Positioned(
                bottom: 12,
                right: 16,
                child: isOwnProfile
                    ? _OutlineButton(
                        label: 'Edit profile',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(user: user),
                          ),
                        ),
                      )
                    : _FollowButton(
                        isFollowing: isFollowing,
                        isLoading: _followLoading,
                        onTap: () => _toggleFollow(
                          isFollowing: isFollowing,
                          currentUid: currentUid,
                        ),
                      ),
              ),
            ],
          ),
        ),

        // ── Spacer for avatar overflow ───────────────────────────────────────
        const SliverToBoxAdapter(
          child: SizedBox(height: avatarTotalRadius + 14),
        ),

        // ── Name, username, bio, stats ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 15,
                  ),
                ),
                if (user.bio.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    user.bio,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.88),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Stats
                Row(
                  children: [
                    _StatChip(count: user.followingCount, label: 'Following'),
                    const SizedBox(width: 20),
                    _StatChip(count: user.followersCount, label: 'Followers'),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        // ── Posts tab bar ────────────────────────────────────────────────────
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyTabDelegate(
            child: Container(
              color: const Color(0xFF0A0A14),
              child: Column(
                children: [
                  Divider(color: Colors.white.withOpacity(0.07), height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Posts',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 3,
                              width: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D9BF0),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white.withOpacity(0.07), height: 1),
                ],
              ),
            ),
          ),
        ),

        // ── Posts list ───────────────────────────────────────────────────────
        postsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF1D9BF0), strokeWidth: 2),
              ),
            ),
          ),
          error: (e, st) {
            // Print the actual error for debugging
            debugPrint('Profile posts error: $e\n$st');
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.white.withOpacity(0.3), size: 28),
                      const SizedBox(height: 12),
                      Text(
                        'Posts need a Firestore index.\nCheck your terminal for a setup link.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          data: (posts) {
            final typed = posts.cast<PostModel>();

            if (typed.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(feedLikesProvider.notifier).loadLikes(typed);
              });
            }

            if (typed.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Text(
                      isOwnProfile
                          ? "You haven't posted yet.\nTap + to write something!"
                          : 'No posts yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => PostCard(
                  post: typed[index],
                  currentUid: currentUid,
                ),
                childCount: typed.length,
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Sticky header delegate ────────────────────────────────────────────────────

class _StickyTabDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _StickyTabDelegate({required this.child});

  @override
  double get minExtent => 62;
  @override
  double get maxExtent => 62;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(_StickyTabDelegate old) => old.child != child;
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final int count;
  final String label;
  const _StatChip({required this.count, required this.label});

  String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(_format(count),
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15)),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              color: Colors.white.withOpacity(0.45), fontSize: 14)),
    ]);
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool isLoading;
  final VoidCallback onTap;

  const _FollowButton({
    required this.isFollowing,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.transparent : Colors.white,
          border: Border.all(
            color: isFollowing
                ? Colors.white.withOpacity(0.4)
                : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isFollowing
                        ? Colors.white
                        : const Color(0xFF0A0A14),
                  ),
                )
              : Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    color: isFollowing
                        ? Colors.white
                        : const Color(0xFF0A0A14),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.35)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
