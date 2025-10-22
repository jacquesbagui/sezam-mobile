import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLogin = true;
  bool _isEmail = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Listen to password changes for strength indicator
    _passwordController.addListener(() {
      if (!_isLogin) {
        setState(() {}); // Trigger rebuild for password strength
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _toggleInputType() {
    setState(() {
      _isEmail = !_isEmail;
      _emailController.clear();
      _errorMessage = null;
    });
  }

  PasswordStrength _getPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;
    if (password.length < 6) return PasswordStrength.weak;

    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    if (strength <= 2) return PasswordStrength.weak;
    if (strength <= 3) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre mot de passe';
    }
    if (!_isLogin) {
      if (value.length < 8) {
        return 'Le mot de passe doit contenir au moins 8 caractères';
      }
      if (!value.contains(RegExp(r'[A-Z]'))) {
        return 'Le mot de passe doit contenir au moins une majuscule';
      }
      if (!value.contains(RegExp(r'[a-z]'))) {
        return 'Le mot de passe doit contenir au moins une minuscule';
      }
      if (!value.contains(RegExp(r'[0-9]'))) {
        return 'Le mot de passe doit contenir au moins un chiffre';
      }
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre téléphone';
    }
    // Remove spaces and check format
    String cleanPhone = value.replaceAll(' ', '');
    if (!RegExp(r'^\+?[0-9]{10,13}$').hasMatch(cleanPhone)) {
      return 'Veuillez entrer un numéro de téléphone valide';
    }
    return null;
  }

  Future<void> _handleAuth() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    // Check password confirmation for signup
    if (!_isLogin && _passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Les mots de passe ne correspondent pas';
      });
      HapticFeedback.lightImpact();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulation d'authentification
      await Future.delayed(const Duration(seconds: 2));

      // Simulate random error for demo (10% chance)
      if (DateTime.now().millisecond % 10 == 0) {
        throw Exception('Identifiants incorrects');
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
        HapticFeedback.lightImpact();
      }
    }
  }

  Future<void> _handleBiometricAuth() async {
    HapticFeedback.selectionClick();
    // TODO: Implémenter l'authentification biométrique
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Authentification biométrique en cours...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    HapticFeedback.selectionClick();
    // TODO: Implémenter la récupération de mot de passe
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Un email de récupération sera envoyé'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.spacing6),
            child: FadeTransition(
              opacity: _fadeAnimation,
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
                          Hero(
                            tag: 'app_logo',
                            child: Container(
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
                            _isLogin
                                ? 'Connectez-vous pour accéder à votre identité numérique'
                                : 'Créez votre compte pour commencer',
                            style: AppTypography.bodyLarge.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.spacing8),

                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.spacing3),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.spacing2),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing4),
                    ],
                
                    // Sélection Connexion/Inscription
                    _SegmentedControl(
                      isFirstSelected: _isLogin,
                      firstLabel: 'Connexion',
                      secondLabel: 'Inscription',
                      onChanged: (isFirst) {
                        setState(() {
                          _isLogin = isFirst;
                          _errorMessage = null;
                          _animationController.reset();
                          _animationController.forward();
                        });
                        HapticFeedback.selectionClick();
                      },
                      isDark: isDark,
                    ),
                
                    const SizedBox(height: AppSpacing.spacing6),

                    // Sélection Email/Téléphone
                    _SegmentedControl(
                      isFirstSelected: _isEmail,
                      firstLabel: 'Email',
                      secondLabel: 'Téléphone',
                      firstIcon: Icons.email_outlined,
                      secondIcon: Icons.phone_outlined,
                      onChanged: (isFirst) {
                        _toggleInputType();
                        HapticFeedback.selectionClick();
                      },
                      isDark: isDark,
                    ),

                    const SizedBox(height: AppSpacing.spacing6),
                
                    // Champs de saisie
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SezamTextField(
                            hint: _isEmail ? 'votre@email.com' : '+33 6 12 34 56 78',
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            keyboardType: _isEmail ? TextInputType.emailAddress : TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(_passwordFocusNode);
                            },
                            validator: _isEmail
                                ? (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer votre email';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                      return 'Veuillez entrer un email valide';
                                    }
                                    return null;
                                  }
                                : _validatePhone,
                          ),

                          const SizedBox(height: AppSpacing.spacing4),

                          SezamTextField(
                            hint: 'Mot de passe',
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            obscureText: _obscurePassword,
                            textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
                            onFieldSubmitted: (_) {
                              if (_isLogin) {
                                _handleAuth();
                              } else {
                                FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
                              }
                            },
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                                HapticFeedback.selectionClick();
                              },
                            ),
                            validator: _validatePassword,
                          ),

                          // Password strength indicator for signup
                          if (!_isLogin && _passwordController.text.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.spacing2),
                            _PasswordStrengthIndicator(
                              strength: _getPasswordStrength(_passwordController.text),
                              isDark: isDark,
                            ),
                          ],

                          // Confirm password field for signup
                          if (!_isLogin) ...[
                            const SizedBox(height: AppSpacing.spacing4),
                            SezamTextField(
                              hint: 'Confirmer le mot de passe',
                              controller: _confirmPasswordController,
                              focusNode: _confirmPasswordFocusNode,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleAuth(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                  HapticFeedback.selectionClick();
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez confirmer votre mot de passe';
                                }
                                if (value != _passwordController.text) {
                                  return 'Les mots de passe ne correspondent pas';
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
                      ),
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
                              HapticFeedback.selectionClick();
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
                            onPressed: _handleForgotPassword,
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
                      icon: Icon(
                        _isLogin ? Icons.lock_open : Icons.person_add,
                        color: Colors.white,
                      ),
                      onPressed: _isLoading ? null : _handleAuth,
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
                        onPressed: _handleBiometricAuth,
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
        ),
      ),
    );
  }
}

