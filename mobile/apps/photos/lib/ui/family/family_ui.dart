import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/notification/toast.dart';

Color familyPageBackgroundColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF161616)
      : const Color(0xFFFAFAFA);
}

class FamilyPageScaffold extends StatelessWidget {
  const FamilyPageScaffold({
    required this.child,
    this.title,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
    super.key,
  });

  final Widget child;
  final String? title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Scaffold(
      backgroundColor: familyPageBackgroundColor(context),
      body: SafeArea(
        child: Padding(
          padding: padding,
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(
                        Icons.arrow_back,
                        size: 24,
                        color: colorScheme.strokeBase,
                      ),
                    ),
                  ),
                  if (title != null) const SizedBox(width: 8),
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: textTheme.largeBold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

void showFamilySnackBar(BuildContext context, String message) {
  showShortToast(context, message);
}
