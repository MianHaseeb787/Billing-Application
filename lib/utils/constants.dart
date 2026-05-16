import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // ── Background layers ─────────────────────────────────────────────────
  static const Color bg       = Color.fromARGB(255, 201, 142, 243); // light purple page bg
  static const Color surface  = Colors.white;                        // card / panel surface
  static const Color surface2 = Color(0xFFF0E6FF);                  // hover / secondary surface
  static const Color border   = Color(0xFFDDC8FF);                  // dividers, input borders

  // ── Brand / semantic colours ──────────────────────────────────────────
  static const Color amber  = Color(0xFF9929EA); // primary CTA (purple)
  static const Color green  = Color(0xFF22C55E); // success / available
  static const Color red    = Color(0xFFF85149); // danger / occupied
  static const Color yellow = Color(0xFFD29922); // warning / reserved
  static const Color blue   = Color(0xFF58A6FF); // info / preparing
  static const Color purple = Color(0xFF9929EA); // brand purple

  // ── Text (dark — for use on white card surfaces) ──────────────────────
  static const Color text1 = Color(0xFF1A1A1A); // primary
  static const Color text2 = Color(0xFF555555); // secondary
  static const Color text3 = Color(0xFF888888); // muted / placeholder

  // ── Legacy aliases ────────────────────────────────────────────────────
  static const Color primaryColor    = amber;
  static const Color secondaryColor  = Colors.black;
  static const Color accentColor     = surface2;
  static const Color backgroundColor = bg;
  static const Color surfaceColor    = surface;
  static const Color successColor    = green;
  static const Color warningColor    = yellow;
  static const Color errorColor      = red;
  static const Color textPrimary     = text1;
  static const Color textSecondary   = text2;

  // ── Spacing (8-pt grid) ───────────────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  static const double defaultPadding = md;
  static const double borderRadius   = 10.0;
  static const double cardRadius     = 14.0;
  static const double buttonRadius   = 28.0;
}
