import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sezam_button.dart';
import '../../../core/models/connection_models.dart';

/// Écran de double authentification pour valider une requête
class TwoFactorAuthScreen extends StatefulWidget {
  final RequestItem request;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const TwoFactorAuthScreen({
    super.key,
    required this.request,
    this.onSuccess,
    this.onCancel,
  });

  @override
  State<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends State<TwoFactorAuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _remainingTime = 60; // Temps restant pour le code
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();

    _startTimer();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer le code de vérification';
    }
    if (value.length != 6) {
      return 'Le code doit contenir 6 chiffres';
    }
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
      return 'Le code ne doit contenir que des chiffres';
    }
    return null;
  }

  Future<void> _handleVerifyCode() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulation de vérification du code
      await Future.delayed(const Duration(seconds: 2));

      // Simuler une erreur aléatoire (5% de chance)
      if (DateTime.now().millisecond % 20 == 0) {
        throw Exception('Code de vérification incorrect');
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        widget.onSuccess?.call();
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

  Future<void> _handleResendCode() async {
    if (_remainingTime > 0) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      // Simulation d'envoi du code
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _remainingTime = 60;
          _isResending = false;
        });
        _startTimer();
        HapticFeedback.selectionClick();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nouveau code envoyé'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors de l\'envoi du code';
          _isResending = false;
        });
      }
    }
  }

  Future<void> _handleBiometricAuth() async {
    HapticFeedback.selectionClick();
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulation d'authentification biométrique
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        HapticFeedback.mediumImpact();
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Authentification biométrique échouée';
          _isLoading = false;
        });
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.spacing6),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.spacing8),

                      // Header avec icône de sécurité
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    offset: const Offset(0, 8),
                                    blurRadius: 20,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/logo/app_icon.png',
                                width: 50,
                                height: 50,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.spacing6),
                            Text(
                              'Double authentification',
                              style: AppTypography.headline3.copyWith(
                                color: AppColors.textPrimaryLight,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.spacing2),
                            Text(
                              'Confirmez votre identité pour valider la demande',
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textSecondaryLight,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.spacing8),

                      // Informations sur la demande
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.spacing6),
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
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.spacing2),
                                Text(
                                  'Demande à valider',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.spacing3),
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: widget.request.iconColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  ),
                                  child: Icon(
                                    widget.request.icon,
                                    color: widget.request.iconColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.spacing3),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.request.title,
                                        style: AppTypography.bodyLarge.copyWith(
                                          color: AppColors.textPrimaryLight,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        widget.request.category,
                                        style: AppTypography.bodyMedium.copyWith(
                                          color: AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.spacing6),

                      // Message d'erreur
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

                      // Champ de saisie du code
                      Text(
                        'Code de vérification',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing2),
                      Text(
                        'Entrez le code à 6 chiffres envoyé sur votre téléphone',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing4),
                      TextFormField(
                        controller: _codeController,
                        focusNode: _codeFocusNode,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: AppTypography.headline3.copyWith(
                          color: AppColors.textPrimaryLight,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration(
                          hintText: '000000',
                          hintStyle: AppTypography.headline3.copyWith(
                            color: AppColors.textSecondaryLight,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            borderSide: BorderSide(
                              color: AppColors.gray300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            borderSide: BorderSide(
                              color: AppColors.gray300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.spacing6,
                            vertical: AppSpacing.spacing4,
                          ),
                        ),
                        validator: _validateCode,
                        onChanged: (value) {
                          if (value.length == 6) {
                            _handleVerifyCode();
                          }
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),

                      const SizedBox(height: AppSpacing.spacing4),

                      // Bouton de renvoi du code
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacing4,
                          vertical: AppSpacing.spacing3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                          border: Border.all(
                            color: AppColors.gray200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.schedule_outlined,
                                  size: 16,
                                  color: AppColors.textSecondaryLight,
                                ),
                                const SizedBox(width: AppSpacing.spacing2),
                                Flexible(
                                  child: Text(
                                    'Vous n\'avez pas reçu le code ?',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.spacing2),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _remainingTime > 0 || _isResending ? null : _handleResendCode,
                                icon: _isResending
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            _remainingTime > 0 || _isResending
                                                ? AppColors.gray400
                                                : AppColors.primary,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        _remainingTime > 0 ? Icons.timer_outlined : Icons.refresh,
                                        size: 16,
                                        color: _remainingTime > 0 || _isResending
                                            ? AppColors.gray400
                                            : AppColors.primary,
                                      ),
                                label: Text(
                                  _isResending
                                      ? 'Envoi en cours...'
                                      : _remainingTime > 0
                                          ? 'Renvoyer dans ${_remainingTime}s'
                                          : 'Renvoyer le code',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: _remainingTime > 0 || _isResending
                                        ? AppColors.gray400
                                        : AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: _remainingTime > 0 || _isResending
                                      ? AppColors.gray400
                                      : AppColors.primary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.spacing4,
                                    vertical: AppSpacing.spacing3,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                    side: BorderSide(
                                      color: _remainingTime > 0 || _isResending
                                          ? AppColors.gray300
                                          : AppColors.primary.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_remainingTime > 0) ...[
                              const SizedBox(height: AppSpacing.spacing2),
                              LinearProgressIndicator(
                                value: (60 - _remainingTime) / 60,
                                backgroundColor: AppColors.gray200,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                minHeight: 2,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.spacing6),

                      // Bouton de vérification
                      SezamButton(
                        text: 'Vérifier le code',
                        icon: Icon(
                          Icons.verified_user,
                          color: Colors.white,
                        ),
                        onPressed: _isLoading ? null : _handleVerifyCode,
                        isLoading: _isLoading,
                        isFullWidth: true,
                      ),

                      const SizedBox(height: AppSpacing.spacing4),

                      // Séparateur
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.gray300,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
                            child: Text(
                              'ou',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.gray300,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.spacing4),

                      // Bouton d'authentification biométrique (désactivé sur Android)
                      if (!Platform.isAndroid) ...[
                        SezamButton(
                          text: 'Authentification biométrique',
                          variant: SezamButtonVariant.grayOutline,
                          icon: const Icon(Icons.fingerprint),
                          onPressed: _isLoading ? null : _handleBiometricAuth,
                          isFullWidth: true,
                        ),
                        const SizedBox(height: AppSpacing.spacing4),
                      ],

                      const SizedBox(height: AppSpacing.spacing6),

                      // Bouton d'annulation
                      TextButton(
                        onPressed: widget.onCancel,
                        child: Text(
                          'Annuler',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
