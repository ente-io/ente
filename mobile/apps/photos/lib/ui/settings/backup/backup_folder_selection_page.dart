import 'dart:ui';

import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/device_files_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/services/sync/remote_sync_service.dart';
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/utils/dialog_util.dart';

class BackupFolderSelectionPage extends StatefulWidget {
  final bool isFirstBackup;
  final bool isOnboarding;

  const BackupFolderSelectionPage({
    required this.isFirstBackup,
    this.isOnboarding = false,
    super.key,
  });

  @override
  State<BackupFolderSelectionPage> createState() =>
      _BackupFolderSelectionPageState();
}

class _BackupFolderSelectionPageState extends State<BackupFolderSelectionPage> {
  final Logger _logger = Logger((_BackupFolderSelectionPageState).toString());
  final Set<String> _allDevicePathIDs = <String>{};
  final Set<String> _selectedDevicePathIDs = <String>{};
  List<DeviceCollection>? _deviceCollections;
  Map<String, int>? _pathIDToItemCount;

  @override
  void initState() {
    FilesDB.instance
        .getDeviceCollections(includeCoverThumbnail: true)
        .then((files) async {
      _pathIDToItemCount =
          await FilesDB.instance.getDevicePathIDToImportedFileCount();
      setState(() {
        _deviceCollections = files;
        _deviceCollections!.sort((first, second) {
          return first.name.toLowerCase().compareTo(second.name.toLowerCase());
        });
        for (final file in _deviceCollections!) {
          _allDevicePathIDs.add(file.id);
          if (file.shouldBackup) {
            _selectedDevicePathIDs.add(file.id);
          }
        }
        if (widget.isOnboarding) {
          _selectedDevicePathIDs.addAll(_allDevicePathIDs);
        }
        _selectedDevicePathIDs
            .removeWhere((folder) => !_allDevicePathIDs.contains(folder));
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isOnboarding
          ? null
          : AppBar(
              elevation: 0,
              title: const Text(""),
            ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(
            height: 0,
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Text(
                AppLocalizations.of(context).selectFoldersForBackup,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'Inter-Bold',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 48),
            child: Text(
              AppLocalizations.of(context)
                  .selectedFoldersWillBeEncryptedAndBackedUp,
              style:
                  Theme.of(context).textTheme.bodySmall!.copyWith(height: 1.3),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(10),
          ),
          _deviceCollections == null
              ? const SizedBox.shrink()
              : GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 6, 64, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _selectedDevicePathIDs.length ==
                                _allDevicePathIDs.length
                            ? AppLocalizations.of(context).unselectAll
                            : AppLocalizations.of(context).selectAll,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  onTap: () {
                    final hasSelectedAll = _selectedDevicePathIDs.length ==
                        _allDevicePathIDs.length;
                    // Flip selection
                    if (hasSelectedAll) {
                      _selectedDevicePathIDs.clear();
                    } else {
                      _selectedDevicePathIDs.addAll(_allDevicePathIDs);
                    }
                    _deviceCollections!.sort((first, second) {
                      return first.name
                          .toLowerCase()
                          .compareTo(second.name.toLowerCase());
                    });
                    setState(() {});
                  },
                ),
          Expanded(child: _getFolders()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: getEnteColorScheme(context).backgroundBase,
                          blurRadius: 24,
                          offset: const Offset(0, -8),
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: OutlinedButton(
                      onPressed:
                          widget.isOnboarding && _selectedDevicePathIDs.isEmpty
                              ? null
                              : () async {
                                  await updateFolderSettings();
                                },
                      child: Text(
                        widget.isFirstBackup
                            ? AppLocalizations.of(context).startBackup
                            : AppLocalizations.of(context).backup,
                      ),
                    ),
                  ),
                  widget.isOnboarding
                      ? const SizedBox(height: 20)
                      : const SizedBox.shrink(),
                  widget.isOnboarding
                      ? GestureDetector(
                          key: const ValueKey("skipBackupButton"),
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              AppLocalizations.of(context).skip,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                    decoration: TextDecoration.underline,
                                  ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> updateFolderSettings() async {
    final dialog = createProgressDialog(
      context,
      AppLocalizations.of(context).updatingFolderSelection,
    );
    await dialog.show();
    try {
      final Map<String, bool> syncStatus = {};
      for (String pathID in _allDevicePathIDs) {
        syncStatus[pathID] = _selectedDevicePathIDs.contains(pathID);
      }
      await Configuration.instance.setHasSelectedAnyBackupFolder(
        _selectedDevicePathIDs.isNotEmpty,
      );
      await Configuration.instance.setSelectAllFoldersForBackup(
        _allDevicePathIDs.length == _selectedDevicePathIDs.length,
      );
      await RemoteSyncService.instance.updateDeviceFolderSyncStatus(syncStatus);
      await dialog.hide();
      Navigator.of(context).pop();
    } catch (e, s) {
      _logger.severe("Failed to updated backup folder", e, s);
      await dialog.hide();
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Widget _getFolders() {
    if (_deviceCollections == null) {
      return const EnteLoadingWidget();
    }
    _sortFiles();
    final scrollController = ScrollController();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: ImplicitlyAnimatedReorderableList<DeviceCollection>(
            controller: scrollController,
            items: _deviceCollections!,
            areItemsTheSame: (oldItem, newItem) => oldItem.id == newItem.id,
            onReorderFinished: (item, from, to, newItems) {
              setState(() {
                _deviceCollections!
                  ..clear()
                  ..addAll(newItems);
              });
            },
            itemBuilder: (context, itemAnimation, file, index) {
              return Reorderable(
                key: ValueKey(file),
                builder: (context, dragAnimation, inDrag) {
                  final t = dragAnimation.value;
                  final elevation = lerpDouble(0, 8, t)!;
                  final themeColor = Theme.of(context).colorScheme.onSurface;
                  final color = Color.lerp(
                    themeColor,
                    themeColor.withValues(alpha: 0.8),
                    t,
                  );
                  return SizeFadeTransition(
                    sizeFraction: 0.7,
                    curve: Curves.easeInOut,
                    animation: itemAnimation,
                    child: Material(
                      color: color,
                      elevation: elevation,
                      type: MaterialType.transparency,
                      child: _getFileItem(file),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _getFileItem(DeviceCollection deviceCollection) {
    final isSelected = _selectedDevicePathIDs.contains(deviceCollection.id);
    final importedCount = _pathIDToItemCount != null
        ? _pathIDToItemCount![deviceCollection.id] ?? 0
        : -1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 1, right: 1),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.boxUnSelectColor,
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(12),
          ),
          // color: isSelected
          //     ? Theme.of(context).colorScheme.boxSelectColor
          //     : Theme.of(context).colorScheme.boxUnSelectColor,
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF00DD4D), Color(0xFF43BA6C)],
                ) //same for both themes
              : LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.boxUnSelectColor,
                    Theme.of(context).colorScheme.boxUnSelectColor,
                  ],
                ),
        ),
        padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
        child: InkWell(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    checkColor: Colors.green,
                    activeColor: Colors.white,
                    value: isSelected,
                    onChanged: (value) {
                      if (value!) {
                        _selectedDevicePathIDs.add(deviceCollection.id);
                      } else {
                        _selectedDevicePathIDs.remove(deviceCollection.id);
                      }
                      setState(() {});
                    },
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          deviceCollection.name,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontFamily: 'Inter-Medium',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      const Padding(padding: EdgeInsets.only(top: 2)),
                      Text(
                        (kDebugMode ? 'inApp: $importedCount : device ' : '') +
                            AppLocalizations.of(context)
                                .itemCount(count: deviceCollection.count),
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _getThumbnail(deviceCollection.thumbnail!, isSelected),
            ],
          ),
          onTap: () {
            final value = !_selectedDevicePathIDs.contains(deviceCollection.id);
            if (value) {
              _selectedDevicePathIDs.add(deviceCollection.id);
            } else {
              _selectedDevicePathIDs.remove(deviceCollection.id);
            }
            setState(() {});
          },
        ),
      ),
    );
  }

  void _sortFiles() {
    _deviceCollections!.sort((first, second) {
      if (_selectedDevicePathIDs.contains(first.id) &&
          _selectedDevicePathIDs.contains(second.id)) {
        return first.name.toLowerCase().compareTo(second.name.toLowerCase());
      } else if (_selectedDevicePathIDs.contains(first.id)) {
        return -1;
      } else if (_selectedDevicePathIDs.contains(second.id)) {
        return 1;
      }
      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });
  }

  Widget _getThumbnail(EnteFile file, bool isSelected) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 88,
        width: 88,
        child: Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            ThumbnailWidget(
              file,
              shouldShowSyncStatus: false,
              key: Key("backup_selection_widget" + file.tag),
            ),
            Padding(
              padding: const EdgeInsets.all(9),
              child: isSelected
                  ? const Icon(
                      Icons.local_police,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
