import 'package:flutter/material.dart';

class MyTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Icon icon;
  final String? Function(String?)? validator;
  final int? maxLines;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.icon,
    this.validator,
    this.maxLines,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  late bool _isObscure;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    // Determine keyboard type: if maxLines > 1 and no keyboardType specified, use multiline
    final bool isMultiline = (widget.maxLines != null && widget.maxLines! > 1);
    final TextInputType finalKeyboardType = widget.keyboardType ?? 
        (isMultiline ? TextInputType.multiline : TextInputType.text);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: TextField(
        controller: widget.controller,
        obscureText: _isObscure,
        maxLines: widget.maxLines ?? 1,
        keyboardType: finalKeyboardType,
        textInputAction: widget.maxLines == null || widget.maxLines == 1 
            ? TextInputAction.next 
            : TextInputAction.newline,
        enabled: true,
        readOnly: false,
        enableInteractiveSelection: true,
        enableSuggestions: !widget.obscureText,
        autocorrect: !widget.obscureText,
        enableIMEPersonalizedLearning: true,
        style: TextStyle(
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Color(0xFF83C5BE).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Color(0xFF83C5BE).withOpacity(0.6),
              width: 2,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Color(0xFF83C5BE).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          prefixIcon: widget.icon,

          //show and hide password icon or custom suffix icon
          suffixIcon: widget.suffixIcon ?? (widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                )
              : null),

          // suffixIcon: IconButton(
          //   onPressed: () {
          //     widget.controller.clear();
          //   },
          //   icon: Icon(
          //     Icons.clear,
          //     color: Theme.of(context).colorScheme.primary,
          //   ),
          // ),
        ),
      ),
    );
  }
}
