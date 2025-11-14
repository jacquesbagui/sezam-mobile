import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Service de stockage des tokens et informations utilisateur
class TokenStorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _rememberMeKey = 'remember_me';
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  
  static TokenStorageService? _instance;
  SharedPreferences? _prefs;
  
  TokenStorageService._internal();
  
  static TokenStorageService get instance {
    _instance ??= TokenStorageService._internal();
    return _instance!;
  }
  
  /// Initialisation du service
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  /// Sauvegarder le token d'authentification
  Future<void> saveToken(String token) async {
    await init();
    await _prefs!.setString(_tokenKey, token);
  }
  
  /// Récupérer le token d'authentification
  String? getToken() {
    if (_prefs == null) return null;
    return _prefs!.getString(_tokenKey);
  }
  
  /// Sauvegarder les informations utilisateur
  Future<void> saveUser(UserModel user) async {
    await init();
    await _prefs!.setString(_userKey, jsonEncode(user.toJson()));
  }
  
  /// Récupérer les informations utilisateur
  Future<UserModel?> getUser() async {
    await init();
    final userJson = _prefs!.getString(_userKey);
    if (userJson == null) return null;
    
    try {
      final json = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }
  
  /// Sauvegarder la préférence "Se souvenir de moi"
  Future<void> setRememberMe(bool value) async {
    await init();
    await _prefs!.setBool(_rememberMeKey, value);
  }
  
  /// Récupérer la préférence "Se souvenir de moi"
  bool getRememberMe() {
    if (_prefs == null) return false;
    return _prefs!.getBool(_rememberMeKey) ?? false;
  }
  
  /// Vérifier si l'utilisateur est connecté
  bool isAuthenticated() {
    return getToken() != null;
  }
  
  /// Déconnexion - supprimer toutes les données d'authentification
  Future<void> clear() async {
    await init();
    await _prefs!.remove(_tokenKey);
    await _prefs!.remove(_userKey);
    // Note: On garde remember_me pour la prochaine connexion
  }
  
  /// Déconnexion complète - supprimer tout y compris remember_me
  Future<void> clearAll() async {
    await init();
    await _prefs!.remove(_tokenKey);
    await _prefs!.remove(_userKey);
    await _prefs!.remove(_rememberMeKey);
  }
  
  /// Marquer que l'onboarding a été vu
  Future<void> setHasSeenOnboarding(bool value) async {
    await init();
    await _prefs!.setBool(_hasSeenOnboardingKey, value);
  }
  
  /// Vérifier si l'onboarding a été vu
  Future<bool> hasSeenOnboarding() async {
    await init();
    return _prefs!.getBool(_hasSeenOnboardingKey) ?? false;
  }
}

