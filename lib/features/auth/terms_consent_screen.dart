import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sezam_button.dart';
import 'widgets/terms_consent_card.dart';
import '../../core/services/profile_service.dart';
import 'package:provider/provider.dart';
import '../../core/providers/profile_provider.dart';

/// Écran pour accepter les conditions d'utilisation
class TermsConsentScreen extends StatefulWidget {
  const TermsConsentScreen({super.key});

  @override
  State<TermsConsentScreen> createState() => _TermsConsentScreenState();
}

class _TermsConsentScreenState extends State<TermsConsentScreen> {
  bool _hasAcceptedTerms = false;
  bool _isLoading = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _loadExistingTerms();
  }

  Future<void> _loadExistingTerms() async {
    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      await profileProvider.loadProfileStatus();
      
      // Vérifier si terms_accepted existe déjà
      // Pour l'instant, on laisse l'utilisateur accepter même s'il a déjà accepté
      // (on pourrait améliorer cela en chargeant depuis l'API user/profile)
    } catch (e) {
      print('Erreur lors du chargement: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _showTermsDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conditions d\'utilisation'),
        content: const SingleChildScrollView(
          child: Text(
            'Les conditions d\'utilisation seront affichées ici. '
            'Vous pouvez intégrer un WebView ou un document PDF.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Politique de confidentialité'),
        content: const SingleChildScrollView(
          child: Text(
            'La politique de confidentialité sera affichée ici. '
            'Vous pouvez intégrer un WebView ou un document PDF.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isInitializing) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.spacing6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.spacing4),
              
              // Icône et titre
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: const Icon(
                  Icons.security,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: AppSpacing.spacing6),
              
              // Titre
              Text(
                'Conditions d\'utilisation',
                style: AppTypography.headline2.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.spacing2),
              
              // Description
              Text(
                'Pour continuer, veuillez lire et accepter nos conditions d\'utilisation et notre politique de confidentialité',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.spacing8),
              
              // Carte de consentement
              TermsConsentCard(
                value: _hasAcceptedTerms,
                onChanged: (value) {
                  setState(() {
                    _hasAcceptedTerms = value;
                  });
                },
                onTermsTap: _showTermsDialog,
                onPrivacyTap: _showPrivacyDialog,
              ),
              
              const SizedBox(height: AppSpacing.spacing8),
              
              // Bouton de continuation
              SezamButton(
                text: 'Accepter et continuer',
                icon: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                onPressed: !_hasAcceptedTerms || _isLoading
                    ? null
                    : _handleContinue,
                isLoading: _isLoading,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (!_hasAcceptedTerms) return;

    setState(() {
      _isLoading = true;
    });

    try {
      HapticFeedback.mediumImpact();
      
      // Sauvegarder l'acceptation des CGU
      final profileService = ProfileService();
      await profileService.acceptTerms();

      if (!mounted) return;

      // Rediriger vers le dashboard
      context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

