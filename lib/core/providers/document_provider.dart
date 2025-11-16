import 'dart:async';
import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../services/document_service.dart';
import '../services/exceptions.dart';

/// Provider pour gérer l'état des documents
class DocumentProvider extends ChangeNotifier {
  final DocumentService _documentService = DocumentService();

  List<DocumentModel> _documents = [];
  List<DocumentModel> _filteredDocuments = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedFilter = 'Tous';
  
  // Cache avec timestamp
  DateTime? _lastLoadedAt;
  static const Duration _cacheTTL = Duration(minutes: 5);
  
  /// Invalider le cache (sans recharger immédiatement)
  void invalidateCache() {
    _lastLoadedAt = null;
    _cachedDocumentTypes = null;
    _documentCountCache.clear();
  }
  
  // Cache pour documentTypes
  List<String>? _cachedDocumentTypes;
  
  // Cache pour getDocumentCountByType
  final Map<String, int> _documentCountCache = {};
  
  // Timer pour debounce de la recherche
  Timer? _searchDebounceTimer;

  List<DocumentModel> get documents => _filteredDocuments;
  List<DocumentModel> get allDocuments => _documents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;

  /// Obtenir les types de documents uniques (avec cache)
  List<String> get documentTypes {
    // Invalider le cache si les documents ont changé
    if (_cachedDocumentTypes == null) {
      final types = _documents
          .map((doc) => doc.type?.displayName ?? doc.type?.name ?? 'Autre')
          .toSet()
          .toList();
      _cachedDocumentTypes = ['Tous', ...types];
    }
    return _cachedDocumentTypes!;
  }

  /// Vérifier si les données sont encore valides (dans le TTL)
  bool get _isCacheValid {
    if (_lastLoadedAt == null) return false;
    if (_documents.isEmpty) return false;
    return DateTime.now().difference(_lastLoadedAt!) < _cacheTTL;
  }

  /// Vérifier si les données sont déjà chargées
  bool get hasData => _documents.isNotEmpty;

  /// Charger les documents (force le rechargement)
  Future<void> loadDocuments({bool force = false}) async {
    // Si le cache est valide et qu'on ne force pas, ne pas recharger
    if (!force && _isCacheValid) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _documents = await _documentService.getDocuments();
      // Invalider les caches
      _cachedDocumentTypes = null;
      _documentCountCache.clear();
      _applyFilters();
      _errorMessage = null;
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      _errorMessage = e is AuthenticationException 
          ? e.message 
          : 'Erreur lors du chargement des documents';
      _documents = [];
      _filteredDocuments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger les documents seulement si nécessaire (cache invalide ou vide)
  Future<void> loadIfNeeded() async {
    if (_isCacheValid) {
      // Cache valide, pas besoin de recharger
      return;
    }
    
    // Si déjà en cours de chargement, ne pas relancer
    if (_isLoading) {
      return;
    }

    await loadDocuments();
  }

  /// Forcer le rechargement (pour pull-to-refresh)
  Future<void> refresh() async {
    await loadDocuments(force: true);
  }

  /// Filtrer les documents
  void _applyFilters() {
    var filtered = List<DocumentModel>.from(_documents);

    // Filtrer par type
    if (_selectedFilter != 'Tous') {
      filtered = filtered.where((doc) {
        final typeName = doc.type?.displayName ?? doc.type?.name ?? 'Autre';
        return typeName == _selectedFilter;
      }).toList();
    }

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((doc) {
        return doc.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (doc.documentNumber ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    _filteredDocuments = filtered;
  }

  /// Mettre à jour la recherche (avec debounce)
  void updateSearch(String query) {
    _searchQuery = query;
    
    // Annuler le timer précédent
    _searchDebounceTimer?.cancel();
    
    // Créer un nouveau timer avec debounce de 300ms
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
      notifyListeners();
    });
  }
  
  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  /// Changer le filtre
  void setFilter(String filter) {
    if (_selectedFilter == filter) return; // Éviter les rebuilds inutiles
    
    _selectedFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  /// Obtenir le nombre de documents par type (avec cache)
  int getDocumentCountByType(String type) {
    // Vérifier le cache
    if (_documentCountCache.containsKey(type)) {
      return _documentCountCache[type]!;
    }
    
    // Calculer et mettre en cache
    int count;
    if (type == 'Tous') {
      count = _documents.length;
    } else {
      count = _documents.where((doc) {
        final typeName = doc.type?.displayName ?? doc.type?.name ?? 'Autre';
        return typeName == type;
      }).length;
    }
    
    _documentCountCache[type] = count;
    return count;
  }
}

