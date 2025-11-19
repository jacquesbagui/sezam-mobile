import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/models/partner_model.dart';
import '../../core/providers/partner_provider.dart';

class PartnersScreen extends StatefulWidget {
  const PartnersScreen({super.key});

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPartners();
    });
  }

  Future<void> _loadPartners() async {
    if (!mounted) return;
    final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
    await partnerProvider.loadIfNeeded();
  }

  Future<void> _refreshPartners() async {
    final partnerProvider = Provider.of<PartnerProvider>(context, listen: false);
    await partnerProvider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Partenaires',
          style: AppTypography.headline4.copyWith(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimaryLight,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: Consumer<PartnerProvider>(
        builder: (context, partnerProvider, child) {
          if (partnerProvider.isLoading && partnerProvider.partners.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (partnerProvider.errorMessage != null && partnerProvider.partners.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.spacing8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.spacing4),
                    Text(
                      'Erreur',
                      style: AppTypography.headline4.copyWith(
                        color: AppColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing2),
                    Text(
                      partnerProvider.errorMessage!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.spacing6),
                    ElevatedButton(
                      onPressed: _loadPartners,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (partnerProvider.partners.isEmpty) {
            return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business_outlined,
                size: 80,
                color: AppColors.gray400,
              ),
              const SizedBox(height: AppSpacing.spacing4),
              Text(
                      'Aucun partenaire',
                style: AppTypography.headline4.copyWith(
                        color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.spacing2),
              Text(
                      'Aucun partenaire disponible pour le moment.',
                style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshPartners,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.spacing4),
              itemCount: partnerProvider.partners.length,
              itemBuilder: (context, index) {
                final partner = partnerProvider.partners[index];
                return _buildPartnerCard(partner);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPartnerCard(PartnerModel partner) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.gray200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing4),
        child: Row(
          children: [
            // Logo ou icône
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: partner.logoUrl != null
                    ? Colors.transparent
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: partner.logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: CachedNetworkImage(
                        imageUrl: partner.logoUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Icon(
                          Icons.business_outlined,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.business_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
            ),
            const SizedBox(width: AppSpacing.spacing4),
            // Informations du partenaire
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          partner.displayName,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (partner.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.spacing2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 14,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Vérifié',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (partner.typeName.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.spacing1),
                    Text(
                      partner.typeName,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (partner.email != null) ...[
                    const SizedBox(height: AppSpacing.spacing1),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: AppSpacing.spacing1),
                        Expanded(
                          child: Text(
                            partner.email!,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }
}
