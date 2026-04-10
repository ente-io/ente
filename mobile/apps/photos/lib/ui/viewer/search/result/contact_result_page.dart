import "dart:async";

import "package:email_validator/email_validator.dart";
import "package:ente_contacts/contacts.dart" as contacts;
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/contacts_changed_event.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/models/gallery_type.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/search_constants.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/photos_contacts_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/collections/album/row_item.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/end_to_end_banner.dart";
import "package:photos/ui/components/menu_item_widget/menu_item_widget_new.dart";
import "package:photos/ui/viewer/actions/file_selection_overlay_bar.dart";
import "package:photos/ui/viewer/gallery/empty_state.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/gallery/hierarchical_search_gallery.dart";
import "package:photos/ui/viewer/gallery/state/boundary_reporter_mixin.dart";
import "package:photos/ui/viewer/gallery/state/gallery_boundaries_provider.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/inherited_search_filter_data.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";
import "package:photos/ui/viewer/hierarchicial_search/applied_filters_for_appbar.dart";
import "package:photos/ui/viewer/hierarchicial_search/recommended_filters_for_appbar.dart";
import "package:photos/ui/viewer/people/person_selection_action_widgets.dart";
import "package:photos/ui/viewer/search/contact_avatar_widget.dart";
import "package:photos/ui/viewer/search/result/edit_contact_page.dart";

class ContactResultPage extends StatefulWidget {
  final SearchResult searchResult;
  final bool enableGrouping;
  final String tagPrefix;

  static const GalleryType appBarType = GalleryType.searchResults;
  static const GalleryType overlayType = GalleryType.searchResults;

  const ContactResultPage(
    this.searchResult, {
    this.enableGrouping = true,
    this.tagPrefix = "",
    super.key,
  });

  @override
  State<ContactResultPage> createState() => _ContactResultPageState();
}

class _ContactResultPageState extends State<ContactResultPage> {
  final _selectedFiles = SelectedFiles();
  late final List<EnteFile> files;
  late final List<Collection> collections;
  late final StreamSubscription<LocalPhotosUpdatedEvent> _filesUpdatedEvent;
  StreamSubscription<ContactsChangedEvent>? _contactsChangedEvent;
  late String _searchResultName;
  late final String _contactEmail;
  late final int? _contactUserId;
  late final SearchFilterDataProvider _searchFilterDataProvider;
  contacts.ContactRecord? _savedContact;
  bool _resolvedSavedContact = false;

