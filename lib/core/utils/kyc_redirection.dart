import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../services/token_storage_service.dart';
import '../services/profile_service.dart';
import '../services/document_service.dart';

/// Utility pour gérer la redirection après connexion en fonction du statut KYC
class KycRedirection {
  /// Vérifier si le KYC est complet (champs + documents requis)
  static Future<bool> isKycComplete(BuildContext context) async {
    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      
      // Charger le statut si nécessaire
      await profileProvider.loadIfNeeded();
      
      // Vérifier si le profil est marqué comme complet
      if (profileProvider.isComplete) {
        return true;
      }
      
      // Vérifier les champs manquants
      final missingFields = profileProvider.missingFields;
      if (missingFields.isNotEmpty) {
        return false;
      }
      
      // Vérifier les documents requis
      final profileStatus = profileProvider.profileStatus;
      if (profileStatus != null) {
        final uploadedDocs = profileStatus.uploadedDocuments;
        final missingDocs = profileStatus.missingDocuments;
        
        // Documents requis: identity_card/passport, photo, proof_of_address
        bool hasIdentityDoc = false;
        bool hasPhoto = false;
        bool hasAddressProof = false;
        
        // Vérifier dans uploadedDocuments
        for (final uploaded in uploadedDocs) {
          final uploadedStr = uploaded.toString().toLowerCase();
          if (uploadedStr.contains('identity_card') || 
              uploadedStr.contains('passport') || 
              uploadedStr.contains('id_card')) {
            hasIdentityDoc = true;
          } else if (uploadedStr.contains('photo')) {
            hasPhoto = true;
          } else if (uploadedStr.contains('proof_of_address')) {
            hasAddressProof = true;
          }
        }
        
        // Si les documents requis ne sont pas trouvés dans uploaded, vérifier dans requiredDocs
        if (!hasIdentityDoc || !hasPhoto || !hasAddressProof) {
          try {
            final requiredDocs = await DocumentService().getRequiredDocuments();
            for (final doc in requiredDocs) {
              final name = (doc['name'] ?? '').toString().toLowerCase();
              final id = (doc['id'] ?? '').toString();
              
              if (name == 'identity_card' || name == 'passport' || name == 'id_card') {
                if (uploadedDocs.contains(id) || uploadedDocs.contains(name)) {
                  hasIdentityDoc = true;
                }
              } else if (name == 'photo') {
                if (uploadedDocs.contains(id) || uploadedDocs.contains(name)) {
                  hasPhoto = true;
                }
              } else if (name == 'proof_of_address') {
                if (uploadedDocs.contains(id) || uploadedDocs.contains(name)) {
                  hasAddressProof = true;
                }
              }
            }
          } catch (e) {
            print('Erreur récupération requiredDocs: $e');
          }
        }
        
        // Vérifier aussi dans missingDocuments pour confirmer
        if (missingDocs.isNotEmpty) {
          // Si des documents manquent explicitement, vérifier lesquels
          final missingDocsLower = missingDocs.map((d) => d.toString().toLowerCase()).toList();
          if (missingDocsLower.any((d) => d.contains('identity') || d.contains('passport'))) {
            hasIdentityDoc = false;
          }
          if (missingDocsLower.any((d) => d.contains('photo'))) {
            hasPhoto = false;
          }
          if (missingDocsLower.any((d) => d.contains('proof_of_address') || d.contains('address'))) {
            hasAddressProof = false;
          }
        }
        
        // Tous les documents requis doivent être présents
        final hasRequiredDocs = hasIdentityDoc && hasPhoto && hasAddressProof;
        return hasRequiredDocs;
      }
      
      // Si pas de statut, considérer comme incomplet
      return false;
    } catch (e) {
      print('Erreur vérification KYC: $e');
      // En cas d'erreur, considérer comme incomplet pour forcer la vérification
      return false;
    }
  }
  
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
    
    // Vérifier si le KYC est complet
    final isComplete = await isKycComplete(context);
    
    if (!context.mounted) return;
    
    // Si le KYC est complet (is_complete = true), vérifier les étapes suivantes
    if (isComplete) {
      // Vérifier si l'utilisateur a complété usage_purpose et terms_accepted
      final profileService = ProfileService();
      final hasCompletedOnboarding = await profileService.hasCompletedOnboarding();
      
      if (!context.mounted) return;
      
      if (!hasCompletedOnboarding) {
        // KYC complet mais onboarding non complété → Usage Purpose
        context.go('/usage-purpose');
      } else {
        // Tout est complété → Dashboard
        context.go('/dashboard');
      }
    } else {
      // KYC incomplet → KYC
      context.go('/kyc');
    }
  }
  
  /// Vérifier et rediriger vers KYC si nécessaire (pour les routes protégées)
  static Future<String?> checkKycAndRedirect(BuildContext context) async {
    try {
      final isComplete = await isKycComplete(context);
      
      if (!isComplete) {
        // KYC incomplet, rediriger vers KYC
        return '/kyc';
      }
      
      // KYC complet, vérifier usage_purpose et terms_accepted
      final profileService = ProfileService();
      
      // Vérifier quel champ manque pour rediriger vers la bonne page
      try {
        final metadata = await profileService.checkOnboardingMetadata();
        
        final hasUsagePurpose = metadata['hasUsagePurpose'] ?? false;
        final hasTermsAccepted = metadata['hasTermsAccepted'] ?? false;
        
        // Si usage_purpose manque, rediriger vers usage-purpose
        if (!hasUsagePurpose) {
          return '/usage-purpose';
        }
        
        // Si terms_accepted manque, rediriger vers terms-consent
        if (!hasTermsAccepted) {
          return '/terms-consent';
        }
      } catch (e) {
        print('Erreur vérification métadonnées: $e');
        // En cas d'erreur, utiliser la méthode hasCompletedOnboarding comme fallback
        final hasCompletedOnboarding = await profileService.hasCompletedOnboarding();
        if (!hasCompletedOnboarding) {
          // Rediriger vers usage-purpose par défaut
          return '/usage-purpose';
        }
      }
      
      // Tout est complété, autoriser l'accès
      return null;
    } catch (e) {
      print('Erreur vérification KYC: $e');
      // En cas d'erreur, rediriger vers KYC pour forcer la vérification
      return '/kyc';
    }
  }
}


