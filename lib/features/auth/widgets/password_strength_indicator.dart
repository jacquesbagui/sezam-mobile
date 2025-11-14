import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Enum pour la force du mot de passe
enum PasswordStrength {
  none,
  weak,
  medium,
  strong,
}

/// Widget pour afficher la force du mot de passe
class PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;
  final bool isDark;

  const PasswordStrengthIndicator({
    super.key,
    required this.strength,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final strengthData = _getStrengthData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strengthData.progress,
                backgroundColor: isDark ? AppColors.gray700 : AppColors.gray200,
                valueColor: AlwaysStoppedAnimation<Color>(strengthData.color),
                minHeight: 4,
              ),
            ),
            const SizedBox(width: AppSpacing.spacing2),
            Text(
              strengthData.label,
              style: AppTypography.bodySmall.copyWith(
                color: strengthData.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (strength != PasswordStrength.none && strength != PasswordStrength.strong) ...[
          const SizedBox(height: AppSpacing.spacing1),
          Text(
            'Ajoutez des majuscules, chiffres et caractères spéciaux',
            style: AppTypography.caption.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ],
    );
  }

  ({double progress, Color color, String label}) _getStrengthData() {
    return switch (strength) {
      PasswordStrength.none => (progress: 0.0, color: AppColors.gray400, label: ''),
      PasswordStrength.weak => (progress: 0.33, color: AppColors.error, label: 'Faible'),
      PasswordStrength.medium => (progress: 0.66, color: AppColors.warning, label: 'Moyen'),
      PasswordStrength.strong => (progress: 1.0, color: AppColors.success, label: 'Fort'),
    };
  }
}

