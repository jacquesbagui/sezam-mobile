import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/personal_info_kyc_screen.dart';
import '../../features/kyc/kyc_screen.dart';
import '../../features/requests/requests_screen.dart' as requests_feature;
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
      
      // Documents
      GoRoute(
        path: '/documents',
        name: 'documents',
        builder: (context, state) => const DocumentsScreen(),
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
      
      // Personal Info KYC - Protected route
      GoRoute(
        path: '/personal-info-kyc',
        name: 'personal-info-kyc',
        redirect: (context, state) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (!authProvider.isAuthenticated) {
            return '/auth';
          }
          return null;
        },
        builder: (context, state) => const PersonalInfoKycScreen(),
      ),
    ],
    errorBuilder: (context, state) => const ErrorScreen(),
  );
}

/// Écrans temporaires pour les routes non encore implémentées
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: const Center(
        child: Text('Écran Documents - À implémenter'),
      ),
    );
  }
}

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
