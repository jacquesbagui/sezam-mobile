import 'package:json_annotation/json_annotation.dart';

part 'notification_model.g.dart';

@JsonSerializable()
class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final String channel;
  @JsonKey(name: 'data')
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'read_at')
  final DateTime? readAt;
  @JsonKey(name: 'sent_at')
  final DateTime? sentAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.channel,
    this.metadata,
    required this.isRead,
    this.readAt,
    this.sentAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  /// Type de notification pour l'affichage dans l'UI
  NotificationType get uiType {
    switch (type.toLowerCase()) {
      case 'consent_request':
      case 'consent_requested':
        return NotificationType.request;
      case 'consent_granted':
      case 'connection':
        return NotificationType.connection;
      case 'security_alert':
      case 'security':
        return NotificationType.security;
      case 'system':
        return NotificationType.system;
      case 'reminder':
        return NotificationType.reminder;
      default:
        return NotificationType.system;
    }
  }
}

/// Types de notifications pour l'UI
enum NotificationType {
  request,
  connection,
  security,
  system,
  reminder,
}

/// Extension pour les propriétés UI des types de notifications
extension NotificationTypeExtension on NotificationType {
  String get iconName {
    switch (this) {
      case NotificationType.request:
        return 'notifications_outlined';
      case NotificationType.connection:
        return 'link';
      case NotificationType.security:
        return 'security';
      case NotificationType.system:
        return 'info_outline';
      case NotificationType.reminder:
        return 'schedule';
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.request:
        return 'Demande';
      case NotificationType.connection:
        return 'Connexion';
      case NotificationType.security:
        return 'Sécurité';
      case NotificationType.system:
        return 'Système';
      case NotificationType.reminder:
        return 'Rappel';
    }
  }

  String get colorHex {
    switch (this) {
      case NotificationType.request:
        return '#3B82F6'; // Blue
      case NotificationType.connection:
        return '#10B981'; // Green
      case NotificationType.security:
        return '#EF4444'; // Red
      case NotificationType.system:
        return '#6B7280'; // Gray
      case NotificationType.reminder:
        return '#F59E0B'; // Orange
    }
  }
}

