import "package:flutter/material.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/ui/viewer/search/search_section.dart";
import "package:photos/ui/viewer/search/search_widget.dart";

class SearchTab extends StatefulWidget {
  const SearchTab({Key? key}) : super(key: key);

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  // Focus nodes are necessary
  String _email = '';
  final textFieldFocusNode = FocusNode();
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Return a ListViewBuilder for value search_types.dart SectionType,
    // render search section for each value
    const searchTypes = SectionType.values;
    return Padding(
      padding: const EdgeInsets.only(
        left: 12.0,
        right: 12.0,
        bottom: 100,
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.topRight,
            child: SearchIconWidget(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: searchTypes.length,
              itemBuilder: (context, index) {
                return SearchSection(sectionType: searchTypes[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  void clearFocus() {
    _textController.clear();
    _email = _textController.text;

    textFieldFocusNode.unfocus();
    setState(() => {});
  }
}
