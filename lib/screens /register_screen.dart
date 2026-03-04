import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart';
import '../providers/providers.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(authNotifierProvider.notifier).clearError();
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authNotifierProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next.isError && next.errorMessage != null) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(next.errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 14))),
            ]),
            backgroundColor: const Color(0xFFE0245E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BgPainter(
            color1: const Color(0xFF794BC4),
            color2: const Color(0xFF1D9BF0),
            offset1: const Offset(0.85, 0.08),
            offset2: const Offset(0.1, 0.9),
          ))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          const SizedBox(height: 28),
                          Center(
                            child: Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1D9BF0), Color(0xFF794BC4)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.flutter_dash,
                                  color: Colors.white, size: 28),
                            ),
                          ),
                          const SizedBox(height: 40),
                          const Text('Create your account',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5, height: 1.15)),
                          const SizedBox(height: 8),
                          Text('Join the conversation today.',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.45),
                                  fontSize: 15, height: 1.4)),
                          const SizedBox(height: 36),
                          Form(
                            key: _formKey,
                            child: Column(children: [
                              AuthTextField(
                                controller: _emailController,
                                label: 'Email',
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Email is required';
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AuthTextField(
                                controller: _passwordController,
                                label: 'Password',
                                isPassword: true,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Password is required';
                                  if (v.length < 6) return 'Must be at least 6 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AuthTextField(
                                controller: _confirmController,
                                label: 'Confirm password',
                                isPassword: true,
                                textInputAction: TextInputAction.done,
                                onEditingComplete: _submit,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Please confirm your password';
                                  if (v != _passwordController.text) return 'Passwords do not match';
                                  return null;
                                },
                              ),
                            ]),
                          ),
                          const SizedBox(height: 12),
                          Text.rich(
                            TextSpan(
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.35),
                                  fontSize: 12, height: 1.5),
                              children: const [
                                TextSpan(text: 'By creating an account you agree to our '),
                                TextSpan(text: 'Terms of Service',
                                    style: TextStyle(color: Color(0xFF1D9BF0))),
                                TextSpan(text: ' and '),
                                TextSpan(text: 'Privacy Policy',
                                    style: TextStyle(color: Color(0xFF1D9BF0))),
                                TextSpan(text: '.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity, height: 52,
                            child: ElevatedButton(
                              onPressed: authState.isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                disabledBackgroundColor: Colors.white30,
                                foregroundColor: const Color(0xFF0A0A14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: authState.isLoading
                                  ? const SizedBox(width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF0A0A14)))
                                  : const Text('Create account',
                                      style: TextStyle(fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: TextButton(
                              onPressed: authState.isLoading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: Text.rich(TextSpan(children: [
                                TextSpan(
                                    text: 'Already have an account?  ',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 14)),
                                const TextSpan(
                                    text: 'Sign in',
                                    style: TextStyle(
                                        color: Color(0xFF1D9BF0),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                              ])),
                            ),
                          ),
                          const SizedBox(height: 40),
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

// Re-use _BgPainter from login_screen.dart (move to shared file if preferred)
class _BgPainter extends CustomPainter {
  final Color color1, color2;
  final Offset offset1, offset2;
  const _BgPainter(
      {required this.color1, required this.color2,
       required this.offset1, required this.offset2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = color1.withOpacity(0.06);
    canvas.drawCircle(Offset(size.width * offset1.dx, size.height * offset1.dy),
        size.width * 0.65, paint);
    paint.color = color2.withOpacity(0.05);
    canvas.drawCircle(Offset(size.width * offset2.dx, size.height * offset2.dy),
        size.width * 0.55, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}