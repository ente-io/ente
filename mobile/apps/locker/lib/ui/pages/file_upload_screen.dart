import 'dart:io';

import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/colors.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import "package:ente_ui/theme/text_style.dart";
import 'package:flutter/material.dart';
import "package:hugeicons/hugeicons.dart";
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/ui/components/collection_selection_widget.dart';
import 'package:locker/ui/components/file_upload_sheet.dart';
import "package:locker/ui/components/gradient_button.dart";
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
  List<File> _files = [];
  List<Collection> _availableCollections = [];
  final Set<int> _selectedCollectionIds = {};

  @override
  void initState() {
    super.initState();
    _files = List.from(widget.files);
    _availableCollections = List.from(widget.collections);

    if (widget.selectedCollection != null &&
        widget.selectedCollection!.type != CollectionType.uncategorized) {
      _selectedCollectionIds.add(widget.selectedCollection!.id);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _toggleCollection(int collectionId) {
    setState(() {
      if (_selectedCollectionIds.contains(collectionId)) {
        _selectedCollectionIds.remove(collectionId);
      } else {
        _selectedCollectionIds.add(collectionId);
      }
    });
  }

  void _onCollectionsUpdated(List<Collection> updatedCollections) {
    setState(() {
      _availableCollections = updatedCollections;
    });
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
              const SizedBox(height: 16),
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: _files.length > 5
                                    ? 360
                                    : _files.length * 84.0,
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
                        ),
                        const SizedBox(height: 24),
                      ],
                      TitleBarTitleWidget(
                        title: context.l10n.collectionLabel,
                      ),
                      const SizedBox(height: 16),
                      CollectionSelectionWidget(
                        collections: _availableCollections,
                        selectedCollectionIds: _selectedCollectionIds,
                        onToggleCollection: _toggleCollection,
                        onCollectionsUpdated: _onCollectionsUpdated,
                        title: "",
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    onTap: _selectedCollectionIds.isEmpty
                        ? null
                        : () async {
                            final selectedCollections = _availableCollections
                                .where(
                                  (c) => _selectedCollectionIds.contains(c.id),
                                )
                                .toList();
                            final result = FileUploadSheetResult(
                              note: '',
                              selectedCollections: selectedCollections,
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
}
