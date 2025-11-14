import '../models/connection_models.dart';

/// Service de gestion des connexions et demandes
class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  /// Créer une connexion à partir d'une demande acceptée
  static ConnectionItem createConnectionFromRequest(RequestItem request) {
    return ConnectionItem(
      id: 'conn_${DateTime.now().millisecondsSinceEpoch}',
      organizationName: request.title,
      organizationLogo: _getOrganizationLogo(request.title),
      connectionType: _getConnectionType(request.category),
      connectedDate: DateTime.now(),
      expiresDate: DateTime.now().add(const Duration(days: 30)), // Durée par défaut
      status: ConnectionStatus.active,
      permissions: _getDefaultPermissions(request.category),
    );
  }

  /// Obtenir le logo d'une organisation
  static String _getOrganizationLogo(String organizationName) {
    // Mapping simple des organisations vers leurs logos
    switch (organizationName.toLowerCase()) {
      case 'banque atlantique':
        return 'https://logo.clearbit.com/banqueatlantique.com';
      case 'orange money':
        return 'https://logo.clearbit.com/orangemoney.sn';
      case 'assurance nsia':
        return 'https://logo.clearbit.com/nsia.com';
      default:
        return '';
    }
  }

  /// Obtenir le type de connexion basé sur la catégorie
  static String _getConnectionType(String category) {
    switch (category.toLowerCase()) {
      case 'banque':
        return 'Service bancaire';
      case 'assurance':
        return 'Service d\'assurance';
      case 'mobile money':
        return 'Service financier';
      default:
        return 'Service';
    }
  }

  /// Obtenir les permissions par défaut basées sur la catégorie
  static List<String> _getDefaultPermissions(String category) {
    switch (category.toLowerCase()) {
      case 'banque':
        return ['Informations personnelles', 'Relevé bancaire', 'CNI'];
      case 'assurance':
        return ['Informations personnelles', 'Justificatif de domicile'];
      case 'mobile money':
        return ['Informations personnelles', 'Justificatif de domicile', 'CNI'];
      default:
        return ['Informations personnelles'];
    }
  }
}