  @override
  void initState() {
    super.initState();
    final params = (widget.searchResult as GenericSearchResult).params;
    files = widget.searchResult.resultFiles();
    collections = params[kContactCollections] ?? <Collection>[];
    _searchResultName = widget.searchResult.name();
    _contactEmail = params[kContactEmail] as String? ?? _searchResultName;
    _contactUserId = params[kContactUserId] as int?;
    _filesUpdatedEvent =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      if (event.type == EventType.deletedFromDevice ||
          event.type == EventType.deletedFromEverywhere ||
          event.type == EventType.deletedFromRemote ||
          event.type == EventType.hide) {
        for (var updatedFile in event.updatedFiles) {
          files.remove(updatedFile);
        }
        setState(() {});
      }
    });

    _searchFilterDataProvider = SearchFilterDataProvider(
      initialGalleryFilter: widget.searchResult.getHierarchicalSearchFilter(),
    );

    if (flagService.enableContact && _contactUserId != null) {
      _refreshSavedContact();
      _contactsChangedEvent =
          Bus.instance.on<ContactsChangedEvent>().listen((event) {
        if (event.matchesContactUserId(_contactUserId)) {
          _refreshSavedContact();
        }
      });
    }
  }

  @override
  void dispose() {
    _filesUpdatedEvent.cancel();
    _contactsChangedEvent?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        final result = files
            .where(
              (file) =>
                  file.creationTime! >= creationStartTime &&
                  file.creationTime! <= creationEndTime,
            )
            .toList();
        return Future.value(
          FileLoadResult(
            result,
            result.length < files.length,
          ),
        );
      },
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      removalEventTypes: const {
        EventType.deletedFromRemote,
        EventType.deletedFromEverywhere,
        EventType.hide,
      },
      tagPrefix: widget.tagPrefix + widget.searchResult.heroTag(),
      selectedFiles: _selectedFiles,
      enableFileGrouping: widget.enableGrouping,
      initialFiles: widget.searchResult.resultFiles().isNotEmpty
          ? [widget.searchResult.resultFiles().first]
          : null,
      header: _buildPageHeader(context),
      emptyState: _shouldShowUnsavedContactEmptyState
          ? _UnsavedContactEmptyState(email: _contactEmail)
          : const EmptyState(),
    );

    return GalleryBoundariesProvider(
      child: GalleryFilesState(
        child: InheritedSearchFilterDataWrapper(
          searchFilterDataProvider: _searchFilterDataProvider,
          child: Scaffold(
            backgroundColor: getEnteColorScheme(context).backgroundColour,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(
                _ContactResultAppBar.preferredHeight(
                  isHierarchicalSearchable: true,
                ),
              ),
              child: widget.enableGrouping
                  ? const _ContactResultAppBar(
                      isHierarchicalSearchable: true,
                    )
                  : const _AppBarWithBoundary(
                      child: _ContactResultAppBar(
                        isHierarchicalSearchable: true,
                      ),
                    ),
            ),
            body: SelectionState(
              selectedFiles: _selectedFiles,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Builder(
                    builder: (context) {
                      return ValueListenableBuilder(
                        valueListenable: InheritedSearchFilterData.of(context)
                            .searchFilterDataProvider!
                            .isSearchingNotifier,
                        builder: (context, value, _) {
                          return value
                              ? HierarchicalSearchGallery(
                                  tagPrefix: widget.tagPrefix,
                                  selectedFiles: _selectedFiles,
                                )
                              : gallery;
                        },
                      );
                    },
                  ),
                  FileSelectionOverlayBar(
                    ContactResultPage.overlayType,
                    _selectedFiles,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactHeader(BuildContext context) {
    if (flagService.enableContact && _contactUserId != null) {
      if (!_resolvedSavedContact) {
        return const Padding(
          padding: EdgeInsets.only(top: 20, bottom: 8),
          child: SizedBox(
            height: 88,
            child: Center(child: EnteLoadingWidget()),
          ),
        );
      }
      if (_savedContact == null) {
        return _UnsavedContactHeader(
          email: _contactEmail,
          itemCount: files.length,
          onTap: _openEditContactPage,
        );
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ContactAvatarWidget(
              contactUserId: _contactUserId,
              email: _contactEmail,
              personId: (widget.searchResult as GenericSearchResult)
                  .params[kPersonParamID] as String?,
              size: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _savedContact?.data?.name ?? _searchResultName,
                    style: _contactHeaderTitleStyle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _savedContact?.email ?? _contactEmail,
                    style: _contactHeaderSubtitleStyle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _ContactHeaderOverflowButton(onEdit: _openEditContactPage),
          ],
        ),
      );
    }

    if (EmailValidator.validate(_searchResultName)) {
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: EndToEndBanner(
          title: context.l10n.linkPerson,
          caption: context.l10n.linkPersonCaption,
          leadingIcon: Icons.person,
          onTap: () async {
            final PersonEntity? updatedPerson = await routeToPage(
              context,
              LinkContactToPersonSelectionPage(
                emailToLink: _searchResultName,
              ),
            );
            if (updatedPerson != null && mounted) {
              setState(() {
                _searchResultName = updatedPerson.data.name;
              });
            }
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget? _buildPageHeader(BuildContext context) {
    final sections = <Widget>[
      _buildContactHeader(context),
      if (collections.isNotEmpty)
        _AlbumsSection(context: context, collections: collections),
    ].whereType<Widget>().toList();
    if (sections.isEmpty) {
      return null;
    }
    return Column(children: sections);
  }

  bool get _shouldShowUnsavedContactEmptyState =>
      flagService.enableContact &&
      _contactUserId != null &&
      _resolvedSavedContact &&
      _savedContact == null &&
      files.isEmpty &&
      collections.isEmpty;

  Future<void> _refreshSavedContact() async {
    final contactUserId = _contactUserId;
    if (contactUserId == null) {
      return;
    }
    final saved = await PhotosContactsService.instance.getContactByUserId(
      contactUserId,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _savedContact = saved;
      _resolvedSavedContact = true;
    });
  }

  Future<void> _openEditContactPage() async {
    final contactUserId = _contactUserId;
    if (contactUserId == null) {
      return;
    }
    final updated = await routeToPage(
      context,
      EditContactPage(
        contactUserId: contactUserId,
        email: _contactEmail,
        existingContact: _savedContact,
      ),
    );
    if (updated is contacts.ContactRecord && mounted) {
      setState(() {
        _savedContact = updated;
      });
    }
  }

  TextStyle _contactHeaderTitleStyle(BuildContext context) {
    return getEnteTextTheme(context).largeBold.copyWith(
          fontSize: 20,
          height: 28 / 20,
        );
  }

  TextStyle _contactHeaderSubtitleStyle(BuildContext context) {
    return getEnteTextTheme(context).mini.copyWith(
          color: getEnteColorScheme(context).textMuted,
          height: 16 / 12,
          fontWeight: FontWeight.w500,
        );
  }
}

enum _ContactHeaderAction { edit }

class _ContactHeaderOverflowButton extends StatelessWidget {
  const _ContactHeaderOverflowButton({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Container(
      decoration: BoxDecoration(
        color: EnteTheme.isDark(context)
            ? colorScheme.backgroundElevated2
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.strokeFainter),
      ),
      child: PopupMenuButton<_ContactHeaderAction>(
        tooltip: "",
        padding: const EdgeInsets.all(2),
        iconSize: 18,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: colorScheme.fill,
        icon: Icon(Icons.more_vert_rounded, color: colorScheme.textBase),
        onSelected: (value) {
          switch (value) {
            case _ContactHeaderAction.edit:
              onEdit();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<_ContactHeaderAction>(
            value: _ContactHeaderAction.edit,
            child: Text(context.l10n.edit),
          ),
        ],
      ),
    );
  }
}

class _AlbumsSection extends StatelessWidget {
  const _AlbumsSection({
    required this.context,
    required this.collections,
  });

  final BuildContext context;
  final List<Collection> collections;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              AppLocalizations.of(context).albums,
              style: getEnteTextTheme(context).largeBold,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 142,
              child: ListView.separated(
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                scrollDirection: Axis.horizontal,
                itemCount: collections.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final item = collections[index];
                  return AlbumRowItemWidget(
                    item,
                    108,
                    key: ValueKey('contact_result_${item.id}'),
                    showFileCount: false,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnsavedContactHeader extends StatelessWidget {
  const _UnsavedContactHeader({
    required this.email,
    required this.itemCount,
    required this.onTap,
  });

  final String email;
  final int itemCount;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            email,
            style: textTheme.largeBold.copyWith(
              fontSize: 20,
              height: 28 / 20,
            ),
          ),
          const SizedBox(height: 20),
          MenuItemWidgetNew(
            title: l10n.addANameAndPhoto,
            subText: l10n.itemCount(count: itemCount),
            titleColor: colorScheme.textBase,
            subTextStyle: textTheme.mini.copyWith(
              color: colorScheme.textMuted,
              height: 16 / 12,
            ),
            titleToSubTextSpacing: 4,
            leadingIconWidget: _AddContactMenuIcon(colorScheme: colorScheme),
            leadingIconSize: 36,
            trailingIcon: Icons.chevron_right_rounded,
            trailingIconIsMuted: true,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _AddContactMenuIcon extends StatelessWidget {
  const _AddContactMenuIcon({required this.colorScheme});

  final EnteColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.greenLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.person_add_alt_1_rounded,
        size: 18,
        color: colorScheme.greenBase,
      ),
    );
  }
}

class _UnsavedContactEmptyState extends StatelessWidget {
  const _UnsavedContactEmptyState({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/ducky_share.png",
              height: 180,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(height: 180);
              },
            ),
            const SizedBox(height: 12),
            Text(
              l10n.nothingToSeeHere,
              style: textTheme.largeBold.copyWith(
                fontSize: 18,
                height: 24 / 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.photosSharedByWillAppearHere(email: email),
              textAlign: TextAlign.center,
              style: textTheme.mini.copyWith(
                color: colorScheme.textMuted,
                height: 16 / 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactResultAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  static const _toolbarHeight = 56.0;
  static const _bottomPadding = 8.0;

  final bool isHierarchicalSearchable;

  const _ContactResultAppBar({
    required this.isHierarchicalSearchable,
  });

  static double preferredHeight({required bool isHierarchicalSearchable}) {
    return isHierarchicalSearchable
        ? _toolbarHeight + kFilterChipHeight + _bottomPadding + 1
        : _toolbarHeight;
  }

  @override
  Size get preferredSize => Size.fromHeight(
        preferredHeight(isHierarchicalSearchable: isHierarchicalSearchable),
      );

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    if (!isHierarchicalSearchable) {
      return AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.backgroundColour,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
      );
    }

    final searchFilterData = InheritedSearchFilterData.of(context);
    return ValueListenableBuilder(
      valueListenable:
          searchFilterData.searchFilterDataProvider!.isSearchingNotifier,
      builder: (context, isSearching, _) {
        return AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: colorScheme.backgroundColour,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 0,
          bottom: isSearching
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(kFilterChipHeight + 1),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      height: kFilterChipHeight + 1,
                      child: AppliedFiltersForAppbar(),
                    ),
                  ),
                )
              : const PreferredSize(
                  preferredSize: Size.fromHeight(0),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: RecommendedFiltersForAppbar(),
                  ),
                ),
        );
      },
    );
  }
}

/// Wrapper widget that reports the app bar as top boundary for auto-scroll
/// when file grouping is disabled
class _AppBarWithBoundary extends StatefulWidget {
  final Widget child;

  const _AppBarWithBoundary({required this.child});

  @override
  State<_AppBarWithBoundary> createState() => _AppBarWithBoundaryState();
}

class _AppBarWithBoundaryState extends State<_AppBarWithBoundary>
    with BoundaryReporter {
  @override
  Widget build(BuildContext context) {
    return boundaryWidget(
      position: BoundaryPosition.top,
      child: widget.child,
    );
  }
}
