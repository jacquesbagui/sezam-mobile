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

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get requiresOtp => _requiresOtp;
  String? get otpEmail => _otpEmail;
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

      await _authService.register(request);
      // Après inscription, OTP requis pour activer le compte
      _requiresOtp = true;
      _otpEmail = email;
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
      } else {
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
  Future<void> verifyOtp(String code) async {
    if (_otpEmail == null) return;
    
    _clearError();
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.verifyOtp(_otpEmail!, code);
      _requiresOtp = false;
      _otpEmail = null;
      _isLoading = false;
      
      // Enregistrer le device après vérification OTP réussie
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

  /// Recharger l'utilisateur depuis le backend
  Future<void> refreshUser() async {
    try {
      await _authService.refreshUser();
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      print('Erreur lors du rechargement de l\'utilisateur: $e');
    }
  }

  /// Enregistrer le device pour les notifications push
  Future<void> _registerDevice() async {
    try {
      final pushService = PushNotificationService();
      final token = await pushService.getToken();
      if (token != null) {
        await pushService.registerDeviceToken(token);
        print('✅ Device enregistré avec succès');
      } else {
        print('⚠️ Aucun token FCM disponible');
      }
    } catch (e) {
      // On ignore silencieusement les erreurs d'enregistrement du device
      print('⚠️ Erreur lors de l\'enregistrement du device: $e');
      print('   L\'app fonctionne mais les notifications push ne sont pas disponibles');
    }
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}

