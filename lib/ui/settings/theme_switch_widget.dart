import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

class ThemeSwitchWidget extends StatelessWidget {
  const ThemeSwitchWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var selectedTheme = 0;
    if (Theme.of(context).brightness == Brightness.dark) {
      selectedTheme = 1;
    }
    return AnimatedToggleSwitch<int>.rolling(
      current: selectedTheme,
      values: const [0, 1],
      onChanged: (i) {
        debugPrint("Changed to {i}, selectedTheme is {selectedTheme} ");
        if (i == 0) {
          AdaptiveTheme.of(context).setLight();
        } else {
          AdaptiveTheme.of(context).setDark();
        }
      },
      iconBuilder: (i, size, foreground) {
        final color = selectedTheme == i
            ? Theme.of(context).colorScheme.themeSwitchActiveIconColor
            : Theme.of(context).colorScheme.themeSwitchInactiveIconColor;
        if (i == 0) {
          return Icon(
            Icons.light_mode,
            color: color,
          );
        } else {
          return Icon(
            Icons.dark_mode,
            color: color,
          );
        }
      },
      height: 36,
      indicatorSize: Size(36, 36),
      indicatorColor: Theme.of(context).colorScheme.themeSwitchIndicatorColor,
      borderColor: Theme.of(context)
          .colorScheme
          .themeSwitchInactiveIconColor
          .withOpacity(0.1),
      borderWidth: 1,
    );
  }
}
