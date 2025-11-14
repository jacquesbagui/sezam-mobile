/// Configuration de l'API SEZAM
class ApiConfig {
  // Base URL de l'API
  static const String baseUrl = 'http://sezam-backend.test';
  
  // Endpoints
  static const String apiPrefix = '/api';
  
  // Auth endpoints
  static const String authPrefix = '$apiPrefix/auth';
  static const String register = '$authPrefix/register';
  static const String login = '$authPrefix/login';
  static const String logout = '$apiPrefix/logout';
  static const String verifyOtp = '$authPrefix/verify-otp';
  static const String resendOtp = '$authPrefix/resend-otp';
  static const String forgotPassword = '$authPrefix/forgot-password';
  static const String resetPassword = '$authPrefix/reset-password';
  
  // User endpoints
  static const String userProfile = '$apiPrefix/user/profile';
  static const String userProfileStatus = '$apiPrefix/user/profile/status';
  static const String updateProfile = '$apiPrefix/user/profile';
  static const String updateProfilePhoto = '$apiPrefix/user/profile/photo';
  static const String generateUserCode = '$apiPrefix/user/generate-code';
  static const String completeKyc = '$apiPrefix/user/kyc/complete';
  
  // Documents endpoints
  static const String documents = '$apiPrefix/user/documents';
  
  // Consents endpoints
  static const String consents = '$apiPrefix/user/consents';
  
  // Notifications endpoints
  static const String notifications = '$apiPrefix/user/notifications';
  
  // Device registration endpoints
  static const String devices = '$apiPrefix/user/devices';
  
  // Reference data endpoints
  static const String nationalities = '$apiPrefix/nationalities';
  static const String countries = '$apiPrefix/countries';
  
  // Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

