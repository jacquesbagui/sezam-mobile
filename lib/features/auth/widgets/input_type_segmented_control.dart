import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Contrôle segmenté pour le type d'entrée (Email/Téléphone)
class InputTypeSegmentedControl extends StatelessWidget {
  final bool isFirstSelected;
  final String firstLabel;
  final String secondLabel;
  final IconData firstIcon;
  final IconData secondIcon;
  final Function(bool) onChanged;
  final bool isDark;

  const InputTypeSegmentedControl({
    super.key,
    required this.isFirstSelected,
    required this.firstLabel,
    required this.secondLabel,
    required this.firstIcon,
    required this.secondIcon,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppColors.gray800 : AppColors.gray100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.gray700 : AppColors.gray200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isFirstSelected 
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: isFirstSelected ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      firstIcon,
                      size: 16,
                      color: isFirstSelected
                          ? AppColors.textPrimaryLight
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                    const SizedBox(width: AppSpacing.spacing2),
                    Text(
                      firstLabel,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isFirstSelected
                            ? AppColors.textPrimaryLight
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        fontWeight: isFirstSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: !isFirstSelected 
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: !isFirstSelected ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      secondIcon,
                      size: 16,
                      color: !isFirstSelected
                          ? AppColors.textPrimaryLight
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                    const SizedBox(width: AppSpacing.spacing2),
                    Text(
                      secondLabel,
                      style: AppTypography.bodyMedium.copyWith(
                        color: !isFirstSelected
                            ? AppColors.textPrimaryLight
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        fontWeight: !isFirstSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

