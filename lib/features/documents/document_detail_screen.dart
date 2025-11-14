import 'package:flutter/material.dart';
import 'package:sezam/core/theme/app_colors.dart';
import 'package:sezam/core/theme/app_typography.dart';
import 'package:sezam/core/theme/app_spacing.dart';
import 'package:sezam/core/models/document_model.dart';

class DocumentDetailScreen extends StatefulWidget {
  final DocumentModel document;

  const DocumentDetailScreen({
    super.key,
    required this.document,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildDocumentCard(),
                const SizedBox(height: AppSpacing.spacing4),
                _buildQuickActions(),
                const SizedBox(height: AppSpacing.spacing4),
                _buildDocumentInfo(),
                const SizedBox(height: AppSpacing.spacing4),
                _buildDocumentHistory(),
                const SizedBox(height: AppSpacing.spacing4),
                _buildSecurityInfo(),
                const SizedBox(height: AppSpacing.spacing8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// AppBar avec effet de parallaxe
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 150,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: AppColors.primary),
          onPressed: _shareDocument,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.gray600),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Text('Supprimer'),
                ],
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getDocumentColor(widget.document.displayName).withValues(alpha: 0.1),
                Colors.white,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40), // Espace pour l'AppBar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _getDocumentColor(widget.document.displayName).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: _getDocumentColor(widget.document.displayName).withValues(alpha: 0.2),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getDocumentIcon(widget.document.displayName),
                    size: 40,
                    color: _getDocumentColor(widget.document.displayName),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing3),
                Text(
                  'Détails du document',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.gray600,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Carte principale du document
  Widget _buildDocumentCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4, vertical: AppSpacing.spacing4),
      padding: const EdgeInsets.all(AppSpacing.spacing4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getDocumentColor(widget.document.displayName).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  _getDocumentIcon(widget.document.displayName),
                  color: _getDocumentColor(widget.document.displayName),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.spacing3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.document.displayName,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    if (widget.document.documentNumber != null && widget.document.documentNumber!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.spacing1),
                      Text(
                        widget.document.documentNumber!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildStatusBadge(widget.document.statusName),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.calendar_today,
                  label: 'Expiration',
                  value: widget.document.expiryDate != null 
                      ? _formatDate(widget.document.expiryDate!) 
                      : 'N/A',
                  color: _getExpirationColor(),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.gray200,
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.security,
                  label: 'Sécurité',
                  value: 'Élevée',
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Actions rapides
  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
      padding: const EdgeInsets.all(AppSpacing.spacing4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.visibility,
              label: 'Voir',
              color: AppColors.primary,
              onTap: _viewDocument,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing3),
          Expanded(
            child: _buildActionButton(
              icon: Icons.download,
              label: 'Télécharger',
              color: AppColors.secondary,
              onTap: _downloadDocument,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing3),
          Expanded(
            child: _buildActionButton(
              icon: Icons.share,
              label: 'Partager',
              color: AppColors.success,
              onTap: _shareDocument,
            ),
          ),
        ],
      ),
    );
  }

  /// Item d'information compact
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(height: AppSpacing.spacing1),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.gray600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing1),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Informations du document
  Widget _buildDocumentInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
      padding: const EdgeInsets.all(AppSpacing.spacing4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Ajouté le',
            value: _formatDate(widget.document.createdAt),
            valueColor: AppColors.gray600,
          ),
          const SizedBox(height: AppSpacing.spacing3),
          
          if (widget.document.verifiedAt != null) ...[
            _buildInfoRow(
              icon: Icons.verified_user,
              label: 'Vérifié le',
              value: _formatDate(widget.document.verifiedAt!),
              valueColor: AppColors.success,
            ),
            const SizedBox(height: AppSpacing.spacing3),
          ],
          
          _buildInfoRow(
            icon: Icons.security,
            label: 'Niveau de sécurité',
            value: 'Élevé',
            valueColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  /// Historique du document
  Widget _buildDocumentHistory() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
      padding: const EdgeInsets.all(AppSpacing.spacing4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historique',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          
          if (widget.document.verifiedAt != null)
            _buildHistoryItem(
              icon: Icons.check_circle,
              iconColor: AppColors.success,
              title: 'Document vérifié',
              subtitle: 'Vérification automatique réussie',
              time: _formatDateTime(widget.document.verifiedAt!),
            ),
          if (widget.document.verifiedAt != null)
            const SizedBox(height: AppSpacing.spacing3),
          
          _buildHistoryItem(
            icon: Icons.upload,
            iconColor: AppColors.primary,
            title: 'Document ajouté',
            subtitle: 'Téléchargé depuis la galerie',
            time: _formatDateTime(widget.document.createdAt),
          ),
        ],
      ),
    );
  }

  /// Informations de sécurité
  Widget _buildSecurityInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
      padding: const EdgeInsets.all(AppSpacing.spacing4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.spacing2),
              Text(
                'Sécurité et confidentialité',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing3),
          Text(
            'Ce document est protégé par un chiffrement de niveau militaire et ne peut être partagé qu\'avec votre autorisation explicite.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gray600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Bouton d'action
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.spacing3,
          horizontal: AppSpacing.spacing2,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: AppSpacing.spacing1),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Item d'historique
  Widget _buildHistoryItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.spacing3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing1),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.gray600,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing1),
              Text(
                time,
                style: AppTypography.caption.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Ligne d'information
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.gray500,
        ),
        const SizedBox(width: AppSpacing.spacing3),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Badge de statut
  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case 'verified':
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        text = 'Vérifié';
        break;
      case 'rejected':
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        text = 'Rejeté';
        break;
    case 'expiringSoon':
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        text = 'Expire bientôt';
        break;
      default:
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        text = 'En attente';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing2,
        vertical: AppSpacing.spacing1,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getDocumentIcon(String displayName) {
    final lowerName = displayName.toLowerCase();
    if (lowerName.contains('identité') || lowerName.contains('cni')) {
      return Icons.credit_card;
    } else if (lowerName.contains('passeport')) {
      return Icons.description;
    } else if (lowerName.contains('permis')) {
      return Icons.drive_eta;
    } else {
      return Icons.description_outlined;
    }
  }

  Color _getDocumentColor(String displayName) {
    final lowerName = displayName.toLowerCase();
    if (lowerName.contains('identité') || lowerName.contains('cni')) {
      return const Color(0xFF4CAF50);
    } else if (lowerName.contains('passeport')) {
      return const Color(0xFF2196F3);
    } else if (lowerName.contains('permis')) {
      return const Color(0xFFFF9800);
    } else {
      return AppColors.gray600;
    }
  }

  Color _getExpirationColor() {
    if (widget.document.isExpiringSoon) {
      return AppColors.warning;
    } else if (widget.document.isExpired) {
      return AppColors.error;
    } else if (widget.document.isVerified) {
      return AppColors.success;
    } else {
      return AppColors.gray600;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    final date = _formatDate(dateTime);
    final hours = dateTime.hour.toString().padLeft(2, '0');
    final minutes = dateTime.minute.toString().padLeft(2, '0');
    return '$date à $hours:$minutes';
  }

  /// Actions
  void _viewDocument() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouverture du document...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _downloadDocument() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Téléchargement en cours...'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  void _shareDocument() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Partage du document...'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Modification du document...'),
            backgroundColor: AppColors.warning,
          ),
        );
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDeleteConfirmation() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.spacing6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Supprimer le document',
              style: AppTypography.headline4.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing4),
            Text(
              'Êtes-vous sûr de vouloir supprimer ce document ? Cette action est irréversible.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spacing6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gray600,
                      side: BorderSide(color: AppColors.gray300),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing3),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Document supprimé'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                    ),
                    child: const Text('Supprimer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}