import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:logging/logging.dart';

class IconUtils {
  IconUtils._privateConstructor();

  static final IconUtils instance = IconUtils._privateConstructor();

  final Map<String, String> _simpleIcons = {};

  Future<void> init() async {
    await _loadJson();
  }

  Widget getIcon(String provider) {
    final title = _getProviderTitle(provider);
    if (_simpleIcons.containsKey(title)) {
      return SvgPicture.asset(
        _getIconPath(provider),
        semanticsLabel: title,
        colorFilter: ColorFilter.mode(
          Color(int.parse("0xFF" + _simpleIcons[title]!)),
          BlendMode.srcIn,
        ),
      );
    } else {
      return Text(title);
    }
  }

  Future<void> _loadJson() async {
    final data = await rootBundle
        .loadString('assets/simple-icons/_data/simple-icons.json');
    final result = json.decode(data);
    Logger("IconUtils").info(result["icons"].length);
    for (final icon in result["icons"]) {
      _simpleIcons[icon["title"].toString().toLowerCase()] = icon["hex"];
    }
    Logger("IconUtils").info(_simpleIcons);
  }

  String _getIconPath(String provider) {
    final title = _getProviderTitle(provider);
    return "assets/simple-icons/icons/$title.svg";
  }

  String _getProviderTitle(String provider) {
    return provider.split(".")[0].toLowerCase();
  }
}
