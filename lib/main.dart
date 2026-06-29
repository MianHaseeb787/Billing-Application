import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    runApp(const App());
  } catch (e) {
    runApp(_ErrorApp(error: e.toString()));
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Dijital Adisyon',
        theme: _buildTheme(),
        home: const _AuthGate(),
      ),
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData.dark();
    final montserrat = GoogleFonts.montserratTextTheme(base.textTheme).apply(
      bodyColor: AppConstants.text1,
      displayColor: AppConstants.text1,
    );

    return base.copyWith(
      textTheme: montserrat,
      scaffoldBackgroundColor: AppConstants.bg,
      colorScheme: const ColorScheme.dark(
        surface: AppConstants.surface,
        primary: AppConstants.amber,
        onPrimary: Colors.white,
        secondary: AppConstants.green,
        onSecondary: Colors.black,
        error: AppConstants.red,
        outline: AppConstants.border,
        outlineVariant: AppConstants.border,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        toolbarHeight: 64,
        iconTheme: const IconThemeData(color: Colors.white70, size: 20),
      ),
      cardTheme: CardThemeData(
        color: AppConstants.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: AppConstants.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: AppConstants.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: AppConstants.amber, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: AppConstants.red),
        ),
        labelStyle: GoogleFonts.montserrat(color: AppConstants.text2, fontSize: 14),
        hintStyle: GoogleFonts.montserrat(color: AppConstants.text3, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: AppConstants.border,
        space: 1,
        thickness: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          disabledBackgroundColor: AppConstants.surface2,
          disabledForegroundColor: AppConstants.text3,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.text1,
          side: const BorderSide(color: AppConstants.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.amber,
          textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppConstants.surface2,
        side: const BorderSide(color: AppConstants.border),
        labelStyle: GoogleFonts.montserrat(color: AppConstants.text2, fontSize: 12),
        selectedColor: AppConstants.amber.withValues(alpha: 0.18),
        checkmarkColor: AppConstants.amber,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppConstants.amber : AppConstants.text3),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppConstants.amber.withValues(alpha: 0.3)
                : AppConstants.surface2),
        trackOutlineColor: WidgetStateProperty.all(AppConstants.border),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.black87,
        contentTextStyle: GoogleFonts.montserrat(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppConstants.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: AppConstants.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppConstants.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppConstants.border),
        ),
        titleTextStyle: GoogleFonts.montserrat(
          color: AppConstants.text1,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.montserrat(
          color: AppConstants.text2,
          fontSize: 14,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: AppConstants.text1,
        iconColor: AppConstants.text2,
        tileColor: Colors.transparent,
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) return const _SplashScreen();
        if (auth.isAuthenticated) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppConstants.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppConstants.amber.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.restaurant, size: 40, color: AppConstants.amber),
            ),
            const SizedBox(height: 28),
            Text(
              'Dijital Adisyon',
              style: GoogleFonts.montserrat(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'SATIŞ NOKTASI',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppConstants.text3,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 52),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppConstants.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorApp extends StatelessWidget {
  final String error;
  const _ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56, color: AppConstants.red),
                const SizedBox(height: 20),
                Text('Başlatma Hatası',
                    style: GoogleFonts.montserrat(
                        fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 12),
                Text(error,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(fontSize: 13, color: AppConstants.text2)),
                const SizedBox(height: 28),
                ElevatedButton(onPressed: main, child: const Text('Tekrar Dene')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
