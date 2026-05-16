import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import 'home_screen.dart';

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
          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 60,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Registration Successful!",
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Text(
                "Your account has been created. You can now login to the system.",
                style: GoogleFonts.montserrat(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size(double.infinity, 45),
                  ),
                  child: Text(
                    "Go to Login",
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
              content: Text(e.toString()),
              backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
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
                      // Logo and Title
                      _buildHeader(),
                      const SizedBox(height: 32),

                      // Registration Form Card
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Progress Steps
                            _buildProgressSteps(),
                            const SizedBox(height: 32),

                            // Step Content
                            if (_currentStep == 0)
                              _buildAccountInfoStep()
                            else
                              _buildRoleSelectionStep(),

                            const SizedBox(height: 24),

                            // Navigation Buttons
                            _buildNavigationButtons(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login Link
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
        // Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppConstants.secondaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.restaurant,
            size: 50,
            color: AppConstants.secondaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Create Account",
          style: GoogleFonts.montserrat(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Join DinO Dine POS System",
          style: GoogleFonts.montserrat(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSteps() {
    return Row(
      children: [
        _buildStep(0, "Account", Icons.person),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep >= 1
                ? AppConstants.secondaryColor
                : Colors.grey[300],
          ),
        ),
        _buildStep(1, "Role", Icons.badge),
      ],
    );
  }

  Widget _buildStep(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isActive ? AppConstants.secondaryColor : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey[600],
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: isActive ? AppConstants.secondaryColor : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountInfoStep() {
    return Column(
      children: [
        // Name Field
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppConstants.secondaryColor,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            if (value.length < 3) {
              return 'Name must be at least 3 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Email Field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppConstants.secondaryColor,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@') || !value.contains('.')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Password Field
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Create a password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppConstants.secondaryColor,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Confirm Password Field
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            hintText: 'Confirm your password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppConstants.secondaryColor,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value != _passwordController.text) {
              return 'Passwords do not match';
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
          "Select Your Role",
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Choose the role that best describes your position",
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),
        ...UserRole.values.map((role) {
          final isSelected = _selectedRole == role;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedRole = role;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? AppConstants.secondaryColor
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? AppConstants.secondaryColor.withOpacity(0.1)
                      : Colors.white,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getRoleColor(role).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getRoleIcon(role),
                        color: _getRoleColor(role),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getRoleName(role),
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getRoleDescription(role),
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppConstants.secondaryColor,
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: AppConstants.secondaryColor),
              ),
              child: Text(
                "Back",
                style: GoogleFonts.montserrat(
                  color: AppConstants.secondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (_currentStep == 0) {
                      // Validate first step before proceeding
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
              backgroundColor: AppConstants.secondaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor:
                  AppConstants.secondaryColor.withOpacity(0.5),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _currentStep == 0 ? "Next" : "Create Account",
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
          "Already have an account? ",
          style: GoogleFonts.montserrat(
            color: Colors.white70,
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
            "Login",
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.cashier:
        return Icons.point_of_sale;
      case UserRole.manager:
        return Icons.manage_accounts;
      case UserRole.kitchen:
        return Icons.kitchen;
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.cashier:
        return Colors.green;
      case UserRole.manager:
        return Colors.blue;
      case UserRole.kitchen:
        return Colors.orange;
    }
  }

  String _getRoleName(UserRole role) {
    return role.toString().split('.').last.toUpperCase();
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Full system access, manage users and settings';
      case UserRole.cashier:
        return 'Handle bills, payments and table management';
      case UserRole.manager:
        return 'Manage menu, inventory and view reports';
      case UserRole.kitchen:
        return 'View and update order status';
    }
  }
}
