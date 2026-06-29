import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.cashier;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        final success = await authProvider.signUp(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
          _selectedRole,
        );

        if (success && mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF16A34A),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kayıt Başarılı!',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: const Color(0xFF111827),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Text(
                'Hesabınız oluşturuldu. Şimdi sisteme giriş yapabilirsiniz.',
                style: GoogleFonts.montserrat(
                    fontSize: 14, color: const Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111827),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Giriş Yap',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString(),
                  style: GoogleFonts.montserrat(fontSize: 13)),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  InputDecoration _fieldDecoration(String label,
      {IconData? prefixIcon, Widget? suffixIcon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: const Color(0xFF9CA3AF))
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      labelStyle: GoogleFonts.montserrat(
          color: const Color(0xFF9CA3AF), fontSize: 14),
      hintStyle: GoogleFonts.montserrat(
          color: const Color(0xFF9CA3AF), fontSize: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: Color(0xFF111827), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE0FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),

                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildProgressSteps(),
                            const SizedBox(height: 32),

                            if (_currentStep == 0)
                              _buildAccountInfoStep()
                            else
                              _buildRoleSelectionStep(),

                            const SizedBox(height: 24),

                            _buildNavigationButtons(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildLoginLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.restaurant_outlined,
            size: 38,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Hesap Oluştur',
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Dijital Adisyon POS Sistemine Katılın',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSteps() {
    return Row(
      children: [
        _buildStep(0, 'Hesap', Icons.person_outline),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep >= 1
                ? const Color(0xFF111827)
                : const Color(0xFFE5E7EB),
          ),
        ),
        _buildStep(1, 'Rol', Icons.badge_outlined),
      ],
    );
  }

  Widget _buildStep(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF111827)
                : const Color(0xFFF3F4F6),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? const Color(0xFF111827)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : const Color(0xFF9CA3AF),
            size: 22,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: isActive
                ? const Color(0xFF111827)
                : const Color(0xFF9CA3AF),
            fontWeight:
                isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountInfoStep() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          style: GoogleFonts.montserrat(
              fontSize: 14, color: const Color(0xFF111827)),
          decoration: _fieldDecoration(
            'Ad Soyad',
            prefixIcon: Icons.person_outline,
            hint: 'Adınızı girin',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen adınızı girin';
            }
            if (value.length < 3) {
              return 'Ad en az 3 karakter olmalıdır';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.montserrat(
              fontSize: 14, color: const Color(0xFF111827)),
          decoration: _fieldDecoration(
            'E-posta',
            prefixIcon: Icons.email_outlined,
            hint: 'E-postanızı girin',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen e-posta girin';
            }
            if (!value.contains('@') || !value.contains('.')) {
              return 'Geçerli bir e-posta girin';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.montserrat(
              fontSize: 14, color: const Color(0xFF111827)),
          decoration: _fieldDecoration(
            'Şifre',
            prefixIcon: Icons.lock_outlined,
            hint: 'Şifre oluşturun',
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: const Color(0xFF9CA3AF),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen şifre girin';
            }
            if (value.length < 6) {
              return 'Şifre en az 6 karakter olmalıdır';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          style: GoogleFonts.montserrat(
              fontSize: 14, color: const Color(0xFF111827)),
          decoration: _fieldDecoration(
            'Şifreyi Onayla',
            prefixIcon: Icons.lock_outlined,
            hint: 'Şifrenizi onaylayın',
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: const Color(0xFF9CA3AF),
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword =
                      !_obscureConfirmPassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value != _passwordController.text) {
              return 'Şifreler eşleşmiyor';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRoleSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rol Seçin',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pozisyonunuzu en iyi açıklayan rolü seçin',
          style: GoogleFonts.montserrat(
            fontSize: 13,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 20),
        ...UserRole.values.map((role) {
          final isSelected = _selectedRole == role;
          final color = _getRoleColor(role);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedRole = role;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF111827)
                        : const Color(0xFFE5E7EB),
                    width: isSelected ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? const Color(0xFF111827).withValues(alpha: 0.04)
                      : Colors.white,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getRoleIcon(role),
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getRoleName(role),
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getRoleDescription(role),
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF111827),
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentStep--;
                });
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                foregroundColor: const Color(0xFF111827),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              child: Text(
                'Geri',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (_currentStep == 0) {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _currentStep = 1;
                        });
                      }
                    } else {
                      _register();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _currentStep == 0 ? 'İleri' : 'Hesap Oluştur',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Zaten hesabınız var mı? ',
          style: GoogleFonts.montserrat(
            color: const Color(0xFF6B7280),
            fontSize: 13,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          child: Text(
            'Giriş Yap',
            style: GoogleFonts.montserrat(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w700,
              fontSize: 13,
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
      case UserRole.cashier:
        return Icons.point_of_sale_outlined;
      case UserRole.manager:
        return Icons.manage_accounts_outlined;
      case UserRole.kitchen:
        return Icons.kitchen_outlined;
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFFDC2626);
      case UserRole.cashier:
        return const Color(0xFF16A34A);
      case UserRole.manager:
        return const Color(0xFF2563EB);
      case UserRole.kitchen:
        return const Color(0xFFD97706);
    }
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'YÖNETİCİ';
      case UserRole.cashier:
        return 'KASIYER';
      case UserRole.manager:
        return 'MÜDÜR';
      case UserRole.kitchen:
        return 'MUTFAK';
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Tam sistem erişimi, kullanıcı ve ayar yönetimi';
      case UserRole.cashier:
        return 'Hesap kesme, ödeme ve masa yönetimi';
      case UserRole.manager:
        return 'Menü yönetimi ve rapor görüntüleme';
      case UserRole.kitchen:
        return 'Sipariş durumlarını görüntüle ve güncelle';
    }
  }
}
