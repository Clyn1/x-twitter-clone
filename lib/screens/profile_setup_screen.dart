// lib/screens/profile_setup_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/profile_setup_state.dart';
import '../providers/providers.dart';
import '../widgets/auth_text_field.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();

  Uint8List? _photoBytes;
  String? _photoMimeType;
  bool _isPickingImage = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final mime = picked.mimeType ?? 'image/jpeg';
        setState(() {
          _photoBytes = bytes;
          _photoMimeType = mime;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: const Color(0xFFE0245E),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _submit() {
    ref.read(profileSetupNotifierProvider.notifier).clearError();
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(profileSetupNotifierProvider.notifier).saveProfile(
            username: _usernameController.text.trim(),
            displayName: _displayNameController.text.trim(),
            bio: _bioController.text.trim(),
            photoBytes: _photoBytes,
            photoMimeType: _photoMimeType,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(profileSetupNotifierProvider);

    ref.listen<ProfileSetupState>(profileSetupNotifierProvider, (_, next) {
      if (next.isError && next.errorMessage != null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(next.errorMessage!,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ]),
            backgroundColor: const Color(0xFFE0245E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      // On success, AuthWrapper automatically re-routes via currentUserProvider stream
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: Stack(
        children: [
          // Background glow
          Positioned.fill(child: CustomPaint(painter: _BgPainter())),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 48),

                          // ── Header ──────────────────────────────────
                          const Text(
                            'Set up your profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tell people who you are.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 36),

                          // ── Avatar picker ───────────────────────────
                          Center(
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF1A1A2E),
                                      border: Border.all(
                                        color: _photoBytes != null
                                            ? const Color(0xFF1D9BF0)
                                            : Colors.white.withOpacity(0.15),
                                        width: 2,
                                      ),
                                      image: _photoBytes != null
                                          ? DecorationImage(
                                              image: MemoryImage(_photoBytes!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: _photoBytes == null
                                        ? _isPickingImage
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Color(0xFF1D9BF0),
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .add_a_photo_outlined,
                                                    color: Colors.white
                                                        .withOpacity(0.4),
                                                    size: 26,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Add photo',
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.35),
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              )
                                        : null,
                                  ),
                                ),
                                if (_photoBytes != null)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1D9BF0),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color:
                                                  const Color(0xFF0A0A14),
                                              width: 2),
                                        ),
                                        child: const Icon(Icons.edit,
                                            color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Optional',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── Form ─────────────────────────────────────
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Display name
                                AuthTextField(
                                  controller: _displayNameController,
                                  label: 'Display name',
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Display name is required';
                                    }
                                    if (v.trim().length > 50) {
                                      return 'Max 50 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Username
                                AuthTextField(
                                  controller: _usernameController,
                                  label: 'Username',
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Username is required';
                                    }
                                    if (v.trim().length < 3) {
                                      return 'At least 3 characters';
                                    }
                                    if (v.trim().length > 20) {
                                      return 'Max 20 characters';
                                    }
                                    if (!RegExp(r'^[a-zA-Z0-9_]+$')
                                        .hasMatch(v.trim())) {
                                      return 'Only letters, numbers and underscores';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text(
                                    'Letters, numbers and underscores only',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.3),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Bio
                                _BioTextField(
                                  controller: _bioController,
                                  onEditingComplete: _submit,
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text(
                                    'Optional · max 160 characters',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.3),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 36),

                          // ── Save button ──────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed:
                                  setupState.isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1D9BF0),
                                disabledBackgroundColor:
                                    const Color(0xFF1D9BF0).withOpacity(0.4),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: setupState.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : const Text(
                                      'Save and continue',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bio text field (multiline, not in AuthTextField to keep it clean) ─────────

class _BioTextField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onEditingComplete;

  const _BioTextField({
    required this.controller,
    this.onEditingComplete,
  });

  @override
  State<_BioTextField> createState() => _BioTextFieldState();
}

class _BioTextFieldState extends State<_BioTextField> {
  bool _isFocused = false;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() => _charCount = widget.controller.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: Stack(
        children: [
          TextFormField(
            controller: widget.controller,
            maxLines: 4,
            maxLength: 160,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                null, // hide default counter, we draw our own
            textInputAction: TextInputAction.done,
            onEditingComplete: widget.onEditingComplete,
            validator: (v) {
              if (v != null && v.length > 160) return 'Max 160 characters';
              return null;
            },
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Bio',
              labelStyle: TextStyle(
                color: _isFocused
                    ? const Color(0xFF1D9BF0)
                    : Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0x20FFFFFF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF1D9BF0), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0245E)),
              ),
            ),
          ),
          // Character counter
          Positioned(
            bottom: 10,
            right: 16,
            child: Text(
              '$_charCount/160',
              style: TextStyle(
                color: _charCount > 140
                    ? const Color(0xFFE0245E)
                    : Colors.white.withOpacity(0.3),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background painter ────────────────────────────────────────────────────────

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    p.color = const Color(0xFF1D9BF0).withOpacity(0.05);
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.1), size.width * 0.6, p);
    p.color = const Color(0xFF794BC4).withOpacity(0.04);
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.85), size.width * 0.55, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}