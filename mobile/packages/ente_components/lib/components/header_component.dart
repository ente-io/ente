import 'package:ente_components/theme/radii.dart';
import 'package:ente_components/theme/spacing.dart';
import 'package:ente_components/theme/text_styles.dart';
import 'package:ente_components/theme/theme.dart';
import 'package:flutter/material.dart';

enum HeaderComponentState { expanded, collapsed }

/// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=11439-5036&m=dev
/// Section: Appbar/header / HeaderComponent
/// Specs: 327px design width, expanded/collapsed states, optional 36px image slot,
/// optional subtitle, and up to two trailing icon actions.
class HeaderComponent extends StatelessWidget {
  const HeaderComponent({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.backButton,
    this.onBack,
    this.action,
    this.actions = const [],
    this.state = HeaderComponentState.expanded,
    this.showBackButton,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? backButton;
  final VoidCallback? onBack;
  final Widget? action;
  final List<Widget> actions;
  final HeaderComponentState state;
  final bool? showBackButton;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final effectiveActions = [...actions, if (action != null) action!];
    final isCollapsed = state == HeaderComponentState.collapsed;
    final shouldShowBackButton = isCollapsed && (showBackButton ?? true);
    final shouldShowLeading = !isCollapsed && leading != null;
    final shouldShowSubtitle = !isCollapsed && subtitle != null;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: isCollapsed ? 38 : 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (shouldShowBackButton) ...[
            _HeaderBackButton(onBack: onBack, child: backButton),
            const SizedBox(width: Spacing.md),
          ],
          if (shouldShowLeading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.md),
              child: SizedBox.square(dimension: 36, child: leading),
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
                  style: (isCollapsed ? TextStyles.h2 : TextStyles.h1Bold)
                      .copyWith(color: colors.textBase),
                ),
                if (shouldShowSubtitle) ...[
                  const SizedBox(height: 2),
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
                for (
                  var index = 0;
                  index < effectiveActions.length;
                  index++
                ) ...[
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

class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton({required this.onBack, this.child});

  final VoidCallback? onBack;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final tooltip = MaterialLocalizations.of(context).backButtonTooltip;

    if (child != null) {
      return IconTheme.merge(
        data: IconThemeData(color: colors.textBase, size: 24),
        child: child!,
      );
    }

    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onBack ?? () => Navigator.maybePop(context),
        child: SizedBox.square(
          dimension: 24,
          child: IconTheme.merge(
            data: IconThemeData(color: colors.textBase, size: 24),
            child: child ?? const Icon(Icons.arrow_back),
          ),
        ),
      ),
    );
  }
}
