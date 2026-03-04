import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart';
import '../providers/providers.dart';
import '../widgets/auth_text_field.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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
    _animController.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(authNotifierProvider.notifier).clearError();
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authNotifierProvider.notifier).login(
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
            color1: const Color(0xFF1D9BF0),
            color2: const Color(0xFF794BC4),
            offset1: const Offset(0.1, 0.1),
            offset2: const Offset(0.9, 0.85),
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
                          const SizedBox(height: 48),
                          Center(
                            child: Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D9BF0),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.flutter_dash,
                                  color: Colors.white, size: 28),
                            ),
                          ),
                          const SizedBox(height: 40),
                          const Text('Welcome back',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5, height: 1.1)),
                          const SizedBox(height: 8),
                          Text('Sign in to continue the conversation.',
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
                                textInputAction: TextInputAction.done,
                                onEditingComplete: _submit,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Password is required';
                                  return null;
                                },
                              ),
                            ]),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity, height: 52,
                            child: ElevatedButton(
                              onPressed: authState.isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1D9BF0),
                                disabledBackgroundColor: const Color(0xFF1D9BF0).withOpacity(0.5),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: authState.isLoading
                                  ? const SizedBox(width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('Sign in',
                                      style: TextStyle(fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 36),
                          Row(children: [
                            Expanded(child: Divider(
                                color: Colors.white.withOpacity(0.1), thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text("Don't have an account?",
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.35),
                                      fontSize: 13)),
                            ),
                            Expanded(child: Divider(
                                color: Colors.white.withOpacity(0.1), thickness: 1)),
                          ]),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity, height: 52,
                            child: OutlinedButton(
                              onPressed: authState.isLoading
                                  ? null
                                  : () => Navigator.of(context).push(_fadeRoute(
                                        const RegisterScreen())),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1D9BF0),
                                side: BorderSide(
                                    color: const Color(0xFF1D9BF0).withOpacity(0.5)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Create account',
                                  style: TextStyle(fontSize: 15,
                                      fontWeight: FontWeight.w500)),
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

PageRouteBuilder _fadeRoute(Widget page) => PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );

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
        size.width * 0.7, paint);
    paint.color = color2.withOpacity(0.05);
    canvas.drawCircle(Offset(size.width * offset2.dx, size.height * offset2.dy),
        size.width * 0.6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}