import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ThemeSwitchWidget extends StatelessWidget {
  const ThemeSwitchWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: Theme.of(context).colorScheme.onSurface == Colors.black,
      activeColor: Theme.of(context).colorScheme.onSurface,
      activeTrackColor: Theme.of(context).colorScheme.onBackground,
      inactiveTrackColor: Theme.of(context).colorScheme.onSurface,
      inactiveThumbColor: Theme.of(context).colorScheme.primary,
      hoverColor: Theme.of(context).colorScheme.onSurface,
      onChanged: (bool value) {
        if (value) {
          AdaptiveTheme.of(context).setLight();
        } else {
          AdaptiveTheme.of(context).setDark();
        }
      },
      // activeThumbImage: new NetworkImage(
      //     'https://cdn0.iconfinder.com/data/icons/multimedia-solid-30px/30/moon_dark_mode_night-512.png'),
      // inactiveThumbImage: new NetworkImage(
      //     'https://cdn0.iconfinder.com/data/icons/multimedia-solid-30px/30/moon_dark_mode_night-512.png'),
    );
  }
}
