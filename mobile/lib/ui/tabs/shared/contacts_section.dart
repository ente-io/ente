import "dart:async";

import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/recent_searches.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/tabs/shared/contacts_all_page.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/search/result/contact_result_page.dart";
import "package:photos/utils/debouncer.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/share_util.dart";

class ContactsSection extends StatefulWidget {
  const ContactsSection({super.key});

  @override
  State<ContactsSection> createState() => _ContactsSectionState();
}

class _ContactsSectionState extends State<ContactsSection> {
  late Future<List<GenericSearchResult>> _contactSearchResults;
  late final StreamSubscription<PeopleChangedEvent>
      _peopleChangedEventSubscription;
  final _logger = Logger("ContactsSection");
  late StreamSubscription<FilesUpdatedEvent> _filesUpdatedEvent;
  final _debouncer = Debouncer(
    const Duration(seconds: 2),
    executionInterval: const Duration(seconds: 10),
  );

  @override
  void initState() {
    super.initState();
    //Adding delay to avoid operation on app start
    _contactSearchResults =
        Future.delayed(const Duration(seconds: 2)).then((_) {
      return SearchService.instance
          .getAllContactsSearchResults(kSearchSectionLimit);
    });

    _filesUpdatedEvent = Bus.instance.on<FilesUpdatedEvent>().listen((event) {
      _reloadContacts();
    });
    _peopleChangedEventSubscription =
        Bus.instance.on<PeopleChangedEvent>().listen((event) {
      if (event.type == PeopleEventType.saveOrEditPerson) {
        _reloadContacts();
      }
    });
  }

  @override
  void dispose() {
    _peopleChangedEventSubscription.cancel();
    _filesUpdatedEvent.cancel();
    _debouncer.cancelDebounceTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GenericSearchResult>>(
      future: _contactSearchResults,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final results = snapshot.data!;
          if (results.isEmpty) {
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
                          S.of(context).contacts,
                          style: textTheme.largeBold,
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            S.of(context).searchPeopleEmptySection,
                            style: textTheme.smallMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const _ContactsSectionEmptyCTAIcon(),
                ],
              ),
            );
          } else {
            final recommendations = <Widget>[
              ...results.map(
                (contactSearchResult) =>
                    ContactRecommendation(contactSearchResult),
              ),
              const ContactCTA(),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  hasMore: (results.length >= kSearchSectionLimit - 1),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 4.5),
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: recommendations,
                  ),
                ),
              ],
            );
          }
        } else if (snapshot.hasError) {
          _logger.severe("Error loading contacts: ${snapshot.error}");
        }
        return const RepaintBoundary(
          child: EnteLoadingWidget(),
        );
      },
    );
  }

  void _reloadContacts() {
    _debouncer.run(
      () async {
        if (mounted) {
          setState(() {
            _contactSearchResults = SearchService.instance
                .getAllContactsSearchResults(kSearchSectionLimit);
          });
        }
      },
    );
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
              ContactResultPage(contactSearchResult),
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
        onTap: () async {
          await shareText(
            S.of(context).shareTextRecommendUsingEnte,
          );
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

class _ContactsSectionEmptyCTAIcon extends StatelessWidget {
  const _ContactsSectionEmptyCTAIcon();

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return GestureDetector(
      onTap: () async {
        await shareText(
          S.of(context).shareTextRecommendUsingEnte,
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
        child: Column(
          children: [
            DottedBorder(
              color: colorScheme.strokeFaint,
              dashPattern: const [3.875, 3.875],
              borderType: BorderType.Circle,
              strokeWidth: 1.5,
              radius: const Radius.circular(33.25),
              child: SizedBox(
                width: 62.5,
                height: 62.5,
                child: Icon(
                  Icons.adaptive.share,
                  color: colorScheme.strokeFaint,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              S.of(context).invite,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: textTheme.miniFaint,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final bool hasMore;
  const _SectionHeader({required this.hasMore});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (hasMore) {
          routeToPage(
            context,
            const ContactsSectionAllPage(),
          );
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              S.of(context).contacts,
              style: getEnteTextTheme(context).largeBold,
            ),
          ),
          hasMore
              ? Container(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 12, 12),
                    child: Icon(
                      Icons.chevron_right_outlined,
                      color: getEnteColorScheme(context).strokeMuted,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
