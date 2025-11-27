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
      body: SafeArea(
        child: Column(
          children: [
            // Top illustration with gradient background
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryLight,
                      AppColors.primary,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative elements
                    Positioned(
                      top: 40,
                      right: 30,
                      child: _buildDecorativeArrow(),
                    ),
                    Positioned(
                      bottom: 80,
                      left: 20,
                      child: _buildDecorativeCoin(),
                    ),
                    Positioned(
                      top: 100,
                      left: 40,
                      child: _buildDecorativeCoin(),
                    ),
                    // Main illustration
                    Center(
                      child: Image.asset(
                        'img/logo.png',
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom content
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Let's",
                      style: AppTextStyles.heading1.copyWith(
                        color: AppColors.text,
                        fontSize: 36,
                      ),
                    ),
                    Text(
                      'manage',
                      style: AppTextStyles.heading1.copyWith(
                        color: AppColors.text,
                        fontSize: 36,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'money ',
                            style: AppTextStyles.heading1.copyWith(
                              color: AppColors.primary,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'with us',
                            style: AppTextStyles.heading1.copyWith(
                              color: AppColors.text,
                              fontSize: 36,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppPadding.xl),
                    
                    // Get Started Button
                    SizedBox(
                      width: 180,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final isAuthenticated = SupabaseService.instance.isAuthenticated;
                          if (isAuthenticated) {
                            Navigator.of(context).pushReplacementNamed('/home');
                          } else {
                            Navigator.of(context).pushReplacementNamed('/login');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeArrow() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.trending_up,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _buildDecorativeCoin() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          '\$',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
