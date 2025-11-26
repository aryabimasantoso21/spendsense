import 'package:flutter/material.dart';
import '../../data/services/supabase_service.dart';
import '../../utils/constants.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Email dan password tidak boleh kosong');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
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
    if (error.contains('Invalid login credentials')) {
      return 'Email atau password salah';
    } else if (error.contains('User not found')) {
      return 'User tidak ditemukan';
    } else if (error.contains('Email not confirmed')) {
      return 'Email belum dikonfirmasi. Cek email Anda.';
    }
    return error.contains('Exception:') ? error.replaceAll('Exception: ', '') : error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: AppPadding.xl),
              SizedBox(
                height: 150,
                child: Image.asset(
                  'img/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: AppPadding.xl),
              Text(
                'Masuk ke SpendSense',
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppPadding.sm),
              Text(
                'Kelola keuangan Anda dengan mudah',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppPadding.xl),
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
              TextField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Masukkan password Anda',
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
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
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
                          'Masuk',
                          style: AppTextStyles.subtitle.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppPadding.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Belum punya akun? ',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            );
                          },
                    child: Text(
                      'Daftar di sini',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
