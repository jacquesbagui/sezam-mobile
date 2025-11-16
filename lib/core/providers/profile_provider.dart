import 'package:flutter/foundation.dart';
import '../models/profile_status_model.dart';
import '../services/profile_service.dart';

/// Provider pour gérer l'état du profil utilisateur
class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  ProfileStatusModel? _profileStatus;
  bool _isLoading = false;
  String? _error;
  
  // Cache avec timestamp
  DateTime? _lastLoadedAt;
  static const Duration _cacheTTL = Duration(minutes: 5);
  
  /// Invalider le cache (sans recharger immédiatement)
  void invalidateCache() {
    _lastLoadedAt = null;
  }

  ProfileStatusModel? get profileStatus => _profileStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  /// Indicateur de progression en pourcentage
  int get completionPercentage => _profileStatus?.completionPercentage ?? 0;

  /// Vérifier si le profil est complet
  bool get isComplete => _profileStatus?.isComplete ?? false;

  /// Obtenir les champs manquants (fieldKeys)
  List<String> get missingFields => _profileStatus?.missingFields ?? [];

  /// Obtenir les champs manquants avec leurs noms d'affichage en français
  List<String> get missingFieldsDisplay => _profileStatus?.missingFieldsDisplay ?? [];

  /// Obtenir les documents manquants
  List<String> get missingDocuments => _profileStatus?.missingDocuments ?? [];

  /// Vérifier si les données sont encore valides (dans le TTL)
  bool get _isCacheValid {
    if (_lastLoadedAt == null) return false;
    if (_profileStatus == null) return false;
    return DateTime.now().difference(_lastLoadedAt!) < _cacheTTL;
  }

  /// Vérifier si les données sont déjà chargées
  bool get hasData => _profileStatus != null;

  /// Charger le statut du profil (force le rechargement)
  Future<void> loadProfileStatus({bool force = false}) async {
    // Si le cache est valide et qu'on ne force pas, ne pas recharger
    if (!force && _isCacheValid) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profileStatus = await _profileService.getProfileStatus();
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      _error = e.toString();
      debugPrint('Erreur chargement profil: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger le statut du profil seulement si nécessaire (cache invalide ou vide)
  Future<void> loadIfNeeded() async {
    if (_isCacheValid) {
      // Cache valide, pas besoin de recharger
      return;
    }
    
    // Si déjà en cours de chargement, ne pas relancer
    if (_isLoading) {
      return;
    }

    await loadProfileStatus();
  }

  /// Forcer le rechargement (pour pull-to-refresh)
  Future<void> refresh() async {
    await loadProfileStatus(force: true);
  }

  /// Mettre à jour le profil
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _profileService.updateProfile(data);
      // Forcer le rechargement après mise à jour
      await refresh();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Erreur mise à jour profil: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