// Helper widget for segmented control
class _SegmentedControl extends StatelessWidget {
  final bool isFirstSelected;
  final String firstLabel;
  final String secondLabel;
  final IconData? firstIcon;
  final IconData? secondIcon;
  final Function(bool) onChanged;
  final bool isDark;

  const _SegmentedControl({
    required this.isFirstSelected,
    required this.firstLabel,
    required this.secondLabel,
    required this.onChanged,
    required this.isDark,
    this.firstIcon,
    this.secondIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.gray800 : AppColors.gray100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  vertical: firstIcon != null ? AppSpacing.spacing3 : AppSpacing.spacing2,
                ),
                decoration: BoxDecoration(
                  color: isFirstSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: isFirstSelected ? AppSpacing.shadowSm : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (firstIcon != null) ...[
                      Icon(
                        firstIcon,
                        size: 16,
                        color: isFirstSelected
                            ? AppColors.textPrimaryLight
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                      const SizedBox(width: AppSpacing.spacing2),
                    ],
                    Text(
                      firstLabel,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isFirstSelected
                            ? AppColors.textPrimaryLight
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        fontWeight: isFirstSelected ? FontWeight.w600 : FontWeight.normal,
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  vertical: secondIcon != null ? AppSpacing.spacing3 : AppSpacing.spacing2,
                ),
                decoration: BoxDecoration(
                  color: !isFirstSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: !isFirstSelected ? AppSpacing.shadowSm : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (secondIcon != null) ...[
                      Icon(
                        secondIcon,
                        size: 16,
                        color: !isFirstSelected
                            ? AppColors.textPrimaryLight
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                      const SizedBox(width: AppSpacing.spacing2),
                    ],
                    Text(
                      secondLabel,
                      style: AppTypography.bodyMedium.copyWith(
                        color: !isFirstSelected
                            ? AppColors.textPrimaryLight
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        fontWeight: !isFirstSelected ? FontWeight.w600 : FontWeight.normal,
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

// Enum for password strength
enum PasswordStrength {
  none,
  weak,
  medium,
  strong,
}

// Helper widget for password strength indicator
class _PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;
  final bool isDark;

  const _PasswordStrengthIndicator({
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
