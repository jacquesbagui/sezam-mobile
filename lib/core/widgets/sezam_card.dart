import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Carte personnalisée de l'application SEZAM
class SezamCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final BorderRadius? borderRadius;
  final Border? border;
  final VoidCallback? onTap;
  final bool isElevated;

  const SezamCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.boxShadow,
    this.borderRadius,
    this.border,
    this.onTap,
    this.isElevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.spacing4),
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusMd),
        border: border ?? Border.all(
          color: isDark ? AppColors.gray700 : AppColors.gray200,
          width: 1,
        ),
        boxShadow: isElevated ? (boxShadow ?? AppSpacing.shadowSm) : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusMd),
        child: cardContent,
      );
    }

    return cardContent;
  }
}

/// Carte avec en-tête et contenu séparés
class SezamCardWithHeader extends StatelessWidget {
  final Widget header;
  final Widget content;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final BorderRadius? borderRadius;
  final Border? border;
  final VoidCallback? onTap;
  final bool isElevated;

  const SezamCardWithHeader({
    super.key,
    required this.header,
    required this.content,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.boxShadow,
    this.borderRadius,
    this.border,
    this.onTap,
    this.isElevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget cardContent = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusMd),
        border: border ?? Border.all(
          color: isDark ? AppColors.gray700 : AppColors.gray200,
          width: 1,
        ),
        boxShadow: isElevated ? (boxShadow ?? AppSpacing.shadowSm) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.spacing4),
            child: header,
          ),
          const Divider(height: 1),
          Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.spacing4),
            child: content,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusMd),
        child: cardContent,
      );
    }

    return cardContent;
  }
}

/// Badge de statut
class SezamBadge extends StatelessWidget {
  final String text;
  final SezamBadgeVariant variant;
  final SezamBadgeSize size;

  const SezamBadge({
    super.key,
    required this.text,
    this.variant = SezamBadgeVariant.primary,
    this.size = SezamBadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (variant) {
      case SezamBadgeVariant.primary:
        backgroundColor = AppColors.primaryWithOpacity(0.1);
        textColor = AppColors.primary;
        break;
      case SezamBadgeVariant.secondary:
        backgroundColor = AppColors.secondaryWithOpacity(0.1);
        textColor = AppColors.secondary;
        break;
      case SezamBadgeVariant.success:
        backgroundColor = AppColors.successWithOpacity(0.1);
        textColor = AppColors.success;
        break;
      case SezamBadgeVariant.warning:
        backgroundColor = AppColors.warningWithOpacity(0.1);
        textColor = AppColors.warning;
        break;
      case SezamBadgeVariant.error:
        backgroundColor = AppColors.errorWithOpacity(0.1);
        textColor = AppColors.error;
        break;
      case SezamBadgeVariant.neutral:
        backgroundColor = AppColors.gray100;
        textColor = AppColors.gray600;
        break;
    }

    double fontSize;
    EdgeInsets padding;

    switch (size) {
      case SezamBadgeSize.small:
        fontSize = 12.0;
        padding = const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing2,
          vertical: AppSpacing.spacing1,
        );
        break;
      case SezamBadgeSize.medium:
        fontSize = 14.0;
        padding = const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing3,
          vertical: AppSpacing.spacing2,
        );
        break;
      case SezamBadgeSize.large:
        fontSize = 16.0;
        padding = const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing4,
          vertical: AppSpacing.spacing3,
        );
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum SezamBadgeVariant {
  primary,
  secondary,
  success,
  warning,
  error,
  neutral,
}

enum SezamBadgeSize {
  small,
  medium,
  large,
}
