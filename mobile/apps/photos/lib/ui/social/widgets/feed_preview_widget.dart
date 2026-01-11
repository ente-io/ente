import "dart:async";

import "package:flutter/material.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/events/social_data_updated_event.dart";
import "package:photos/models/social/feed_data_provider.dart";
import "package:photos/models/social/feed_item.dart";
import "package:photos/models/social/social_data_provider.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/social/feed_screen.dart";
import "package:photos/ui/social/widgets/feed_preview_item_widget.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/standalone/debouncer.dart";

/// Widget that displays a preview of the latest feed item.
///
/// Shown in the Sharing tab to provide quick access to the activity feed.
class FeedPreviewWidget extends StatefulWidget {
  const FeedPreviewWidget({super.key});

  @override
  State<FeedPreviewWidget> createState() => _FeedPreviewWidgetState();
}

class _FeedPreviewWidgetState extends State<FeedPreviewWidget> {
  FeedItem? _latestItem;
  bool _isLoading = true;
  late final int _currentUserID;
  Map<String, String> _anonDisplayNames = {};

  late final StreamSubscription<SocialDataUpdatedEvent> _socialDataSubscription;
  late final StreamSubscription<PeopleChangedEvent> _peopleChangedSubscription;
  final _refreshDebouncer = Debouncer(const Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    _currentUserID = Configuration.instance.getUserID() ?? 0;
    _loadLatestItem();

    // Listen for social data updates (comments/reactions synced)
    _socialDataSubscription =
        Bus.instance.on<SocialDataUpdatedEvent>().listen((event) {
      _refreshDebouncer.run(() => _loadLatestItem());
    });

    // Listen for people changes (user names updated)
    _peopleChangedSubscription =
        Bus.instance.on<PeopleChangedEvent>().listen((event) {
      // Refresh if a person was saved/edited and matches the current actor
      if (event.type == PeopleEventType.saveOrEditPerson &&
          _latestItem != null) {
        final personUserID = event.person?.data.userID;
        if (personUserID != null &&
            _latestItem!.actorUserIDs.contains(personUserID)) {
          _refreshDebouncer.run(() => _loadLatestItem());
        }
      }
    });
  }

  @override
  void dispose() {
    _socialDataSubscription.cancel();
    _peopleChangedSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadLatestItem() async {
    final item = await FeedDataProvider.instance.getLatestFeedItem();

    // Load anon display names if there's an item
    Map<String, String> anonNames = {};
    if (item != null) {
      anonNames = await SocialDataProvider.instance
          .getAnonDisplayNamesForCollection(item.collectionID);
    }

    if (mounted) {
      setState(() {
        _latestItem = item;
        _anonDisplayNames = anonNames;
        _isLoading = false;
      });
    }
  }

  void _onTap() {
    routeToPage(context, const FeedScreen());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_latestItem == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = getEnteColorScheme(context);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.backgroundElevated2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.strokeFainter,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: FeedPreviewItemWidget(
                feedItem: _latestItem!,
                currentUserID: _currentUserID,
                anonDisplayNames: _anonDisplayNames,
                onTap: _onTap,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
