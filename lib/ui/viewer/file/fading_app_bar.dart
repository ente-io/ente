import 'dart:io';
import 'dart:io' as io;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:logging/logging.dart';
import 'package:media_extension/media_extension.dart';
import 'package:path/path.dart' as file_path;
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/models/ignored_file.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/models/trash_file.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/favorites_service.dart';
import 'package:photos/services/hidden_service.dart';
import 'package:photos/services/ignored_files_service.dart';
import 'package:photos/services/local_sync_service.dart';
import "package:photos/ui/actions/file/file_actions.dart";
import 'package:photos/ui/common/progress_dialog.dart';
import 'package:photos/ui/create_collection_sheet.dart';
import 'package:photos/ui/viewer/file/custom_app_bar.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:photos/utils/toast_util.dart';

class FadingAppBar extends StatefulWidget implements PreferredSizeWidget {
  final File file;
  final Function(File) onFileRemoved;
  final double height;
  final bool shouldShowActions;
  final int? userID;

  const FadingAppBar(
    this.file,
    this.onFileRemoved,
    this.userID,
    this.height,
    this.shouldShowActions, {
    Key? key,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  FadingAppBarState createState() => FadingAppBarState();
}

class FadingAppBarState extends State<FadingAppBar> {
  final _logger = Logger("FadingAppBar");
  bool _shouldHide = false;

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      IgnorePointer(
        ignoring: _shouldHide,
        child: AnimatedOpacity(
          opacity: _shouldHide ? 0 : 1,
          duration: const Duration(milliseconds: 150),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.72),
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
                stops: const [0, 0.2, 1],
              ),
            ),
            child: _buildAppBar(),
          ),
        ),
      ),
      Size.fromHeight(Platform.isAndroid ? 80 : 96),
    );
  }

  void hide() {
    setState(() {
      _shouldHide = true;
    });
  }

  void show() {
    if (mounted) {
      setState(() {
        _shouldHide = false;
      });
    }
  }

  AppBar _buildAppBar() {
    debugPrint("building app bar");

    final List<Widget> actions = [];
    final isTrashedFile = widget.file is TrashFile;
    final shouldShowActions = widget.shouldShowActions && !isTrashedFile;
    final bool isOwnedByUser =
        widget.file.ownerID == null || widget.file.ownerID == widget.userID;
    final bool isFileUploaded = widget.file.isUploaded;
    bool isFileHidden = false;
    if (isOwnedByUser && isFileUploaded) {
      isFileHidden = CollectionsService.instance
              .getCollectionByID(widget.file.collectionID!)
              ?.isHidden() ??
          false;
    }
    // only show fav option for files owned by the user
    if (isOwnedByUser && !isFileHidden && isFileUploaded) {
      actions.add(_getFavoriteButton());
    }
    actions.add(
      PopupMenuButton(
        itemBuilder: (context) {
          final List<PopupMenuItem> items = [];
          if (widget.file.isRemoteFile) {
            items.add(
              PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(
                      Platform.isAndroid
                          ? Icons.download
                          : CupertinoIcons.cloud_download,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8),
                    ),
                    const Text("Download"),
                  ],
                ),
              ),
            );
          }
          // options for files owned by the user
          if (isOwnedByUser) {
            items.add(
              PopupMenuItem(
                value: 2,
                child: Row(
                  children: [
                    Icon(
                      Platform.isAndroid
                          ? Icons.delete_outline
                          : CupertinoIcons.delete,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8),
                    ),
                    const Text("Delete"),
                  ],
                ),
              ),
            );
          }
          if ((widget.file.fileType == FileType.image ||
                  widget.file.fileType == FileType.livePhoto) &&
              Platform.isAndroid) {
            items.add(
              PopupMenuItem(
                value: 3,
                child: Row(
                  children: [
                    Icon(
                      Icons.wallpaper_outlined,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8),
                    ),
                    const Text("Set as"),
                  ],
                ),
              ),
            );
          }
          if (isOwnedByUser && widget.file.isUploaded) {
            if (!isFileHidden) {
              items.add(
                PopupMenuItem(
                  value: 4,
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_off,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8),
                      ),
                      const Text("Hide"),
                    ],
                  ),
                ),
              );
            } else {
              items.add(
                PopupMenuItem(
                  value: 5,
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8),
                      ),
                      const Text("Unhide"),
                    ],
                  ),
                ),
              );
            }
          }
          return items;
        },
        onSelected: (dynamic value) async {
          if (value == 1) {
            _download(widget.file);
          } else if (value == 2) {
            await _showSingleFileDeleteSheet(widget.file);
          } else if (value == 3) {
            _setAs(widget.file);
          } else if (value == 4) {
            _handleHideRequest(context);
          } else if (value == 5) {
            _handleUnHideRequest(context);
          }
        },
      ),
    );
    return AppBar(
      iconTheme:
          const IconThemeData(color: Colors.white), //same for both themes
      actions: shouldShowActions ? actions : [],
      elevation: 0,
      backgroundColor: const Color(0x00000000),
    );
  }

  Future<void> _handleHideRequest(BuildContext context) async {
    try {
      final hideResult =
          await CollectionsService.instance.hideFiles(context, [widget.file]);
      if (hideResult) {
        widget.onFileRemoved(widget.file);
      }
    } catch (e, s) {
      _logger.severe("failed to update file visibility", e, s);
      await showGenericErrorDialog(context: context);
    }
  }

  Future<void> _handleUnHideRequest(BuildContext context) async {
    final s = SelectedFiles();
    s.files.add(widget.file);
    createCollectionSheet(
      s,
      null,
      context,
      actionType: CollectionActionType.unHide,
    );
  }

  Widget _getFavoriteButton() {
    return FutureBuilder<bool>(
      future: FavoritesService.instance.isFavorite(widget.file),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _getLikeButton(widget.file, snapshot.data);
        } else {
          return _getLikeButton(widget.file, false);
        }
      },
    );
  }

  Widget _getLikeButton(File file, bool? isLiked) {
    return LikeButton(
      isLiked: isLiked,
      onTap: (oldValue) async {
        final isLiked = !oldValue;
        bool hasError = false;
        if (isLiked) {
          final shouldBlockUser = file.uploadedFileID == null;
          late ProgressDialog dialog;
          if (shouldBlockUser) {
            dialog = createProgressDialog(context, "Adding to favorites...");
            await dialog.show();
          }
          try {
            await FavoritesService.instance.addToFavorites(context, file);
          } catch (e, s) {
            _logger.severe(e, s);
            hasError = true;
            showToast(context, "Sorry, could not add this to favorites!");
          } finally {
            if (shouldBlockUser) {
              await dialog.hide();
            }
          }
        } else {
          try {
            await FavoritesService.instance.removeFromFavorites(context, file);
          } catch (e, s) {
            _logger.severe(e, s);
            hasError = true;
            showToast(context, "Sorry, could not remove this from favorites!");
          }
        }
        return hasError ? oldValue : isLiked;
      },
      likeBuilder: (isLiked) {
        return Icon(
          isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color:
              isLiked ? Colors.pinkAccent : Colors.white, //same for both themes
          size: 24,
        );
      },
    );
  }

  Future<void> _showSingleFileDeleteSheet(File file) async {
    await showSingleFileDeleteSheet(
      context,
      file,
      onFileRemoved: widget.onFileRemoved,
    );
  }

  Future<void> _download(File file) async {
    final dialog = createProgressDialog(context, "Downloading...");
    await dialog.show();
    try {
      final FileType type = file.fileType;
      final bool downloadLivePhotoOnDroid =
          type == FileType.livePhoto && Platform.isAndroid;
      AssetEntity? savedAsset;
      final io.File? fileToSave = await getFile(file);
      //Disabling notifications for assets changing to insert the file into
      //files db before triggering a sync.
      PhotoManager.stopChangeNotify();
      if (type == FileType.image) {
        savedAsset = await PhotoManager.editor
            .saveImageWithPath(fileToSave!.path, title: file.title!);
      } else if (type == FileType.video) {
        savedAsset = await PhotoManager.editor
            .saveVideo(fileToSave!, title: file.title!);
      } else if (type == FileType.livePhoto) {
        final io.File? liveVideoFile =
            await getFileFromServer(file, liveVideo: true);
        if (liveVideoFile == null) {
          throw AssertionError("Live video can not be null");
        }
        if (downloadLivePhotoOnDroid) {
          await _saveLivePhotoOnDroid(fileToSave!, liveVideoFile, file);
        } else {
          savedAsset = await PhotoManager.editor.darwin.saveLivePhoto(
            imageFile: fileToSave!,
            videoFile: liveVideoFile,
            title: file.title!,
          );
        }
      }

      if (savedAsset != null) {
        file.localID = savedAsset.id;
        await FilesDB.instance.insert(file);
        Bus.instance.fire(
          LocalPhotosUpdatedEvent(
            [file],
            source: "download",
          ),
        );
      } else if (!downloadLivePhotoOnDroid && savedAsset == null) {
        _logger.severe('Failed to save assert of type $type');
      }
      showToast(context, "File saved to gallery");
      await dialog.hide();
    } catch (e) {
      _logger.warning("Failed to save file", e);
      await dialog.hide();
      showGenericErrorDialog(context: context);
    } finally {
      PhotoManager.startChangeNotify();
      LocalSyncService.instance.checkAndSync().ignore();
    }
  }

  Future<void> _saveLivePhotoOnDroid(
    io.File image,
    io.File video,
    File enteFile,
  ) async {
    debugPrint("Downloading LivePhoto on Droid");
    AssetEntity? savedAsset = await (PhotoManager.editor
        .saveImageWithPath(image.path, title: enteFile.title!));
    if (savedAsset == null) {
      throw Exception("Failed to save image of live photo");
    }
    IgnoredFile ignoreVideoFile = IgnoredFile(
      savedAsset.id,
      savedAsset.title ?? '',
      savedAsset.relativePath ?? 'remoteDownload',
      "remoteDownload",
    );
    await IgnoredFilesService.instance.cacheAndInsert([ignoreVideoFile]);
    final videoTitle = file_path.basenameWithoutExtension(enteFile.title!) +
        file_path.extension(video.path);
    savedAsset = (await (PhotoManager.editor.saveVideo(
      video,
      title: videoTitle,
    )));
    if (savedAsset == null) {
      throw Exception("Failed to save video of live photo");
    }

    ignoreVideoFile = IgnoredFile(
      savedAsset.id,
      savedAsset.title ?? videoTitle,
      savedAsset.relativePath ?? 'remoteDownload',
      "remoteDownload",
    );
    await IgnoredFilesService.instance.cacheAndInsert([ignoreVideoFile]);
  }

  Future<void> _setAs(File file) async {
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    try {
      final io.File? fileToSave = await (getFile(file));
      if (fileToSave == null) {
        throw Exception("Fail to get file for setAs operation");
      }
      final m = MediaExtension();
      final bool result = await m.setAs("file://${fileToSave.path}", "image/*");
      if (result == false) {
        showShortToast(context, "Something went wrong");
      }
      dialog.hide();
    } catch (e) {
      dialog.hide();
      _logger.severe("Failed to use as", e);
      showGenericErrorDialog(context: context);
    }
  }
}
