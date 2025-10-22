import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sezam_button.dart';

/// Écran d'onboarding de l'application SEZAM
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.security,
      title: 'Centralisez votre identité numérique',
      description: 'Stockez tous vos documents d\'identité en un seul endroit sécurisé et accessible.',
      color: AppColors.primary,
    ),
    OnboardingPage(
      icon: Icons.share,
      title: 'Partagez vos documents en toute sécurité',
      description: 'Autorisez l\'accès à vos informations uniquement aux services de confiance.',
      color: AppColors.secondary,
    ),
    OnboardingPage(
      icon: Icons.verified_user,
      title: 'Contrôlez qui accède à vos données',
      description: 'Gérez les autorisations et révoquez l\'accès à tout moment.',
      color: AppColors.success,
    ),
    OnboardingPage(
      icon: Icons.qr_code_scanner,
      title: 'Connexions instantanées',
      description: 'Connectez-vous aux services en scannant un QR code ou en quelques clics.',
      color: AppColors.warning,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppSpacing.animationNormal,
        curve: AppSpacing.animationCurve,
      );
    } else {
      context.go('/auth');
    }
  }

  void _skipOnboarding() {
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header avec bouton Skip
            Padding(
              padding: const EdgeInsets.all(AppSpacing.spacing4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60), // Espace pour centrer le titre
                  Text(
                    'SEZAM',
                    style: AppTypography.headline3.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'Passer',
                      style: AppTypography.button.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu des pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_pages[index]);
                },
              ),
            ),
            
            // Indicateurs de page
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildPageIndicator(index),
                ),
              ),
            ),
            
            // Boutons de navigation
            Padding(
              padding: const EdgeInsets.all(AppSpacing.spacing6),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: SezamButton(
                        text: 'Précédent',
                        variant: SezamButtonVariant.outline,
                        onPressed: () {
                          _pageController.previousPage(
                            duration: AppSpacing.animationNormal,
                            curve: AppSpacing.animationCurve,
                          );
                        },
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: AppSpacing.spacing4),
                  Expanded(
                    child: SezamButton(
                      text: _currentPage == _pages.length - 1 ? 'Commencer' : 'Suivant',
                      onPressed: _nextPage,
                      isFullWidth: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spacing6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: page.color,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          
          // Titre
          Text(
            page.title,
            style: AppTypography.headline2.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.spacing4),
          
          // Description
          Text(
            page.description,
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = index == _currentPage;

    return AnimatedContainer(
      duration: AppSpacing.animationFast,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing1),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary
            : (isDark ? AppColors.gray600 : AppColors.gray300),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
