import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sezam_button.dart';
import '../../core/widgets/sezam_text_field.dart';

/// Écran d'authentification de l'application SEZAM
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isEmail = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  void _toggleInputType() {
    setState(() {
      _isEmail = !_isEmail;
    });
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulation d'authentification
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.spacing6),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.spacing8),
                
                // Logo et titre
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                        child: Icon(
                          Icons.security,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing4),
                      Text(
                        'Bienvenue sur SEZAM',
                        style: AppTypography.headline2.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing2),
                      Text(
                        'Connectez-vous pour accéder à votre identité numérique',
                        style: AppTypography.bodyLarge.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.spacing8),
                
                // Sélection Connexion/Inscription
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.gray800 : AppColors.gray100,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isLogin = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing2),
                            decoration: BoxDecoration(
                              color: _isLogin ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              boxShadow: _isLogin ? AppSpacing.shadowSm : null,
                            ),
                            child: Text(
                              'Connexion',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium.copyWith(
                                color: _isLogin 
                                    ? AppColors.textPrimaryLight 
                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                fontWeight: _isLogin ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isLogin = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing2),
                            decoration: BoxDecoration(
                              color: !_isLogin ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              boxShadow: !_isLogin ? AppSpacing.shadowSm : null,
                            ),
                            child: Text(
                              'Inscription',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium.copyWith(
                                color: !_isLogin 
                                    ? AppColors.textPrimaryLight 
                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                fontWeight: !_isLogin ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.spacing6),
                
                // Sélection Email/Téléphone
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.gray800 : AppColors.gray100,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isEmail = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing3),
                            decoration: BoxDecoration(
                              color: _isEmail ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              boxShadow: _isEmail ? AppSpacing.shadowSm : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 16,
                                  color: _isEmail 
                                      ? AppColors.textPrimaryLight 
                                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                ),
                                const SizedBox(width: AppSpacing.spacing2),
                                Text(
                                  'Email',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: _isEmail 
                                        ? AppColors.textPrimaryLight 
                                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    fontWeight: _isEmail ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isEmail = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing3),
                            decoration: BoxDecoration(
                              color: !_isEmail ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              boxShadow: !_isEmail ? AppSpacing.shadowSm : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  size: 16,
                                  color: !_isEmail 
                                      ? AppColors.textPrimaryLight 
                                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                ),
                                const SizedBox(width: AppSpacing.spacing2),
                                Text(
                                  'Téléphone',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: !_isEmail 
                                        ? AppColors.textPrimaryLight 
                                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    fontWeight: !_isEmail ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.spacing6),
                
                // Champs de saisie
                SezamTextField(
                  hint: _isEmail ? 'votre@email.com' : '+33 6 12 34 56 78',
                  controller: _emailController,
                  keyboardType: _isEmail ? TextInputType.emailAddress : TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer ${_isEmail ? 'votre email' : 'votre téléphone'}';
                    }
                    if (_isEmail && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Veuillez entrer un email valide';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSpacing.spacing4),
                
                SezamTextField(
                  hint: 'Mot de passe',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    if (!_isLogin && value.length < 8) {
                      return 'Le mot de passe doit contenir au moins 8 caractères';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSpacing.spacing4),
                
                // Options supplémentaires
                if (_isLogin) ...[
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      Text(
                        'Se souvenir de moi',
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          // TODO: Implémenter la récupération de mot de passe
                        },
                        child: Text(
                          'Mot de passe oublié ?',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.spacing6),
                ],
                
                // Bouton principal
                SezamButton(
                  text: _isLogin ? 'Se connecter' : 'Créer un compte',
                  icon: const Icon(Icons.lock, color: Colors.white),
                  onPressed: _handleAuth,
                  isLoading: _isLoading,
                  isFullWidth: true,
                ),
                
                const SizedBox(height: AppSpacing.spacing4),
                
                // Bouton biométrique
                if (_isLogin) ...[
                  SezamButton(
                    text: 'Connexion biométrique',
                    variant: SezamButtonVariant.grayOutline,
                    icon: const Icon(Icons.fingerprint),
                    onPressed: () {
                      // TODO: Implémenter l'authentification biométrique
                    },
                    isFullWidth: true,
                  ),
                  const SizedBox(height: AppSpacing.spacing6),
                ],
                
                // Lien pour changer de mode
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin ? 'Pas encore de compte ? ' : 'Déjà un compte ? ',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    TextButton(
                      onPressed: _toggleAuthMode,
                      child: Text(
                        _isLogin ? 'S\'inscrire' : 'Se connecter',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
