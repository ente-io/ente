import "package:flutter/material.dart";
import "package:photos/models/typedefs.dart";

class GallerySortOrderProvider extends StatefulWidget {
  final bool? sortOrderAsc;
  final Widget child;

  const GallerySortOrderProvider({
    ///false if null
    this.sortOrderAsc,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  GallerySortOrderStateProvider createState() =>
      GallerySortOrderStateProvider();
}

class GallerySortOrderStateProvider extends State<GallerySortOrderProvider> {
  late bool _sortOrderAsc;
  @override
  void initState() {
    _sortOrderAsc = widget.sortOrderAsc ?? false;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GallerySortOrder(
      sortOrderAsc: _sortOrderAsc,
      updateSortOrder: updateSortOrder,
      child: widget.child,
    );
  }

  void updateSortOrder(bool sortOrderAsc) {
    setState(() {
      _sortOrderAsc = sortOrderAsc;
    });
  }
}

class GallerySortOrder extends InheritedWidget {
  final bool sortOrderAsc;
  final VoidCallbackParamBool updateSortOrder;

  const GallerySortOrder({
    required this.sortOrderAsc,
    required this.updateSortOrder,
    required Widget child,
    Key? key,
  }) : super(key: key, child: child);

  static GallerySortOrder? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GallerySortOrder>();
  }

  @override
  bool updateShouldNotify(GallerySortOrder oldWidget) {
    return sortOrderAsc != oldWidget.sortOrderAsc;
  }
}
