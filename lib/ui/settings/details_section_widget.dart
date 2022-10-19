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
  final ValueNotifier<bool> _isStorageCardPressed = ValueNotifier(false);

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
        onTapDown: (details) {
          _isStorageCardPressed.value = true;
        },
        onTapUp: (details) {
          _isStorageCardPressed.value = false;
        },
        child: containerForUserDetails(inheritedUserDetails),
      );
    }
  }

  Widget containerForUserDetails(
    InheritedUserDetails inheritedUserDetails,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 350),
      child: AspectRatio(
        aspectRatio: 2 / 1,
        child: Stack(
          children: [
            _background,
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: FutureBuilder(
                future: inheritedUserDetails.userDetails,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return userDetails(snapshot.data as UserDetails);
                  }
                  if (snapshot.hasError) {
                    _logger.severe(
                        'failed to load user details', snapshot.error);
                    return const EnteLoadingWidget();
                  }
                  return const EnteLoadingWidget();
                },
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ValueListenableBuilder<bool>(
                  builder: (BuildContext context, bool value, Widget? child) {
                    return Icon(
                      Icons.chevron_right_outlined,
                      color: value ? strokeMutedDark : strokeBaseDark,
                    );
                  },
                  valueListenable: _isStorageCardPressed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget userDetails(UserDetails userDetails) {
    const hundredMBinBytes = 107374182;

    final isMobileScreenSmall = MediaQuery.of(context).size.width <= 365;
    final freeSpaceInBytes = userDetails.getFreeStorage();
    final shouldShowFreeSpaceInMBs = freeSpaceInBytes < hundredMBinBytes;

    final usedSpaceInGB =
        convertBytesToGBs(userDetails.getFamilyOrPersonalUsage());
    final totalStorageInGB = convertBytesToGBs(userDetails.getTotalStorage());

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Storage",
                style: getEnteTextTheme(context)
                    .small
                    .copyWith(color: textMutedDark),
              ),
              const SizedBox(height: 2),
              RichText(
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                text: TextSpan(
                  style: getEnteTextTheme(context)
                      .h3Bold
                      .copyWith(color: textBaseDark),
                  children: [
                    TextSpan(text: usedSpaceInGB.toString()),
                    TextSpan(text: isMobileScreenSmall ? "/" : " GB of "),
                    TextSpan(text: totalStorageInGB.toString() + " GB used"),
                  ],
                ),
              ),
            ],
          ),
        ),
        Column(
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
                          const SizedBox(width: 4),
                          Text(
                            "You",
                            style: getEnteTextTheme(context)
                                .miniBold
                                .copyWith(color: textBaseDark),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 8.71,
                            height: 8.99,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.75),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Family",
                            style: getEnteTextTheme(context)
                                .miniBold
                                .copyWith(color: textBaseDark),
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
                RichText(
                  text: TextSpan(
                    style: getEnteTextTheme(context)
                        .mini
                        .copyWith(color: textFaintDark),
                    children: [
                      TextSpan(
                        text:
                            "${shouldShowFreeSpaceInMBs ? convertBytesToMBs(freeSpaceInBytes) : _roundedFreeSpace(totalStorageInGB, usedSpaceInGB)}",
                      ),
                      TextSpan(
                        text:
                            shouldShowFreeSpaceInMBs ? " MB free" : " GB free",
                      )
                    ],
                  ),
                ),
              ],
            ),
          ],
        )
      ],
    );
  }

  num _roundedFreeSpace(num totalStorageInGB, num usedSpaceInGB) {
    int fractionDigits;
    //subtracting usedSpace from totalStorage in GB instead of converting from bytes so that free space and used space adds up in the UI
    final freeSpace = totalStorageInGB - usedSpaceInGB;
    //show one decimal place if free space is less than 10GB
    if (freeSpace < 10) {
      fractionDigits = 1;
    } else {
      fractionDigits = 0;
    }
    //omit decimal if decimal is 0
    if (fractionDigits == 1 && freeSpace.remainder(1) == 0) {
      fractionDigits = 0;
    }
    return num.parse(freeSpace.toStringAsFixed(fractionDigits));
  }
}
