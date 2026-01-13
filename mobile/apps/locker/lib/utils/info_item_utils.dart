import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:locker/models/info/info_item.dart';

class InfoIconConfig {
  final dynamic icon;
  final Color color;
  final Color backgroundColor;

  const InfoIconConfig({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });
}

class InfoItemUtils {
  // Centralized configuration - change icons and colors here only
  static const Map<InfoType, InfoIconConfig> _infoTypeConfigs = {
    InfoType.note: InfoIconConfig(
      icon: HugeIcons.strokeRoundedNote,
      color: Color.fromRGBO(255, 152, 0, 1),
      backgroundColor: Color.fromRGBO(255, 152, 0, 0.06),
    ),
    InfoType.physicalRecord: InfoIconConfig(
      icon: HugeIcons.strokeRoundedBriefcase01,
      color: Color.fromRGBO(156, 39, 176, 1),
      backgroundColor: Color.fromRGBO(156, 39, 176, 0.06),
    ),
    InfoType.accountCredential: InfoIconConfig(
      icon: HugeIcons.strokeRoundedLockPassword,
      color: Color.fromRGBO(16, 113, 255, 1),
      backgroundColor: Color.fromRGBO(16, 113, 255, 0.06),
    ),
    InfoType.emergencyContact: InfoIconConfig(
      icon: HugeIcons.strokeRoundedContactBook,
      color: Color.fromRGBO(244, 67, 54, 1),
      backgroundColor: Color.fromRGBO(244, 67, 54, 0.06),
    ),
  };

  static InfoIconConfig _getInfoConfig(InfoType type) {
    return _infoTypeConfigs[type] ?? _infoTypeConfigs[InfoType.note]!;
  }

  static Widget getInfoIcon(
    InfoType type, {
    bool showBackground = true,
    double size = 24,
  }) {
    final config = _getInfoConfig(type);

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
}
