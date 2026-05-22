import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/ui/collections/collection_action_sheet.dart";

class SharedEmptyState extends StatelessWidget {
  const SharedEmptyState({super.key});

  static const _topPadding = 32.0;
  static const _sectionSpacing = 48.0;
  static const _contentToButtonSpacing = 56.0;
  static const _buttonHeight = 52.0;
  static const _contentWidth = 343.0;
  static const _featureWidth = 300.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final strings = AppLocalizations.of(context);
    final bottomPadding = 64 + MediaQuery.paddingOf(context).bottom + 32;
    final features = [
      strings.albumsSharedEmptyFeatureShareLovedOnes,
      strings.albumsSharedEmptyFeatureReactAndComment,
      strings.albumsSharedEmptyFeaturePrivacy,
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, _topPadding, 16, bottomPadding),
        child: SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fill(
                bottom: _buttonHeight + _contentToButtonSpacing,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: _contentWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          "assets/shared.png",
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: _sectionSpacing),
                        Text(
                          strings.albumsSharedEmptyTitle,
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
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: ButtonComponent(
                  label: strings.shareAnAlbum,
                  shouldSurfaceExecutionStates: false,
                  onTap: () async {
                    showCollectionActionSheet(
                      context,
                      actionType: CollectionActionType.shareCollection,
                    );
                  },
                ),
              ),
            ],
          ),
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
