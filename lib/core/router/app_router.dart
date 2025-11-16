import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/success_screen.dart';
import '../../features/auth/otp_verification_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/kyc/kyc_screen.dart';
import '../../features/requests/requests_screen.dart' as requests_feature;
import '../../features/documents/documents_screen.dart' as documents_feature;
import '../../features/auth/usage_purpose_screen.dart';
import '../../features/auth/terms_consent_screen.dart';
import '../../core/providers/auth_provider.dart';

/// Configuration des routes de l'application SEZAM
class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Authentication
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      
      // OTP Verification - Protected route (for registration)
      GoRoute(
        path: '/otp-verification',
        name: 'otp-verification',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          final otpCode = state.uri.queryParameters['otp_code']; // Pour les tests
          return OtpVerificationScreen(
            email: email,
            otpCode: otpCode,
          );
        },
      ),
      
      // Registration Success - Protected route
      GoRoute(
        path: '/registration-success',
        name: 'registration-success',
        redirect: (context, state) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (!authProvider.isAuthenticated) {
            return '/auth';
          }
          return null;
        },
        builder: (context, state) => const RegistrationSuccessScreen(),
      ),
      
      // Dashboard (avec navigation bottom) - Protected route
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        redirect: (context, state) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (!authProvider.isAuthenticated) {
            return '/auth';
          }
          return null;
        },
        builder: (context, state) => const DashboardScreen(),
      ),
      
      // Documents - Protected route
      GoRoute(
        path: '/documents',
        name: 'documents',
        redirect: (context, state) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (!authProvider.isAuthenticated) {
            return '/auth';
          }
          return null;
        },
        builder: (context, state) => const documents_feature.DocumentsScreen(),
      ),
      
      // Requests (use real feature screen)
      GoRoute(
        path: '/requests',
        name: 'requests',
        builder: (context, state) => const requests_feature.RequestsScreen(),
      ),
      
      // Profile - Protected route
      GoRoute(
        path: '/profile',
        name: 'profile',
        redirect: (context, state) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (!authProvider.isAuthenticated) {
            return '/auth';
          }
          return null;
        },
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // KYC - Protected route
      GoRoute(
        path: '/kyc',
        name: 'kyc',
        redirect: (context, state) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (!authProvider.isAuthenticated) {
            return '/auth';
          }
          return null;
        },
        builder: (context, state) => const KycScreen(),
      ),
      
      // Usage Purpose - Protected route
      GoRoute(
        path: '/usage-purpose',
        name: 'usage-purpose',
        redirect: (context, state) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (!authProvider.isAuthenticated) {
            return '/auth';
          }
          return null;
        },
        builder: (context, state) => const UsagePurposeScreen(),
      ),
      
      // Terms Consent - Protected route
      GoRoute(
        path: '/terms-consent',
        name: 'terms-consent',
        redirect: (context, state) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (!authProvider.isAuthenticated) {
            return '/auth';
          }
          return null;
        },
        builder: (context, state) => const TermsConsentScreen(),
      ),
    ],
    errorBuilder: (context, state) => const ErrorScreen(),
  );
}

// Removed placeholder DocumentsScreen; using real implementation from features/documents/documents_screen.dart
// Removed placeholder RequestsScreen; using real implementation from features/requests/requests_screen.dart

// ProfileScreen is imported from features/profile/profile_screen.dart

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erreur')),
      body: const Center(
        child: Text('Page non trouvée'),
      ),
    );
  }
}
