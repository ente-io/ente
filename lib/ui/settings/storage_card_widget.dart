import 'dart:math';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/states/user_details_state.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/loading_widget.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:photos/ui/payment/subscription.dart';
import 'package:photos/ui/settings/storage_error_widget.dart';
import 'package:photos/ui/settings/storage_progress_widget.dart';
import 'package:photos/utils/data_util.dart';

class StorageCardWidget extends StatefulWidget {
  const StorageCardWidget({Key? key}) : super(key: key);

  @override
  State<StorageCardWidget> createState() => _StorageCardWidgetState();
}

class _StorageCardWidgetState extends State<StorageCardWidget> {
  late Image _background;
  final _logger = Logger((_StorageCardWidgetState).toString());
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
  void dispose() {
    _isStorageCardPressed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inheritedUserDetails = InheritedUserDetails.of(context);

    if (inheritedUserDetails == null) {
      _logger.severe(
        (InheritedUserDetails).toString() + 'is null',
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
        onTapDown: (details) => _isStorageCardPressed.value = true,
        onTapCancel: () => _isStorageCardPressed.value = false,
        onTapUp: (details) => _isStorageCardPressed.value = false,
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
            FutureBuilder(
              future: inheritedUserDetails.userDetails,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return userDetails(snapshot.data as UserDetails);
                }
                if (snapshot.hasError) {
                  _logger.severe(
                    'failed to load user details',
                    snapshot.error,
                  );
                  return const StorageErrorWidget();
                }
                return const EnteLoadingWidget(color: strokeBaseDark);
              },
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
    const oneTBinBytes = 1073741824000;

    final usedStorageInBytes = userDetails.getFamilyOrPersonalUsage();
    final totalStorageInBytes = userDetails.getTotalStorage();
    final freeStorageInBytes = totalStorageInBytes - usedStorageInBytes;

    final isMobileScreenSmall = MediaQuery.of(context).size.width <= 336;
    final shouldShowFreeSpaceInMBs = freeStorageInBytes < hundredMBinBytes;
    final shouldShowFreeSpaceInTBs = freeStorageInBytes >= oneTBinBytes;
    final shouldShowUsedStorageInTBs = usedStorageInBytes >= oneTBinBytes;
    final shouldShowTotalStorageInTBs = totalStorageInBytes >= oneTBinBytes;
    final shouldShowUsedStorageInMBs = usedStorageInBytes < hundredMBinBytes;

    final usedStorageInGB = roundBytesUsedToGBs(
      usedStorageInBytes,
      freeStorageInBytes,
    );
    final totalStorageInGB = convertBytesToGBs(totalStorageInBytes).truncate();

    final usedStorageInTB = roundGBsToTBs(usedStorageInGB);
    final totalStorageInTB = roundGBsToTBs(totalStorageInGB);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        20,
        16,
        isMobileScreenSmall ? 12 : 20,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMobileScreenSmall ? "Used space" : "Storage",
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
                    children: _usedStorageDetails(
                      isMobileScreenSmall: isMobileScreenSmall,
                      shouldShowTotalStorageInTBs: shouldShowTotalStorageInTBs,
                      shouldShowUsedStorageInTBs: shouldShowUsedStorageInTBs,
                      shouldShowUsedStorageInMBs: shouldShowUsedStorageInMBs,
                      usedStorageInBytes: usedStorageInBytes,
                      usedStorageInGB: usedStorageInGB,
                      totalStorageInTB: totalStorageInTB,
                      usedStorageInTB: usedStorageInTB,
                      totalStorageInGB: totalStorageInGB,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Stack(
                children: <Widget>[
                  const StorageProgressWidget(
                    color:
                        Color.fromRGBO(255, 255, 255, 0.2), //hardcoded in figma
                    fractionOfStorage: 1,
                  ),
                  userDetails.isPartOfFamily()
                      ? StorageProgressWidget(
                          color: strokeBaseDark,
                          fractionOfStorage:
                              ((userDetails.getFamilyOrPersonalUsage()) /
                                  userDetails.getTotalStorage()),
                        )
                      : const SizedBox.shrink(),
                  StorageProgressWidget(
                    color: userDetails.isPartOfFamily()
                        ? getEnteColorScheme(context).primary300
                        : strokeBaseDark,
                    fractionOfStorage:
                        (userDetails.usage / userDetails.getTotalStorage()),
                  )
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
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: getEnteColorScheme(context).primary300,
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
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: textBaseDark,
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
                      : const SizedBox.shrink(),
                  RichText(
                    text: TextSpan(
                      style: getEnteTextTheme(context)
                          .mini
                          .copyWith(color: textFaintDark),
                      children: [
                        TextSpan(
                          text:
                              "${shouldShowFreeSpaceInMBs ? max(0, convertBytesToMBs(freeStorageInBytes)) : _roundedFreeSpace(totalStorageInGB, usedStorageInGB)}",
                        ),
                        TextSpan(
                          text: shouldShowFreeSpaceInTBs
                              ? " TB free"
                              : shouldShowFreeSpaceInMBs
                                  ? " MB free"
                                  : " GB free",
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  num _roundedFreeSpace(num totalStorageInGB, num usedStorageInGB) {
    int fractionDigits;
    //subtracting usedSpace from totalStorage in GB instead of converting from bytes so that free space and used space adds up in the UI
    final freeStorage = totalStorageInGB - usedStorageInGB;

    if (freeStorage >= 1000) {
      return roundGBsToTBs(freeStorage);
    }
    //show one decimal place if free space is less than 10GB
    if (freeStorage < 10) {
      fractionDigits = 1;
    } else {
      fractionDigits = 0;
    }
    //omit decimal if decimal is 0
    if (fractionDigits == 1 && freeStorage.remainder(1) == 0) {
      fractionDigits = 0;
    }
    return num.parse(freeStorage.toStringAsFixed(fractionDigits));
  }

  List<TextSpan> _usedStorageDetails({
    @required isMobileScreenSmall,
    @required shouldShowUsedStorageInTBs,
    @required shouldShowTotalStorageInTBs,
    @required shouldShowUsedStorageInMBs,
    @required usedStorageInBytes,
    @required usedStorageInGB,
    @required totalStorageInGB,
    @required usedStorageInTB,
    @required totalStorageInTB,
  }) {
    if (isMobileScreenSmall) {
      return [
        TextSpan(text: usedStorageInGB.toString() + "/"),
        TextSpan(text: totalStorageInGB.toString() + " GB"),
      ];
    }

    return [
      TextSpan(
        text: shouldShowUsedStorageInTBs
            ? usedStorageInTB.toString() + " TB of "
            : shouldShowUsedStorageInMBs
                ? convertBytesToMBs(usedStorageInBytes).toString() + " MB of "
                : usedStorageInGB.toString() + " GB of ",
      ),
      TextSpan(
        text: shouldShowTotalStorageInTBs
            ? totalStorageInTB.toString() + " TB used"
            : totalStorageInGB.toString() + " GB used",
      ),
    ];
  }
}
