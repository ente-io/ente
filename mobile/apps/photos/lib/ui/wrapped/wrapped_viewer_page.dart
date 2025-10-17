import "dart:async";

import "package:flutter/material.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/wrapped/models.dart";
import "package:photos/services/wrapped/wrapped_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/theme/text_style.dart";
import "package:photos/ui/notification/toast.dart";

/// Basic viewer for the stats-only Ente Wrapped experience.
class WrappedViewerPage extends StatefulWidget {
  const WrappedViewerPage({
    required this.initialState,
    super.key,
  });

  final WrappedEntryState initialState;

  @override
  State<WrappedViewerPage> createState() => _WrappedViewerPageState();
}

class _WrappedViewerPageState extends State<WrappedViewerPage> {
  late PageController _pageController;
  late WrappedEntryState _state;
  late int _currentIndex;
  VoidCallback? _stateListener;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    final int initialPage = _initialPageForState(_state);
    _currentIndex = initialPage;
    _pageController = PageController(initialPage: initialPage);
    _stateListener = () => _handleServiceUpdate(wrappedService.state);
    wrappedService.stateListenable.addListener(_stateListener!);
  }

  @override
  void dispose() {
    if (_stateListener != null) {
      wrappedService.stateListenable.removeListener(_stateListener!);
    }
    _pageController.dispose();
    super.dispose();
  }

  int _initialPageForState(WrappedEntryState state) {
    final int cardCount = state.result?.cards.length ?? 0;
    if (cardCount <= 1) {
      return 0;
    }
    return state.resumeIndex.clamp(0, cardCount - 1);
  }

  void _handleServiceUpdate(WrappedEntryState next) {
    if (!mounted) {
      return;
    }
    setState(() {
      _state = next;
    });
    final int newCardCount = next.result?.cards.length ?? 0;
    if (newCardCount == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    if (_currentIndex >= newCardCount) {
      _jumpToPage(newCardCount - 1);
    }
  }

  Future<void> _jumpToPage(int page) async {
    if (!_pageController.hasClients) {
      _currentIndex = page;
      return;
    }
    _currentIndex = page;
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void _handlePageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    wrappedService.updateResumeIndex(index);
    final int lastIndex = (_state.result?.cards.length ?? 1) - 1;
    if (index == lastIndex) {
      wrappedService.markComplete(true);
    } else if (_state.isComplete) {
      wrappedService.markComplete(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final WrappedResult? result = _state.result;
    final int cardCount = result?.cards.length ?? 0;
    if (result == null || cardCount == 0) {
      scheduleMicrotask(() {
        if (mounted) {
          showShortToast(context, "Wrapped data not available");
          Navigator.of(context).maybePop();
        }
      });
      return const SizedBox.shrink();
    }

    final enteColorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          return;
        }
        wrappedService.updateResumeIndex(_currentIndex);
        if (_currentIndex != cardCount - 1) {
          wrappedService.markComplete(false);
        }
      },
      child: Scaffold(
        backgroundColor: enteColorScheme.backgroundBase,
        appBar: AppBar(
          title: Text(
            "Wrapped ${result.year}",
            style: textTheme.largeBold,
          ),
          backgroundColor: enteColorScheme.backgroundBase,
          foregroundColor: enteColorScheme.textBase,
          elevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / cardCount,
                backgroundColor: enteColorScheme.fillFaint,
                color: enteColorScheme.primary500,
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _handlePageChanged,
                itemCount: cardCount,
                itemBuilder: (BuildContext context, int index) {
                  final WrappedCard card = result.cards[index];
                  return _StatsCard(
                    card: card,
                    colorScheme: enteColorScheme,
                    textTheme: textTheme,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.card,
    required this.colorScheme,
    required this.textTheme,
  });

  final WrappedCard card;
  final EnteColorScheme colorScheme;
  final EnteTextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final List<Widget> mediaBadges = card.media.isEmpty
        ? const <Widget>[]
        : card.media
            .take(4)
            .map(
              (MediaRef ref) => Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primary400.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "#${ref.uploadedFileID}",
                  style: textTheme.tinyMuted,
                  textAlign: TextAlign.center,
                ),
              ),
            )
            .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Material(
        color: colorScheme.backgroundElevated,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.fillFaint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _labelForCardType(card.type),
                  style: textTheme.tinyMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                card.title,
                style: textTheme.h2Bold,
              ),
              if (card.subtitle != null && card.subtitle!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    card.subtitle!,
                    style: textTheme.bodyMuted,
                  ),
                ),
              if (mediaBadges.isNotEmpty) ...[
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: mediaBadges,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _labelForCardType(WrappedCardType type) {
    switch (type) {
      case WrappedCardType.statsTotals:
        return "Totals";
      case WrappedCardType.statsVelocity:
        return "Rhythm";
      case WrappedCardType.busiestDay:
        return "Biggest day";
      case WrappedCardType.longestStreak:
        return "Streak";
      case WrappedCardType.longestGap:
        return "Break";
      default:
        return "Stats";
    }
  }
}
