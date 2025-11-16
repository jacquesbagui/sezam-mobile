import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../services/token_storage_service.dart';
import '../services/exceptions.dart';
import '../services/push_notification_service.dart';

/// Provider pour gérer l'état d'authentification
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final TokenStorageService _tokenStorage = TokenStorageService.instance;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _requiresOtp = false;
  String? _otpEmail;
  String? _otpType;
  String? _otpCode; // Code OTP pour les tests

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get requiresOtp => _requiresOtp;
  String? get otpEmail => _otpEmail;
  String? get otpCode => _otpCode; // Code OTP pour les tests
  bool get isAuthenticated => _currentUser != null && _tokenStorage.getToken() != null;

  AuthProvider() {
    // Charger l'utilisateur depuis le stockage local
    _loadCurrentUser();
    
    // Écouter les changements d'utilisateur
    _authService.userStream.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  bool _isInitialized = false;
  
  /// Charger l'utilisateur actuel depuis le stockage local
  Future<void> _loadCurrentUser() async {
    _currentUser = await _authService.getCurrentUser();
    print('🔑 Loaded user from storage: ${_currentUser?.email ?? 'null'}');
    print('🔑 Token exists: ${_tokenStorage.getToken() != null}');
    _isInitialized = true;
    notifyListeners();
  }
  
  /// Attendre que l'initialisation soit terminée
  Future<void> waitForInitialization() async {
    while (!_isInitialized) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Réinitialiser l'état d'erreur
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Gérer l'erreur
  void _handleError(dynamic error) {
    if (error is AuthenticationException) {
      _errorMessage = error.message;
    } else if (error is Exception) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
    } else {
      _errorMessage = 'Une erreur est survenue';
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Inscription
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    required String password,
  }) async {
    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      final request = RegisterRequest(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
      );

      final response = await _authService.register(request);
      // Après inscription, OTP requis pour activer le compte
      _requiresOtp = true;
      _otpEmail = email;
      _otpType = 'email_verification';
      // Récupérer le code OTP pour les tests si disponible
      _otpCode = response.otpCode;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  /// Connexion
  Future<bool> login(String identifier, String password, {bool rememberMe = false}) async {
    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _authService.login(identifier, password, rememberMe: rememberMe);
      
      _isLoading = false; // Toujours réinitialiser le loading
      
      if (!success) {
        // OTP requis
        _requiresOtp = true;
        _otpEmail = identifier; // Peut être email ou téléphone, on assume email pour OTP
        _otpType = 'login';
      } else {
        // Récupérer l'utilisateur depuis le storage (le token est déjà enregistré par login)
        _currentUser = await _authService.getCurrentUser();
        
        // Enregistrer le device après connexion réussie
        await _registerDevice();
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  /// Vérification OTP
  Future<void> verifyOtp(String code, {String? otpType}) async {
    if (_otpEmail == null) return;
    
    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      // Utiliser le type d'OTP stocké ou celui fourni en paramètre, ou par défaut email_verification
      final type = otpType ?? _otpType ?? 'email_verification';
      
      await _authService.verifyOtp(_otpEmail!, code, otpType: type);
      _requiresOtp = false;
      _otpEmail = null;
      _otpType = null;
      _isLoading = false;
      
      // S'assurer que le storage est initialisé
      await _tokenStorage.init();
      
      // Récupérer l'utilisateur depuis le storage (le token est déjà enregistré par verifyOtp)
      // Le userStream devrait déjà avoir mis à jour _currentUser, mais on s'assure qu'il est bien chargé
      _currentUser = await _authService.getCurrentUser();
      
      // Vérifier que le token est bien disponible
      final token = _tokenStorage.getToken();
      if (token == null) {
        print('⚠️ Token non disponible après vérification OTP');
        throw AuthenticationException('Erreur d\'authentification: token non disponible');
      }
      
      print('✅ Token disponible après vérification OTP: ${token.substring(0, 20)}...');
      
      // Enregistrer le device après vérification OTP réussie et chargement de l'utilisateur
      await _registerDevice();
      
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  /// Renvoyer le code OTP
  Future<void> resendOtp() async {
    if (_otpEmail == null) return;
    
    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.resendOtp(_otpEmail!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  /// Mot de passe oublié
  Future<void> forgotPassword(String email) async {
    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  bool _isRefreshingUser = false;
  
  /// Recharger l'utilisateur depuis le backend
  Future<void> refreshUser() async {
    // Éviter les appels multiples simultanés
    if (_isRefreshingUser) {
      print('⚠️ refreshUser déjà en cours, ignoré');
      return;
    }
    
    _isRefreshingUser = true;
    try {
      await _authService.refreshUser();
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      print('❌ Erreur lors du rechargement de l\'utilisateur: $e');
    } finally {
      _isRefreshingUser = false;
    }
  }

  /// Enregistrer le device pour les notifications push
  Future<void> _registerDevice() async {
    try {
      // S'assurer que le storage est initialisé
      await _tokenStorage.init();
      
      // Vérifier que l'utilisateur est authentifié avant d'enregistrer le device
      if (_currentUser == null) {
        print('⚠️ Utilisateur non authentifié, enregistrement du device différé');
        return;
      }
      
      // Vérifier que le token d'authentification est disponible
      final authToken = _tokenStorage.getToken();
      if (authToken == null) {
        print('⚠️ Token d\'authentification non disponible, enregistrement du device différé');
        return;
      }
      
      print('🔑 Token d\'authentification disponible: ${authToken.substring(0, 20)}...');
      
      final pushService = PushNotificationService.instance;
      final token = await pushService.getToken();
      if (token != null) {
        final success = await pushService.registerDeviceToken(token);
        if (success) {
          print('✅ Device enregistré avec succès');
        } else {
          print('⚠️ Échec de l\'enregistrement du device');
        }
      } else {
        print('⚠️ Aucun token FCM disponible');
      }
    } catch (e) {
      // On ignore silencieusement les erreurs d'enregistrement du device
      // L'erreur "Unauthenticated" peut survenir si le token n'est pas encore disponible
      if (e.toString().contains('Unauthenticated') || 
          e.toString().contains('401') ||
          e.toString().contains('unauthenticated')) {
        print('⚠️ Authentification non encore disponible, enregistrement du device différé');
      } else {
        print('⚠️ Erreur lors de l\'enregistrement du device: $e');
        print('   L\'app fonctionne mais les notifications push ne sont pas disponibles');
      }
    }
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}

