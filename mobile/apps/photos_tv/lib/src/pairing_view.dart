import 'package:flutter/material.dart';
import 'package:photos_tv/src/loading_widget.dart';

/// Pairing screen for entering TV code in Ente Photos.
class PairingView extends StatelessWidget {
  final String? pairingCode;
  final String? error;
  final VoidCallback onRetry;

  /// Creates pairing view.
  const PairingView({
    super.key,
    required this.pairingCode,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ente',
                style: TextStyle(fontSize: 52, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 32),
              const Text(
                'Enter this code on Ente Photos to pair this screen',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: _pairingCodeHeight,
                child: pairingCode == null
                    ? const EnteLoadingWidget(size: 24)
                    : _PairingCode(code: pairingCode!),
              ),
              const SizedBox(height: 24),
              if (error != null)
                TextButton(onPressed: onRetry, child: Text('Retry: $error'))
              else
                const Text('Visit ente.com/cast for help'),
            ],
          ),
        ),
      ),
    );
  }
}

class _PairingCode extends StatelessWidget {
  final String code;

  const _PairingCode({required this.code});

  @override
  Widget build(BuildContext context) {
    final characters = code.characters.toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Wrap(
        alignment: WrapAlignment.center,
        children: List.generate(characters.length, (index) {
          final character = characters[index];
          final backgroundColor = index.isEven
              ? _pairingCodeDarkBackground
              : _pairingCodeLightBackground;
          final foregroundColor =
              _pairingCodeColors[index % _pairingCodeColors.length];
          return Container(
            width: 80,
            height: _pairingCodeHeight,
            alignment: Alignment.center,
            color: backgroundColor,
            child: Text(
              character,
              style: TextStyle(
                color: foregroundColor,
                fontFamily: 'monospace',
                fontSize: 64,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          );
        }),
      ),
    );
  }
}

const _pairingCodeHeight = 92.0;
const _pairingCodeDarkBackground = Color(0xFF2E2E2E);
const _pairingCodeLightBackground = Color(0xFF5E5E5E);
const _pairingCodeColors = [
  Color(0xFF87CEFA),
  Color(0xFF90EE90),
  Color(0xFFF08080),
  Color(0xFFFFFFE0),
  Color(0xFFFFB6C1),
  Color(0xFFE0FFFF),
  Color(0xFFFAFAD2),
  Color(0xFF87CEFA),
  Color(0xFFD3D3D3),
  Color(0xFFB0C4DE),
  Color(0xFFFFA07A),
  Color(0xFF20B2AA),
  Color(0xFF778899),
  Color(0xFFAFEEEE),
  Color(0xFF7A58C1),
  Color(0xFFFFA500),
  Color(0xFFA0522D),
  Color(0xFF9370DB),
  Color(0xFF008080),
  Color(0xFF808000),
];
