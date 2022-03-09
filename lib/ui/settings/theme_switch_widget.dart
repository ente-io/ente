import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ThemeSwitchWidget extends StatelessWidget {
  const ThemeSwitchWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: true,
      activeColor: Colors.black,
      onChanged: (bool value) {
        print(value);
      },
      activeThumbImage: new NetworkImage(
          'https://cdn0.iconfinder.com/data/icons/multimedia-solid-30px/30/moon_dark_mode_night-512.png'),
      inactiveThumbImage: new NetworkImage(
          'https://cdn0.iconfinder.com/data/icons/multimedia-solid-30px/30/moon_dark_mode_night-512.png'),
    );
  }
}
