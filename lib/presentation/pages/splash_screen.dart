import 'package:flutter/material.dart';
import '../../data/services/supabase_service.dart';
import '../../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      // Check if user is authenticated
      final isAuthenticated = SupabaseService.instance.isAuthenticated;
      
      if (isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppPadding.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo dengan ilustrasi
                SizedBox(
                  height: 300,
                  child: Image.asset(
                    'img/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: AppPadding.xl),

                // Text
                Column(
                  children: [
                    Text(
                      "Let's",
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      'manage',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'money ',
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'with us',
                            style: AppTextStyles.heading2.copyWith(
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppPadding.xl),

                // Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                      ),
                    ),
                    child: Text(
                      'Get Started',
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
