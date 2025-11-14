/// Exceptions personnalisées pour l'application SEZAM

/// Exception pour les erreurs de connexion réseau
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => message;
}

/// Exception pour les erreurs d'authentification
class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);
  
  @override
  String toString() => message;
}

/// Exception pour les erreurs de validation
class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? errors;
  
  ValidationException(this.message, {this.errors});
  
  @override
  String toString() => message;
}

/// Exception pour les erreurs de serveur
class ServerException implements Exception {
  final String message;
  final int statusCode;
  
  ServerException(this.message, this.statusCode);
  
  @override
  String toString() => message;
}

