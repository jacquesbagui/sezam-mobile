import 'package:flutter/material.dart';

/// Modèle pour les notifications
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionText;
  final VoidCallback? onAction;
  final Map<String, dynamic>? metadata;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionText,
    this.onAction,
    this.metadata,
  });

  /// Créer une copie avec des propriétés modifiées
  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? actionText,
    VoidCallback? onAction,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionText: actionText ?? this.actionText,
      onAction: onAction ?? this.onAction,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Types de notifications
enum NotificationType {
  request,      // Nouvelle demande d'accès
  connection,    // Connexion établie/expirée
  security,      // Alertes de sécurité
  system,       // Notifications système
  reminder,     // Rappels
}

/// Extension pour obtenir les propriétés des types de notifications
extension NotificationTypeExtension on NotificationType {
  IconData get icon {
    switch (this) {
      case NotificationType.request:
        return Icons.notifications_outlined;
      case NotificationType.connection:
        return Icons.link;
      case NotificationType.security:
        return Icons.security;
      case NotificationType.system:
        return Icons.info_outline;
      case NotificationType.reminder:
        return Icons.schedule;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.request:
        return const Color(0xFF3B82F6); // Blue
      case NotificationType.connection:
        return const Color(0xFF10B981); // Green
      case NotificationType.security:
        return const Color(0xFFEF4444); // Red
      case NotificationType.system:
        return const Color(0xFF6B7280); // Gray
      case NotificationType.reminder:
        return const Color(0xFFF59E0B); // Orange
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
}

/// Service de gestion des notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationItem> _notifications = [];
  final List<VoidCallback> _listeners = [];

  /// Obtenir toutes les notifications
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  /// Obtenir les notifications non lues
  List<NotificationItem> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();

  /// Obtenir le nombre de notifications non lues
  int get unreadCount => unreadNotifications.length;

  /// Ajouter une notification
  void addNotification(NotificationItem notification) {
    _notifications.insert(0, notification);
    _notifyListeners();
  }

  /// Marquer une notification comme lue
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notifyListeners();
    }
  }

  /// Marquer toutes les notifications comme lues
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    _notifyListeners();
  }

  /// Supprimer une notification
  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _notifyListeners();
  }

  /// Supprimer toutes les notifications
  void clearAllNotifications() {
    _notifications.clear();
    _notifyListeners();
  }

  /// Supprimer les notifications lues
  void clearReadNotifications() {
    _notifications.removeWhere((n) => n.isRead);
    _notifyListeners();
  }

  /// Ajouter un listener pour les changements
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Supprimer un listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notifier tous les listeners
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Initialiser avec des notifications de démonstration
  void initializeDemoNotifications({bool notifyListeners = false}) {
    _notifications.clear();
    
    final demoNotifications = [
      NotificationItem(
        id: 'notif_1',
        title: 'Nouvelle demande d\'accès',
        message: 'Banque Atlantique souhaite accéder à vos données personnelles',
        type: NotificationType.request,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        actionText: 'Voir',
      ),
      NotificationItem(
        id: 'notif_2',
        title: 'Connexion établie',
        message: 'Votre connexion avec Orange Money a été créée avec succès',
        type: NotificationType.connection,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      NotificationItem(
        id: 'notif_3',
        title: 'Alerte de sécurité',
        message: 'Tentative de connexion suspecte détectée depuis un nouvel appareil',
        type: NotificationType.security,
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        actionText: 'Vérifier',
      ),
      NotificationItem(
        id: 'notif_4',
        title: 'Rappel de mise à jour',
        message: 'Nouvelle version de SEZAM disponible avec des améliorations de sécurité',
        type: NotificationType.system,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        actionText: 'Mettre à jour',
      ),
      NotificationItem(
        id: 'notif_5',
        title: 'Expiration proche',
        message: 'Votre connexion avec Assurance NSIA expire dans 3 jours',
        type: NotificationType.reminder,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        actionText: 'Renouveler',
      ),
    ];

    _notifications.addAll(demoNotifications);
    
    if (notifyListeners) {
      _notifyListeners();
    }
  }
}
