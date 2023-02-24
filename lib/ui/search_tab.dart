import "package:flutter/widgets.dart";
import "package:photos/ui/viewer/search/tab_empty_state.dart";

class SearchTab extends StatefulWidget {
  const SearchTab({Key? key}) : super(key: key);
  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: SearchTabEmptyState());
  }
}
