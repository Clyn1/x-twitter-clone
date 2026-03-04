import 'package:flutter/material.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final VoidCallback? onEditingComplete;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onEditingComplete,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscure = true;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.isPassword && _obscure,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onEditingComplete: widget.onEditingComplete,
        validator: widget.validator,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: _isFocused ? const Color(0xFF1D9BF0) : Colors.white54,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: const Color(0xFF1A1A2E),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1D9BF0), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0245E)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0245E), width: 1.5),
          ),
          errorStyle: const TextStyle(color: Color(0xFFE0245E), fontSize: 12),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.white38,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
        ),
      ),
    );
  }
}