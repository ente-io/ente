import 'dart:ui';

import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import "package:photo_manager/photo_manager.dart";
import 'package:photos/core/configuration.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/generated/l10n.dart';
import "package:photos/image_providers/local_thumbnail_img_provider.dart";
import "package:photos/services/local/local_assets_cache.dart";
import "package:photos/services/local/local_import.dart";
import 'package:photos/services/sync/remote_sync_service.dart';
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/common/loading_widget.dart';
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import 'package:photos/utils/dialog_util.dart';

class BackupFolderSelectionPageV2 extends StatefulWidget {
  final bool isFirstBackup;
  final bool isOnboarding;

  const BackupFolderSelectionPageV2({
    required this.isFirstBackup,
    this.isOnboarding = false,
    super.key,
  });

  @override
  State<BackupFolderSelectionPageV2> createState() =>
      _BackupFolderSelectionPageV2State();
}

class _BackupFolderSelectionPageV2State
    extends State<BackupFolderSelectionPageV2> {
  final Logger _logger = Logger((_BackupFolderSelectionPageV2State).toString());
  final Set<String> _allDevicePathIDs = <String>{};
  final Set<String> _selectedDevicePathIDs = <String>{};
  List<AssetPathEntity>? _assetPathEntities;
  Map<String, Set<String>> _assetCount = {};
  final Map<String, AssetEntity> _pathToLatestAsset = {};

  @override
  void initState() {
    _logger.info("BackupFolderSelectionPageV2 init");
    LocalImportService.instance
        .getLocalAssetsCache()
        .then((LocalAssetsCache c) async {
      _assetPathEntities = c.assetPaths.values.toList();
      _logger.info(
        "BackupFolderSelectionPageV2 got ${_assetPathEntities!.length} paths",
      );
      _assetCount.clear();
      _assetCount = c.pathToAssetIDs;
      _logger.info("Asset count: $_assetCount");
      _assetPathEntities!.removeWhere(
        (path) => (_assetCount[path.id] ?? {}).isEmpty,
      );
      final List<AssetEntity> latestAssets = c.assets.values.toList();
      // sort by decreate creation date
      latestAssets.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
      for (final path in _assetPathEntities ?? []) {
        final assetIDs = _assetCount[path.id] ?? {};
        for (final assetID in assetIDs) {
          for (final sortedAsset in latestAssets) {
            if (sortedAsset.id == assetID) {
              _pathToLatestAsset[path.id] = sortedAsset;
              break;
            }
          }
        }
      }

      setState(() {
        _assetPathEntities!.sort((first, second) {
          return first.name.toLowerCase().compareTo(second.name.toLowerCase());
        });
        for (final path in _assetPathEntities!) {
          _allDevicePathIDs.add(path.id);
          // todo: replace this logic based on where we decide to store mapping
          // of folders that needs to be backed up.
          final bool shouldBackup = false || path.albumTypeEx != null;
          if (shouldBackup) {
            _selectedDevicePathIDs.add(path.id);
          }
        }
        if (widget.isOnboarding) {
          _selectedDevicePathIDs.addAll(_allDevicePathIDs);
        }
        _selectedDevicePathIDs
            .removeWhere((folder) => !_allDevicePathIDs.contains(folder));
      });
    }).onError((e, s) {
      _logger.warning(
        "Failed to get asset paths for backup folder selection",
        e,
        s,
      );
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
                S.of(context).selectFoldersForBackup,
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
              S.of(context).selectedFoldersWillBeEncryptedAndBackedUp,
              style:
                  Theme.of(context).textTheme.bodySmall!.copyWith(height: 1.3),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(10),
          ),
          _assetPathEntities == null
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
                            ? S.of(context).unselectAll
                            : S.of(context).selectAll,
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
                    _assetPathEntities!.sort((first, second) {
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
                            ? S.of(context).startBackup
                            : S.of(context).backup,
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
                              S.of(context).skip,
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
      S.of(context).updatingFolderSelection,
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
    if (_assetPathEntities == null) {
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
          child: ImplicitlyAnimatedReorderableList<AssetPathEntity>(
            controller: scrollController,
            items: _assetPathEntities!,
            areItemsTheSame: (oldItem, newItem) => oldItem.id == newItem.id,
            onReorderFinished: (item, from, to, newItems) {
              setState(() {
                _assetPathEntities!
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
                  final color =
                      Color.lerp(themeColor, themeColor.withOpacity(0.8), t);
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

  Widget _getFileItem(AssetPathEntity assetPathEntity) {
    final isSelected = _selectedDevicePathIDs.contains(assetPathEntity.id);
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
                        _selectedDevicePathIDs.add(assetPathEntity.id);
                      } else {
                        _selectedDevicePathIDs.remove(assetPathEntity.id);
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
                          assetPathEntity.name,
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
                                    .withOpacity(0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      const Padding(padding: EdgeInsets.only(top: 2)),
                      FutureBuilder<int>(
                        future: kDebugMode
                            ? assetPathEntity.assetCountAsync
                            : Future.value(0),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              (kDebugMode
                                      ? 'inApp: ${snapshot.data} : device '
                                      : '') +
                                  S.of(context).itemCount(
                                        _assetCount[assetPathEntity.id]
                                                ?.length ??
                                            0,
                                      ),
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              _getThumbnail(assetPathEntity, isSelected),
            ],
          ),
          onTap: () {
            final value = !_selectedDevicePathIDs.contains(assetPathEntity.id);
            if (value) {
              _selectedDevicePathIDs.add(assetPathEntity.id);
            } else {
              _selectedDevicePathIDs.remove(assetPathEntity.id);
            }
            setState(() {});
          },
        ),
      ),
    );
  }

  void _sortFiles() {
    _assetPathEntities!.sort((first, second) {
      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });
  }

  // todo: replace with asset thumbnail provider
  Widget _getThumbnail(AssetPathEntity path, bool isSelected) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 88,
        width: 88,
        child: Stack(
          alignment: AlignmentDirectional.bottomEnd,
          children: [
            _pathToLatestAsset[path.id] != null
                ? Image(
                    key: Key("backup_selection_widget" + path.id),
                    image: LocalThumbnailProvider(
                      LocalThumbnailProviderKey(
                        asset: _pathToLatestAsset[path.id]!,
                      ),
                    ),
                    fit: BoxFit.cover,
                  )
                : const NoThumbnailWidget(),
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
