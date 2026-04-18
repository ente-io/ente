import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class FileIconConfig {
  final dynamic icon;
  final Color color;
  final Color backgroundColor;
  final Set<String> extensions;

  const FileIconConfig({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.extensions,
  });
}

class FileIconUtils {
  // Centralized configuration - change icons and colors here only
  static const Map<String, FileIconConfig> _fileTypeConfigs = {
    'pdf': FileIconConfig(
      extensions: {'.pdf'},
      icon: HugeIcons.strokeRoundedFile01,
      color: Color.fromRGBO(246, 58, 58, 1),
      backgroundColor: Color.fromRGBO(255, 58, 58, 0.06),
    ),
    'image': FileIconConfig(
      extensions: {'.jpg', '.png', '.heic'},
      icon: HugeIcons.strokeRoundedImage01,
      color: Color.fromRGBO(8, 194, 37, 1),
      backgroundColor: Color.fromRGBO(8, 194, 37, 0.06),
    ),
    'presentation': FileIconConfig(
      extensions: {'.pptx'},
      icon: HugeIcons.strokeRoundedPresentation01,
      color: Color.fromRGBO(16, 113, 255, 1),
      backgroundColor: Color.fromRGBO(16, 113, 255, 0.06),
    ),
    'spreadsheet': FileIconConfig(
      extensions: {'.xlsx'},
      icon: HugeIcons.strokeRoundedTable01,
      color: Color(0xFF388E3C),
      backgroundColor: Color(0xFFE8F5E9),
    ),
  };

  static const FileIconConfig _defaultConfig = FileIconConfig(
    extensions: {},
    icon: HugeIcons.strokeRoundedFile02,
    color: Color(0xFF757575),
    backgroundColor: Color(0xFFFAFAFA),
  );

  static FileIconConfig _getFileConfig(String fileName) {
    final lowerFileName = fileName.toLowerCase();
    final lastDotIndex = lowerFileName.lastIndexOf('.');

    if (lastDotIndex == -1) {
      return _defaultConfig; // No extension found
    }

    final extension = lowerFileName.substring(lastDotIndex);

    for (final config in _fileTypeConfigs.values) {
      if (config.extensions.contains(extension)) {
        return config;
      }
    }

    return _defaultConfig;
  }

  static Widget getFileIcon(
    String fileName, {
    bool showBackground = true,
    double size = 24,
  }) {
    final config = _getFileConfig(fileName);

    final icon = HugeIcon(
      icon: config.icon,
      color: config.color,
      size: size,
    );

    if (!showBackground) {
      return icon;
    }

    return Container(
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: icon,
      ),
    );
  }

  Color getFileIconColor(String fileName) {
    return _getFileConfig(fileName).color;
  }

  Color getFileIconBackgroundColor(String fileName) {
    return _getFileConfig(fileName).backgroundColor;
  }
}
