import 'package:ente_pure_utils/ente_pure_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/user_details.dart';
import 'package:photos/states/user_details_state.dart';
import 'package:photos/theme/colors.dart';
import "package:photos/ui/common/loading_widget.dart";
import 'package:photos/ui/payment/subscription.dart';
import 'package:photos/ui/settings/storage_progress_widget.dart';

class StorageCardWidget extends StatefulWidget {
  const StorageCardWidget({super.key});

  @override
  State<StorageCardWidget> createState() => _StorageCardWidgetState();
}

class _StorageCardWidgetState extends State<StorageCardWidget> {
  final _logger = Logger((_StorageCardWidgetState).toString());
  int? familyMemberStorageLimit;
  bool showFamilyBreakup = false;

  @override
  Widget build(BuildContext context) {
    final inheritedUserDetails = InheritedUserDetails.of(context);
    final userDetails = inheritedUserDetails?.userDetails;

    if (inheritedUserDetails == null) {
      _logger.severe(
        (InheritedUserDetails).toString() + 'is null',
      );
      throw Error();
    } else {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () async {
          // ignore: unawaited_futures
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) {
                return getSubscriptionPage();
              },
            ),
          );
        },
        child: containerForUserDetails(userDetails),
      );
    }
  }

  Widget containerForUserDetails(
    UserDetails? userDetails,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0xFF212121),
            Color(0xFF434343),
          ],
        ),
      ),
      child: userDetails is UserDetails
          ? _userDetails(userDetails)
          : const EnteLoadingWidget(
              color: strokeBaseDark,
            ),
    );
  }

  Widget _userDetails(UserDetails userDetails) {
    const hundredMBinBytes = 107374182;
    const oneTBinBytes = 1073741824000;
    showFamilyBreakup = userDetails.isPartOfFamily();
    if (showFamilyBreakup) {
      familyMemberStorageLimit = userDetails.familyMemberStorageLimit();
      showFamilyBreakup = familyMemberStorageLimit == null;
    }

    final usedStorageInBytes = familyMemberStorageLimit != null
        ? userDetails.usage
        : userDetails.getFamilyOrPersonalUsage();
    final totalStorageInBytes = familyMemberStorageLimit != null
        ? familyMemberStorageLimit!
        : userDetails.getTotalStorage();
    final freeStorageInBytes = totalStorageInBytes - usedStorageInBytes;

    final isMobileScreenSmall =
        MediaQuery.of(context).size.width <= mobileSmallThreshold;
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMobileScreenSmall
                ? AppLocalizations.of(context).usedSpace
                : AppLocalizations.of(context).storage,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textMutedDark,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textBaseDark,
                letterSpacing: -1,
              ),
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
          const SizedBox(height: 16),
          Stack(
            children: <Widget>[
              const StorageProgressWidget(
                color: Color.fromRGBO(193, 193, 193, 0.11),
                fractionOfStorage: 1,
              ),
              showFamilyBreakup
                  ? StorageProgressWidget(
                      color: const Color(0xFFF4D93B), // Family: yellow
                      fractionOfStorage:
                          ((usedStorageInBytes) / totalStorageInBytes),
                    )
                  : const SizedBox.shrink(),
              StorageProgressWidget(
                color: const Color(0xFF08C225),
                fractionOfStorage: (userDetails.usage / totalStorageInBytes),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              showFamilyBreakup
                  ? Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF08C225),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context).storageBreakupYou,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: textBaseDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFF4D93B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context).storageBreakupFamily,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: textBaseDark,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
              Text(
                AppLocalizations.of(context).memoryCount(
                  count: userDetails.fileCount,
                  formattedCount: NumberFormat().format(userDetails.fileCount),
                ),
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color.fromRGBO(165, 165, 165, 0.79),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
        TextSpan(text: '$usedStorageInGB/$totalStorageInGB GB'),
      ];
    }
    late num currentUsage, totalStorage;
    late String currentUsageUnit, totalStorageUnit;

    // Determine the appropriate usage and units
    if (shouldShowUsedStorageInTBs) {
      currentUsage = usedStorageInTB;
      currentUsageUnit = "TB";
    } else if (shouldShowUsedStorageInMBs) {
      currentUsage = convertBytesToMBs(usedStorageInBytes);
      currentUsageUnit = "MB";
    } else {
      currentUsage = usedStorageInGB;
      currentUsageUnit = "GB";
    }

    // Determine the appropriate total storage and units
    if (shouldShowTotalStorageInTBs) {
      totalStorage = totalStorageInTB;
      totalStorageUnit = "TB";
    } else {
      totalStorage = totalStorageInGB;
      totalStorageUnit = "GB";
    }

    return [
      TextSpan(text: '$currentUsage $currentUsageUnit  '),
      const TextSpan(
        text: 'of',
        style: TextStyle(color: textMutedDark),
      ),
      TextSpan(text: '  $totalStorage $totalStorageUnit used'),
    ];
  }
}
