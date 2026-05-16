import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class CustomPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;

  const CustomPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppConstants.secondaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
