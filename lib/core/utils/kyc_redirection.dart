import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../services/token_storage_service.dart';

/// Utility pour gérer la redirection après connexion en fonction du statut KYC
class KycRedirection {
  /// Rediriger l'utilisateur après connexion en fonction du statut du profil
  static Future<void> redirectAfterLogin(BuildContext context) async {
    // Attendre un peu pour s'assurer que l'auth est complète
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!context.mounted) return;
    
    // Vérifier si l'onboarding a déjà été vu
    final hasSeenOnboarding = await TokenStorageService.instance.hasSeenOnboarding();
    
    if (!context.mounted) return;
    
    // Si l'onboarding n'a pas été vu, rediriger vers l'onboarding
    if (!hasSeenOnboarding) {
      context.go('/onboarding');
      return;
    }
    
    // Charger le statut du profil KYC
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    await profileProvider.loadProfileStatus();
    
    if (!context.mounted) return;
    
    // Si le KYC est complet (is_complete = true), aller au dashboard
    // Peu importe si le profil est validé par l'admin ou non
    if (profileProvider.isComplete) {
      // KYC complet → Dashboard
      context.go('/dashboard');
    } else {
      // KYC incomplet → KYC
      context.go('/kyc');
    }
  }
}


