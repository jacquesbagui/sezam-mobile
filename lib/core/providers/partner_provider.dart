import 'package:flutter/material.dart';
import '../models/partner_model.dart';
import '../services/partner_service.dart';
import '../services/exceptions.dart';

/// Provider pour gérer l'état des partenaires
class PartnerProvider extends ChangeNotifier {
  final PartnerService _partnerService = PartnerService();

  List<PartnerModel> _partners = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Cache avec timestamp
  DateTime? _lastLoadedAt;
  static const Duration _cacheTTL = Duration(minutes: 5);
  
  /// Invalider le cache (sans recharger immédiatement)
  void invalidateCache() {
    _lastLoadedAt = null;
  }

  List<PartnerModel> get partners => _partners;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Vérifier si les données sont encore valides (dans le TTL)
  bool get _isCacheValid {
    if (_lastLoadedAt == null) return false;
    return DateTime.now().difference(_lastLoadedAt!) < _cacheTTL;
  }

  /// Vérifier si les données sont déjà chargées
  bool get hasData => _partners.isNotEmpty;

  /// Charger les partenaires (force le rechargement)
  Future<void> loadPartners({bool force = false}) async {
    // Si le cache est valide et qu'on ne force pas, ne pas recharger
    if (!force && _isCacheValid) {
      print('📋 Cache valide, utilisation du cache');
      return;
    }

    print('🔄 Chargement des partenaires (force: $force)...');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _partners = await _partnerService.getPartners();
      _errorMessage = null;
      _lastLoadedAt = DateTime.now();
      
      print('✅ ${_partners.length} partenaire(s) chargé(s)');
    } catch (e) {
      print('❌ Erreur lors du chargement: $e');
      _errorMessage = e is AuthenticationException 
          ? e.message 
          : 'Erreur lors du chargement des partenaires';
      _partners = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger les partenaires seulement si nécessaire (cache invalide ou vide)
  Future<void> loadIfNeeded() async {
    if (_isCacheValid) {
      // Cache valide, pas besoin de recharger
      return;
    }
    
    // Si déjà en cours de chargement, ne pas relancer
    if (_isLoading) {
      return;
    }

    await loadPartners();
  }

  /// Forcer le rechargement (pour pull-to-refresh)
  Future<void> refresh() async {
    await loadPartners(force: true);
  }
}

