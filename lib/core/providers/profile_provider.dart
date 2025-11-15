import 'package:flutter/foundation.dart';
import '../models/profile_status_model.dart';
import '../services/profile_service.dart';

/// Provider pour gérer l'état du profil utilisateur
class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  ProfileStatusModel? _profileStatus;
  bool _isLoading = false;
  String? _error;

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

  /// Charger le statut du profil
  Future<void> loadProfileStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profileStatus = await _profileService.getProfileStatus();
    } catch (e) {
      _error = e.toString();
      debugPrint('Erreur chargement profil: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mettre à jour le profil
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _profileService.updateProfile(data);
      // Recharger le statut après mise à jour
      await loadProfileStatus();
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

