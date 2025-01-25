import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/all_icon_data.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/utils/icon_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomIconPage extends StatefulWidget {
  final Map<String, AllIconData> allIcons;
  final String currentIcon;

  const CustomIconPage({
    super.key,
    required this.allIcons,
    required this.currentIcon,
  });

  @override
  State<CustomIconPage> createState() => _CustomIconPageState();
}

class _CustomIconPageState extends State<CustomIconPage> {
  Map<String, AllIconData> _filteredIcons = {};
  bool _showSearchBox = false;
  final bool _autoFocusSearch =
      PreferenceService.instance.shouldAutoFocusOnSearchBar();
  final TextEditingController _textController = TextEditingController();
  String _searchText = "";

  // Used to request focus on the search box when clicked the search icon
  late FocusNode searchBoxFocusNode;
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    _filteredIcons = widget.allIcons;
    _showSearchBox = _autoFocusSearch;
    searchBoxFocusNode = FocusNode();
    ServicesBinding.instance.keyboard.addHandler(_handleKeyEvent);
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    searchBoxFocusNode.dispose();
    _scrollController.dispose();
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
      if ((_pressedKeys.contains(LogicalKeyboardKey.controlLeft) ||
              _pressedKeys.contains(LogicalKeyboardKey.control) ||
              _pressedKeys.contains(LogicalKeyboardKey.controlRight)) &&
          event.logicalKey == LogicalKeyboardKey.keyF) {
        setState(() {
          _showSearchBox = true;
          searchBoxFocusNode.requestFocus();
          _textController.clear();
          _searchText = "";
        });
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() {
          _textController.clear();
          _searchText = "";
          _showSearchBox = false;
          _applyFilteringAndRefresh();
        });
        return true;
      }
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }
    return false;
  }

  void _applyFilteringAndRefresh() {
    if (_searchText.isEmpty) {
      setState(() {
        _filteredIcons = widget.allIcons;
      });
      return;
    }

    final filteredIcons = <String, AllIconData>{};
    widget.allIcons.forEach((title, iconData) {
      if (title.toLowerCase().contains(_searchText.toLowerCase())) {
        filteredIcons[title] = iconData;
      }
    });

    setState(() {
      _filteredIcons = filteredIcons;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: !_showSearchBox
            ? const Text('Choose icon')
            : TextField(
                autocorrect: false,
                enableSuggestions: false,
                autofocus: _autoFocusSearch,
                controller: _textController,
                onChanged: (value) {
                  _searchText = value;
                  _applyFilteringAndRefresh();
                },
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                focusNode: searchBoxFocusNode,
              ),
        actions: [
          IconButton(
            icon: _showSearchBox
                ? const Icon(Icons.clear)
                : const Icon(Icons.search),
            tooltip: l10n.search,
            onPressed: () {
              setState(
                () {
                  _showSearchBox = !_showSearchBox;
                  if (!_showSearchBox) {
                    _textController.clear();
                    _searchText = "";
                  } else {
                    _searchText = _textController.text;

                    // Request focus on the search box
                    searchBoxFocusNode.requestFocus();
                  }
                  _applyFilteringAndRefresh();
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  interactive: true,
                  child: GridView.builder(
                    controller: _scrollController,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (MediaQuery.sizeOf(context).width ~/ 90)
                          .clamp(1, double.infinity)
                          .toInt(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1,
                    ),
                    itemCount: _filteredIcons.length,
                    itemBuilder: (context, index) {
                      final title = _filteredIcons.keys.elementAt(index);
                      final iconData = _filteredIcons[title]!;
                      IconType iconType = iconData.type;
                      String? color = iconData.color;
                      String? slug = iconData.slug;
                      Widget iconWidget;
                      if (iconType == IconType.simpleIcon) {
                        final simpleIconPath = normalizeSimpleIconName(title);
                        iconWidget = IconUtils.instance.getSVGIcon(
                          "assets/simple-icons/icons/$simpleIconPath.svg",
                          title,
                          color,
                          40,
                          context,
                        );
                      } else {
                        iconWidget = IconUtils.instance.getSVGIcon(
                          "assets/custom-icons/icons/${slug ?? title}.svg",
                          title,
                          color,
                          40,
                          context,
                        );
                      }

                      return GestureDetector(
                        key: ValueKey(title),
                        onTap: () {
                          final newIcon = AllIconData(
                            title: title,
                            type: iconType,
                            color: color,
                            slug: slug,
                          );
                          Navigator.of(context).pop(newIcon);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 1.5,
                              color: title.toLowerCase() ==
                                      widget.currentIcon.toLowerCase()
                                  ? getEnteColorScheme(context)
                                      .tagChipSelectedColor
                                  : Colors.transparent,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(12.0),
                            ),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              Expanded(
                                child: iconWidget,
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: title.toLowerCase() ==
                                        widget.currentIcon.toLowerCase()
                                    ? const EdgeInsets.only(left: 2, right: 2)
                                    : const EdgeInsets.all(0.0),
                                child: Text(
                                  '${title[0].toUpperCase()}${title.substring(1)}',
                                  style: getEnteTextTheme(context).mini,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
