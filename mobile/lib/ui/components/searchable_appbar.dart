import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:photos/theme/ente_theme.dart";

class SearchableAppBar extends StatefulWidget {
  final Widget title;
  final List<Widget>? actions;
  final Function(String) onSearch;
  final VoidCallback? onSearchClosed;
  final String heroTag;

  const SearchableAppBar({
    super.key,
    required this.title,
    this.actions,
    required this.onSearch,
    this.onSearchClosed,
    this.heroTag = "",
  });

  @override
  State<SearchableAppBar> createState() => _SearchableAppBarState();
}

class _SearchableAppBarState extends State<SearchableAppBar> {
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

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
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    return SliverAppBar(
      floating: true,
      elevation: 0,
      automaticallyImplyLeading: !_isSearchActive,
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
            : Hero(
                key: const ValueKey('titleBar'),
                tag: widget.heroTag,
                child: widget.title,
              ),
      ),
      actions: _isSearchActive
          ? null
          : [
              GestureDetector(
                onTap: _activateSearch,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: SvgPicture.asset(
                      isLightMode
                          ? "assets/icons/search_icon_light.svg"
                          : "assets/icons/search_icon_dark.svg",
                    ),
                  ),
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
      child: TextFormField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          filled: true,
          fillColor: colorScheme.fillFaint,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colorScheme.strokeMuted,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.cancel_rounded,
              color: colorScheme.strokeMuted,
            ),
            onPressed: _deactivateSearch,
          ),
          border: const UnderlineInputBorder(
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: colorScheme.strokeFaint,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: widget.onSearch,
      ),
    );
  }
}
