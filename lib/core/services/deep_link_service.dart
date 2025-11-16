import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';

/// Service pour gérer les deep links de l'application
class DeepLinkService {
  static DeepLinkService? _instance;
  static DeepLinkService get instance => _instance ??= DeepLinkService._();
  
  DeepLinkService._();

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  /// Initialiser le service de deep links
  Future<void> initialize() async {
    _appLinks = AppLinks();
    
    // Gérer le deep link initial (si l'app a été lancée via un deep link)
    try {
      final initialUri = await _appLinks?.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du lien initial: $e');
    }
    
    _listenToDeepLinks();
  }

  /// Écouter les deep links entrants
  void _listenToDeepLinks() {
    _linkSubscription = _appLinks?.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Erreur deep link: $err');
      },
    );
  }

  /// Gérer un deep link
  void _handleDeepLink(Uri uri) {
    debugPrint('🔗 Deep link reçu: ${uri.toString()}');
    
    final path = uri.path;
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    
    if (segments.isEmpty) {
      _navigateTo('/dashboard');
      return;
    }

    final route = segments[0];
    final id = segments.length > 1 ? segments[1] : null;

    switch (route) {
      case 'requests':
        if (id != null) {
          _navigateToRequestDetail(id);
        } else {
          _navigateTo('/requests');
        }
        break;
      
      case 'consents':
        if (id != null) {
          _navigateToConsentDetail(id);
        } else {
          _navigateTo('/requests');
        }
        break;
      
      case 'documents':
        if (id != null) {
          _navigateToDocumentDetail(id);
        } else {
          _navigateTo('/documents');
        }
        break;
      
      case 'dashboard':
        _navigateTo('/dashboard');
        break;
      
      case 'profile':
        _navigateTo('/profile');
        break;
      
      default:
        debugPrint('⚠️ Route non reconnue: $route');
        _navigateTo('/dashboard');
        break;
    }
  }

  /// Naviguer vers le détail d'une demande de consentement
  void _navigateToRequestDetail(String consentId) {
    // D'abord naviguer vers le dashboard, puis vers les requests
    _navigateTo('/dashboard');
    Future.delayed(const Duration(milliseconds: 300), () {
      // TODO: Implémenter la navigation vers RequestDetailScreen
      // Pour l'instant, on navigue vers la liste des requests
      _navigateTo('/requests');
    });
  }

  /// Naviguer vers le détail d'un consentement
  void _navigateToConsentDetail(String consentId) {
    // Similaire à request detail
    _navigateTo('/dashboard');
    Future.delayed(const Duration(milliseconds: 300), () {
      _navigateTo('/requests');
    });
  }

  /// Naviguer vers le détail d'un document
  void _navigateToDocumentDetail(String documentId) {
    // D'abord naviguer vers le dashboard, puis vers les documents
    _navigateTo('/dashboard');
    Future.delayed(const Duration(milliseconds: 300), () {
      // TODO: Implémenter la navigation vers DocumentDetailScreen
      // Pour l'instant, on navigue vers la liste des documents
      _navigateTo('/documents');
    });
  }

  /// Naviguer vers une route
  void _navigateTo(String route) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context != null) {
      context.go(route);
    } else {
      debugPrint('⚠️ Contexte de navigation non disponible');
    }
  }

  /// Nettoyer les ressources
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}

