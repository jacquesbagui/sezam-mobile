import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sezam_button.dart';
import 'widgets/usage_purpose_selector.dart';
import '../../core/services/profile_service.dart';
import 'package:provider/provider.dart';
import '../../core/providers/profile_provider.dart';

/// Écran pour sélectionner le motif d'utilisation
class UsagePurposeScreen extends StatefulWidget {
  const UsagePurposeScreen({super.key});

  @override
  State<UsagePurposeScreen> createState() => _UsagePurposeScreenState();
}

class _UsagePurposeScreenState extends State<UsagePurposeScreen> {
  String? _selectedPurpose;
  bool _isLoading = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _loadExistingPurpose();
  }

  Future<void> _loadExistingPurpose() async {
    try {
      // Charger le statut du profil
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      await profileProvider.loadProfileStatus();
      
      // Vérifier si usage_purpose existe déjà dans les métadonnées
      // Pour l'instant, on laisse l'utilisateur sélectionner même s'il a déjà choisi
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
                            
              // Titre
              Text(
                'Comment allez-vous utiliser SEZAM ?',
                style: AppTypography.headline2.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.spacing2),
              
              // Description
              Text(
                'Sélectionnez le motif principal de votre utilisation pour personnaliser votre expérience',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.spacing8),
              
              // Sélecteur de motif
              UsagePurposeSelector(
                selectedPurpose: _selectedPurpose,
                onChanged: (value) {
                  setState(() {
                    _selectedPurpose = value;
                  });
                  HapticFeedback.selectionClick();
                },
              ),
              
              const SizedBox(height: AppSpacing.spacing8),
              
              // Bouton de continuation
              SezamButton(
                text: 'Continuer',
                icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                onPressed: _selectedPurpose == null || _isLoading
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
    if (_selectedPurpose == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      HapticFeedback.mediumImpact();
      
      // Sauvegarder le motif d'utilisation
      final profileService = ProfileService();
      await profileService.updateUsagePurpose(_selectedPurpose!);

      if (!mounted) return;

      // Rediriger vers la page de consentement CGU
      context.go('/terms-consent');
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

