import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/ui/common/backup_flow_helper.dart";

class OnEnteEmptyState extends StatelessWidget {
  const OnEnteEmptyState({super.key});

  static const _topPadding = 32.0;
  static const _sectionSpacing = 48.0;
  static const _contentWidth = 343.0;
  static const _featureWidth = 300.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final strings = AppLocalizations.of(context);
    final bottomPadding = 64 + MediaQuery.paddingOf(context).bottom + 32;
    final features = [
      strings.albumsOnEnteEmptyFeatureAccessAnyDevice,
      strings.albumsOnEnteEmptyFeatureShareLovedOnes,
      strings.albumsOnEnteEmptyFeaturePrivacy,
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, _topPadding, 16, bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "assets/on_ente.png",
            ),
            const SizedBox(height: _sectionSpacing),
            SizedBox(
              width: _contentWidth,
              child: Column(
                children: [
                  Text(
                    strings.albumsOnEnteEmptyTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Nunito",
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      height: 28 / 24,
                      letterSpacing: 0,
                      color: colors.textBase,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: _featureWidth,
                    child: Column(
                      children: [
                        _BackupFeatureRow(label: features[0]),
                        const SizedBox(height: 12),
                        _BackupFeatureRow(label: features[1]),
                        const SizedBox(height: 12),
                        _BackupFeatureRow(label: features[2]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: _sectionSpacing),
            ButtonComponent(
              label: strings.albumsOnEnteEmptyCta,
              shouldSurfaceExecutionStates: false,
              onTap: () async {
                await handleFolderSelectionBackupFlow(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupFeatureRow extends StatelessWidget {
  const _BackupFeatureRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 5,
          height: 20,
          child: Align(
            alignment: Alignment.center,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              child: const SizedBox.square(dimension: 4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyles.body.copyWith(color: colors.textLight),
          ),
        ),
      ],
    );
  }
}
