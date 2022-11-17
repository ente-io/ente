import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/trash_file.dart';
import 'package:photos/theme/colors.dart';
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.6),
          ],
          stops: const [0.75, 1],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 4),
          child: Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: Colors.white.withOpacity(0.9),
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

class FavoriteOverlayIcon extends StatelessWidget {
  const FavoriteOverlayIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: EdgeInsets.only(left: 4, bottom: 4),
        child: Icon(
          Icons.favorite_rounded,
          size: 20,
          color: Colors.white, // fixed
        ),
      ),
    );
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
          color: strokeMutedDark,
        ),
      ),
    );
  }
}
