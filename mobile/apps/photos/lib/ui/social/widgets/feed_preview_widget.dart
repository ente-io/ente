import "package:flutter/material.dart";
import "package:photos/core/configuration.dart";
import "package:photos/models/social/feed_data_provider.dart";
import "package:photos/models/social/feed_item.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/social/feed_screen.dart";
import "package:photos/ui/social/widgets/feed_item_widget.dart";
import "package:photos/utils/navigation_util.dart";

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

  @override
  void initState() {
    super.initState();
    _currentUserID = Configuration.instance.getUserID() ?? 0;
    _loadLatestItem();
  }

  Future<void> _loadLatestItem() async {
    final item = await FeedDataProvider.instance.getLatestFeedItem();
    if (mounted) {
      setState(() {
        _latestItem = item;
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
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.backgroundElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: FeedItemWidget(
                      feedItem: _latestItem!,
                      currentUserID: _currentUserID,
                      onTap: _onTap,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.strokeMuted,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
