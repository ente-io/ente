import 'package:ente_components/theme/radii.dart';
import 'package:ente_components/theme/spacing.dart';
import 'package:ente_components/theme/text_styles.dart';
import 'package:ente_components/theme/theme.dart';
import 'package:flutter/material.dart';

/// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=2475-5968&m=dev
/// Section: Appbar/header / HeaderComponent
/// Specs: 327px design width, optional 36px image slot, optional subtitle, and up to two trailing icon actions.
class HeaderComponent extends StatelessWidget {
  const HeaderComponent({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.action,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? action;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final effectiveActions = [
      ...actions,
      if (action != null) action!,
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.md),
              child: SizedBox.square(
                dimension: 36,
                child: leading,
              ),
            ),
            const SizedBox(width: Spacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.h1Bold.copyWith(color: colors.textBase),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: Spacing.xxs),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.mini.copyWith(color: colors.textLight),
                  ),
                ],
              ],
            ),
          ),
          if (effectiveActions.isNotEmpty) ...[
            const SizedBox(width: Spacing.md),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0;
                    index < effectiveActions.length;
                    index++) ...[
                  effectiveActions[index],
                  if (index != effectiveActions.length - 1)
                    const SizedBox(width: 6),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
