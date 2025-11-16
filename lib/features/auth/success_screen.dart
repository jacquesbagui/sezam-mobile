import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sezam_button.dart';

/// Écran de succès après inscription
class RegistrationSuccessScreen extends StatefulWidget {
  const RegistrationSuccessScreen({super.key});

  @override
  State<RegistrationSuccessScreen> createState() => _RegistrationSuccessScreenState();
}

class _RegistrationSuccessScreenState extends State<RegistrationSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    HapticFeedback.mediumImpact();
    if (mounted) {
      // Utiliser un délai pour s'assurer que le contexte est prêt
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          context.go('/kyc');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.spacing6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.spacing8),

              // Animation de succès
              Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.success,
                          AppColors.success.withValues(alpha: 0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.spacing8),

              // Titre
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Text(
                    'Compte créé avec succès !',
                    style: AppTypography.headline1.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.spacing4),

              // Description
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Text(
                    'Bienvenue sur SEZAM ! Votre compte a été créé avec succès. Pour accéder à tous les services, vous devez compléter votre profil KYC.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.spacing8),

              // Informations sur le KYC
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.spacing5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.spacing2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                              child: const Icon(
                                Icons.verified_user,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.spacing3),
                            Expanded(
                              child: Text(
                                'Vérification d\'identité (KYC)',
                                style: AppTypography.headline3.copyWith(
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.spacing4),
                        _buildInfoItem(
                          icon: Icons.person_outline,
                          text: 'Informations personnelles',
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.spacing3),
                        _buildInfoItem(
                          icon: Icons.credit_card_outlined,
                          text: 'Documents d\'identité',
                          isDark: isDark,
                        ),
                        const SizedBox(height: AppSpacing.spacing3),
                        _buildInfoItem(
                          icon: Icons.shield_outlined,
                          text: 'Sécurité et confidentialité',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.spacing8),

              // Bouton continuer
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SezamButton(
                    text: 'Commencer le KYC',
                    icon: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    ),
                    onPressed: _handleContinue,
                    isFullWidth: true,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.spacing4),

              // Lien pour continuer plus tard
              FadeTransition(
                opacity: _fadeAnimation,
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.go('/dashboard');
                  },
                  child: Text(
                    'Continuer plus tard',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.spacing3),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }
}

