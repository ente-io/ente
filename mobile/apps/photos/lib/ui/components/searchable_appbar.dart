import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/soft_icon_button.dart";
import "package:photos/ui/components/text_input_widget_v2.dart";

class SearchableAppBar extends StatefulWidget {
  final Widget title;
  final List<Widget>? actions;
  final Function(String) onSearch;
  final VoidCallback? onSearchClosed;
  final String heroTag;
  final bool autoActivateSearch;
  final Color? backgroundColor;
  final bool? centerTitle;
  final EdgeInsetsGeometry searchIconPadding;
  final bool pinned;

  const SearchableAppBar({
    super.key,
    required this.title,
    this.actions,
    required this.onSearch,
    this.onSearchClosed,
    this.heroTag = "",
    this.autoActivateSearch = false,
    this.backgroundColor,
    this.centerTitle,
    this.searchIconPadding = const EdgeInsets.all(12.0),
    this.pinned = false,
  });

  @override
  State<SearchableAppBar> createState() => _SearchableAppBarState();
}

class _SearchableAppBarState extends State<SearchableAppBar> {
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.autoActivateSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _activateSearch();
      });
    }
  }

  @override
  void didUpdateWidget(covariant SearchableAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoActivateSearch &&
        !oldWidget.autoActivateSearch &&
        !_isSearchActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _activateSearch();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _activateSearch() {
    setState(() {
      _isSearchActive = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _deactivateSearch() {
    setState(() {
      _isSearchActive = false;
      _searchController.clear();
    });
    _searchFocusNode.unfocus();
    if (widget.onSearchClosed != null) {
      widget.onSearchClosed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return SliverAppBar(
      floating: !widget.pinned,
      pinned: widget.pinned,
      backgroundColor:
          widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: !_isSearchActive,
      centerTitle: widget.centerTitle,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _isSearchActive
            ? _buildSearchField()
            : widget.heroTag.isNotEmpty
                ? Hero(
                    key: const ValueKey('titleBar'),
                    tag: widget.heroTag,
                    child: widget.title,
                  )
                : widget.title,
      ),
      actions: _isSearchActive
          ? null
          : [
              Padding(
                padding: widget.searchIconPadding,
                child: SoftIconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                    size: 18,
                    color: colorScheme.textBase,
                  ),
                  onTap: _activateSearch,
                ),
              ),
              ...?widget.actions,
            ],
    );
  }

  Widget _buildSearchField() {
    final colorScheme = getEnteColorScheme(context);
    return Container(
      key: const ValueKey('searchBar'),
      alignment: Alignment.center,
      child: TextInputWidgetV2(
        textEditingController: _searchController,
        focusNode: _searchFocusNode,
        autoFocus: true,
        shouldSurfaceExecutionStates: false,
        leadingWidget: HugeIcon(
          icon: HugeIcons.strokeRoundedSearch01,
          size: 18,
          color: colorScheme.textMuted,
        ),
        trailingWidget: GestureDetector(
          onTap: _deactivateSearch,
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedCancel01,
            size: 18,
            color: colorScheme.textMuted,
          ),
        ),
        onChange: widget.onSearch,
      ),
    );
  }
}
