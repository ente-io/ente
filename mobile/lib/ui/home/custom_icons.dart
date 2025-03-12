import 'package:flutter_app_icon_changer/flutter_app_icon_changer.dart';

class CustomIcons {
  /// A list of all available [CustomIcon] instances.
  static final List<CustomIcon> list = [
    IconLight(),
    IconDark(),
    IconGreen(),
  ];
}

/// A sealed class representing a custom app icon with a preview path.
///
/// This class cannot be extended outside of its library.
sealed class CustomIcon extends AppIcon {
  /// The file path to the preview image of the icon.
  final String previewPath;

  CustomIcon({
    required this.previewPath,
    required super.iOSIcon,
    required super.androidIcon,
    required super.isDefaultIcon,
  });

  /// Creates a [CustomIcon] instance from a string [icon] name.
  ///
  /// Returns the corresponding [CustomIcon] if found;
  /// Otherwise, returns the default icon.
  factory CustomIcon.fromString(String? icon) {
    if (icon == null) return IconGreen();

    return CustomIcons.list.firstWhere(
      (e) => e.iOSIcon == icon || e.androidIcon == icon,
      orElse: () => IconGreen(),
    );
  }
}

final class IconLight extends CustomIcon {
  IconLight()
      : super(
          iOSIcon: 'IconLight',
          androidIcon: 'IconLight',
          previewPath: 'assets/icons/icon2.png',
          isDefaultIcon: false,
        );
}

final class IconDark extends CustomIcon {
  IconDark()
      : super(
          iOSIcon: 'IconDark',
          androidIcon: 'IconDark',
          previewPath: 'assets/icons/icon2.png',
          isDefaultIcon: false,
        );
}

final class IconGreen extends CustomIcon {
  IconGreen()
      : super(
          iOSIcon: 'IconGreen',
          androidIcon: 'MainActivity',
          previewPath: 'assets/icons/icon2.png',
          isDefaultIcon: true,
        );
}
