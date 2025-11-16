import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Bouton principal de l'application SEZAM
class SezamButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final SezamButtonVariant variant;
  final SezamButtonSize size;
  final bool isLoading;
  final Widget? icon;
  final bool isFullWidth;

  const SezamButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = SezamButtonVariant.primary,
    this.size = SezamButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: isFullWidth ? double.infinity : null,
        height: size == SezamButtonSize.large ? 48 : null,
        child: variant == SezamButtonVariant.outline || variant == SezamButtonVariant.gray || variant == SezamButtonVariant.grayOutline
            ? OutlinedButton(
                onPressed: isLoading ? null : () {
                  // Feedback haptique pour meilleure réactivité
                  if (onPressed != null) {
                    HapticFeedback.selectionClick();
                    onPressed!();
                  }
                },
                style: variant == SezamButtonVariant.outline 
                    ? _getOutlinedButtonStyle(context)
                    : variant == SezamButtonVariant.gray
                        ? _getGrayButtonStyle(context)
                        : _getGrayOutlineButtonStyle(context),
                child: _buildButtonContent(),
              )
            : ElevatedButton(
                onPressed: isLoading ? null : () {
                  // Feedback haptique pour meilleure réactivité
                  if (onPressed != null) {
                    HapticFeedback.selectionClick();
                    onPressed!();
                  }
                },
                style: _getButtonStyle(context),
                child: _buildButtonContent(),
              ),
      ),
    );
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    Color? borderColor;

    switch (variant) {
      case SezamButtonVariant.primary:
        backgroundColor = AppColors.primary;
        foregroundColor = AppColors.textPrimaryDark;
        break;
      case SezamButtonVariant.secondary:
        backgroundColor = AppColors.secondary;
        foregroundColor = AppColors.textPrimaryDark;
        break;
      case SezamButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.primary;
        borderColor = AppColors.primary;
        break;
      case SezamButtonVariant.destructive:
        backgroundColor = AppColors.error;
        foregroundColor = AppColors.textPrimaryDark;
        break;
      case SezamButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.textPrimaryLight;
        break;
      case SezamButtonVariant.gray:
        backgroundColor = AppColors.gray200;
        foregroundColor = AppColors.textPrimaryLight;
        break;
      case SezamButtonVariant.grayOutline:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.textPrimaryLight;
        borderColor = AppColors.gray300;
        break;
    }

    EdgeInsets padding;
    double fontSize;

    switch (size) {
      case SezamButtonSize.small:
        padding = const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing4,
          vertical: AppSpacing.spacing2,
        );
        fontSize = 14.0;
        break;
      case SezamButtonSize.medium:
        padding = const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing6,
          vertical: AppSpacing.spacing3,
        );
        fontSize = 16.0;
        break;
      case SezamButtonSize.large:
        padding = const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing8,
          vertical: AppSpacing.spacing4,
        );
        fontSize = 18.0;
        break;
    }

    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: variant == SezamButtonVariant.outline || variant == SezamButtonVariant.ghost ? 0 : 2,
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: borderColor != null ? BorderSide(color: borderColor) : BorderSide.none,
      ),
      textStyle: AppTypography.button.copyWith(fontSize: fontSize),
    );
  }

  ButtonStyle _getOutlinedButtonStyle(BuildContext context) {
    EdgeInsets padding;
    double fontSize;

    switch (size) {
      case SezamButtonSize.small:
        padding = const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing4,
          vertical: AppSpacing.spacing2,
        );
        fontSize = 14.0;
        break;
      case SezamButtonSize.medium:
        padding = const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing6,
          vertical: AppSpacing.spacing3,
        );
        fontSize = 16.0;
        break;
      case SezamButtonSize.large:
        padding = const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing8,
          vertical: AppSpacing.spacing4,
        );
        fontSize = 18.0;
        break;
    }

    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary, width: 2),
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      textStyle: AppTypography.button.copyWith(fontSize: fontSize),
    );
  }

  ButtonStyle _getGrayButtonStyle(BuildContext context) {
    EdgeInsets padding;
    double fontSize;

    switch (size) {
      case SezamButtonSize.small:
        padding = const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing4,
          vertical: AppSpacing.spacing2,
        );
        fontSize = 14.0;
        break;
      case SezamButtonSize.medium:
        padding = const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing6,
          vertical: AppSpacing.spacing3,
        );
        fontSize = 16.0;
        break;
      case SezamButtonSize.large:
        padding = const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing8,
          vertical: AppSpacing.spacing4,
        );
        fontSize = 18.0;
        break;
    }

    return OutlinedButton.styleFrom(
      backgroundColor: AppColors.gray200,
      foregroundColor: AppColors.textPrimaryLight,
      side: const BorderSide(color: AppColors.gray300),
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      textStyle: AppTypography.button.copyWith(fontSize: fontSize),
    );
  }

  ButtonStyle _getGrayOutlineButtonStyle(BuildContext context) {
    EdgeInsets padding;
    double fontSize;

    switch (size) {
      case SezamButtonSize.small:
        padding = const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing4,
          vertical: AppSpacing.spacing2,
        );
        fontSize = 14.0;
        break;
      case SezamButtonSize.medium:
        padding = const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing6,
          vertical: AppSpacing.spacing3,
        );
        fontSize = 16.0;
        break;
      case SezamButtonSize.large:
        padding = const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing8,
          vertical: AppSpacing.spacing4,
        );
        fontSize = 18.0;
        break;
    }

    return OutlinedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimaryLight,
      side: const BorderSide(color: AppColors.gray300),
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      textStyle: AppTypography.button.copyWith(fontSize: fontSize),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == SezamButtonVariant.outline || variant == SezamButtonVariant.ghost
                ? AppColors.primary
                : AppColors.textPrimaryDark,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: AppSpacing.spacing2),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}

enum SezamButtonVariant {
  primary,
  secondary,
  outline,
  destructive,
  ghost,
  gray,
  grayOutline,
}

enum SezamButtonSize {
  small,
  medium,
  large,
}
