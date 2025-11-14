import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sezam/core/theme/app_colors.dart';
import 'package:sezam/core/theme/app_typography.dart';
import 'package:sezam/core/theme/app_spacing.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanning = false;
  String? _scannedData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Scanner QR Code',
          style: AppTypography.headline4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildScannerView(),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }

  /// Vue du scanner QR
  Widget _buildScannerView() {
    return Stack(
      children: [
        // Zone de scan simulée
        Container(
          margin: const EdgeInsets.all(AppSpacing.spacing6),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: _isScanning ? AppColors.primary : Colors.grey[700]!,
              width: 2,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 120,
                  color: _isScanning ? AppColors.primary : Colors.grey[600],
                ),
                const SizedBox(height: AppSpacing.spacing4),
                Text(
                  _isScanning ? 'Scan en cours...' : 'Positionnez le QR code ici',
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_scannedData != null) ...[
                  const SizedBox(height: AppSpacing.spacing4),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.spacing3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Text(
                      'Données scannées: $_scannedData',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        // Cadre de scan (corners)
        ..._buildScanCorners(),
        
        // Instructions
        Positioned(
          top: AppSpacing.spacing8,
          left: AppSpacing.spacing6,
          right: AppSpacing.spacing6,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.spacing3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              'Scannez un QR code pour connecter une organisation ou accéder à un service',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  /// Corners du cadre de scan
  List<Widget> _buildScanCorners() {
    const cornerSize = 30.0;
    const cornerWidth = 3.0;
    
    return [
      // Top-left corner
      Positioned(
        top: AppSpacing.spacing6 + 50,
        left: AppSpacing.spacing6 + 50,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.primary, width: cornerWidth),
              left: BorderSide(color: AppColors.primary, width: cornerWidth),
            ),
          ),
        ),
      ),
      // Top-right corner
      Positioned(
        top: AppSpacing.spacing6 + 50,
        right: AppSpacing.spacing6 + 50,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.primary, width: cornerWidth),
              right: BorderSide(color: AppColors.primary, width: cornerWidth),
            ),
          ),
        ),
      ),
      // Bottom-left corner
      Positioned(
        bottom: AppSpacing.spacing6 + 150,
        left: AppSpacing.spacing6 + 50,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.primary, width: cornerWidth),
              left: BorderSide(color: AppColors.primary, width: cornerWidth),
            ),
          ),
        ),
      ),
      // Bottom-right corner
      Positioned(
        bottom: AppSpacing.spacing6 + 150,
        right: AppSpacing.spacing6 + 50,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.primary, width: cornerWidth),
              right: BorderSide(color: AppColors.primary, width: cornerWidth),
            ),
          ),
        ),
      ),
    ];
  }

  /// Contrôles du bas
  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.spacing6,
        right: AppSpacing.spacing6,
        top: AppSpacing.spacing4,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.spacing6,
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          if (_scannedData != null) ...[
            _buildScannedDataActions(),
            const SizedBox(height: AppSpacing.spacing4),
          ],
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? _stopScanning : _startScanning,
                  icon: Icon(_isScanning ? Icons.stop : Icons.play_arrow),
                  label: Text(_isScanning ? 'Arrêter' : 'Commencer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isScanning ? AppColors.error : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacing3),
              IconButton(
                onPressed: _toggleFlashlight,
                icon: Icon(
                  Icons.flashlight_on,
                  color: Colors.white,
                  size: 28,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  padding: const EdgeInsets.all(AppSpacing.spacing3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Actions pour les données scannées
  Widget _buildScannedDataActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _copyScannedData,
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copier'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.grey[600]!),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing3),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.spacing3),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _processScannedData,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Traiter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing3),
            ),
          ),
        ),
      ],
    );
  }

  /// Démarrer le scan
  void _startScanning() {
    setState(() {
      _isScanning = true;
      _scannedData = null;
    });
    
    // Simulation du scan
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isScanning) {
        setState(() {
          _scannedData = 'https://sezam.sn/connect/orange-money';
          _isScanning = false;
        });
        
        // Vibration haptique
        HapticFeedback.mediumImpact();
      }
    });
  }

  /// Arrêter le scan
  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
  }

  /// Basculer la lampe de poche
  void _toggleFlashlight() {
    // TODO: Implémenter le contrôle de la lampe de poche
    HapticFeedback.lightImpact();
  }

  /// Copier les données scannées
  void _copyScannedData() {
    if (_scannedData != null) {
      Clipboard.setData(ClipboardData(text: _scannedData!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Données copiées dans le presse-papiers'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  /// Traiter les données scannées
  void _processScannedData() {
    if (_scannedData != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connexion détectée'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Organisation: Orange Money'),
              const SizedBox(height: AppSpacing.spacing2),
              const Text('Type: Connexion financière'),
              const SizedBox(height: AppSpacing.spacing2),
              const Text('Voulez-vous autoriser cette connexion ?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, {'connected': true, 'organization': 'Orange Money'});
              },
              child: const Text('Autoriser'),
            ),
          ],
        ),
      );
    }
  }
}
