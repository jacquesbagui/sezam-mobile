import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/navigation/sezam_navigation.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const SettingsScreen({super.key, this.onBackToDashboard});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = true;
  bool _darkModeEnabled = false;
  bool _autoLockEnabled = true;
  int _autoLockTimeout = 5; // minutes
  String _selectedLanguage = 'Français';

  final List<String> _languages = [
    'Français',
    'English',
    'Español',
    'العربية',
  ];

  final List<int> _autoLockTimeouts = [1, 5, 10, 15, 30]; // minutes

  @override
  Widget build(BuildContext context) {    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: SezamAppBar(
        title: 'Paramètres',
        actions: [
          IconButton(
            onPressed: _showAboutDialog,
            icon: Icon(
              Icons.info_outline,
              color: AppColors.textPrimaryLight,
            ),
            tooltip: 'À propos',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
            const SizedBox(height: AppSpacing.spacing6),
            _buildSecuritySection(),
            const SizedBox(height: AppSpacing.spacing6),
            _buildPreferencesSection(),
            const SizedBox(height: AppSpacing.spacing6),
            _buildPrivacySection(),
            const SizedBox(height: AppSpacing.spacing6),
            _buildSupportSection(),
            const SizedBox(height: AppSpacing.spacing6),
            _buildAccountSection(),
            const SizedBox(height: AppSpacing.spacing8),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.gray200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'John Doe',
                  style: AppTypography.headline4.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing1),
                Text(
                  'john.doe@example.com',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing3,
                    vertical: AppSpacing.spacing1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    'Compte vérifié',
                    style: AppTypography.bodyXSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _editProfile,
            icon: Icon(
              Icons.edit,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return _buildSection(
      title: 'Sécurité',
      icon: Icons.security,
      children: [
        _buildSwitchTile(
          title: 'Authentification biométrique',
          subtitle: 'Utiliser l\'empreinte digitale ou la reconnaissance faciale',
          value: _biometricEnabled,
          onChanged: (value) {
            setState(() {
              _biometricEnabled = value;
            });
            HapticFeedback.selectionClick();
          },
        ),
        _buildDivider(),
        _buildSwitchTile(
          title: 'Verrouillage automatique',
          subtitle: 'Verrouiller l\'app après une période d\'inactivité',
          value: _autoLockEnabled,
          onChanged: (value) {
            setState(() {
              _autoLockEnabled = value;
            });
            HapticFeedback.selectionClick();
          },
        ),
        if (_autoLockEnabled) ...[
          _buildDivider(),
          _buildListTile(
            title: 'Délai de verrouillage',
            subtitle: '$_autoLockTimeout minutes',
            trailing: Icons.arrow_forward_ios,
            onTap: _showAutoLockDialog,
          ),
        ],
        _buildDivider(),
        _buildListTile(
          title: 'Changer le mot de passe',
          subtitle: 'Modifier votre mot de passe de connexion',
          trailing: Icons.arrow_forward_ios,
          onTap: _changePassword,
        ),
        _buildDivider(),
        _buildListTile(
          title: 'Appareils connectés',
          subtitle: 'Gérer les appareils autorisés',
          trailing: Icons.arrow_forward_ios,
          onTap: _manageDevices,
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return _buildSection(
      title: 'Préférences',
      icon: Icons.tune,
      children: [
        _buildSwitchTile(
          title: 'Notifications',
          subtitle: 'Recevoir des notifications push',
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() {
              _notificationsEnabled = value;
            });
            HapticFeedback.selectionClick();
          },
        ),
        _buildDivider(),
        _buildSwitchTile(
          title: 'Mode sombre',
          subtitle: 'Interface en mode sombre',
          value: _darkModeEnabled,
          onChanged: (value) {
            setState(() {
              _darkModeEnabled = value;
            });
            HapticFeedback.selectionClick();
          },
        ),
        _buildDivider(),
        _buildListTile(
          title: 'Langue',
          subtitle: _selectedLanguage,
          trailing: Icons.arrow_forward_ios,
          onTap: _showLanguageDialog,
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return _buildSection(
      title: 'Confidentialité',
      icon: Icons.privacy_tip,
      children: [
        _buildListTile(
          title: 'Politique de confidentialité',
          subtitle: 'Consulter notre politique de confidentialité',
          trailing: Icons.arrow_forward_ios,
          onTap: _showPrivacyPolicy,
        ),
        _buildDivider(),
        _buildListTile(
          title: 'Conditions d\'utilisation',
          subtitle: 'Consulter nos conditions d\'utilisation',
          trailing: Icons.arrow_forward_ios,
          onTap: _showTermsOfService,
        ),
        _buildDivider(),
        _buildListTile(
          title: 'Gestion des données',
          subtitle: 'Contrôler vos données personnelles',
          trailing: Icons.arrow_forward_ios,
          onTap: _manageData,
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _buildSection(
      title: 'Support',
      icon: Icons.help_outline,
      children: [
        _buildListTile(
          title: 'Centre d\'aide',
          subtitle: 'FAQ et guides d\'utilisation',
          trailing: Icons.arrow_forward_ios,
          onTap: _openHelpCenter,
        ),
        _buildDivider(),
        _buildListTile(
          title: 'Nous contacter',
          subtitle: 'Support technique et assistance',
          trailing: Icons.arrow_forward_ios,
          onTap: _contactSupport,
        ),
        _buildDivider(),
        _buildListTile(
          title: 'Signaler un problème',
          subtitle: 'Signaler un bug ou un problème',
          trailing: Icons.arrow_forward_ios,
          onTap: _reportIssue,
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _buildSection(
      title: 'Compte',
      icon: Icons.account_circle,
      children: [
        _buildListTile(
          title: 'Exporter mes données',
          subtitle: 'Télécharger une copie de vos données',
          trailing: Icons.download,
          onTap: _exportData,
        ),
        _buildDivider(),
        _buildListTile(
          title: 'Se déconnecter',
          subtitle: 'Déconnexion de tous les appareils',
          trailing: Icons.logout,
          onTap: _logout,
          textColor: AppColors.error,
        ),
        _buildDivider(),
        _buildListTile(
          title: 'Supprimer le compte',
          subtitle: 'Supprimer définitivement votre compte',
          trailing: Icons.delete_forever,
          onTap: _deleteAccount,
          textColor: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.gray200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing4),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.spacing2),
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing4,
        vertical: AppSpacing.spacing2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing1),
                Text(
                  subtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.gray400,
            inactiveTrackColor: AppColors.gray200,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData trailing,
    required VoidCallback onTap,
    Color? textColor,
  }) {    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing4,
            vertical: AppSpacing.spacing3,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(
                        color: textColor ?? (AppColors.textPrimaryLight),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing1),
                    Text(
                      subtitle,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                trailing,
                size: 16,
                color: textColor ?? (AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {    return Divider(
      height: 1,
      color: AppColors.gray200,
      indent: AppSpacing.spacing4,
      endIndent: AppSpacing.spacing4,
    );
  }

  // Actions
  void _editProfile() {
    HapticFeedback.lightImpact();
    // TODO: Naviguer vers l'écran d'édition de profil
  }

  void _changePassword() {
    HapticFeedback.lightImpact();
    // TODO: Naviguer vers l'écran de changement de mot de passe
  }

  void _manageDevices() {
    HapticFeedback.lightImpact();
    // TODO: Naviguer vers l'écran de gestion des appareils
  }

  void _showAutoLockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Délai de verrouillage'),
        content: RadioGroup<int>(
          groupValue: _autoLockTimeout,
          onChanged: (value) {
            setState(() {
              _autoLockTimeout = value!;
            });
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _autoLockTimeouts.map((timeout) {
              return RadioListTile<int>(
                title: Text('$timeout minute${timeout > 1 ? 's' : ''}'),
                value: timeout,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Langue'),
        content: RadioGroup<String>(
          groupValue: _selectedLanguage,
          onChanged: (value) {
            setState(() {
              _selectedLanguage = value!;
            });
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _languages.map((language) {
              return RadioListTile<String>(
                title: Text(language),
                value: language,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    HapticFeedback.lightImpact();
    // TODO: Ouvrir la politique de confidentialité
  }

  void _showTermsOfService() {
    HapticFeedback.lightImpact();
    // TODO: Ouvrir les conditions d'utilisation
  }

  void _manageData() {
    HapticFeedback.lightImpact();
    // TODO: Naviguer vers l'écran de gestion des données
  }

  void _openHelpCenter() {
    HapticFeedback.lightImpact();
    // TODO: Naviguer vers le centre d'aide
  }

  void _contactSupport() {
    HapticFeedback.lightImpact();
    // TODO: Ouvrir le formulaire de contact
  }

  void _reportIssue() {
    HapticFeedback.lightImpact();
    // TODO: Ouvrir le formulaire de signalement
  }

  void _exportData() {
    HapticFeedback.lightImpact();
    // TODO: Lancer l'export des données
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implémenter la déconnexion
            },
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront définitivement supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implémenter la suppression du compte
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'SEZAM',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Icon(
          Icons.security,
          size: 30,
          color: AppColors.primary,
        ),
      ),
      children: [
        const Text('Application d\'identité numérique sécurisée'),
      ],
    );
  }
}
