import "dart:async";

import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/events/event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/recent_searches.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/search/result/search_result_page.dart";
import "package:photos/ui/viewer/search/search_section_cta.dart";
import "package:photos/ui/viewer/search_tab/section_header.dart";
import "package:photos/utils/navigation_util.dart";

class ContactsSection extends StatefulWidget {
  final List<GenericSearchResult> contactSearchResults;
  const ContactsSection(this.contactSearchResults, {super.key});

  @override
  State<ContactsSection> createState() => _ContactsSectionState();
}

class _ContactsSectionState extends State<ContactsSection> {
  late List<GenericSearchResult> _contactSearchResults;
  final streamSubscriptions = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    _contactSearchResults = widget.contactSearchResults;

    final streamsToListenTo = SectionType.contacts.sectionUpdateEvents();
    for (Stream<Event> stream in streamsToListenTo) {
      streamSubscriptions.add(
        stream.listen((event) async {
          _contactSearchResults = (await SectionType.contacts.getData(
            context,
            limit: kSearchSectionLimit,
          )) as List<GenericSearchResult>;
          setState(() {});
        }),
      );
    }
  }

  @override
  void dispose() {
    for (var subscriptions in streamSubscriptions) {
      subscriptions.cancel();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ContactsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _contactSearchResults = widget.contactSearchResults;
  }

  @override
  Widget build(BuildContext context) {
    if (_contactSearchResults.isEmpty) {
      final textTheme = getEnteTextTheme(context);
      return Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SectionType.contacts.sectionTitle(context),
                    style: textTheme.largeBold,
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      SectionType.contacts.getEmptyStateText(context),
                      style: textTheme.smallMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SearchSectionEmptyCTAIcon(SectionType.contacts),
          ],
        ),
      );
    } else {
      final recommendations = <Widget>[
        ..._contactSearchResults.map(
          (contactSearchResult) => ContactRecommendation(contactSearchResult),
        ),
        const ContactCTA(),
      ];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              SectionType.contacts,
              hasMore:
                  (_contactSearchResults.length >= kSearchSectionLimit - 1),
            ),
            const SizedBox(height: 2),
            SizedBox(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 4.5),
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: recommendations,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

class ContactRecommendation extends StatelessWidget {
  final GenericSearchResult contactSearchResult;
  const ContactRecommendation(this.contactSearchResult, {super.key});

  @override
  Widget build(BuildContext context) {
    final heroTag = contactSearchResult.heroTag() +
        (contactSearchResult.previewThumbnail()?.tag ?? "");
    final enteTextTheme = getEnteTextTheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: GestureDetector(
        onTap: () {
          RecentSearches().add(contactSearchResult.name());
          if (contactSearchResult.onResultTap != null) {
            contactSearchResult.onResultTap!(context);
          } else {
            routeToPage(
              context,
              SearchResultPage(contactSearchResult),
            );
          }
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: double.infinity,
            minHeight: 115.5,
            maxWidth: 100,
            minWidth: 100,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 4.25, vertical: 10.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 67.75,
                    height: 67.75,
                    child: contactSearchResult.previewThumbnail() != null
                        ? Hero(
                            tag: heroTag,
                            child: ThumbnailWidget(
                              contactSearchResult.previewThumbnail()!,
                              shouldShowArchiveStatus: false,
                              shouldShowSyncStatus: false,
                            ),
                          )
                        : const NoThumbnailWidget(),
                  ),
                ),
                const SizedBox(height: 10.5),
                SizedBox(
                  width: 91.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        contactSearchResult.name(),
                        style: enteTextTheme.small,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContactCTA extends StatelessWidget {
  const ContactCTA({super.key});

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = getEnteColorScheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: GestureDetector(
        onTap: SectionType.contacts.ctaOnTap(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: double.infinity,
            minHeight: 115.5,
            maxWidth: 100,
            minWidth: 100,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 4.25, vertical: 10.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DottedBorder(
                  borderType: BorderType.Circle,
                  strokeWidth: 1.5,
                  borderPadding: const EdgeInsets.all(0.75),
                  dashPattern: const [4, 4],
                  radius: const Radius.circular(2.35),
                  padding: EdgeInsets.zero,
                  color: enteColorScheme.strokeFaint,
                  child: SizedBox(
                    height: 67.75,
                    width: 67.75,
                    child: Icon(
                      Icons.adaptive.share,
                      color: enteColorScheme.strokeFaint,
                    ),
                  ),
                ),
                const SizedBox(height: 10.5),
                Text(
                  S.of(context).invite,
                  style: getEnteTextTheme(context).smallFaint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
