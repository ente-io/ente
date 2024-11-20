import 'dart:ui';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/ui/code_widget.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class ReorderCodesPage extends StatefulWidget {
  const ReorderCodesPage({super.key, required this.codes});
  final List<Code> codes;

  @override
  State<ReorderCodesPage> createState() => _ReorderCodesPageState();
}

class _ReorderCodesPageState extends State<ReorderCodesPage> {
  int selectedSortOption = 2;
  final logger = Logger('ReorderCodesPage');

  @override
  Widget build(BuildContext context) {
    final bool isCompactMode = PreferenceService.instance.isCompactMode();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final hasSaved = await saveUpadedIndexes();
          if (hasSaved) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Edit Codes"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final hasSaved = await saveUpadedIndexes();
              if (hasSaved) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            PopupMenuButton(
              icon: const Icon(Icons.sort),
              onSelected: (int value) {
                selectedSortOption = value;
                switch (value) {
                  case 0:
                    sortByIssuer();
                    break;
                  case 1:
                    sortByAccount();
                    break;
                  case 2:
                    setState(() {});
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      selectedSortOption == 0
                          ? const Icon(Icons.check)
                          : const SizedBox.square(dimension: 24),
                      const SizedBox(width: 10),
                      const Text("Issuer"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      selectedSortOption == 1
                          ? const Icon(Icons.check)
                          : const SizedBox.square(dimension: 24),
                      const SizedBox(width: 10),
                      const Text("Account"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      selectedSortOption == 2
                          ? const Icon(Icons.check)
                          : const SizedBox.square(dimension: 24),
                      const SizedBox(width: 10),
                      const Text("Manual"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: ReorderableListView(
          buildDefaultDragHandles: false,
          proxyDecorator:
              (Widget child, int index, Animation<double> animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (BuildContext context, _) {
                final animValue = Curves.easeInOut.transform(animation.value);
                final scale = lerpDouble(1, 1.05, animValue)!;
                return Transform.scale(scale: scale, child: child);
              },
            );
          },
          children: [
            for (final code in widget.codes)
              selectedSortOption == 2
                  ? ReorderableDragStartListener(
                      key: ValueKey('${code.hashCode}_${code.generatedID}'),
                      index: widget.codes.indexOf(code),
                      child: CodeWidget(
                        key: ValueKey(code.generatedID),
                        code,
                        isCompactMode: isCompactMode,
                      ),
                    )
                  : CodeWidget(
                      key: ValueKey('${code.hashCode}_${code.generatedID}'),
                      code,
                      isCompactMode: isCompactMode,
                    ),
          ],
          onReorder: (oldIndex, newIndex) {
            if (selectedSortOption == 2) updateCodeIndex(oldIndex, newIndex);
          },
        ),
      ),
    );
  }

  Future<bool> saveUpadedIndexes() async {
    final result = await CodeStore.instance.saveUpadedIndexes(widget.codes);
    return result;
  }

  void updateCodeIndex(int oldIndex, int newIndex) {
    setState(() {
      // Adjust index when moving down the list
      // oldIndex = 2, newIndex = 0
      if (oldIndex < newIndex) newIndex -= 1;
      final Code code = widget.codes.removeAt(oldIndex);
      widget.codes.insert(newIndex, code);
    });
  }

  void sortByIssuer() {
    widget.codes.sort((a, b) => a.issuer.compareTo(b.issuer));
    setState(() {});
  }

  void sortByAccount() {
    widget.codes.sort((a, b) => a.account.compareTo(b.account));
    setState(() {});
  }
}
