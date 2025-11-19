import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Option de motif d'utilisation
class UsagePurposeOption {
  final String id;
  final String label;
  final String description;
  final IconData icon;

  const UsagePurposeOption({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });
}

/// Sélecteur moderne de motif d'utilisation
class UsagePurposeSelector extends StatefulWidget {
  final String? selectedPurpose;
  final ValueChanged<String> onChanged;
  final List<UsagePurposeOption>? customOptions;

  const UsagePurposeSelector({
    super.key,
    this.selectedPurpose,
    required this.onChanged,
    this.customOptions,
  });

  @override
  State<UsagePurposeSelector> createState() => _UsagePurposeSelectorState();
}

class _UsagePurposeSelectorState extends State<UsagePurposeSelector> {
  static const List<UsagePurposeOption> _defaultOptions = [
    UsagePurposeOption(
      id: 'open_account',
      label: 'Ouvrir un compte',
      description: 'Ouvrir un compte bancaire ou financier',
      icon: Icons.account_balance_outlined,
    ),
    UsagePurposeOption(
      id: 'insurance',
      label: 'Assurance',
      description: 'Souscrire à une assurance',
      icon: Icons.shield_outlined,
    ),
    UsagePurposeOption(
      id: 'loan',
      label: 'Demande de prêt',
      description: 'Faire une demande de crédit ou prêt',
      icon: Icons.credit_card_outlined,
    ),
    UsagePurposeOption(
      id: 'investment',
      label: 'Investissement',
      description: 'Ouvrir un compte d\'investissement',
      icon: Icons.trending_up_outlined,
    ),
    UsagePurposeOption(
      id: 'mobile_operator',
      label: 'Opérateur mobile',
      description: 'Souscrire à un forfait mobile',
      icon: Icons.phone_android_outlined,
    ),
    UsagePurposeOption(
      id: 'utility',
      label: 'Services publics',
      description: 'Ouvrir un contrat électricité, eau, gaz',
      icon: Icons.home_outlined,
    ),
    UsagePurposeOption(
      id: 'other',
      label: 'Autre',
      description: 'Autre motif d\'utilisation',
      icon: Icons.more_horiz,
    ),
  ];

  List<UsagePurposeOption> get _options =>
      widget.customOptions ?? _defaultOptions;

  @override
  Widget build(BuildContext context) {    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Motif d\'utilisation',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing3),
        ..._options.map((option) => _buildOptionCard(option)),
      ],
    );
  }

  Widget _buildOptionCard(UsagePurposeOption option) {
    final isSelected = widget.selectedPurpose == option.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing3),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onChanged(option.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(AppSpacing.spacing4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.borderLight,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Icône
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.gray100,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  option.icon,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondaryLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.spacing3),
              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing1),
                    Text(
                      option.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              // Indicateur de sélection
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.gray400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

