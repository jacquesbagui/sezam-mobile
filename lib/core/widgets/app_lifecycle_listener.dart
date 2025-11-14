import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/consent_provider.dart';
import '../providers/profile_provider.dart';

/// Widget qui écoute le cycle de vie de l'app pour rafraîchir les données
class SezamAppLifecycleListener extends StatefulWidget {
  final Widget child;

  const SezamAppLifecycleListener({
    super.key,
    required this.child,
  });

  @override
  State<SezamAppLifecycleListener> createState() => _SezamAppLifecycleListenerState();
}

class _SezamAppLifecycleListenerState extends State<SezamAppLifecycleListener>
    with WidgetsBindingObserver {
  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Rafraîchir les données quand l'app revient au premier plan
    if (_lastLifecycleState == AppLifecycleState.paused &&
        state == AppLifecycleState.resumed) {
      _refreshAllData();
    }

    // Rafraîchir aussi quand l'app passe de inactive à resumed
    if (_lastLifecycleState == AppLifecycleState.inactive &&
        state == AppLifecycleState.resumed) {
      _refreshAllData();
    }

    _lastLifecycleState = state;
  }

  Future<void> _refreshAllData() async {
    if (!mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Ne rafraîchir que si l'utilisateur est authentifié
      if (!authProvider.isAuthenticated) {
        return;
      }

      print('🔄 App revenue au premier plan - rafraîchissement des données...');

      // Rafraîchir les données en parallèle
      await Future.wait([
        authProvider.refreshUser().catchError((e) => print('Erreur refreshUser: $e')),
        Provider.of<ConsentProvider>(context, listen: false)
            .loadConsents()
            .catchError((e) => print('Erreur loadConsents: $e')),
        Provider.of<ProfileProvider>(context, listen: false)
            .loadProfileStatus()
            .catchError((e) => print('Erreur loadProfileStatus: $e')),
      ], eagerError: false);

      print('✅ Données rafraîchies avec succès');
    } catch (e) {
      print('❌ Erreur lors du rafraîchissement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

