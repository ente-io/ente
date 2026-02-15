import 'dart:math';

import 'package:ente_pure_utils/ente_pure_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:photos/db/device_files_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/service_locator.dart';
import 'package:photos/services/sync/remote_sync_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/buttons/button_widget_v2.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/settings/backup/backup_settings_screen.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/utils/dialog_util.dart';

class BackupFolderSelectionPage extends StatefulWidget {
  final bool isFirstBackup;
  final bool isOnboarding;

  /// When true, skip the "only new backup" warning dialog.
  /// This is used when coming from the "backup only new photos" toggle
  /// to prevent recursive navigation back to backup settings.
  final bool fromOnlyNewPhotosToggle;

  const BackupFolderSelectionPage({
    required this.isFirstBackup,
    this.isOnboarding = false,
    this.fromOnlyNewPhotosToggle = false,
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
  late final bool _treatAsOnboarding;

  static const _maxThumbnailWidth = 224.0;
  static const _gridHorizontalPadding = 16.0;
  static const _gridCrossSpacing = 8.0;
  static const _gridMainSpacing = 8.0;
  static const _thumbnailRadius = 12.0;
  static const _titleFadeDistance = 72.0;

  double _titleFadeProgress = 0;

  @override
  void initState() {
    _treatAsOnboarding = widget.isOnboarding ||
        backupPreferenceService.hasSkippedOnboardingPermission;
    FilesDB.instance
        .getDeviceCollections(includeCoverThumbnail: true)
        .then((files) async {
      _pathIDToItemCount =
          await FilesDB.instance.getDevicePathIDToImportedFileCount();
      if (!mounted) {
        return;
      }
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
        if (_treatAsOnboarding) {
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
    final colorScheme = getEnteColorScheme(context);
    return Scaffold(
      backgroundColor: colorScheme.backgroundColour,
      body: _treatAsOnboarding
          ? SafeArea(
              top: true,
              bottom: false,
              child: _buildScrollableBody(),
            )
          : _buildScrollableBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Future<void> updateFolderSettings() async {
    final l10n = AppLocalizations.of(context);
    final dialog = createProgressDialog(
      context,
      l10n.updatingFolderSelection,
    );
    await dialog.show();
    try {
      final Map<String, bool> syncStatus = {};
      for (String pathID in _allDevicePathIDs) {
        syncStatus[pathID] = _selectedDevicePathIDs.contains(pathID);
      }
      await backupPreferenceService.setHasSelectedAnyBackupFolder(
        _selectedDevicePathIDs.isNotEmpty,
      );
      await backupPreferenceService.setSelectAllFoldersForBackup(
        _allDevicePathIDs.length == _selectedDevicePathIDs.length,
      );
      await RemoteSyncService.instance.updateDeviceFolderSyncStatus(syncStatus);
      await dialog.hide();
      await backupPreferenceService.setHasManualFolderSelection(true);

      // Skip the warning dialog if we came from the "backup only new photos"
      // toggle to avoid recursive navigation back to backup settings.
      final onlyNewSinceEpoch = backupPreferenceService.onlyNewSinceEpoch;
      if (onlyNewSinceEpoch != null && !widget.fromOnlyNewPhotosToggle) {
        final shouldContinue =
            await _showOnlyNewBackupWarning(onlyNewSinceEpoch);

        if (!shouldContinue) return;
      }

      if (context.mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e, s) {
      _logger.severe("Failed to updated backup folder", e, s);
      await dialog.hide();
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<bool> _showOnlyNewBackupWarning(int onlyNewSinceEpoch) async {
    final l10n = AppLocalizations.of(context);
    final date = DateTime.fromMicrosecondsSinceEpoch(onlyNewSinceEpoch);
    final locale = Localizations.localeOf(context).languageCode;
    final formattedDate = DateFormat.yMMMd(locale).format(date);

    final result = await showChoiceDialog(
      context,
      title: l10n.warning,
      body: l10n.backupOnlyNewPhotosWarningBody(formattedDate: formattedDate),
      firstButtonLabel: l10n.updateSettings,
      firstButtonOnTap: () async {
        await routeToPage(
          context,
          const BackupSettingsScreen(),
        );
      },
      firstButtonType: ButtonType.neutral,
      secondButtonLabel: l10n.ok,
      secondButtonAction: ButtonAction.second,
    );

    return result?.action == ButtonAction.second;
  }

  Widget _buildBottomNavigationBar() {
    final l10n = AppLocalizations.of(context);
    final colorScheme = getEnteColorScheme(context);
    final canSubmit = !(_treatAsOnboarding && _selectedDevicePathIDs.isEmpty);

    return Container(
      color: colorScheme.backgroundColour,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ButtonWidgetV2(
                buttonType: ButtonTypeV2.primary,
                labelText:
                    widget.isFirstBackup ? l10n.startBackup : l10n.backup,
                isDisabled: !canSubmit,
                onTap: canSubmit
                    ? () async {
                        await updateFolderSettings();
                      }
                    : null,
              ),
              if (_treatAsOnboarding) ...[
                const SizedBox(height: 16),
                ButtonWidgetV2(
                  key: const ValueKey("skipBackupButton"),
                  buttonType: ButtonTypeV2.link,
                  labelText: l10n.skip,
                  onTap: () async {
                    Navigator.of(context).pop(false);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableBody() {
    final l10n = AppLocalizations.of(context);
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: CustomScrollView(
        primary: true,
        slivers: [
          if (_treatAsOnboarding) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.backupToEnte,
                  style: textTheme.h3Bold,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.selectAlbumsToBackUpToEnte,
                  style: textTheme.smallMuted,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ] else ...[
            SliverAppBar(
              backgroundColor: colorScheme.backgroundColour,
              elevation: 0,
              scrolledUnderElevation: 0,
              pinned: true,
              automaticallyImplyLeading: false,
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
              ),
              titleSpacing: 0,
              title: Opacity(
                opacity: _titleFadeProgress,
                child: Text(
                  l10n.backupToEnte,
                  style: textTheme.h3Bold,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Opacity(
                opacity: 1 - _titleFadeProgress,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n.backupToEnte,
                        style: textTheme.h3Bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n.selectAlbumsToBackUpToEnte,
                        style: textTheme.smallMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
          if (_deviceCollections != null)
            SliverToBoxAdapter(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _toggleSelectAll,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _selectedDevicePathIDs.length ==
                                _allDevicePathIDs.length
                            ? l10n.unselectAll
                            : l10n.selectAll,
                        style: textTheme.small.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          _buildFoldersSliver(),
        ],
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_treatAsOnboarding ||
        notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final progress =
        (notification.metrics.pixels / _titleFadeDistance).clamp(0.0, 1.0);
    if ((progress - _titleFadeProgress).abs() > 0.01 && mounted) {
      setState(() {
        _titleFadeProgress = progress;
      });
    }
    return false;
  }

  Widget _buildFoldersSliver() {
    if (_deviceCollections == null) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EnteLoadingWidget(),
      );
    }
    _sortFiles();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = max(screenWidth ~/ _maxThumbnailWidth, 3);
    final totalCrossAxisSpacing = (crossAxisCount - 1) * _gridCrossSpacing;
    final sideOfThumbnail =
        (screenWidth - totalCrossAxisSpacing - _gridHorizontalPadding) /
            crossAxisCount;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: _gridHorizontalPadding / 2,
      ),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _buildFolderItem(
              _deviceCollections![index],
              sideOfThumbnail,
            );
          },
          childCount: _deviceCollections!.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: _gridCrossSpacing,
          mainAxisSpacing: _gridMainSpacing,
          childAspectRatio: sideOfThumbnail / (sideOfThumbnail + 46),
        ),
      ),
    );
  }

  Widget _buildFolderItem(
    DeviceCollection deviceCollection,
    double sideOfThumbnail,
  ) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isSelected = _selectedDevicePathIDs.contains(deviceCollection.id);
    final importedCount = _pathIDToItemCount?[deviceCollection.id];
    final formattedCount = NumberFormat().format(deviceCollection.count);
    final countText = kDebugMode && importedCount != null
        ? "inApp: $importedCount | device: $formattedCount"
        : formattedCount;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggleFolderSelection(deviceCollection.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: sideOfThumbnail,
            height: sideOfThumbnail,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(_thumbnailRadius + 1),
                  child: Container(
                    color: colorScheme.strokeFaint,
                    width: sideOfThumbnail,
                    height: sideOfThumbnail,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(1),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_thumbnailRadius),
                    child: SizedBox(
                      width: sideOfThumbnail - 2,
                      height: sideOfThumbnail - 2,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (deviceCollection.thumbnail != null)
                            ThumbnailWidget(
                              deviceCollection.thumbnail!,
                              shouldShowSyncStatus: false,
                              key: ValueKey(
                                "backup_selection_widget_${deviceCollection.id}",
                              ),
                            )
                          else
                            ColoredBox(color: colorScheme.fillDark),
                          if (isSelected)
                            ColoredBox(
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(0.75),
                      decoration: BoxDecoration(
                        color: colorScheme.backgroundColour,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: colorScheme.greenBase,
                        size: 22,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: sideOfThumbnail,
            child: Text(
              deviceCollection.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.small,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: sideOfThumbnail,
            child: Text(
              countText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.miniMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSelectAll() {
    setState(() {
      final hasSelectedAll =
          _selectedDevicePathIDs.length == _allDevicePathIDs.length;
      if (hasSelectedAll) {
        _selectedDevicePathIDs.clear();
      } else {
        _selectedDevicePathIDs.addAll(_allDevicePathIDs);
      }
      _deviceCollections!.sort((first, second) {
        return first.name.toLowerCase().compareTo(second.name.toLowerCase());
      });
    });
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

  void _toggleFolderSelection(String folderId) {
    setState(() {
      if (_selectedDevicePathIDs.contains(folderId)) {
        _selectedDevicePathIDs.remove(folderId);
      } else {
        _selectedDevicePathIDs.add(folderId);
      }
    });
  }
}
