import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Champ de saisie téléphone avec indicatif international
class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;
  final FormFieldValidator<String> validator;  final ValueChanged<String>? onChanged;

  const PhoneInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.validator,
    this.onChanged,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  String _selectedCountryCode = '+225';
  String _selectedCountryFlag = '🇨🇮';

  final List<Map<String, String>> _countries = [
    // Côte d'Ivoire (par défaut)
    {'code': '+225', 'flag': '🇨🇮', 'name': 'Côte d\'Ivoire'},
    
    // Afrique de l'Ouest
    {'code': '+221', 'flag': '🇸🇳', 'name': 'Sénégal'},
    {'code': '+223', 'flag': '🇲🇱', 'name': 'Mali'},
    {'code': '+226', 'flag': '🇧🇫', 'name': 'Burkina Faso'},
    {'code': '+227', 'flag': '🇳🇪', 'name': 'Niger'},
    {'code': '+228', 'flag': '🇹🇬', 'name': 'Togo'},
    {'code': '+229', 'flag': '🇧🇯', 'name': 'Bénin'},
    {'code': '+230', 'flag': '🇲🇺', 'name': 'Maurice'},
    {'code': '+231', 'flag': '🇱🇷', 'name': 'Liberia'},
    {'code': '+232', 'flag': '🇸🇱', 'name': 'Sierra Leone'},
    {'code': '+233', 'flag': '🇬🇭', 'name': 'Ghana'},
    {'code': '+234', 'flag': '🇳🇬', 'name': 'Nigeria'},
    {'code': '+235', 'flag': '🇹🇩', 'name': 'Tchad'},
    {'code': '+236', 'flag': '🇨🇫', 'name': 'République centrafricaine'},
    {'code': '+237', 'flag': '🇨🇲', 'name': 'Cameroun'},
    {'code': '+238', 'flag': '🇨🇻', 'name': 'Cap-Vert'},
    {'code': '+239', 'flag': '🇸🇹', 'name': 'São Tomé-et-Príncipe'},
    {'code': '+240', 'flag': '🇬🇶', 'name': 'Guinée équatoriale'},
    {'code': '+241', 'flag': '🇬🇦', 'name': 'Gabon'},
    {'code': '+242', 'flag': '🇨🇬', 'name': 'République du Congo'},
    {'code': '+243', 'flag': '🇨🇩', 'name': 'RD Congo'},
    {'code': '+244', 'flag': '🇦🇴', 'name': 'Angola'},
    {'code': '+245', 'flag': '🇬🇼', 'name': 'Guinée-Bissau'},
    {'code': '+246', 'flag': '🇮🇴', 'name': 'Territoire britannique de l\'océan Indien'},
    {'code': '+247', 'flag': '🇦🇨', 'name': 'Ascension'},
    {'code': '+248', 'flag': '🇸🇨', 'name': 'Seychelles'},
    {'code': '+249', 'flag': '🇸🇩', 'name': 'Soudan'},
    {'code': '+250', 'flag': '🇷🇼', 'name': 'Rwanda'},
    {'code': '+251', 'flag': '🇪🇹', 'name': 'Éthiopie'},
    {'code': '+252', 'flag': '🇸🇴', 'name': 'Somalie'},
    {'code': '+253', 'flag': '🇩🇯', 'name': 'Djibouti'},
    {'code': '+254', 'flag': '🇰🇪', 'name': 'Kenya'},
    {'code': '+255', 'flag': '🇹🇿', 'name': 'Tanzanie'},
    {'code': '+256', 'flag': '🇺🇬', 'name': 'Ouganda'},
    {'code': '+257', 'flag': '🇧🇮', 'name': 'Burundi'},
    {'code': '+258', 'flag': '🇲🇿', 'name': 'Mozambique'},
    {'code': '+260', 'flag': '🇿🇲', 'name': 'Zambie'},
    {'code': '+261', 'flag': '🇲🇬', 'name': 'Madagascar'},
    {'code': '+262', 'flag': '🇷🇪', 'name': 'La Réunion'},
    {'code': '+263', 'flag': '🇿🇼', 'name': 'Zimbabwe'},
    {'code': '+264', 'flag': '🇳🇦', 'name': 'Namibie'},
    {'code': '+265', 'flag': '🇲🇼', 'name': 'Malawi'},
    {'code': '+266', 'flag': '🇱🇸', 'name': 'Lesotho'},
    {'code': '+267', 'flag': '🇧🇼', 'name': 'Botswana'},
    {'code': '+268', 'flag': '🇸🇿', 'name': 'Eswatini'},
    {'code': '+269', 'flag': '🇰🇲', 'name': 'Comores'},
    {'code': '+290', 'flag': '🇸🇭', 'name': 'Sainte-Hélène'},
    {'code': '+291', 'flag': '🇪🇷', 'name': 'Érythrée'},
    {'code': '+297', 'flag': '🇦🇼', 'name': 'Aruba'},
    {'code': '+298', 'flag': '🇫🇴', 'name': 'Îles Féroé'},
    {'code': '+299', 'flag': '🇬🇱', 'name': 'Groenland'},
    
    // Afrique du Nord
    {'code': '+212', 'flag': '🇲🇦', 'name': 'Maroc'},
    {'code': '+213', 'flag': '🇩🇿', 'name': 'Algérie'},
    {'code': '+216', 'flag': '🇹🇳', 'name': 'Tunisie'},
    {'code': '+218', 'flag': '🇱🇾', 'name': 'Libye'},
    {'code': '+20', 'flag': '🇪🇬', 'name': 'Égypte'},
    
    // Afrique du Sud
    {'code': '+27', 'flag': '🇿🇦', 'name': 'Afrique du Sud'},
    
    // Guinée
    {'code': '+224', 'flag': '🇬🇳', 'name': 'Guinée'},
    
    // Mauritanie
    {'code': '+222', 'flag': '🇲🇷', 'name': 'Mauritanie'},
    
    // Gambie
    {'code': '+220', 'flag': '🇬🇲', 'name': 'Gambie'},
    
    // Autres pays (optionnels pour compléter)
    {'code': '+33', 'flag': '🇫🇷', 'name': 'France'},
    {'code': '+32', 'flag': '🇧🇪', 'name': 'Belgique'},
    {'code': '+44', 'flag': '🇬🇧', 'name': 'Royaume-Uni'},
    {'code': '+1', 'flag': '🇺🇸', 'name': 'États-Unis'},
    {'code': '+1', 'flag': '🇨🇦', 'name': 'Canada'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.gray300,
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
                color: AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: '6 12 34 56 78',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
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
      backgroundColor: Colors.white,
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
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing4),
            
            // Title
            Text(
              'Sélectionner un pays',
              style: AppTypography.headline3.copyWith(
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing4),
            
            // Search field
            TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un pays...',
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textSecondaryLight,
                ),
                filled: true,
                fillColor: AppColors.gray100,
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
                                color: AppColors.textPrimaryLight,
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
