import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sezam_button.dart';
import '../../core/widgets/sezam_text_field.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/kyc_redirection.dart';
import 'widgets/phone_input_field.dart';
import 'widgets/input_type_segmented_control.dart';
import 'widgets/password_strength_indicator.dart';

/// Écran d'authentification de l'application SEZAM
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  late AnimationController _animationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLogin = true;
  bool _isEmail = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String _signupPhone = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
    _slideAnimationController.forward();

    // Listen to password changes for strength indicator
    _passwordController.addListener(() {
      if (!_isLogin) {
        setState(() {}); // Trigger rebuild for password strength
      }
    });

    // Focus initial field depending on mode
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusInitialField());
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideAnimationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
    });
    // Animate transition
    _slideAnimationController.reset();
    _slideAnimationController.forward();
    _animationController.reset();
    _animationController.forward();
    // Move focus to the appropriate first field
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusInitialField());
  }

  void _toggleInputType() {
    setState(() {
      _isEmail = !_isEmail;
      _emailController.clear();
      _errorMessage = null;
    });
  }

  void _focusInitialField() {
    if (_isLogin) {
      _emailFocusNode.requestFocus();
    } else {
      _firstNameFocusNode.requestFocus();
    }
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
    if (value.length < 8) {
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

    // En inscription, l'email est requis (géré par validator). Pas de bascule téléphone.

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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (_isLogin) {
        // Login
        final success = await authProvider.login(
          _emailController.text.trim(),
          _passwordController.text,
          rememberMe: _rememberMe,
        );

        if (!mounted) return;

        setState(() {
          _isLoading = false; // Toujours arrêter le loading local
        });
        
        if (!success && authProvider.requiresOtp) {
          // Rediriger vers l'écran OTP pour le login
          if (mounted) {
            context.go('/otp-verification?email=${Uri.encodeComponent(_emailController.text.trim())}');
          }
        } else if (authProvider.errorMessage != null) {
          setState(() {
            _errorMessage = authProvider.errorMessage;
          });
          HapticFeedback.lightImpact();
        } else {
          HapticFeedback.mediumImpact();
          // Login réussi: redirection
          await KycRedirection.redirectAfterLogin(context);
        }
      } else {
        // Register
        await authProvider.register(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _signupPhone.trim().isEmpty ? null : _signupPhone.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        if (authProvider.errorMessage != null) {
          setState(() {
            _errorMessage = authProvider.errorMessage;
            _isLoading = false;
          });
          HapticFeedback.lightImpact();
        } else {
          HapticFeedback.mediumImpact();
          setState(() {
            _isLoading = false;
          });
          // Après inscription: rediriger vers l'écran OTP
          if (mounted) {
            final otpCode = authProvider.otpCode;
            final email = _emailController.text.trim();
            final uri = otpCode != null
                ? '/otp-verification?email=${Uri.encodeComponent(email)}&otp_code=${Uri.encodeComponent(otpCode)}'
                : '/otp-verification?email=${Uri.encodeComponent(email)}';
            context.go(uri);
          }
        }
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

    if (mounted) {
      HapticFeedback.mediumImpact();
      // Rediriger vers KYC ou Dashboard selon le statut du profil
      await KycRedirection.redirectAfterLogin(context);
    }
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
              child: SlideTransition(
                position: _slideAnimation,
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
                            child: Image.asset(
                              'assets/logo/app_icon.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.spacing4),
                          Text(
                            'Bienvenue sur SEZAM',
                            style: AppTypography.headline2.copyWith(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.spacing2),
                          Text(
                            _isLogin
                                ? 'Accédez à vos documents et services en toute sécurité'
                                : 'Créez votre identité numérique et gérez vos documents',
                            style: AppTypography.bodyLarge.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              height: 1.4,
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
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
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
                
                    // Sélection Email/Téléphone (login uniquement)
                    if (_isLogin)
                      InputTypeSegmentedControl(
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
                          if (!_isLogin) ...[
                            SezamTextField(
                              key: const ValueKey('firstNameField'),
                              hint: 'Prénom',
                              controller: _firstNameController,
                              focusNode: _firstNameFocusNode,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) {
                                FocusScope.of(context).requestFocus(_lastNameFocusNode);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre prénom';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.spacing4),
                            SezamTextField(
                              key: const ValueKey('lastNameField'),
                              hint: 'Nom',
                              controller: _lastNameController,
                              focusNode: _lastNameFocusNode,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) {
                                FocusScope.of(context).requestFocus(_emailFocusNode);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre nom';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.spacing4),
                            // Email obligatoire pour l'inscription
                            SezamTextField(
                              key: const ValueKey('emailFieldSignup'),
                              hint: 'votre@email.com',
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) {
                                FocusScope.of(context).requestFocus(_phoneFocusNode);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre email';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Veuillez entrer un email valide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.spacing4),
                            // Téléphone (optionnel) avec indicatif
                            PhoneInputField(
                              key: const ValueKey('phoneFieldSignup'),
                              controller: _phoneController,
                              focusNode: _phoneFocusNode,
                              onSubmitted: () {
                                FocusScope.of(context).requestFocus(_passwordFocusNode);
                              },
                              onChanged: (value) {
                                setState(() {
                                  _signupPhone = value;
                                });
                              },
                              validator: (value) {
                                // Optionnel: si vide OK, sinon vérifier longueur min
                                if (value == null || value.trim().isEmpty) return null;
                                if (value.replaceAll(RegExp(r'\D'), '').length < 8) {
                                  return 'Veuillez entrer un numéro de téléphone valide';
                                }
                                return null;
                              },
                              isDark: isDark,
                            ),
                            const SizedBox(height: AppSpacing.spacing4),
                          ],

                          // Champs d'identifiant pour connexion
                          if (_isLogin) ...[
                            if (_isEmail)
                              SezamTextField(
                                key: const ValueKey('emailField'),
                                hint: 'votre@email.com',
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) {
                                  FocusScope.of(context).requestFocus(_passwordFocusNode);
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre email';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Veuillez entrer un email valide';
                                  }
                                  return null;
                                },
                              )
                            else
                              PhoneInputField(
                                key: const ValueKey('phoneField'),
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                onSubmitted: () {
                                  FocusScope.of(context).requestFocus(_passwordFocusNode);
                                },
                                validator: _validatePhone,
                                isDark: isDark,
                              ),
                          ],

                          const SizedBox(height: AppSpacing.spacing4),

                          SezamTextField(
                            hint: 'Mot de passe',
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            obscureText: _obscurePassword,
                            textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
                            onSubmitted: (_) {
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
                            PasswordStrengthIndicator(
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
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) {
                                // Ne pas soumettre, laisser l'utilisateur voir les autres champs
                                FocusScope.of(context).unfocus();
                              },
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

                    // Bouton biométrique (désactivé sur Android)
                    if (_isLogin && !Platform.isAndroid) ...[
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
    ),
    );
  }
}
