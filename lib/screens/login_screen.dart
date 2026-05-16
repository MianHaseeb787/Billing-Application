import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final ok = await auth.signIn(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;
      if (ok) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        _err(auth.error ?? 'Geçersiz kimlik bilgileri.');
      }
    } catch (e) {
      if (mounted) _err(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppConstants.red),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 150, 22, 209),
      body: Row(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFF0A0A0A),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/t-rex.svg',
                    height: 140,
                    colorFilter: const ColorFilter.mode(
                        AppConstants.amber, BlendMode.srcIn),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'DinO Dine',
                    style: GoogleFonts.montserrat(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SATIŞ  NOKTASI',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.text3,
                      letterSpacing: 5,
                    ),
                  ),
                  const SizedBox(height: 52),
                  _featureRow(Icons.table_restaurant_outlined,
                      'Masa ve Sipariş Yönetimi'),
                  const SizedBox(height: 16),
                  _featureRow(Icons.kitchen_outlined, 'Mutfak Ekran Sistemi'),
                  const SizedBox(height: 16),
                  _featureRow(
                      Icons.receipt_long_outlined, 'Fatura ve Ödemeler'),
                  const SizedBox(height: 16),
                  _featureRow(Icons.bar_chart_outlined, 'Satış Analitiği'),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tekrar Hoş Geldiniz',
                          style: GoogleFonts.montserrat(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hesabınıza giriş yapın',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 36),
                        _label('E-posta adresi'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          style: _inputStyle,
                          decoration: const InputDecoration(
                              hintText: 'siz@restoran.com'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Zorunlu';
                            if (!v.contains('@'))
                              return 'Geçerli bir e-posta girin';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _label('Şifre'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.password],
                          style: _inputStyle,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                                color: Colors.white60,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          onFieldSubmitted: (_) => _submit(),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Zorunlu' : null,
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.black),
                                  )
                                : const Text('Giriş Yap'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Şifrenizi sıfırlamak için sistem yöneticinizle iletişime geçin.'),
                              ),
                            ),
                            child: Text(
                              'Şifremi unuttum?',
                              style: GoogleFonts.montserrat(
                                  fontSize: 13, color: Colors.white70),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: Text(
                            'DinO Dine POS  ·  v1.0',
                            style: GoogleFonts.montserrat(
                                fontSize: 11, color: Colors.white38),
                          ),
                        ),
                      ],
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

  Widget _featureRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppConstants.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppConstants.amber),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: GoogleFonts.montserrat(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white70),
      );

  TextStyle get _inputStyle =>
      GoogleFonts.montserrat(fontSize: 14, color: Colors.white);
}
