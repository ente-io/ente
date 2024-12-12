import 'dart:ui';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/theme/ente_theme.dart';
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
  bool hasChanged = false;
  final logger = Logger('ReorderCodesPage');

  @override
  Widget build(BuildContext context) {
    final bool isCompactMode = PreferenceService.instance.isCompactMode();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Custom order"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          GestureDetector(
            onTap: () async {
              final hasSaved = await saveUpadedIndexes();
              if (hasSaved) {
                Navigator.of(context).pop();
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                context.l10n.save,
                style: TextStyle(
                  color: hasChanged
                      ? getEnteColorScheme(context).textBase
                      : getEnteColorScheme(context).strokeMuted,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ReorderableListView(
        buildDefaultDragHandles: false,
        proxyDecorator: (Widget child, int index, Animation<double> animation) {
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
      hasChanged = true;
    });
  }
}
