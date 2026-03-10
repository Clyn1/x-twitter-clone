// lib/screens/edit_profile_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum EditProfileStatus { initial, loading, success, error }

class EditProfileState {
  final EditProfileStatus status;
  final String? errorMessage;
  const EditProfileState({
    this.status = EditProfileStatus.initial,
    this.errorMessage,
  });
  bool get isLoading => status == EditProfileStatus.loading;
  bool get isSuccess => status == EditProfileStatus.success;
  bool get isError => status == EditProfileStatus.error;
  static const initial = EditProfileState();
}

// ── Screen ────────────────────────────────────────────────────────────────────

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;

  Uint8List? _newImageBytes;
  String? _newImageMimeType;
  bool _isSaving = false;
  String? _errorMessage;
  String? _usernameError;
  bool _checkingUsername = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.user.displayName);
    _usernameController =
        TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ── Image picker ────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _newImageBytes = bytes;
        _newImageMimeType = picked.mimeType ?? 'image/jpeg';
      });
    }
  }

  // ── Username validation ─────────────────────────────────────────────────────

  Future<void> _validateUsername(String value) async {
    final trimmed = value.trim().toLowerCase();

    // Same as current — no check needed
    if (trimmed == widget.user.username) {
      setState(() => _usernameError = null);
      return;
    }

    // Format check
    if (trimmed.length < 3) {
      setState(() => _usernameError = 'Must be at least 3 characters');
      return;
    }
    if (trimmed.length > 20) {
      setState(() => _usernameError = 'Must be 20 characters or fewer');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
      setState(
          () => _usernameError = 'Only letters, numbers and underscores');
      return;
    }

    // Availability check
    setState(() {
      _checkingUsername = true;
      _usernameError = null;
    });
    try {
      final taken = await ref
          .read(userServiceProvider)
          .isUsernameTaken(trimmed);
      setState(() {
        _usernameError = taken ? 'Username already taken' : null;
        _checkingUsername = false;
      });
    } catch (_) {
      setState(() {
        _checkingUsername = false;
      });
    }
  }

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Display name cannot be empty');
      return;
    }
    if (_usernameError != null || _checkingUsername) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      String? photoUrl = widget.user.photoUrl;

      // Upload new photo if selected
      if (_newImageBytes != null && _newImageMimeType != null) {
        photoUrl = await ref.read(userServiceProvider).uploadProfilePhoto(
              uid: widget.user.uid,
              imageBytes: _newImageBytes!,
              mimeType: _newImageMimeType!,
            );
      }

      // Update Firestore
      await ref.read(userServiceProvider).updateProfile(
            uid: widget.user.uid,
            displayName: name,
            username: username,
            bio: bio,
            photoUrl: photoUrl,
          );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Could not save changes. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit profile',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: (_isSaving || _usernameError != null ||
                      _checkingUsername)
                  ? null
                  : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.white24,
                foregroundColor: const Color(0xFF0A0A14),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0A0A14)))
                  : const Text('Save',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Cover + Avatar ──────────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover
                Container(
                  height: 120,
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

                // Avatar
                Positioned(
                  bottom: -40,
                  left: 16,
                  child: GestureDetector(
                    onTap: _isSaving ? null : _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1A1A2E),
                            border: Border.all(
                                color: const Color(0xFF0A0A14),
                                width: 4),
                            image: _newImageBytes != null
                                ? DecorationImage(
                                    image: MemoryImage(_newImageBytes!),
                                    fit: BoxFit.cover,
                                  )
                                : widget.user.photoUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(
                                            widget.user.photoUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                          child: (_newImageBytes == null &&
                                  widget.user.photoUrl == null)
                              ? Center(
                                  child: Text(
                                    widget.user.displayName.isNotEmpty
                                        ? widget.user.displayName[0]
                                            .toUpperCase()
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
                        // Camera overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.45),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // ── Error banner ────────────────────────────────────────────
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0245E).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFE0245E).withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFFE0245E), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!,
                        style: const TextStyle(
                            color: Color(0xFFE0245E), fontSize: 13)),
                  ),
                ]),
              ),

            // ── Fields ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _EditField(
                    controller: _nameController,
                    label: 'Display name',
                    maxLength: 50,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 4),
                  _EditField(
                    controller: _usernameController,
                    label: 'Username',
                    maxLength: 20,
                    prefix: '@',
                    enabled: !_isSaving,
                    errorText: _usernameError,
                    suffixIcon: _checkingUsername
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF1D9BF0)),
                            ),
                          )
                        : _usernameError == null &&
                                _usernameController.text.trim() !=
                                    widget.user.username
                            ? const Icon(Icons.check_circle,
                                color: Color(0xFF34A853), size: 20)
                            : null,
                    onChanged: (v) {
                      setState(() {});
                      Future.delayed(
                          const Duration(milliseconds: 600), () {
                        if (_usernameController.text == v) {
                          _validateUsername(v);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 4),
                  _EditField(
                    controller: _bioController,
                    label: 'Bio',
                    maxLength: 160,
                    maxLines: 4,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable edit field ───────────────────────────────────────────────────────

class _EditField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final int maxLength;
  final int maxLines;
  final String? prefix;
  final bool enabled;
  final String? errorText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const _EditField({
    required this.controller,
    required this.label,
    required this.maxLength,
    this.maxLines = 1,
    this.prefix,
    this.enabled = true,
    this.errorText,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  State<_EditField> createState() => _EditFieldState();
}

class _EditFieldState extends State<_EditField> {
  late int _charCount;

  @override
  void initState() {
    super.initState();
    _charCount = widget.controller.text.length;
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() {
    setState(() => _charCount = widget.controller.text.length);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool nearLimit = _charCount >= widget.maxLength - 10;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111122),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.errorText != null
                    ? const Color(0xFFE0245E).withOpacity(0.6)
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.errorText != null
                          ? const Color(0xFFE0245E)
                          : const Color(0xFF1D9BF0),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (widget.prefix != null)
                        Text(widget.prefix!,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 16)),
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          enabled: widget.enabled,
                          maxLines: widget.maxLines,
                          maxLength: widget.maxLength,
                          onChanged: widget.onChanged,
                          buildCounter: (_, {required currentLength,
                                required isFocused, maxLength}) =>
                              null,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (widget.suffixIcon != null) widget.suffixIcon!,
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Error + char count row
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, top: 4),
            child: Row(
              children: [
                if (widget.errorText != null)
                  Text(
                    widget.errorText!,
                    style: const TextStyle(
                        color: Color(0xFFE0245E), fontSize: 12),
                  ),
                const Spacer(),
                Text(
                  '$_charCount / ${widget.maxLength}',
                  style: TextStyle(
                    color: nearLimit
                        ? const Color(0xFFFFAD1F)
                        : Colors.white.withOpacity(0.25),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
