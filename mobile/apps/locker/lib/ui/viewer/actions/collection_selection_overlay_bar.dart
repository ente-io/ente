import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_utils/navigation_util.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/models/selected_collections.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/ui/components/selection_action_button_widget.dart";
import "package:locker/ui/sharing/add_participant_page.dart";
import "package:locker/utils/collection_actions.dart";

class CollectionSelectionOverlayBar extends StatefulWidget {
  final SelectedCollections selectedCollections;
  final List<Collection> collection;
  const CollectionSelectionOverlayBar({
    required this.selectedCollections,
    required this.collection,
    super.key,
  });

  @override
  State<CollectionSelectionOverlayBar> createState() =>
      _CollectionSelectionOverlayBarState();
}

class _CollectionSelectionOverlayBarState
    extends State<CollectionSelectionOverlayBar> {
  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final colorScheme = getEnteColorScheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                ListenableBuilder(
                  listenable: widget.selectedCollections,
                  builder: (context, child) {
                    final isAllSelected = widget.selectedCollections.count ==
                        widget.collection.length;
                    final buttonText =
                        isAllSelected ? 'Deselect All' : 'Select All';
                    final iconData = isAllSelected
                        ? Icons.remove_circle_outline
                        : Icons.check_circle_outline_outlined;

                    return InkWell(
                      onTap: () {
                        if (isAllSelected) {
                          widget.selectedCollections.clearAll();
                        } else {
                          widget.selectedCollections
                              .select(widget.collection.toSet());
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.strokeMuted,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          color: isDarkMode
                              ? const Color.fromRGBO(27, 27, 27, 1)
                              : colorScheme.backgroundElevated2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              buttonText,
                              style: getEnteTextTheme(context).bodyBold,
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              iconData,
                              color: colorScheme.textBase,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),
                ListenableBuilder(
                  listenable: widget.selectedCollections,
                  builder: (context, child) {
                    final count = widget.selectedCollections.count;
                    final countText =
                        count == 1 ? '1 selected' : '$count selected';

                    return InkWell(
                      onTap: () {
                        widget.selectedCollections.clearAll();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.strokeMuted,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          color: isDarkMode
                              ? const Color.fromRGBO(27, 27, 27, 1)
                              : colorScheme.backgroundElevated2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              countText,
                              style: getEnteTextTheme(context).bodyBold,
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.close,
                              size: 16,
                              color: colorScheme.textBase,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            elevation: 4,
            surfaceTintColor: isDarkMode
                ? const Color.fromRGBO(18, 18, 18, 1)
                : colorScheme.backgroundBase,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 28 + bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.selectedCollections,
      builder: (context, child) {
        final selectedCollections = widget.selectedCollections.collections;
        if (selectedCollections.isEmpty) {
          return const SizedBox.shrink();
        }

        final actions = _getActionsForSelection(selectedCollections);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color.fromRGBO(255, 255, 255, 0.04)
                : getEnteColorScheme(context).backgroundElevated2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: actions,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _getActionsForSelection(
    Set<Collection> selectedCollections,
  ) {
    final isSingleSelection = selectedCollections.length == 1;
    final collection = isSingleSelection ? selectedCollections.first : null;
    final actions = <Widget>[];

    if (isSingleSelection) {
      actions.addAll([
        SelectionActionButton(
          icon: Icons.share_outlined,
          label: context.l10n.share,
          onTap: _shareCollection,
        ),
        SelectionActionButton(
          icon: Icons.edit_outlined,
          label: context.l10n.edit,
          onTap: () {
            CollectionActions.editCollection(
              context,
              collection!,
            );
          },
        ),
        SelectionActionButton(
          icon: Icons.delete_outline,
          label: context.l10n.delete,
          onTap: () {
            CollectionActions.deleteCollection(context, collection!);
          },
          isDestructive: true,
        ),
      ]);
    } else {
      actions.addAll([
        SelectionActionButton(
          icon: Icons.delete_outline,
          label: context.l10n.delete,
          onTap: () {
            CollectionActions.deleteMultipleCollections(
              context,
              selectedCollections.toList(),
            );
          },
          isDestructive: true,
        ),
      ]);
    }
    return actions;
  }

  Future<void> _shareCollection() async {
    await routeToPage(
      context,
      AddParticipantPage(
        widget.selectedCollections.collections.toList(),
        const [ActionTypesToShow.addViewer, ActionTypesToShow.addCollaborator],
      ),
    );
    widget.selectedCollections.clearAll();
  }
}
