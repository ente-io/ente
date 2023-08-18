import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';

class IconUtils {
  IconUtils._privateConstructor();

  static final IconUtils instance = IconUtils._privateConstructor();

  // Map of icon-title to the color code in HEX
  final Map<String, String> _simpleIcons = {};
  final Map<String, String> _customIcons = {};

  Future<void> init() async {
    await _loadJson();
  }

  Widget getIcon(String provider) {
    final title = _getProviderTitle(provider);
    if (_simpleIcons.containsKey(title)) {
      return _getSVGIcon(
        "assets/simple-icons/icons/$title.svg",
        title,
        _simpleIcons[title]!,
      );
    } else if (_customIcons.containsKey(title)) {
      return _getSVGIcon(
        "assets/custom-icons/icons/$title.svg",
        title,
        _customIcons[title]!,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _getSVGIcon(String path, String title, String color) {
    return SvgPicture.asset(
      path,
      width: 24,
      semanticsLabel: title,
      colorFilter: ColorFilter.mode(
        Color(int.parse("0xFF" + color)),
        BlendMode.srcIn,
      ),
    );
  }

  Future<void> _loadJson() async {
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
      _customIcons[icon["title"].toString().toLowerCase()] = icon["hex"];
    }
  }

  String _getProviderTitle(String provider) {
    return provider.split(".")[0].toLowerCase();
  }
}
