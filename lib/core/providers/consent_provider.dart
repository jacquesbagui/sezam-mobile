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
  
  // Cache avec timestamp
  DateTime? _lastLoadedAt;
  static const Duration _cacheTTL = Duration(minutes: 5);
  
  /// Invalider le cache (sans recharger immédiatement)
  void invalidateCache() {
    _lastLoadedAt = null;
  }

  List<ConsentModel> get consents => _consents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Vérifier si les données sont encore valides (dans le TTL)
  bool get _isCacheValid {
    if (_lastLoadedAt == null) return false;
    return DateTime.now().difference(_lastLoadedAt!) < _cacheTTL;
  }

  /// Vérifier si les données sont déjà chargées
  bool get hasData => _consents.isNotEmpty;

  /// Charger les consentements (force le rechargement)
  Future<void> loadConsents({bool force = false}) async {
    // Si le cache est valide et qu'on ne force pas, ne pas recharger
    if (!force && _isCacheValid) {
      print('📋 Cache valide, utilisation du cache');
      return;
    }

    print('🔄 Chargement des consentements (force: $force)...');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _consents = await _consentService.getConsents();
      _errorMessage = null;
      _lastLoadedAt = DateTime.now();
      
      print('✅ ${_consents.length} consentement(s) chargé(s)');
      print('   - En attente: ${pendingConsents.length}');
      print('   - Accordés: ${activeConsents.length}');
      print('   - Refusés: ${deniedConsents.length}');
    } catch (e) {
      print('❌ Erreur lors du chargement: $e');
      _errorMessage = e is AuthenticationException 
          ? e.message 
          : 'Erreur lors du chargement des consentements';
      _consents = [];
    } finally {
      _isLoading = false;
      notifyListeners();
      // Log réduit pour éviter la surcharge
    }
  }

  /// Charger les consentements seulement si nécessaire (cache invalide ou vide)
  Future<void> loadIfNeeded() async {
    if (_isCacheValid) {
      // Cache valide, pas besoin de recharger
      return;
    }
    
    // Si déjà en cours de chargement, ne pas relancer
    if (_isLoading) {
      return;
    }

    await loadConsents();
  }

  /// Forcer le rechargement (pour pull-to-refresh)
  Future<void> refresh() async {
    await loadConsents(force: true);
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
  /// Retourne le code OTP en mode test (si disponible)
  Future<String?> requestConsentOtp(String consentId) async {
    try {
      return await _consentService.requestConsentOtp(consentId);
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
      await refresh(); // Forcer le rechargement après modification
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
      await refresh(); // Forcer le rechargement après modification
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
      await refresh(); // Forcer le rechargement après modification
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
      await refresh(); // Forcer le rechargement après modification
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
      await refresh(); // Forcer le rechargement après modification
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}

