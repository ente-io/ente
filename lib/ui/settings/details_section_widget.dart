import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/count_of_file_types.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/states/user_details_state.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/loading_widget.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:photos/ui/payment/subscription.dart';
import 'package:photos/utils/data_util.dart';

class DetailsSectionWidget extends StatefulWidget {
  const DetailsSectionWidget({Key? key}) : super(key: key);

  @override
  State<DetailsSectionWidget> createState() => _DetailsSectionWidgetState();
}

class _DetailsSectionWidgetState extends State<DetailsSectionWidget> {
  late Image _background;
  final _logger = Logger((_DetailsSectionWidgetState).toString());

  @override
  void initState() {
    super.initState();
    _background = const Image(
      image: AssetImage("assets/storage_card_background.png"),
      fit: BoxFit.fill,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // precache background image to avoid flicker
    // https://stackoverflow.com/questions/51343735/flutter-image-preload
    precacheImage(_background.image, context);
  }

  @override
  Widget build(BuildContext context) {
    final inheritedUserDetails = InheritedUserDetails.of(context);

    if (inheritedUserDetails == null) {
      _logger.severe(
        (InheritedUserDetails).toString() +
            ' not found before ' +
            (_DetailsSectionWidgetState).toString() +
            ' on tree',
      );
      throw Error();
    } else {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () async {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) {
                return getSubscriptionPage();
              },
            ),
          );
        },
        child: containerForUserDetails(inheritedUserDetails),
      );
    }
  }

  Widget containerForUserDetails(
    InheritedUserDetails inheritedUserDetails,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 428, maxHeight: 175),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            color: Colors.transparent,
            child: AspectRatio(
              aspectRatio: 2 / 1,
              child: _background,
            ),
          ),
          FutureBuilder(
            future: inheritedUserDetails.userDetails,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return userDetails(snapshot.data as UserDetails);
              }
              if (snapshot.hasError) {
                _logger.severe('failed to load user details', snapshot.error);
                return const EnteLoadingWidget();
              }
              return const EnteLoadingWidget();
            },
          ),
          const Align(
            alignment: Alignment.centerRight,
            child: Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget userDetails(UserDetails userDetails) {
    final usedSpaceInGB =
        convertUsedSpaceInBytesToGB(userDetails.getFamilyOrPersonalUsage());
    return Padding(
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Storage",
                    style: Theme.of(context).textTheme.subtitle2!.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                  ),
                  Text(
                    "$usedSpaceInGB GB of ${convertBytesToReadableFormat(userDetails.getTotalStorage())} used",
                    style: Theme.of(context)
                        .textTheme
                        .headline5!
                        .copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Stack(
                  children: <Widget>[
                    Container(
                      color: Colors.white.withOpacity(0.2),
                      width: MediaQuery.of(context).size.width,
                      height: 4,
                    ),
                    Container(
                      color: Colors.white.withOpacity(0.75),
                      width: MediaQuery.of(context).size.width *
                          ((userDetails.getFamilyOrPersonalUsage()) /
                              userDetails.getTotalStorage()),
                      height: 4,
                    ),
                    Container(
                      color: Colors.white,
                      width: MediaQuery.of(context).size.width *
                          (userDetails.usage / userDetails.getTotalStorage()),
                      height: 4,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    userDetails.isPartOfFamily()
                        ? Row(
                            children: [
                              Container(
                                width: 8.71,
                                height: 8.99,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                              ),
                              Text(
                                "You",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText1!
                                    .copyWith(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(right: 12),
                              ),
                              Container(
                                width: 8.71,
                                height: 8.99,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.75),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                              ),
                              Text(
                                "Family",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText1!
                                    .copyWith(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                              ),
                            ],
                          )
                        : FutureBuilder(
                            future: FilesDB.instance.fetchPhotoAndVideoCount(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final countOfFileTypes =
                                    snapshot.data as CountOfFileTypes;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${NumberFormat().format(countOfFileTypes.photosCount)} photos",
                                      style: getEnteTextTheme(context)
                                          .mini
                                          .copyWith(color: textBaseDark),
                                    ),
                                    Text(
                                      "${NumberFormat().format(countOfFileTypes.videosCount)} videos",
                                      style: getEnteTextTheme(context)
                                          .mini
                                          .copyWith(color: textBaseDark),
                                    ),
                                  ],
                                );
                              } else if (snapshot.hasError) {
                                _logger.severe(
                                  'Error fetching photo and video count',
                                  snapshot.error,
                                );
                                return const SizedBox.shrink();
                              } else {
                                return const EnteLoadingWidget();
                              }
                            },
                          ),
                    Text(
                      "${convertBytesToReadableFormat(userDetails.getFamilyOrPersonalUsage())} used",
                      style: Theme.of(context).textTheme.bodyText1!.copyWith(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
