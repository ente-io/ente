import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/trash_file.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/ui/sharing/user_avator_widget.dart';
import 'package:photos/utils/date_time_util.dart';

class ThumbnailPlaceHolder extends StatelessWidget {
  const ThumbnailPlaceHolder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.galleryThumbBackgroundColor,
    );
  }
}

class UnSyncedIcon extends StatelessWidget {
  const UnSyncedIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          // background: linear-gradient(73.58deg, rgba(0, 0, 0, 0.3) -6.66%, rgba(255, 255, 255, 0) 44.44%);
          colors: [
            Color.fromRGBO(255, 255, 255, 0),
            Colors.transparent,
            // Color.fromRGBO(0, 0, 0, 0.3),
          ],
          stops: [-0.067, 0.445],
        ),
      ),
      child: const Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: EdgeInsets.only(left: 4, bottom: 4),
          child: Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: fixedStrokeMutedWhite,
          ),
        ),
      ),
    );
  }
}

class VideoOverlayIcon extends StatelessWidget {
  const VideoOverlayIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 64,
      child: Icon(
        Icons.play_circle_outline,
        size: 40,
        color: Colors.white70,
      ),
    );
  }
}

class LivePhotoOverlayIcon extends StatelessWidget {
  const LivePhotoOverlayIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.only(right: 4, bottom: 4),
        child: Icon(
          Icons.album_outlined,
          size: 14,
          color: Colors.white, // fixed
        ),
      ),
    );
  }
}

class OwnerAvatarOverlayIcon extends StatelessWidget {
  final User user;
  const OwnerAvatarOverlayIcon(this.user, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 4, top: 4),
        child: UserAvatarWidget(
          user,
          type: AvatarType.tiny,
          thumbnailView: true,
        ),
      ),
    );
  }
}

class FavoriteOverlayIcon extends StatelessWidget {
  const FavoriteOverlayIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const BottomLeftOverlayIcon(Icons.favorite_rounded);
  }
}

class TrashedFileOverlayText extends StatelessWidget {
  final TrashFile file;

  const TrashedFileOverlayText(this.file, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.33), Colors.transparent],
        ),
      ),
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        daysLeft(file.deleteBy),
        style: Theme.of(context)
            .textTheme
            .subtitle2!
            .copyWith(color: Colors.white), //same for both themes
      ),
    );
  }
}

class ArchiveOverlayIcon extends StatelessWidget {
  const ArchiveOverlayIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: EdgeInsets.only(left: 4, bottom: 4),
        child: Icon(
          Icons.archive_outlined,
          size: 20,
          color: fixedStrokeMutedWhite,
        ),
      ),
    );
  }
}

// Base variations

/// Icon overlay in the bottom left.
///
/// This usually indicates ente specific state of a file, e.g. if it is
/// favorited/archived.
class BottomLeftOverlayIcon extends StatelessWidget {
  final IconData icon;

  /// Overriddable color. Default is a fixed white.
  final Color color;

  const BottomLeftOverlayIcon(
    this.icon, {
    Key? key,
    this.color = Colors.white, // fixed
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.center,
          colors: [
            Color.fromRGBO(0, 0, 0, 0.14),
            Color.fromRGBO(0, 0, 0, 0.05),
            Color.fromRGBO(0, 0, 0, 0.0),
          ],
          stops: [0, 0.6, 1],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Icon(
            icon,
            size: 22,
            color: color,
          ),
        ),
      ),
    );
  }
}
