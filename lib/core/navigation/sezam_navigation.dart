import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../providers/consent_provider.dart';

/// Navigation principale de l'application SEZAM
class SezamBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const SezamBottomNavigation({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          boxShadow: AppSpacing.shadowLg,
          border: Border(
            top: BorderSide(
              color: AppColors.gray200,
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.spacing4,
            right: AppSpacing.spacing4,
            top: AppSpacing.spacing2,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.spacing2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Accueil',
                index: 0,
                isActive: currentIndex == 0,
              ),
              _buildNavItem(
                context,
                icon: Icons.description_outlined,
                activeIcon: Icons.description,
                label: 'Documents',
                index: 1,
                isActive: currentIndex == 1,
              ),
              Selector<ConsentProvider, bool>(
                selector: (_, provider) => provider.pendingConsents.isNotEmpty,
                builder: (context, hasNotification, child) {
                  return _buildNavItem(
                    context,
                    icon: Icons.request_page_outlined,
                    activeIcon: Icons.request_page,
                    label: 'Demandes',
                    index: 2,
                    isActive: currentIndex == 2,
                    hasNotification: hasNotification,
                  );
                },
              ),
              _buildNavItem(
                context,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profil',
                index: 4,
                isActive: currentIndex == 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isActive,
    bool hasNotification = false,
  }) {    final activeColor = AppColors.primary;
    final inactiveColor = AppColors.textSecondaryLight;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap?.call(index);
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing3,
              vertical: AppSpacing.spacing2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                      child: Icon(
                        isActive ? activeIcon : icon,
                        key: ValueKey('$index-$isActive'),
                        size: 24,
                        color: isActive ? activeColor : inactiveColor,
                      ),
                    ),
                    if (hasNotification)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spacing1),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: AppTypography.caption.copyWith(
                    color: isActive ? activeColor : inactiveColor,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// AppBar personnalisée de l'application SEZAM
class SezamAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool showBackButton;

  const SezamAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {    return AppBar(
      title: Text(
        title,
        style: AppTypography.headline4.copyWith(
          color: foregroundColor ?? (AppColors.textPrimaryLight),
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? (AppColors.backgroundLight),
      foregroundColor: foregroundColor ?? (AppColors.textPrimaryLight),
      elevation: elevation ?? 0,
      leading: leading ?? (showBackButton ? const BackButton() : null),
      actions: actions,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}