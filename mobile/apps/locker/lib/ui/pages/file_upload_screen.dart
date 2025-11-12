import 'dart:io';

import "package:dotted_border/dotted_border.dart";
import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/colors.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import "package:ente_ui/theme/text_style.dart";
import 'package:flutter/material.dart';
import "package:hugeicons/hugeicons.dart";
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/ui/components/file_upload_dialog.dart';
import "package:locker/ui/components/gradient_button.dart";
import 'package:locker/utils/collection_actions.dart';
import "package:locker/utils/file_icon_utils.dart";
import 'package:path/path.dart' as path;

class FileUploadScreen extends StatefulWidget {
  final List<File> files;
  final List<Collection> collections;
  final Collection? selectedCollection;

  const FileUploadScreen({
    super.key,
    required this.files,
    required this.collections,
    this.selectedCollection,
  });

  @override
  State<FileUploadScreen> createState() => _FileUploadScreenState();
}

class _FileUploadScreenState extends State<FileUploadScreen> {
  late List<File> _files;
  final Set<Collection> _selectedCollections = {};

  @override
  void initState() {
    super.initState();
    _files = List.from(widget.files);

    if (widget.selectedCollection != null &&
        widget.selectedCollection!.type != CollectionType.uncategorized) {
      _selectedCollections.add(widget.selectedCollection!);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.backgroundBase,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        elevation: 0,
      ),
      backgroundColor: colorScheme.backgroundBase,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TitleBarTitleWidget(
                      title: context.l10n.uploadFiles,
                    ),
                    Text(
                      context.l10n.filesSelected(_files.length),
                      style: textTheme.smallMuted,
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: colorScheme.fillFaint,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      size: 24,
                      color: colorScheme.textBase,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                controller: ScrollController(),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_files.isNotEmpty) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.strokeFainter,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight:
                                _files.length > 5 ? 360 : _files.length * 84.0,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: _files.length > 5
                                ? const BouncingScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            itemCount: _files.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              return _buildFileItem(
                                _files[index],
                                colorScheme,
                                textTheme,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    TitleBarTitleWidget(
                      title: context.l10n.collections,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: [
                        ...widget.collections.map((collection) {
                          final isSelected =
                              _selectedCollections.contains(collection);
                          return _buildCollectionChip(
                            name: collection.name ?? context.l10n.unnamed,
                            isSelected: isSelected,
                            onTap: () => _onCollectionSelected(collection),
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          );
                        }),
                        _buildNewCollectionChip(colorScheme, textTheme),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: GradientButton(
                  onTap: _selectedCollections.isEmpty
                      ? null
                      : () async {
                          final result = FileUploadDialogResult(
                            note: '',
                            selectedCollections: _selectedCollections.toList(),
                          );
                          Navigator.of(context).pop(result);
                        },
                  text: context.l10n.save,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(
    File file,
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    final fileName = path.basename(file.path);

    final widget = Flexible(
      flex: 6,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            width: 60,
            height: 60,
            child: _buildFileIcon(fileName),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: textTheme.body,
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backdropBase,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          widget,
          Flexible(
            flex: 1,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _files.remove(file);
                  if (_files.isEmpty) {
                    Navigator.of(context).pop();
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.backgroundElevated,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    color: colorScheme.textBase,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileIcon(String fileName) {
    return FileIconUtils.getFileIcon(fileName, showBackground: true);
  }

  void _onCollectionSelected(Collection collection) {
    setState(() {
      if (_selectedCollections.contains(collection)) {
        _selectedCollections.remove(collection);
      } else {
        _selectedCollections.add(collection);
      }
    });
  }

  Widget _buildCollectionChip({
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
    required EnteColorScheme colorScheme,
    required EnteTextTheme textTheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary700.withValues(alpha: 0.2)
              : colorScheme.fillFaint,
          borderRadius: const BorderRadius.all(Radius.circular(24.0)),
          border: Border.all(
            color: isSelected ? colorScheme.primary700 : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          name,
          style: textTheme.small.copyWith(
            color: isSelected ? colorScheme.primary700 : colorScheme.textBase,
          ),
        ),
      ),
    );
  }

  Widget _buildNewCollectionChip(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return GestureDetector(
      onTap: () async {
        final newCollection = await CollectionActions.createCollection(context);
        if (newCollection != null && mounted) {
          setState(() {
            widget.collections.add(newCollection);
            _selectedCollections.add(newCollection);
          });
        }
      },
      child: DottedBorder(
        options: const RoundedRectDottedBorderOptions(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          strokeWidth: 1,
          color: Color.fromRGBO(82, 82, 82, 0.6),
          dashPattern: [5, 5],
          radius: Radius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: 18,
              color: colorScheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              context.l10n.collectionButtonLabel,
              style: textTheme.body.copyWith(
                color: colorScheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
