import 'dart:convert';

import 'package:ente_auth/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:logging/logging.dart';

class IconUtils {
  IconUtils._privateConstructor();

  static final IconUtils instance = IconUtils._privateConstructor();

  // Map of icon-title to the color code in HEX
  final Map<String, String> _simpleIcons = {};
  final Map<String, CustomIconData> _customIcons = {};

  Future<void> init() async {
    await _loadJson();
  }

  Widget getIcon(
    BuildContext context,
    String provider, {
    double width = 24,
  }) {
    final title = _getProviderTitle(provider);
    if (_customIcons.containsKey(title)) {
      return _getSVGIcon(
        "assets/custom-icons/icons/${_customIcons[title]!.slug ?? title}.svg",
        title,
        _customIcons[title]!.color,
        width,
      );
    } else if (_simpleIcons.containsKey(title)) {
      return _getSVGIcon(
        "assets/simple-icons/icons/$title.svg",
        title,
        _simpleIcons[title],
        width,
      );
    } else if (title.isNotEmpty) {
      bool showLargeIcon = width > 24;
      return CircleAvatar(
        radius: width / 2,
        backgroundColor: getEnteColorScheme(context).avatarColors[
            title.hashCode % getEnteColorScheme(context).avatarColors.length],
        child: Text(
          title.toUpperCase()[0],
          // fixed color
          style: showLargeIcon
              ? getEnteTextTheme(context).h3Bold.copyWith(color: Colors.white)
              : getEnteTextTheme(context).body.copyWith(color: Colors.white),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _getSVGIcon(
    String path,
    String title,
    String? color,
    double width,
  ) {
    return SvgPicture.asset(
      path,
      width: width,
      semanticsLabel: title,
      colorFilter: color != null
          ? ColorFilter.mode(
              Color(int.parse("0xFF" + color)),
              BlendMode.srcIn,
            )
          : null,
    );
  }

  Future<void> _loadJson() async {
    try {
      final simpleIconData = await rootBundle
          .loadString('assets/simple-icons/_data/simple-icons.json');
      final simpleIcons = json.decode(simpleIconData);
      for (final icon in simpleIcons["icons"]) {
        _simpleIcons[icon["title"].toString().toLowerCase()] = icon["hex"];
      }
      final customIconData = await rootBundle
          .loadString('assets/custom-icons/_data/custom-icons.json');
      final customIcons = json.decode(customIconData);
      for (final icon in customIcons["icons"]) {
        _customIcons[icon["title"].toString().toLowerCase()] = CustomIconData(
          icon["slug"],
          icon["hex"],
        );
      }
    } catch (e) {
      Logger("IconUtils").severe("Error loading icons", e);
    }
  }

  String _getProviderTitle(String provider) {
    return provider.split(RegExp(r'[.(]'))[0].trim().toLowerCase();
  }
}

class CustomIconData {
  final String? slug;
  final String? color;

  CustomIconData(this.slug, this.color);
}
