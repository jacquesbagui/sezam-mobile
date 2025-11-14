import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/reference_service.dart';
import '../../core/services/app_event_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Enum pour les types de champs
enum FieldType { text, email, phone, date, select }

/// Écran pour éditer un champ de profil spécifique
class EditProfileFieldScreen extends StatefulWidget {
  final String fieldKey;
  final String label;
  final String? initialValue;
  final FieldType fieldType;
  final List<String>? options;

  const EditProfileFieldScreen({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.fieldType,
    this.initialValue,
    this.options,
  });

  @override
  State<EditProfileFieldScreen> createState() => _EditProfileFieldScreenState();
}

class _EditProfileFieldScreenState extends State<EditProfileFieldScreen> {
  late TextEditingController _controller;
  DateTime? _selectedDate;
  bool _isSaving = false;
  
  // Phone country code state
  String _dialCode = '+225';
  String _countryFlag = '🇨🇮';
  late final List<Map<String, String>> _countries;
  String? _selectedOptionId;
  List<Map<String, String>> _selectOptions = const [];
  bool _loadingOptions = false; // reserved for future loading states (kept minimal)
  
  Future<void> _openSelectSheet(List<String> options) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(AppSpacing.spacing4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sélectionner ${widget.label.toLowerCase()}',
                        style: AppTypography.headline4.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.gray200),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.gray200),
                  itemBuilder: (context, index) {
                    final opt = options[index];
                    final isSelected = _controller.text.trim() == opt;
                    return ListTile(
                      title: Text(opt),
                      trailing: isSelected ? Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () => Navigator.pop(context, opt),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      setState(() {
        // Mettre à jour l'id sélectionné si disponible
        final match = _selectOptions.firstWhere(
          (e) => (e['name'] ?? '') == selected,
          orElse: () => {},
        );
        _selectedOptionId = match['id'];
        // Pour country/nationality, stocker l'id dans le controller
        if (widget.fieldKey == 'country' || widget.fieldKey == 'nationality') {
          _controller.text = _selectedOptionId ?? '';
        } else {
          _controller.text = selected;
        }
      });
    }
  }

  Future<void> _loadSelectOptions() async {
    setState(() => _loadingOptions = true);
    try {
      final ref = ReferenceService();
      if (widget.fieldKey == 'nationality') {
        final list = await ref.getNationalities();
        _selectOptions = list
            .map((n) => {
                  'id': n.id,
                  'name': n.name,
                })
            .toList();
      } else if (widget.fieldKey == 'country') {
        _selectOptions = await ref.getCountries();
      }

      // Préselection par valeur initiale
      if ((widget.initialValue ?? '').isNotEmpty) {
        final match = _selectOptions.firstWhere(
          (e) => (e['name'] ?? '').toLowerCase() == widget.initialValue!.toLowerCase(),
          orElse: () => {},
        );
        _selectedOptionId = match['id'];
      }
      setState(() {});
    } catch (e) {
      // Could log or show a toast
    } finally {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  Future<void> _openCountryPicker() async {
    final List<Map<String, String>> countries = _countries;

    final picked = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(AppSpacing.spacing4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sélectionner un indicatif',
                        style: AppTypography.headline4.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.gray200),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: countries.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.gray200),
                  itemBuilder: (context, index) {
                    final c = countries[index];
                    final isSelected = _dialCode == c['code'];
                    return ListTile(
                      leading: Text(c['flag'] ?? '', style: TextStyle(fontSize: 20)),
                      title: Text(c['name'] ?? ''),
                      subtitle: Text(c['code'] ?? ''),
                      trailing: isSelected ? Icon(Icons.check, color: AppColors.primary) : null,
                      onTap: () => Navigator.pop(context, c),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dialCode = picked['code'] ?? _dialCode;
        _countryFlag = picked['flag'] ?? _countryFlag;
      });
    }
  }

  void _initPhoneFromInitial() {
    final raw = widget.initialValue ?? '';
    if (raw.isEmpty) return;
    // Keep only digits for parsing
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return;

    // Sort country codes by length desc to prefer longest match
    final codes = _countries
        .map((c) => c['code'] ?? '')
        .where((c) => c.isNotEmpty)
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    String? matchedCode;
    for (final code in codes) {
      final codeDigits = code.replaceAll('+', '');
      if (digitsOnly.startsWith(codeDigits)) {
        matchedCode = code;
        break;
      }
    }

    if (matchedCode != null) {
      final codeDigits = matchedCode.replaceAll('+', '');
      final national = digitsOnly.substring(codeDigits.length);
      final country = _countries.firstWhere(
        (c) => c['code'] == matchedCode,
        orElse: () => {'flag': _countryFlag, 'code': _dialCode},
      );
      _dialCode = country['code'] ?? _dialCode;
      _countryFlag = country['flag'] ?? _countryFlag;
      _controller.text = national;
    } else {
      // No country code detected, just set digits
      _controller.text = digitsOnly;
    }
  }

  @override
  void initState() {
    super.initState();
    _countries = <Map<String, String>>[
      {'name': 'Côte d\'Ivoire', 'code': '+225', 'flag': '🇨🇮'},
      {'name': 'France', 'code': '+33', 'flag': '🇫🇷'},
      {'name': 'Belgique', 'code': '+32', 'flag': '🇧🇪'},
      {'name': 'Sénégal', 'code': '+221', 'flag': '🇸🇳'},
      {'name': 'Mali', 'code': '+223', 'flag': '🇲🇱'},
      {'name': 'Cameroun', 'code': '+237', 'flag': '🇨🇲'},
      {'name': 'Maroc', 'code': '+212', 'flag': '🇲🇦'},
      {'name': 'Tunisie', 'code': '+216', 'flag': '🇹🇳'},
      {'name': 'Canada', 'code': '+1', 'flag': '🇨🇦'},
      {'name': 'Royaume-Uni', 'code': '+44', 'flag': '🇬🇧'},
    ];
    _controller = TextEditingController(text: widget.initialValue);
    if (widget.fieldType == FieldType.phone) {
      _initPhoneFromInitial();
    }
    if (widget.fieldType == FieldType.select) {
      // Charger les options au démarrage
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSelectOptions();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _controller.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _saveField() async {
    if (!_validateField()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profileProvider = context.read<ProfileProvider>();
      final profileService = ProfileService();
      final payload = profileService.buildUpdatePayload(
        fieldKey: widget.fieldKey,
        text: _controller.text,
        selectedDate: _selectedDate,
        selectedId: _selectedOptionId,
      );

      final ok = await profileProvider.updateProfile(payload);
      if (!ok) {
        throw Exception(profileProvider.error ?? 'Échec de la mise à jour');
      }

      // Émettre un événement pour déclencher le rafraîchissement
      AppEventService.instance.emit(AppEventType.profileUpdated);

      if (mounted) {
        /*ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Champ mis à jour avec succès'),
            backgroundColor: AppColors.success,
          ),
        );*/
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  bool _validateField() {
    if (_controller.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ce champ est obligatoire'),
          backgroundColor: AppColors.error,
        ),
      );
      return false;
      }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDateField = widget.fieldType == FieldType.date;
    final isSelectField = widget.fieldType == FieldType.select;
    final List<String> selectOptions = widget.options ?? _selectOptions.map((e) => e['name'] ?? '').toList();

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Text('Modifier ${widget.label}'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.spacing4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.label,
                    style: AppTypography.headline4.copyWith(
                      fontWeight: FontWeight.bold,
                              ),
                            ),
                  SizedBox(height: AppSpacing.spacing2),
                            Text(
                    'Modifiez cette information ci-dessous',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),

            SizedBox(height: AppSpacing.spacing4),

            // Champ de saisie
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.spacing4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.gray200),
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
                  
                  if (isDateField)
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          hintText: 'Sélectionner une date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _controller.text.isEmpty 
                            ? 'Sélectionner une date' 
                            : _controller.text,
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    )
                  else if (isSelectField)
                    InkWell(
                      onTap: () async {
                        // Si des options sont fournies (ex: occupation), les utiliser directement
                        if (widget.options != null && widget.options!.isNotEmpty) {
                          await _openSelectSheet(widget.options!);
                          return;
                        }
                        // Sinon charger depuis backend (nationality/country)
                        if (_selectOptions.isEmpty) {
                          await _loadSelectOptions();
                        }
                        if (_selectOptions.isNotEmpty) {
                          await _openSelectSheet(_selectOptions.map((e) => e['name'] ?? '').toList());
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          hintText: 'Sélectionner ${widget.label.toLowerCase()}',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        child: Builder(builder: (context) {
                          if (_loadingOptions) {
                            return Text(
                              'Chargement...',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            );
                          }
                          String display = _controller.text;
                          if ((widget.fieldKey == 'country' || widget.fieldKey == 'nationality') && _selectedOptionId != null) {
                            final match = _selectOptions.firstWhere(
                              (e) => e['id'] == _selectedOptionId,
                              orElse: () => {},
                            );
                            display = (match['name'] ?? '').isNotEmpty ? match['name']! : display;
                          }
                          if (display.isEmpty) {
                            display = 'Sélectionner ${widget.label.toLowerCase()}';
                          }
                          return Text(
                            display,
                            style: AppTypography.bodyMedium,
                          );
                        }),
                      ),
                    )
                  else
                    (widget.fieldType == FieldType.phone)
                      ? Row(
                          children: [
                            InkWell(
                              onTap: _openCountryPicker,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.spacing3,
                                  vertical: AppSpacing.spacing3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gray100,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  border: Border.all(color: AppColors.gray200),
                                ),
                                child: Row(
                                  children: [
                                    Text(_countryFlag),
                                    SizedBox(width: AppSpacing.spacing2),
                                    Text(
                                      _dialCode,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: AppSpacing.spacing1),
                                    Icon(Icons.arrow_drop_down, color: AppColors.gray500),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: AppSpacing.spacing2),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                decoration: InputDecoration(
                                  hintText: 'Numéro de téléphone',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  ),
                                  counterText: '',
                                ),
                                keyboardType: TextInputType.phone,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                            ),
                          ],
                        )
                      : TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Entrez ${widget.label.toLowerCase()}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                          ),
                          keyboardType: TextInputType.text,
                        ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.spacing6),

            // Bouton de sauvegarde
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveField,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('Enregistrer'),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
