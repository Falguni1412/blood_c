import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextEditingController controller;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final Color? labelColor;
  final Color? iconColor;
  final String? hintText;
  final bool isUnderline;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final int? maxLines;

  const CustomTextField({
    super.key,
    required this.labelText,
    this.prefixIcon,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.labelColor,
    this.iconColor,
    this.hintText,
    this.isUnderline = false,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: isUnderline ? 4.0 : 5.0),
      decoration:
          isUnderline
              ? null
              : BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: labelColor ?? Colors.grey,
            fontSize: isUnderline ? 14 : 13,
            fontWeight: isUnderline ? FontWeight.w500 : FontWeight.normal,
          ),
          floatingLabelStyle: TextStyle(
            color: labelColor ?? Colors.grey,
            fontWeight: isUnderline ? FontWeight.w500 : FontWeight.normal,
          ),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon:
              prefixIcon == null
                  ? null
                  : Icon(prefixIcon, color: iconColor ?? Colors.grey),
          suffixIcon: suffixIcon,
          border:
              isUnderline
                  ? UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  )
                  : InputBorder.none,
          enabledBorder:
              isUnderline
                  ? UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  )
                  : InputBorder.none,
          focusedBorder:
              isUnderline
                  ? UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: labelColor ?? Colors.blue,
                      width: 2,
                    ),
                  )
                  : InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isUnderline ? 0 : 16,
            vertical: 10,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }
}
