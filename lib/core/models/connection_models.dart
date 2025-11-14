import 'package:flutter/material.dart';

/// Modèle pour les demandes d'accès
class RequestItem {
  final String title;
  final String category;
  final int dataCount;
  final IconData icon;
  final Color iconColor;
  final RequestStatus status;

  RequestItem({
    required this.title,
    required this.category,
    required this.dataCount,
    required this.icon,
    required this.iconColor,
    required this.status,
  });
}

/// Statuts des demandes
enum RequestStatus {
  pending,
  accepted,
  rejected,
}

/// Modèle pour les connexions
class ConnectionItem {
  final String id;
  final String organizationName;
  final String organizationLogo;
  final String connectionType;
  final DateTime connectedDate;
  DateTime expiresDate;
  ConnectionStatus status;
  final List<String> permissions;

  ConnectionItem({
    required this.id,
    required this.organizationName,
    required this.organizationLogo,
    required this.connectionType,
    required this.connectedDate,
    required this.expiresDate,
    required this.status,
    required this.permissions,
  });
}

/// Statuts des connexions
enum ConnectionStatus {
  active,
  expired,
  revoked,
}
