import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;
  final double? fontSize;
  final int flex;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.color,
    this.backgroundColor,
    this.fontSize,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: color ?? AppConstants.secondaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: fontSize ?? 28,
                fontWeight: FontWeight.bold,
                color: color ?? AppConstants.secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatCardGrid extends StatelessWidget {
  final List<StatCard> cards;

  const StatCardGrid({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          cards[i],
          if (i < cards.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }
}
