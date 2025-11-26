import 'package:flutter/material.dart';
import '../../data/services/supabase_service.dart';
import '../../utils/constants.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Email dan password tidak boleh kosong');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Password tidak cocok');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Password minimal 6 karakter');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.instance.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun berhasil dibuat! Silakan masuk.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _errorMessage = _parseError(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _parseError(String error) {
    if (error.contains('User already registered')) {
      return 'Email sudah terdaftar';
    } else if (error.contains('Invalid email')) {
      return 'Email tidak valid';
    } else if (error.contains('Password')) {
      return 'Password tidak memenuhi syarat keamanan';
    }
    return error.contains('Exception:') ? error.replaceAll('Exception: ', '') : error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: AppPadding.md),
              Text(
                'Buat Akun SpendSense',
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppPadding.sm),
              Text(
                'Daftar untuk mengelola keuangan Anda',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppPadding.xl),

              // Email Input
              TextField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Masukkan email Anda',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(AppPadding.md),
                ),
              ),
              const SizedBox(height: AppPadding.md),

              // Password Input
              TextField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Minimal 6 karakter',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(AppPadding.md),
                ),
              ),
              const SizedBox(height: AppPadding.md),

              // Confirm Password Input
              TextField(
                controller: _confirmPasswordController,
                enabled: !_isLoading,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  hintText: 'Ulang password Anda',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(AppPadding.md),
                ),
              ),
              const SizedBox(height: AppPadding.md),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(AppPadding.md),
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.expense, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.expense),
                      const SizedBox(width: AppPadding.sm),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.expense,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppPadding.lg),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.textSecondary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          'Daftar',
                          style: AppTextStyles.subtitle.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
