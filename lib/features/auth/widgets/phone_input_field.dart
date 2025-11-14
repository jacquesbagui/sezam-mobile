import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Champ de saisie téléphone avec indicatif international
class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;
  final FormFieldValidator<String> validator;
  final bool isDark;
  final ValueChanged<String>? onChanged;

  const PhoneInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.validator,
    required this.isDark,
    this.onChanged,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  String _selectedCountryCode = '+33';
  String _selectedCountryFlag = '🇫🇷';

  final List<Map<String, String>> _countries = [
    {'code': '+33', 'flag': '🇫🇷', 'name': 'France'},
    {'code': '+32', 'flag': '🇧🇪', 'name': 'Belgique'},
    {'code': '+41', 'flag': '🇨🇭', 'name': 'Suisse'},
    {'code': '+49', 'flag': '🇩🇪', 'name': 'Allemagne'},
    {'code': '+34', 'flag': '🇪🇸', 'name': 'Espagne'},
    {'code': '+39', 'flag': '🇮🇹', 'name': 'Italie'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'Royaume-Uni'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'États-Unis'},
    {'code': '+1', 'flag': '🇨🇦', 'name': 'Canada'},
    {'code': '+52', 'flag': '🇲🇽', 'name': 'Mexique'},
    {'code': '+51', 'flag': '🇵🇪', 'name': 'Pérou'},
    {'code': '+56', 'flag': '🇨🇱', 'name': 'Chili'},
    {'code': '+57', 'flag': '🇨🇴', 'name': 'Colombie'},
    {'code': '+58', 'flag': '🇻🇪', 'name': 'Vénézuela'},
    {'code': '+506', 'flag': '🇨🇷', 'name': 'Costa Rica'},
    {'code': '+507', 'flag': '🇵🇦', 'name': 'Panama'},
    {'code': '+508', 'flag': '🇵🇷', 'name': 'Porto Rico'},
    {'code': '+509', 'flag': '🇭🇹', 'name': 'Haïti'},
    {'code': '+501', 'flag': '🇧🇿', 'name': 'Belize'},
    {'code': '+502', 'flag': '🇬🇹', 'name': 'Guatemala'},
    {'code': '+503', 'flag': '🇸🇻', 'name': 'El Salvador'},
    {'code': '+504', 'flag': '🇭🇳', 'name': 'Honduras'},
    {'code': '+505', 'flag': '🇳🇮', 'name': 'Nicaragua'},
    {'code': '+506', 'flag': '🇸🇦', 'name': 'Arabie Saoudite'},
    
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.gray800 : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: widget.isDark ? AppColors.gray600 : AppColors.gray300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Indicatif pays
          GestureDetector(
            onTap: _showCountryPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing3,
                vertical: AppSpacing.spacing4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusMd),
                  bottomLeft: Radius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedCountryFlag,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: AppSpacing.spacing2),
                  Text(
                    _selectedCountryCode,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacing1),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          // Champ de saisie numéro
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => widget.onSubmitted(),
              onChanged: (value) {
                widget.onChanged?.call('$_selectedCountryCode${value.trim()}');
              },
              validator: widget.validator,
              style: AppTypography.bodyMedium.copyWith(
                color: widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: '6 12 34 56 78',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing4,
                  vertical: AppSpacing.spacing4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDark ? AppColors.gray900 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(AppSpacing.spacing6),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.gray600 : AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing4),
            
            // Title
            Text(
              'Sélectionner un pays',
              style: AppTypography.headline3.copyWith(
                color: widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing4),
            
            // Search field
            TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un pays...',
                prefixIcon: Icon(
                  Icons.search,
                  color: widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                filled: true,
                fillColor: widget.isDark ? AppColors.gray800 : AppColors.gray100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing4,
                  vertical: AppSpacing.spacing3,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing4),
            
            // Countries list
            Expanded(
              child: ListView.builder(
                itemCount: _countries.length,
                itemBuilder: (context, index) {
                  final country = _countries[index];
                  final isSelected = country['code'] == _selectedCountryCode;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCountryCode = country['code']!;
                        _selectedCountryFlag = country['flag']!;
                      });
                      // Propagate combined value when country changes
                      widget.onChanged?.call('$_selectedCountryCode${widget.controller.text.trim()}');
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacing4,
                        vertical: AppSpacing.spacing3,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: isSelected 
                            ? Border.all(color: AppColors.primary, width: 1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(country['flag']!, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: AppSpacing.spacing3),
                          Expanded(
                            child: Text(
                              country['name']!,
                              style: AppTypography.bodyMedium.copyWith(
                                color: widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          Text(
                            country['code']!,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
