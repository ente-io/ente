import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:photos/service_locator.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/notification/toast.dart';

class LocalThumbnailConfigScreen extends StatefulWidget {
  const LocalThumbnailConfigScreen({super.key});

  @override
  State<LocalThumbnailConfigScreen> createState() =>
      _LocalThumbnailConfigScreenState();
}

class _LocalThumbnailConfigScreenState
    extends State<LocalThumbnailConfigScreen> {
  static final Logger _logger = Logger("LocalThumbnailConfigScreen");

  late TextEditingController _smallMaxConcurrentController;
  late TextEditingController _smallTimeoutController;
  late TextEditingController _smallMaxSizeController;
  late TextEditingController _largeMaxConcurrentController;
  late TextEditingController _largeTimeoutController;
  late TextEditingController _largeMaxSizeController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _smallMaxConcurrentController = TextEditingController(
      text: localSettings.smallQueueMaxConcurrent.toString(),
    );
    _smallTimeoutController = TextEditingController(
      text: localSettings.smallQueueTimeoutSeconds.toString(),
    );
    _smallMaxSizeController = TextEditingController(
      text: localSettings.smallQueueMaxSize.toString(),
    );
    _largeMaxConcurrentController = TextEditingController(
      text: localSettings.largeQueueMaxConcurrent.toString(),
    );
    _largeTimeoutController = TextEditingController(
      text: localSettings.largeQueueTimeoutSeconds.toString(),
    );
    _largeMaxSizeController = TextEditingController(
      text: localSettings.largeQueueMaxSize.toString(),
    );
  }

  @override
  void dispose() {
    _smallMaxConcurrentController.dispose();
    _smallTimeoutController.dispose();
    _smallMaxSizeController.dispose();
    _largeMaxConcurrentController.dispose();
    _largeTimeoutController.dispose();
    _largeMaxSizeController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    try {
      // Validate and save small queue settings
      final smallMaxConcurrent =
          int.tryParse(_smallMaxConcurrentController.text);
      final smallTimeout = int.tryParse(_smallTimeoutController.text);
      final smallMaxSize = int.tryParse(_smallMaxSizeController.text);

      // Validate and save large queue settings
      final largeMaxConcurrent =
          int.tryParse(_largeMaxConcurrentController.text);
      final largeTimeout = int.tryParse(_largeTimeoutController.text);
      final largeMaxSize = int.tryParse(_largeMaxSizeController.text);

      if (smallMaxConcurrent == null ||
          smallTimeout == null ||
          smallMaxSize == null ||
          largeMaxConcurrent == null ||
          largeTimeout == null ||
          largeMaxSize == null) {
        showShortToast(context, "Please enter valid numbers");
        return;
      }

      // Basic validation - just ensure positive numbers
      if (smallMaxConcurrent < 1 ||
          largeMaxConcurrent < 1 ||
          smallTimeout < 1 ||
          largeTimeout < 1 ||
          smallMaxSize < 1 ||
          largeMaxSize < 1) {
        showShortToast(
          context,
          "All values must be positive numbers",
        );
        return;
      }

      await localSettings.setSmallQueueMaxConcurrent(smallMaxConcurrent);
      await localSettings.setSmallQueueTimeout(smallTimeout);
      await localSettings.setSmallQueueMaxSize(smallMaxSize);
      await localSettings.setLargeQueueMaxConcurrent(largeMaxConcurrent);
      await localSettings.setLargeQueueTimeout(largeTimeout);
      await localSettings.setLargeQueueMaxSize(largeMaxSize);

      _logger.info(
        "Local thumbnail queue settings updated:\n"
        "Small Queue - MaxConcurrent: $smallMaxConcurrent, Timeout: ${smallTimeout}s, MaxSize: $smallMaxSize\n"
        "Large Queue - MaxConcurrent: $largeMaxConcurrent, Timeout: ${largeTimeout}s, MaxSize: $largeMaxSize",
      );

      if (mounted) {
        showShortToast(
          context,
          "Settings saved. Restart app to apply changes.",
        );
      }
    } catch (e) {
      showShortToast(context, "Error saving settings");
    }
  }

  Future<void> _resetToDefaults() async {
    await localSettings.resetThumbnailQueueSettings();
    setState(() {
      _smallMaxConcurrentController.text = "15";
      _smallTimeoutController.text = "60";
      _smallMaxSizeController.text = "200";
      _largeMaxConcurrentController.text = "5";
      _largeTimeoutController.text = "60";
      _largeMaxSizeController.text = "200";
    });

    _logger.info(
      "Local thumbnail queue settings reset to defaults:\n"
      "Small Queue - MaxConcurrent: 15, Timeout: 60s, MaxSize: 200\n"
      "Large Queue - MaxConcurrent: 5, Timeout: 60s, MaxSize: 200",
    );

    if (mounted) {
      showShortToast(
        context,
        "Reset to defaults. Restart app to apply changes.",
      );
    }
  }

  Widget _buildNumberField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: getEnteTextTheme(context).body.copyWith(
                  color: getEnteColorScheme(context).textMuted,
                ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: getEnteTextTheme(context).body.copyWith(
                    color: getEnteColorScheme(context).textFaint,
                  ),
              filled: true,
              fillColor: getEnteColorScheme(context).fillFaint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            style: getEnteTextTheme(context).body,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Scaffold(
      body: Container(
        color: colorScheme.backdropBase,
        child: SafeArea(
          child: Column(
            children: [
              const TitleBarTitleWidget(
                title: "Local Thumbnail Queue Config",
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Small Local Thumbnail Queue",
                        style: getEnteTextTheme(context).largeBold,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Used when gallery grid has 4 or more columns",
                        style: getEnteTextTheme(context).small.copyWith(
                              color: colorScheme.textMuted,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildNumberField(
                        label: "Max Concurrent Tasks",
                        hint: "Default: 15",
                        controller: _smallMaxConcurrentController,
                      ),
                      _buildNumberField(
                        label: "Timeout (seconds)",
                        hint: "Default: 60",
                        controller: _smallTimeoutController,
                      ),
                      _buildNumberField(
                        label: "Max Queue Size",
                        hint: "Default: 200",
                        controller: _smallMaxSizeController,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        "Large Local Thumbnail Queue",
                        style: getEnteTextTheme(context).largeBold,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Used when gallery grid has less than 4 columns",
                        style: getEnteTextTheme(context).small.copyWith(
                              color: colorScheme.textMuted,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildNumberField(
                        label: "Max Concurrent Tasks",
                        hint: "Default: 5",
                        controller: _largeMaxConcurrentController,
                      ),
                      _buildNumberField(
                        label: "Timeout (seconds)",
                        hint: "Default: 60",
                        controller: _largeTimeoutController,
                      ),
                      _buildNumberField(
                        label: "Max Queue Size",
                        hint: "Default: 200",
                        controller: _largeMaxSizeController,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary700,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Save Settings",
                            style: getEnteTextTheme(context).bodyBold.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _resetToDefaults,
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.primary700,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: colorScheme.strokeMuted,
                              ),
                            ),
                          ),
                          child: const Text(
                            "Reset to Defaults",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.fillFaint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: colorScheme.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Changes require app restart to take effect",
                                style: getEnteTextTheme(context).small.copyWith(
                                      color: colorScheme.textMuted,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
