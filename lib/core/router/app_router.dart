import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';

/// Configuration des routes de l'application SEZAM
class AppRouter {
  static final GoRouter router = GoRouter(
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
      
      // Dashboard (avec navigation bottom)
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      
      // Documents
      GoRoute(
        path: '/documents',
        name: 'documents',
        builder: (context, state) => const DocumentsScreen(),
      ),
      
      // Requests
      GoRoute(
        path: '/requests',
        name: 'requests',
        builder: (context, state) => const RequestsScreen(),
      ),
      
      // Profile
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
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

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demandes')),
      body: const Center(
        child: Text('Écran Demandes - À implémenter'),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: const Center(
        child: Text('Écran Profil - À implémenter'),
      ),
    );
  }
}

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
