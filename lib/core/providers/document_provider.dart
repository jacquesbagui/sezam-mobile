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

  List<DocumentModel> get documents => _filteredDocuments;
  List<DocumentModel> get allDocuments => _documents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;

  /// Obtenir les types de documents uniques
  List<String> get documentTypes {
    final types = _documents
        .map((doc) => doc.type?.displayName ?? doc.type?.name ?? 'Autre')
        .toSet()
        .toList();
    return ['Tous', ...types];
  }

  /// Charger les documents
  Future<void> loadDocuments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _documents = await _documentService.getDocuments();
      _applyFilters();
      _errorMessage = null;
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

  /// Mettre à jour la recherche
  void updateSearch(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Changer le filtre
  void setFilter(String filter) {
    _selectedFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  /// Obtenir le nombre de documents par type
  int getDocumentCountByType(String type) {
    if (type == 'Tous') return _documents.length;
    return _documents.where((doc) {
      final typeName = doc.type?.displayName ?? doc.type?.name ?? 'Autre';
      return typeName == type;
    }).length;
  }
}

