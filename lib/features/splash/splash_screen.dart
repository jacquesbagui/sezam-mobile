import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/services/token_storage_service.dart';

/// Écran de splash screen de l'application SEZAM
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    await _animationController.forward();
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (mounted) {
      // Attendre que le provider charge l'utilisateur depuis le stockage
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Attendre que l'initialisation soit terminée
      await authProvider.waitForInitialization();
      
      if (!mounted) return;
      
      // Débug : vérifier l'état d'authentification
      print('🔐 AuthProvider state:');
      print('  - isAuthenticated: ${authProvider.isAuthenticated}');
      print('  - currentUser: ${authProvider.currentUser?.email ?? 'null'}');
      print('  - token: ${authProvider.currentUser != null ? 'exists' : 'null'}');
      
      // Vérifier si l'utilisateur est connecté
      if (authProvider.isAuthenticated) {
        // Vérifier si l'onboarding a déjà été vu
        final hasSeenOnboarding = await TokenStorageService.instance.hasSeenOnboarding();
        print('🔐 hasSeenOnboarding: $hasSeenOnboarding');
        
        if (!mounted) return;
        
        // Si l'onboarding n'a pas été vu, rediriger vers l'onboarding
        if (!hasSeenOnboarding) {
          context.go('/onboarding');
          return;
        }
        
        // Utilisateur connecté, vérifier le statut du profil KYC
        final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
        await profileProvider.loadProfileStatus();
        
        if (!mounted) return;
        
        // Si le KYC est complet (is_complete = true), aller au dashboard
        // Peu importe si le profil est validé par l'admin ou non
        if (profileProvider.isComplete) {
          context.go('/dashboard');
          return;
        }
        
        // Règle locale minimale: champs requis + pièce d'identité
        final meetsMinimum = _meetsKycMinimum(context, profileProvider);
        if (!meetsMinimum) {
          context.go('/kyc');
        } else {
          context.go('/dashboard');
        }
      } else {
        // Vérifier si l'onboarding a déjà été vu
        final hasSeenOnboarding = await TokenStorageService.instance.hasSeenOnboarding();
        
        if (!mounted) return;
        
        if (hasSeenOnboarding) {
          // Onboarding déjà vu, aller directement à l'authentification
          context.go('/auth');
        } else {
          // Premier lancement, afficher Reviewboarding
          context.go('/onboarding');
        }
      }
    }
  }

  bool _meetsKycMinimum(BuildContext context, ProfileProvider profileProvider) {
    // Vérifier uniquement les champs requis pour le KYC
    // Les champs requis pour le KYC sont : birth_date, birth_place, gender_id, nationality_id,
    // address_line1, city, country_id, occupation
    final missingFields = profileProvider.missingFields;
    
    // Si tous les champs requis pour le KYC sont remplis, le minimum est atteint
    return missingFields.isEmpty;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo de l'application
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
                        boxShadow: AppSpacing.primaryShadow,
                      ),
                      child: const Icon(
                        Icons.security,
                        size: 60,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing8),
                    
                    // Nom de l'application
                    Text(
                      'SEZAM',
                      style: AppTypography.headline1.copyWith(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing2),
                    
                    // Slogan
                    Text(
                      'Votre identité numérique sécurisée',
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.spacing16),
                    
                    // Indicateur de chargement
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
