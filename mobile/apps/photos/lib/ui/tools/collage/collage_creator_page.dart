import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/ui/tools/collage/collage_test_grid.dart";
import "package:photos/ui/tools/collage/collage_with_five_items.dart";
import "package:photos/ui/tools/collage/collage_with_four_items.dart";
import "package:photos/ui/tools/collage/collage_with_six_items.dart";
import "package:photos/ui/tools/collage/collage_with_three_items.dart";
import "package:photos/ui/tools/collage/collage_with_two_items.dart";

class CollageCreatorPage extends StatelessWidget {
  static const int _collageItemsMin = 2;
  static const int _collageItemsMax = 6;
  static bool isValidCount(int count) {
    return count >= _collageItemsMin && count <= _collageItemsMax;
  }

  final List<EnteFile> files;

  const CollageCreatorPage(this.files, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(AppLocalizations.of(context).createCollage),
      ),
      body: _getBody(context),
    );
  }

  Widget _getBody(BuildContext context) {
    final count = files.length;
    Widget collage;
    switch (count) {
      case 2:
        collage = CollageWithTwoItems(
          files[0],
          files[1],
        );
        break;
      case 3:
        collage = CollageWithThreeItems(
          files[0],
          files[1],
          files[2],
        );
        break;
      case 4:
        collage = CollageWithFourItems(
          files[0],
          files[1],
          files[2],
          files[3],
        );
        break;
      case 5:
        collage = CollageWithFiveItems(
          files[0],
          files[1],
          files[2],
          files[3],
          files[4],
        );
        break;
      case 6:
        collage = CollageWithSixItems(
          files[0],
          files[1],
          files[2],
          files[3],
          files[4],
          files[5],
        );
        break;
      default:
        collage = const TestGrid();
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: collage,
    );
  }
}
