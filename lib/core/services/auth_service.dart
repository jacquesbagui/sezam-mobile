import 'dart:async';
import '../models/auth_models.dart';
import '../models/user_model.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';
import 'api_client.dart';
import 'token_storage_service.dart';
import 'exceptions.dart';

/// Service d'authentification pour SEZAM
class AuthService {
  final ApiClient _apiClient;
  final TokenStorageService _tokenStorage;
  final StreamController<UserModel?> _userStreamController;
  
  Stream<UserModel?> get userStream => _userStreamController.stream;

  AuthService({
    ApiClient? apiClient,
    TokenStorageService? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorageService.instance,
        _userStreamController = StreamController<UserModel?>.broadcast();

  /// Inscription d'un nouvel utilisateur
  Future<ApiResponse<UserModel>> register(RegisterRequest request) async {
    try {
      // Le backend exige le champ password_confirmation lors de l'inscription
      // Nous l'ajoutons explicitement au payload sans modifier le modèle généré
      final Map<String, dynamic> body = {
        ...request.toJson(),
        'password_confirmation': request.password,
      };

      final response = await _apiClient.post<UserModel>(
        ApiConfig.register,
        body: body,
        fromJson: (json) => UserModel.fromJson(json),
      );

      // Enregistrer le token si disponible
      if (response.token != null) {
        await _tokenStorage.saveToken(response.token!);
      }

      // Enregistrer l'utilisateur si disponible
      if (response.data != null) {
        await _tokenStorage.saveUser(response.data!);
        _userStreamController.add(response.data);
      }
      
      // Retourner la réponse avec le code OTP si disponible (pour les tests)
      return response;
    } catch (e) {
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Connexion d'un utilisateur
  Future<bool> login(String identifier, String password, {bool rememberMe = false}) async {
    try {
      final request = LoginRequest(
        identifier: identifier,
        password: password,
      );

      final response = await _apiClient.post<UserModel>(
        ApiConfig.login,
        body: request.toJson(),
        fromJson: (json) => UserModel.fromJson(json),
      );

      // Vérifier si OTP est requis
      if (response.requiresOtp == true) {
        // OTP requis, ne pas connecter l'utilisateur
        // L'utilisateur devra vérifier l'OTP
        return false;
      }

      // Enregistrer le token
      if (response.token != null) {
        await _tokenStorage.saveToken(response.token!);
      }

      // Enregistrer la préférence "Se souvenir de moi"
      await _tokenStorage.setRememberMe(rememberMe);

      // Enregistrer l'utilisateur
      if (response.data != null) {
        await _tokenStorage.saveUser(response.data!);
        _userStreamController.add(response.data);
      }

      return true;
    } catch (e) {
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Vérification du code OTP
  Future<void> verifyOtp(String identifier, String code, {String? otpType}) async {
    try {
      // Déterminer le type d'OTP si non fourni
      final type = otpType ?? 'email_verification';
      
      final request = VerifyOtpRequest(
        identifier: identifier,
        otpType: type,
        code: code,
      );

      final response = await _apiClient.post<UserModel>(
        ApiConfig.verifyOtp,
        body: request.toJson(),
        fromJson: (json) => UserModel.fromJson(json),
      );

      // Enregistrer le token
      if (response.token != null) {
        await _tokenStorage.saveToken(response.token!);
      }

      // Enregistrer l'utilisateur
      if (response.data != null) {
        await _tokenStorage.saveUser(response.data!);
        _userStreamController.add(response.data);
      }
    } catch (e) {
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Renvoyer le code OTP
  Future<void> resendOtp(String email) async {
    try {
      await _apiClient.post(
        ApiConfig.resendOtp,
        body: {'email': email},
      );
    } catch (e) {
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Mot de passe oublié
  Future<void> forgotPassword(String email) async {
    try {
      final request = ForgotPasswordRequest(email: email);

      await _apiClient.post(
        ApiConfig.forgotPassword,
        body: request.toJson(),
      );
    } catch (e) {
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Réinitialisation du mot de passe
  Future<void> resetPassword(ResetPasswordRequest request) async {
    try {
      await _apiClient.post(
        ApiConfig.resetPassword,
        body: request.toJson(),
      );
    } catch (e) {
      if (e is ApiException) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConfig.logout);
    } catch (e) {
      // Continuer même en cas d'erreur
    } finally {
      await _tokenStorage.clearAll();
      _userStreamController.add(null);
    }
  }

  /// Vérifier si l'utilisateur est connecté
  bool isAuthenticated() {
    return _tokenStorage.isAuthenticated();
  }

  /// Obtenir l'utilisateur actuel
  Future<UserModel?> getCurrentUser() async {
    final user = await _tokenStorage.getUser();
    // Notifier le stream pour que le provider soit au courant
    if (user != null) {
      _userStreamController.add(user);
    }
    return user;
  }

  /// Recharger l'utilisateur depuis le backend
  Future<void> refreshUser() async {
    try {
      print('🔄 Rechargement de l\'utilisateur depuis le backend...');
      final response = await _apiClient.get<UserModel>(
        ApiConfig.userProfile,
        fromJson: (json) => UserModel.fromJson(json),
      );

      print('📦 Response data: ${response.data?.toJson()}');
      print('🔍 Profile in response: ${response.data?.profile}');
      
      if (response.data != null) {
        await _tokenStorage.saveUser(response.data!);
        _userStreamController.add(response.data);
        print('✅ Utilisateur rechargé avec succès');
        print('🏳️ Nationality after refresh: ${response.data?.profile?['nationality']}');
      }
    } catch (e) {
      print('❌ Erreur lors du rechargement de l\'utilisateur: $e');
      rethrow;
    }
  }

  /// Obtenir le token d'authentification
  String? getToken() {
    return _tokenStorage.getToken();
  }

  /// Libérer les ressources
  void dispose() {
    _userStreamController.close();
  }
}

