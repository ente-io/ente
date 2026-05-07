import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/base_bottom_sheet.dart';
import 'package:photos/ui/components/buttons/button_widget_v2.dart';
import 'package:photos/ui/notification/toast.dart';

Color familyPageBackgroundColor(BuildContext context) {
  return getEnteColorScheme(context).backgroundColour;
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
  showToast(context, message);
}

Future<bool> showFamilyConfirmationSheet(
  BuildContext context, {
  required String title,
  required String body,
  required String actionLabel,
}) async {
  final confirmed = await showBaseBottomSheet<bool>(
    context,
    title: title,
    headerSpacing: 20,
    padding: const EdgeInsets.all(16),
    backgroundColor: getEnteColorScheme(context).backgroundColour,
    child: _FamilyConfirmationContent(
      body: body,
      actionLabel: actionLabel,
    ),
  );

  return confirmed == true;
}

class _FamilyConfirmationContent extends StatelessWidget {
  const _FamilyConfirmationContent({
    required this.body,
    required this.actionLabel,
  });

  final String body;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          body,
          style: textTheme.small.copyWith(
            color: colorScheme.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        ButtonWidgetV2(
          buttonType: ButtonTypeV2.critical,
          labelText: actionLabel,
          onTap: () async {
            Navigator.of(context).pop(true);
          },
          shouldSurfaceExecutionStates: false,
        ),
      ],
    );
  }
}
