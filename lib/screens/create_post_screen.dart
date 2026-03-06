// lib/screens/create_post_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';


class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageMimeType;
  static const int _maxChars = 280;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  int get _remaining => _maxChars - _contentController.text.length;
  bool get _canPost =>
      _contentController.text.trim().isNotEmpty && _remaining >= 0;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageMimeType = picked.mimeType ?? 'image/jpeg';
      });
    }
  }

  void _removeImage() => setState(() {
        _imageBytes = null;
        _imageMimeType = null;
      });

  Future<void> _submit(UserModel user) async {
    if (!_canPost) return;
    await ref.read(createPostProvider.notifier).createPost(
          uid: user.uid,
          username: user.username,
          displayName: user.displayName,
          photoUrl: user.photoUrl,
          content: _contentController.text.trim(),
          imageBytes: _imageBytes,
          imageMimeType: _imageMimeType,
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final postState = ref.watch(createPostProvider);

    // Listen for success → clear and show feedback
    ref.listen(createPostProvider, (_, next) {
      if (next.isSuccess) {
        _contentController.clear();
        setState(() {
          _imageBytes = null;
          _imageMimeType = null;
        });
        ref.read(createPostProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Posted!', style: TextStyle(color: Colors.white)),
            ]),
            backgroundColor: const Color(0xFF1D9BF0),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      if (next.isError && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!,
                style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFFE0245E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A14),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'New post',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: (postState.isLoading || !_canPost || user == null)
                  ? null
                  : () => _submit(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9BF0),
                disabledBackgroundColor:
                    const Color(0xFF1D9BF0).withOpacity(0.4),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: postState.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Post',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Divider(color: Colors.white.withOpacity(0.07), height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1D9BF0).withOpacity(0.2),
                      image: user?.photoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(user!.photoUrl!),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: user?.photoUrl == null
                        ? Center(
                            child: Text(
                              user?.displayName.isNotEmpty == true
                                  ? user!.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Color(0xFF1D9BF0),
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text field
                        TextField(
                          controller: _contentController,
                          maxLines: null,
                          maxLength: _maxChars + 20,
                          buildCounter: (_, {required currentLength,
                                required isFocused, maxLength}) =>
                              null,
                          autofocus: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: "What's happening?",
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 18,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),

                        // Image preview
                        if (_imageBytes != null) ...[
                          const SizedBox(height: 12),
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _imageBytes!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: _removeImage,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom toolbar
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.07),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Image attach
                IconButton(
                  onPressed: _pickImage,
                  icon: Icon(
                    Icons.image_outlined,
                    color: const Color(0xFF1D9BF0).withOpacity(0.85),
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Spacer(),

                // Char counter
                _remaining <= 60
                    ? Row(children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            value: (_maxChars - _remaining) / _maxChars,
                            strokeWidth: 2.5,
                            backgroundColor:
                                Colors.white.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _remaining < 0
                                  ? const Color(0xFFE0245E)
                                  : _remaining <= 20
                                      ? const Color(0xFFFFAD1F)
                                      : const Color(0xFF1D9BF0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_remaining',
                          style: TextStyle(
                            color: _remaining < 0
                                ? const Color(0xFFE0245E)
                                : Colors.white.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      ])
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}