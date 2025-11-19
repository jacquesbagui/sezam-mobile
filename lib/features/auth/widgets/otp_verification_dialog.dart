import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Dialogue de vérification OTP
class OtpVerificationDialog extends StatefulWidget {
  final String email;
  final VoidCallback onResend;
  final Function(String code) onSubmit;
  final String? testCode; // Code OTP en mode test (optionnel)

  const OtpVerificationDialog({
    super.key,
    required this.email,
    required this.onResend,
    required this.onSubmit,
    this.testCode,
  });

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _currentTestCode;

  @override
  void initState() {
    super.initState();
    _currentTestCode = widget.testCode;
    print('🔑 OtpVerificationDialog initState - testCode: ${widget.testCode}');
    print('🔑 _currentTestCode initialisé: $_currentTestCode');
  }
  
  @override
  void didUpdateWidget(OtpVerificationDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.testCode != widget.testCode) {
      print('🔄 OtpVerificationDialog didUpdateWidget - nouveau testCode: ${widget.testCode}');
      setState(() {
        _currentTestCode = widget.testCode;
      });
    }
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
  }

  void _submitCode() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6) {
      setState(() => _isLoading = true);
      widget.onSubmit(code);
    }
  }

  @override
  Widget build(BuildContext context) {    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: keyboardHeight > 0 ? 20 : 80,
      ),
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icone avec animation (masquer si clavier ouvert)
              if (keyboardHeight == 0)
                Container(
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              
              if (keyboardHeight == 0) const SizedBox(height: 24),
              
              // Titre
              Text(
                'Vérification du code',
                style: AppTypography.headline2.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: keyboardHeight > 0 ? 20 : 24,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: keyboardHeight > 0 ? 4 : 8),
              
              // Description
              Text(
                'Entrez le code à 6 chiffres envoyé à',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Afficher le code OTP en mode test
              Builder(
                builder: (context) {
                  print('🔑 Build - _currentTestCode: $_currentTestCode');
                  print('🔑 Build - widget.testCode: ${widget.testCode}');
                  
                  // Utiliser widget.testCode directement si _currentTestCode est null
                  final displayCode = _currentTestCode ?? widget.testCode;
                  
                  if (displayCode != null && displayCode.isNotEmpty) {
                    print('✅ Affichage du code OTP en mode test: $displayCode');
                    return Column(
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Mode test',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                displayCode,
                                style: AppTypography.headline3.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  letterSpacing: 4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    print('⚠️ Aucun code OTP à afficher');
                    return const SizedBox.shrink();
                  }
                },
              ),
              
              SizedBox(height: keyboardHeight > 0 ? 20 : 32),
              
              // Champs de code
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < 5 ? 8 : 0,
                      ),
                      child: ListenableBuilder(
                        listenable: Listenable.merge([_focusNodes[index], _controllers[index]]),
                        builder: (context, _) {
                          final hasFocus = _focusNodes[index].hasFocus;
                          final hasValue = _controllers[index].text.isNotEmpty;
                          
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
        
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (value) {
                                setState(() {}); // Force rebuild pour afficher la valeur
                                _onCodeChanged(index, value);
                              },
                              onSubmitted: (_) {
                                if (index == 5) {
                                  _submitCode();
                                }
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: AppTypography.headline2.copyWith(
                                color: AppColors.textPrimaryLight,
                                fontSize: 26,
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
              
              const SizedBox(height: 32),
              
              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Vérifier',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Lien pour renvoyer le code
              TextButton(
                onPressed: _isLoading ? null : widget.onResend,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Renvoyer le code',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

