import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_strings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _subtitleController;
  late Animation<double> _titleOpacity;
  late Animation<double> _subtitleOpacity;

  @override
  void initState() {
    super.initState();

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );

    _subtitleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeOut),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _titleController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _subtitleController.forward();
    await Future.delayed(const Duration(milliseconds: 1600));
    _navigate();
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      onboardingDone ? '/home' : '/onboarding',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _titleOpacity,
              child: Text(
                AppStrings.splashTitle,
                style: AppTypography.splashTitle(color: AppColors.darkText),
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _subtitleOpacity,
              child: Text(
                AppStrings.splashSubtitle,
                style: AppTypography.splashSubtitle(
                    color: AppColors.darkTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
