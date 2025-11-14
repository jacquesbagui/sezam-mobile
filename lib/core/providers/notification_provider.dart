import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Provider pour gérer l'état des notifications
class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Notifications non lues
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  /// Nombre de notifications non lues
  int get unreadCount => unreadNotifications.length;

  /// Charger les notifications
  Future<void> loadNotifications({bool unreadOnly = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _notificationService.getNotifications(
        unreadOnly: unreadOnly,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      print('Erreur loadNotifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      
      // Mettre à jour localement
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          type: _notifications[index].type,
          title: _notifications[index].title,
          body: _notifications[index].body,
          channel: _notifications[index].channel,
          metadata: _notifications[index].metadata,
          isRead: true,
          readAt: DateTime.now(),
          sentAt: _notifications[index].sentAt,
          createdAt: _notifications[index].createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Erreur markAsRead: $e');
      rethrow;
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    try {
      final unreadIds = unreadNotifications.map((n) => n.id).toList();
      for (final id in unreadIds) {
        await markAsRead(id);
      }
    } catch (e) {
      print('Erreur markAllAsRead: $e');
      rethrow;
    }
  }
}

