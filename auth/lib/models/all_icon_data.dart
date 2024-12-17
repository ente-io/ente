enum IconType { simpleIcon, customIcon }

class AllIconData {
  final String title;
  final IconType type;
  final String? color;
  final String? slug;

  AllIconData({
    required this.title,
    required this.type,
    required this.color,
    this.slug,
  });
}
