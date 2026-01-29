import "dart:async";

import "package:ente_events/event_bus.dart";
import 'package:ente_ui/components/buttons/button_widget.dart';
import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/colors.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import "package:ente_ui/theme/text_style.dart";
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:ente_ui/utils/toast_util.dart';
import 'package:flutter/material.dart';
import "package:hugeicons/hugeicons.dart";
import "package:locker/events/collections_updated_event.dart";
import 'package:locker/l10n/l10n.dart';
import "package:locker/models/selected_files.dart";
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/services/trash/models/trash_file.dart';
import 'package:locker/services/trash/trash_service.dart';
import "package:locker/ui/components/delete_confirmation_sheet.dart";
import "package:locker/ui/components/empty_state_widget.dart";
import 'package:locker/ui/components/item_list_view.dart';
import "package:locker/ui/viewer/actions/file_selection_overlay_bar.dart";

class TrashPage extends StatefulWidget {
  final List<TrashFile> trashFiles;

  const TrashPage({
    super.key,
    required this.trashFiles,
  });

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  List<TrashFile> _trashFiles = [];
  final SelectedFiles _selectedFiles = SelectedFiles();
  final ScrollController _scrollController = ScrollController();
  late StreamSubscription<CollectionsUpdatedEvent> _trashUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _trashFiles = List.from(widget.trashFiles);
    _trashUpdateSubscription = Bus.instance
        .on<CollectionsUpdatedEvent>()
        .listen((_) => _refreshTrashFiles());
  }

  @override
  void dispose() {
    _trashUpdateSubscription.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshTrashFiles() async {
    final trashFiles = await TrashService.instance.getTrashFiles();
    if (!mounted) return;
    setState(() {
      _trashFiles = List.from(trashFiles);
    });
  }

  Future<void> _emptyTrash() async {
    final result = await showDeleteConfirmationSheet(
      context,
      title: context.l10n.emptyTrash,
      body: context.l10n.emptyTrashConfirmation,
      deleteButtonLabel: context.l10n.emptyTrash,
      assetPath: "assets/collection_delete_icon.png",
    );

    if (result?.buttonResult.action == ButtonAction.first && mounted) {
      await _performEmptyTrash();
    }
  }

  Future<void> _performEmptyTrash() async {
    final dialog = createProgressDialog(
      context,
      context.l10n.clearingTrash,
      isDismissible: false,
    );
    await dialog.show();
    try {
      await TrashService.instance.emptyTrash();
      _selectedFiles.clearAll();
      setState(() {
        _trashFiles.clear();
      });
      showToast(
        context,
        context.l10n.trashClearedSuccessfully,
      );
      Navigator.of(context).pop();
    } catch (error) {
      showToast(
        context,
        context.l10n.failedToClearTrash(error.toString()),
      );
    } finally {
      await dialog.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Scaffold(
      backgroundColor: colorScheme.backgroundBase,
      appBar: AppBar(
        backgroundColor: colorScheme.backgroundBase,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 48,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_outlined,
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBody(context, colorScheme, textTheme),
          FileSelectionOverlayBar(
            selectedFiles: _selectedFiles,
            files: _trashFiles.cast<EnteFile>(),
            scrollController: _scrollController,
            isTrashMode: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TitleBarTitleWidget(
            title: context.l10n.trash,
            trailingWidgets: [
              GestureDetector(
                onTap: _emptyTrash,
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: colorScheme.backdropBase,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    color: colorScheme.textBase,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _trashFiles.isEmpty
                ? Center(
                    child: EmptyStateWidget(
                      assetPath: 'assets/empty_state.png',
                      title: context.l10n.yourTrashIsEmpty,
                      showBorder: false,
                    ),
                  )
                : ItemListView(
                    files: _trashFiles.cast<EnteFile>(),
                    physics: const BouncingScrollPhysics(),
                    scrollController: _scrollController,
                    selectedFiles: _selectedFiles,
                    selectionEnabled: true,
                  ),
          ),
        ],
      ),
    );
  }
}
