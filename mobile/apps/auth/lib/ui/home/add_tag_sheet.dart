import 'dart:async';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/onboarding/model/tag_enums.dart';
import 'package:ente_auth/onboarding/view/common/tag_chip.dart';
import 'package:ente_auth/store/code_display_store.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:ente_auth/ui/utils/icon_utils.dart';
import 'package:flutter/material.dart';



class AddTagSheet extends StatefulWidget {
  final List<Code> selectedCodes;

  const AddTagSheet({
    super.key,
    required this.selectedCodes,
  });

  @override
  State<AddTagSheet> createState() => _AddTagSheetState();
}

class _AddTagSheetState extends State<AddTagSheet> {
  List<String> _allTags = [];
  final Set<String> _selectedTagsInSheet = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final allTagsFromServer = await CodeDisplayStore.instance.getAllTags();
    final initialTagsForSelection = <String>{};

    for (final code in widget.selectedCodes) {
      initialTagsForSelection.addAll(code.display.tags);
    }

    if (mounted) {
      setState(() {
        _allTags = allTagsFromServer;
        _selectedTagsInSheet.addAll(initialTagsForSelection);
        _isLoading = false;
      });
    }
  }

  Future<void> _onDonePressed() async {
    final List<Future> updateFutures = [];
    for (final code in widget.selectedCodes) {
      final updatedCode = code.copyWith(
        display: code.display.copyWith(tags: _selectedTagsInSheet.toList()),
      );
      updateFutures.add(CodeStore.instance.addCode(updatedCode));
    }
    await Future.wait(updateFutures);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showCreateTagDialog() async {
    final textController = TextEditingController();
    final newTag = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(context.l10n.createNewTag),
              content: TextField(
                controller: textController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: ButtonWidget(
                        buttonType: ButtonType.secondary,
                        labelText: context.l10n.cancel,
                        onTap: () async => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ButtonWidget(
                        buttonType: ButtonType.primary,
                        labelText: context.l10n.create,
                        isDisabled: textController.text.trim().isEmpty,
                        onTap: () async => Navigator.of(context).pop(textController.text.trim()),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    if (newTag != null && newTag.isNotEmpty) {
      setState(() {
        if (!_allTags.contains(newTag)) {
          _allTags.add(newTag);
          _allTags.sort();
        }
        _selectedTagsInSheet.add(newTag);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.selectedCodes.length} ${context.l10n.selected}',
                style: textTheme.large,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.fillFaint.withValues(alpha: 0.025),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.selectedCodes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final code = widget.selectedCodes[index];
                final iconData =
                    code.display.isCustomIcon ? code.display.iconID : code.issuer;
                
                return SizedBox(
  width: 60,
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 50,   
        height: 50,   
        decoration: BoxDecoration(
          color: colorScheme.fillFaint.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(  
          child: IconUtils.instance.getIcon(context, iconData.trim(), width: 28),
        ),
    ),
      const SizedBox(height: 8),
      Text(
        code.issuer,
        overflow: TextOverflow.ellipsis,
        style: textTheme.mini.copyWith(color: colorScheme.textMuted,),
      ),
    ],
  ),
);
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(context.l10n.tags, style: textTheme.body),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  ..._allTags.map((tag) {
                    final isSelected = _selectedTagsInSheet.contains(tag);
                    return TagChip(
                      label: tag,
                      action: TagChipAction.check,
                      state: isSelected
                          ? TagChipState.selected
                          : TagChipState.unselected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedTagsInSheet.remove(tag);
                          } else {
                            _selectedTagsInSheet.add(tag);
                          }
                        });
                      },
                    );
                  }),
                  TagChip(
                    label: context.l10n.addNew,
                    iconData: Icons.add,
                    state: TagChipState.unselected,
                    onTap: _showCreateTagDialog,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.fillBase,
                foregroundColor: colorScheme.backgroundBase,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _onDonePressed,
              child: Text(context.l10n.done),
            ),
          ),
        ],
      ),
    );
  }
}