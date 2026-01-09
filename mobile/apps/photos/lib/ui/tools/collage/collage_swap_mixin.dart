import "package:flutter/material.dart";
import "package:photos/models/file/file.dart";

mixin CollageSwapMixin<T extends StatefulWidget> on State<T> {
  late List<EnteFile> collageFiles;
  int? _selectedSwapIndex;

  @protected
  void initCollageFiles(List<EnteFile> files) {
    collageFiles = List<EnteFile>.from(files);
  }

  @protected
  bool get isSwapSelectionActive => _selectedSwapIndex != null;

  @protected
  bool isSelectedForSwap(int index) {
    return _selectedSwapIndex == index;
  }

  @protected
  void onCollageItemTapped(int index) {
    if (!isSwapSelectionActive) {
      return;
    }

    setState(() {
      if (_selectedSwapIndex == index) {
        _selectedSwapIndex = null;
        return;
      }
      final swapIndex = _selectedSwapIndex!;
      final current = collageFiles[index];
      collageFiles[index] = collageFiles[swapIndex];
      collageFiles[swapIndex] = current;
      _selectedSwapIndex = null;
    });
  }

  @protected
  void onCollageItemLongPressed(int index) {
    setState(() {
      if (_selectedSwapIndex == index) {
        _selectedSwapIndex = null;
        return;
      }
      _selectedSwapIndex = index;
    });
  }

  @protected
  void clearSwapSelection() {
    if (_selectedSwapIndex != null) {
      setState(() {
        _selectedSwapIndex = null;
      });
    }
  }
}
