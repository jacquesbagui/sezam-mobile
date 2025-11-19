import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/sezam_button.dart';
import '../../core/providers/auth_provider.dart';

/// Écran de vérification OTP pour l'inscription
class OtpVerificationScreen extends StatefulWidget {
  final String? email;
  final String? otpCode; // Code OTP pour les tests

  const OtpVerificationScreen({
    super.key,
    this.email,
    this.otpCode,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _errorMessage;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    // Si un code OTP est fourni (pour les tests), le pré-remplir
    if (widget.otpCode != null && widget.otpCode!.length == 6) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (int i = 0; i < 6; i++) {
          _controllers[i].text = widget.otpCode![i];
        }
      });
    }
    // Focus sur le premier champ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Auto-submit quand les 6 chiffres sont remplis
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6) {
      _submitCode(code);
    }
  }

  Future<void> _submitCode(String code) async {
    if (code.length != 6) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.verifyOtp(code);

      if (!mounted) return;

      if (authProvider.errorMessage != null) {
        setState(() {
          _errorMessage = authProvider.errorMessage;
          _isLoading = false;
        });
        HapticFeedback.lightImpact();
        // Réinitialiser les champs en cas d'erreur
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      } else {
        HapticFeedback.mediumImpact();
        // Rediriger vers la page de succès après vérification OTP réussie
        context.go('/registration-success');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
        HapticFeedback.lightImpact();
        // Réinitialiser les champs en cas d'erreur
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.resendOtp();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code renvoyé avec succès'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = widget.email ?? authProvider.otpEmail ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/auth');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.spacing6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.spacing4),
              
              // Icône
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.spacing6),
              
              // Titre
              Text(
                'Vérification du code',
                style: AppTypography.headline2.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.spacing2),
              
              // Description
              Text(
                'Entrez le code à 6 chiffres envoyé à',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.spacing1),
              Text(
                email,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Afficher le code OTP pour les tests
              if (widget.otpCode != null) ...[
                const SizedBox(height: AppSpacing.spacing4),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.spacing3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.spacing2),
                          Text(
                            'Code OTP (tests)',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.spacing2),
                      Text(
                        widget.otpCode!,
                        style: AppTypography.headline2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
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
              
              // Champs de code
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < 5 ? AppSpacing.spacing2 : 0,
                      ),
                      child: ListenableBuilder(
                        listenable: Listenable.merge([_focusNodes[index], _controllers[index]]),
                        builder: (context, _) {
                          final hasFocus = _focusNodes[index].hasFocus;
                          final hasValue = _controllers[index].text.isNotEmpty;
                          
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            height: 64,
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (value) {
                                _onCodeChanged(index, value);
                              },
                              onSubmitted: (_) {
                                if (index == 5) {
                                  final code = _controllers.map((c) => c.text).join();
                                  _submitCode(code);
                                }
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: AppTypography.headline2.copyWith(
                                color: AppColors.textPrimaryLight,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0,
                                height: 1.2,
                              ),
                              cursorColor: AppColors.primary,
                              cursorWidth: 2,
                              showCursor: hasFocus && !hasValue,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: AppSpacing.spacing8),
              
              // Bouton de soumission
              SezamButton(
                text: 'Vérifier',
                icon: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                onPressed: _isLoading
                    ? null
                    : () {
                        final code = _controllers.map((c) => c.text).join();
                        _submitCode(code);
                      },
                isLoading: _isLoading,
                isFullWidth: true,
              ),
              
              const SizedBox(height: AppSpacing.spacing4),
              
              // Lien pour renvoyer le code
              TextButton(
                onPressed: _isResending || _isLoading ? null : _resendOtp,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4, vertical: AppSpacing.spacing3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: _isResending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.spacing2),
                          Text(
                            'Renvoyer le code',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

