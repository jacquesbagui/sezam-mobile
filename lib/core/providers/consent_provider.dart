import 'package:flutter/material.dart';
import '../models/consent_model.dart';
import '../services/consent_service.dart';
import '../services/exceptions.dart';

/// Provider pour gérer l'état des consentements
class ConsentProvider extends ChangeNotifier {
  final ConsentService _consentService = ConsentService();

  List<ConsentModel> _consents = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ConsentModel> get consents => _consents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charger les consentements
  Future<void> loadConsents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _consents = await _consentService.getConsents();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e is AuthenticationException 
          ? e.message 
          : 'Erreur lors du chargement des consentements';
      _consents = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtenir les consentements actifs (granted)
  List<ConsentModel> get activeConsents {
    return _consents.where((consent) => consent.isGranted).toList();
  }

  /// Obtenir les consentements récents (5 derniers)
  List<ConsentModel> get recentConsents {
    final sorted = List<ConsentModel>.from(_consents);
    // Trier par date de création au lieu de grantedAt (car pending n'a pas de grantedAt)
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(5).toList();
  }

  /// Vérifier si l'utilisateur a des consentements
  bool get hasConsents => _consents.isNotEmpty;
  
  /// Obtenir les consentements en attente (pending)
  List<ConsentModel> get pendingConsents {
    return _consents.where((consent) => consent.isPending).toList();
  }
  
  /// Obtenir les consentements refusés (denied)
  List<ConsentModel> get deniedConsents {
    return _consents.where((consent) => consent.isDenied).toList();
  }
  
  /// Demander l'OTP pour valider un consentement
  Future<void> requestConsentOtp(String consentId) async {
    try {
      await _consentService.requestConsentOtp(consentId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Accorder un consentement (avec OTP requis)
  Future<void> grantConsent(String consentId, List<String> scopeIds, {required String otpCode}) async {
    try {
      await _consentService.grantConsent(consentId, scopeIds, otpCode: otpCode);
      await loadConsents(); // Recharger la liste
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  /// Refuser un consentement
  Future<void> denyConsent(String consentId) async {
    try {
      await _consentService.denyConsent(consentId);
      await loadConsents(); // Recharger la liste
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  /// Demander la révocation d'un consentement
  Future<void> requestRevocation(String consentId, {String? reason}) async {
    try {
      await _consentService.requestRevocation(consentId, reason: reason);
      await loadConsents(); // Recharger la liste
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Retirer un scope d'un consentement (désactiver)
  Future<void> removeScope(String consentId, String scopeId) async {
    try {
      await _consentService.removeScope(consentId, scopeId);
      await loadConsents(); // Recharger la liste
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Réactiver un scope d'un consentement
  Future<void> enableScope(String consentId, String scopeId) async {
    try {
      await _consentService.enableScope(consentId, scopeId);
      await loadConsents(); // Recharger la liste
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}

