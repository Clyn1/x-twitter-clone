// lib/widgets/auth_helpers.dart
//
// Shared UI helpers used by both LoginScreen and RegisterScreen.
// Keeping these here avoids the private-symbol import problem.

import 'package:flutter/material.dart';

/// A full-width primary button with built-in loading spinner.
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withOpacity(0.4),
          foregroundColor: textColor,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: textColor),
              )
            : Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Red error snackbar shown on auth failures.
SnackBar buildErrorSnackBar(String message) => SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(message,
                style:
                    const TextStyle(color: Colors.white, fontSize: 14))),
      ]),
      backgroundColor: const Color(0xFFE0245E),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    );

/// Fade transition page route.
PageRouteBuilder<void> fadePageRoute(Widget page) => PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 220),
    );
   