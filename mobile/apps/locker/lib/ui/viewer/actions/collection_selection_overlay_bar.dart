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
  void initState() {
    super.initState();
    widget.selectedCollections.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    widget.selectedCollections.removeListener(_onSelectionChanged);
    super.dispose();
  }

  void _onSelectionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final hasSelection = widget.selectedCollections.collections.isNotEmpty;

    return IgnorePointer(
      ignoring: !hasSelection,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          offset: hasSelection ? Offset.zero : const Offset(0, 1),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: hasSelection ? 1.0 : 0.0,
            curve: Curves.easeInOut,
            child: hasSelection
                ? Container(
                    decoration: BoxDecoration(
                      color: colorScheme.backdropBase,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      border: Border(
                        top: BorderSide(color: colorScheme.strokeFaint),
                      ),
                    ),
                    child: Padding(
                      padding:
                          EdgeInsets.fromLTRB(16, 16, 16, 28 + bottomPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              ListenableBuilder(
                                listenable: widget.selectedCollections,
                                builder: (context, child) {
                                  final isAllSelected =
                                      widget.selectedCollections.count ==
                                          widget.collection.length;
                                  final buttonText = isAllSelected
                                      ? context.l10n.deselectAll
                                      : context.l10n.selectAll;
                                  final iconData = isAllSelected
                                      ? Icons.remove_circle_outline
                                      : Icons.check_circle_outline_outlined;

                                  return InkWell(
                                    onTap: () {
                                      if (isAllSelected) {
                                        widget.selectedCollections.clearAll();
                                      } else {
                                        widget.selectedCollections.select(
                                          widget.collection.toSet(),
                                        );
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: colorScheme.backgroundElevated2,
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 14.0,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            buttonText,
                                            style: textTheme.body,
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            iconData,
                                            color: getEnteColorScheme(context)
                                                .textBase,
                                            size: 20,
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
                                  final count =
                                      widget.selectedCollections.count;
                                  final countText = count == 1
                                      ? '1 selected'
                                      : '$count selected';

                                  return InkWell(
                                    onTap: () {
                                      widget.selectedCollections.clearAll();
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: colorScheme.backgroundElevated2,
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 14.0,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            countText,
                                            style: textTheme.body,
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.close,
                                            color: getEnteColorScheme(context)
                                                .textBase,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return ListenableBuilder(
      listenable: widget.selectedCollections,
      builder: (context, child) {
        final selectedCollections = widget.selectedCollections.collections;
        if (selectedCollections.isEmpty) {
          return const SizedBox.shrink();
        }

        final actions = _getActionsForSelection(selectedCollections);

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                child: child,
              ),
            );
          },
          child: actions.length > 1
              ? Row(
                  key: const ValueKey('multi_action'),
                  children: _buildActionRow(actions),
                )
              : Row(
                  key: const ValueKey('single_action'),
                  children: [Expanded(child: actions.first)],
                ),
        );
      },
    );
  }

  List<Widget> _buildActionRow(List<Widget> actions) {
    final children = <Widget>[];
    for (var i = 0; i < actions.length; i++) {
      children.add(Expanded(child: actions[i]));
      if (i != actions.length - 1) {
        children.add(const SizedBox(width: 12));
      }
    }
    return children;
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
