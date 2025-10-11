import 'dart:io';

import "package:ente_ui/components/buttons/gradient_button.dart";
import "package:ente_ui/components/title_bar_title_widget.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import "package:hugeicons/hugeicons.dart";
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/ui/components/file_upload_dialog.dart';
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
  final List<Collection> _selectedCollections = [];

  @override
  void initState() {
    super.initState();
    _files = List.from(widget.files);

    if (widget.selectedCollection != null) {
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
        backgroundColor: getEnteColorScheme(context).backgroundBase,
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
                      color: colorScheme.backdropBase,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      size: 24,
                      color: colorScheme.iconColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_files.isNotEmpty) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.fillFaint,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: _files.length > 5
                                ? 420 // Show exactly 5 items (84 * 5)
                                : _files.length *
                                    84.0, // Actual height for fewer items
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
                              return _buildFileItem(_files[index]);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    TitleBarTitleWidget(
                      title: context.l10n.addToCollection,
                    ),
                    const SizedBox(height: 24),
                    // Collection chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: [
                        _buildCollectionChip(
                          context,
                          context.l10n.uncategorized,
                          _selectedCollections.isEmpty,
                          () {
                            setState(() {
                              _selectedCollections.clear();
                            });
                          },
                          isPrimary: true,
                        ),
                        ...widget.collections.map((collection) {
                          final isSelected =
                              _selectedCollections.contains(collection);
                          return _buildCollectionChip(
                            context,
                            collection.name ?? context.l10n.unnamed,
                            isSelected,
                            () {
                              setState(() {
                                if (isSelected) {
                                  _selectedCollections.remove(collection);
                                } else {
                                  _selectedCollections.add(collection);
                                }
                              });
                            },
                          );
                        }),
                        _buildNewCollectionChip(context),
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
                  hugeIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedFileUpload,
                    color: colorScheme.backdropBase,
                  ),
                  onTap: () async {
                    final result = FileUploadDialogResult(
                      note: '',
                      selectedCollections: _selectedCollections.isNotEmpty
                          ? _selectedCollections
                          : [],
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

  Widget _buildFileItem(File file) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final fileName = path.basename(file.path);

    final widget = Flexible(
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: _buildFileIcon(fileName),
          ),
          const SizedBox(width: 12),
          Text(
            fileName,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: textTheme.body,
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backgroundBase,
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
                    borderRadius: BorderRadius.circular(50),
                    color: colorScheme.backdropBase,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    color: colorScheme.iconColor,
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

  Widget _buildCollectionChip(
    BuildContext context,
    String name,
    bool isSelected,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isPrimary
                  ? colorScheme.primary700.withValues(alpha: 0.12)
                  : colorScheme.fillFaint)
              : colorScheme.backgroundElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? (isPrimary ? colorScheme.primary700 : colorScheme.strokeMuted)
                : colorScheme.strokeFaint,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          name,
          style: textTheme.body.copyWith(
            color: isSelected
                ? (isPrimary ? colorScheme.primary700 : colorScheme.textBase)
                : colorScheme.textMuted,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNewCollectionChip(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.strokeFaint.withValues(alpha: 0.6),
            width: 1.5,
          ),
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
              context.l10n.newCollection,
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
