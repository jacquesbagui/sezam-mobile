import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Carte interactive moderne pour le consentement aux CGU
class TermsConsentCard extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyTap;

  const TermsConsentCard({
    super.key,
    required this.value,
    required this.onChanged,
    this.onTermsTap,
    this.onPrivacyTap,
  });

  @override
  State<TermsConsentCard> createState() => _TermsConsentCardState();
}

class _TermsConsentCardState extends State<TermsConsentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(AppSpacing.spacing4),
          decoration: BoxDecoration(
            color: widget.value
                ? AppColors.primary.withValues(alpha: 0.1)
                : isDark
                    ? AppColors.surfaceDark
                    : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: widget.value
                  ? AppColors.primary
                  : isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
              width: widget.value ? 2 : 1,
            ),
            boxShadow: widget.value
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
              // Icône de validation animée
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: widget.value ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: widget.value
                        ? AppColors.primary
                        : isDark
                            ? AppColors.gray500
                            : AppColors.gray400,
                    width: 2,
                  ),
                ),
                child: widget.value
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.spacing3),
              // Texte du consentement
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'J\'accepte les '),
                      WidgetSpan(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onTermsTap?.call();
                          },
                          child: Text(
                            'Conditions d\'utilisation',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' et la '),
                      WidgetSpan(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onPrivacyTap?.call();
                          },
                          child: Text(
                            'Politique de confidentialité',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

