import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'edit_profile_field_screen.dart' show EditProfileFieldScreen, FieldType;

/// Écran KYC pour compléter les informations personnelles
class PersonalInfoKycScreen extends StatefulWidget {
  const PersonalInfoKycScreen({super.key});

  @override
  State<PersonalInfoKycScreen> createState() => _PersonalInfoKycScreenState();
}

class _PersonalInfoKycScreenState extends State<PersonalInfoKycScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfileStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Text('Informations personnelles'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              padding: EdgeInsets.all(AppSpacing.spacing4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.spacing3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  SizedBox(width: AppSpacing.spacing3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations personnelles',
                          style: AppTypography.headline4.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppSpacing.spacing1),
                        Text(
                          'Complétez vos informations de base',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.spacing4),

            // Liste des champs à compléter
            _buildInfoItem(
              icon: Icons.badge_outlined,
              label: 'Nom et prénom',
              value: authProvider.currentUser?.fullName ?? 'Non renseigné',
              fieldType: 'fullName',
              color: _getFieldColor(authProvider.currentUser?.fullName),
            ),

            SizedBox(height: AppSpacing.spacing2),

            _buildInfoItem(
              icon: Icons.cake_outlined,
              label: 'Date de naissance',
              value: 'Non renseigné',
              fieldType: 'birthDate',
              color: AppColors.error,
            ),

            SizedBox(height: AppSpacing.spacing2),

            _buildInfoItem(
              icon: Icons.flag_outlined,
              label: 'Nationalité',
              value: 'Non renseigné',
              fieldType: 'nationality',
              color: AppColors.error,
            ),

            SizedBox(height: AppSpacing.spacing2),

            _buildInfoItem(
              icon: Icons.work_outline,
              label: 'Profession',
              value: 'Non renseigné',
              fieldType: 'occupation',
              color: AppColors.error,
            ),

            SizedBox(height: AppSpacing.spacing2),

            _buildInfoItem(
              icon: Icons.business_outlined,
              label: 'Employeur',
              value: 'Non renseigné',
              fieldType: 'employer',
              color: AppColors.error,
            ),

            SizedBox(height: AppSpacing.spacing2),

            _buildInfoItem(
              icon: Icons.phone_outlined,
              label: 'Téléphone',
              value: authProvider.currentUser?.phone ?? 'Non renseigné',
              fieldType: 'phone',
              color: _getFieldColor(authProvider.currentUser?.phone),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFieldColor(dynamic value) {
    if (value == null || 
        value == 'Non renseigné' || 
        value.toString().trim().isEmpty ||
        (value is Map && value.isEmpty)) {
      return AppColors.error;
    }
    return AppColors.success;
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required String fieldType,
    required Color color,
  }) {
    final isCompleted = color == AppColors.success;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          FieldType enumFieldType = FieldType.text;
          if (fieldType == 'birthDate') enumFieldType = FieldType.date;
          else if (fieldType == 'phone') enumFieldType = FieldType.phone;
          else if (fieldType == 'fullName') enumFieldType = FieldType.email;
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfileFieldScreen(
                fieldKey: fieldType,
                label: label,
                fieldType: enumFieldType,
                initialValue: isCompleted ? value : null,
              ),
            ),
          ).then((_) {
            if (mounted) {
              context.read<ProfileProvider>().loadProfileStatus();
            }
          });
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.spacing3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.spacing2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 24),
              ),

              SizedBox(width: AppSpacing.spacing3),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isCompleted ? 'COMPLÉTÉ' : 'À COMPLÉTER',
                            style: AppTypography.bodyXSmall.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.spacing1),
                    Text(
                      value,
                      style: AppTypography.bodySmall.copyWith(
                        color: isCompleted 
                          ? AppColors.textPrimaryLight 
                          : AppColors.textSecondaryLight,
                        fontStyle: isCompleted ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                isCompleted ? Icons.check_circle : Icons.edit_outlined,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

