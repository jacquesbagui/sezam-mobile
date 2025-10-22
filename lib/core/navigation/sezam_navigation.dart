import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: AppSpacing.shadowLg,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.gray700 : AppColors.gray200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing4,
            vertical: AppSpacing.spacing2,
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
              _buildNavItem(
                context,
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications,
                label: 'Demandes',
                index: 2,
                isActive: currentIndex == 2,
                hasNotification: true,
              ),
              _buildNavItem(
                context,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profil',
                index: 3,
                isActive: currentIndex == 3,
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
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onTap?.call(index),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing3,
          vertical: AppSpacing.spacing2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 24,
                  color: isActive
                      ? AppColors.primary
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
                if (hasNotification)
                  Positioned(
                    right: 0,
                    top: 0,
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
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isActive
                    ? AppColors.primary
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      title: Text(
        title,
        style: AppTypography.headline4.copyWith(
          color: foregroundColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
      foregroundColor: foregroundColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
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
