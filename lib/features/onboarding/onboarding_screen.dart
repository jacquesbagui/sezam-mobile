import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sezam_button.dart';
import '../../core/services/token_storage_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/profile_provider.dart';

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

  void _nextPage() async {
    // Feedback haptique pour une meilleure réactivité perçue
    HapticFeedback.selectionClick();
    
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 200), // Plus rapide que 300ms
        curve: Curves.easeOutCubic, // Courbe plus fluide
      );
    } else {
      // Marquer que l'onboarding a été vu
      await TokenStorageService.instance.setHasSeenOnboarding(true);
      if (mounted) {
        // Après onboarding, vérifier si l'utilisateur est connecté
        // Si oui, rediriger vers KYC ou Dashboard selon le statut du profil
        // Si non, rediriger vers auth
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isAuthenticated) {
          // Utilisateur connecté, vérifier le statut du profil (utiliser cache)
          final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
          await profileProvider.loadIfNeeded(); // Utiliser cache si disponible
          
          if (!mounted) return;
          
          // Rediriger vers KYC si le profil n'est pas complet, sinon vers dashboard
          if (!profileProvider.isComplete) {
            context.go('/kyc');
          } else {
            context.go('/dashboard');
          }
        } else {
          context.go('/auth');
        }
      }
    }
  }

  void _skipOnboarding() async {
    // Feedback haptique
    HapticFeedback.lightImpact();
    
    // Marquer que l'onboarding a été vu
    await TokenStorageService.instance.setHasSeenOnboarding(true);
    if (mounted) {
      // Après skip onboarding, vérifier si l'utilisateur est connecté
      // Si oui, rediriger vers KYC ou Dashboard selon le statut du profil
      // Si non, rediriger vers auth
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        // Utilisateur connecté, vérifier le statut du profil (utiliser cache)
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
        await profileProvider.loadIfNeeded(); // Utiliser cache si disponible
        
        if (!mounted) return;
        
        // Rediriger vers KYC si le profil n'est pas complet, sinon vers dashboard
        if (!profileProvider.isComplete) {
          context.go('/kyc');
        } else {
          context.go('/dashboard');
        }
      } else {
        context.go('/auth');
      }
    }
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
            RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.spacing4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 60), // Espace pour centrer le titre
                    Text(
                      'SEZAM',
                      style: AppTypography.headline3.copyWith(
                        color: AppColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _skipOnboarding,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.spacing3,
                            vertical: AppSpacing.spacing2,
                          ),
                          child: Text(
                            'Passer',
                            style: AppTypography.button.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Contenu des pages
            Expanded(
              child: RepaintBoundary(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return RepaintBoundary(
                      child: _buildOnboardingPage(_pages[index]),
                    );
                  },
                ),
              ),
            ),
            
            // Indicateurs de page
            RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildPageIndicator(index),
                  ),
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
                      child: RepaintBoundary(
                        child: SezamButton(
                          text: 'Précédent',
                          variant: SezamButtonVariant.outline,
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 200), // Plus rapide
                              curve: Curves.easeOutCubic,
                            );
                          },
                        ),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: AppSpacing.spacing4),
                  Expanded(
                    child: RepaintBoundary(
                      child: SezamButton(
                        text: _currentPage == _pages.length - 1 ? 'Commencer' : 'Suivant',
                        onPressed: _nextPage,
                        isFullWidth: true,
                      ),
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
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spacing6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône (sans animation lourde pour meilleure performance)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
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
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.spacing4),
          
          // Description
          Text(
            page.description,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200), // Plus rapide
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing1),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary
            : AppColors.gray300,
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
