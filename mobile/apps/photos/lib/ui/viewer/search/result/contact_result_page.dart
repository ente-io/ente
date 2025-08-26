import "dart:async";

import "package:email_validator/email_validator.dart";
import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/collection/collection.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/gallery_type.dart';
import "package:photos/models/ml/face/person.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/search_constants.dart";
import 'package:photos/models/search/search_result.dart';
import 'package:photos/models/selected_files.dart';
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/collections/album/row_item.dart";
import "package:photos/ui/components/end_to_end_banner.dart";
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import "package:photos/ui/viewer/gallery/hierarchical_search_gallery.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/inherited_search_filter_data.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";
import "package:photos/ui/viewer/people/person_selection_action_widgets.dart";
import "package:photos/utils/navigation_util.dart";

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
  late String _searchResultName;
  late final SearchFilterDataProvider _searchFilterDataProvider;

  @override
  void initState() {
    super.initState();
    files = widget.searchResult.resultFiles();
    collections = (widget.searchResult as GenericSearchResult)
            .params[kContactCollections] ??
        <Collection>[];
    _searchResultName = widget.searchResult.name();
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
  }

  @override
  void dispose() {
    _filesUpdatedEvent.cancel();
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
      header: Column(
        children: [
          if (EmailValidator.validate(_searchResultName))
            Padding(
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
                  if (updatedPerson != null) {
                    setState(() {
                      _searchResultName = updatedPerson.data.name;
                    });
                  }
                },
              ),
            ),
          if (collections.isNotEmpty)
            _AlbumsSection(context: context, collections: collections),
        ],
      ),
    );

    return GalleryFilesState(
      child: InheritedSearchFilterDataWrapper(
        searchFilterDataProvider: _searchFilterDataProvider,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(90.0),
            child: GalleryAppBarWidget(
              key: ValueKey(_searchResultName),
              ContactResultPage.appBarType,
              _searchResultName,
              _selectedFiles,
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
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              AppLocalizations.of(context).albums,
              style: getEnteTextTheme(context).large,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 147,
              child: ListView.separated(
                separatorBuilder: (context, index) => const SizedBox(width: 4),
                scrollDirection: Axis.horizontal,
                itemCount: collections.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final item = collections[index];
                  return AlbumRowItemWidget(
                    item,
                    120,
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
