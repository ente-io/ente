import 'dart:math' as math;

import 'package:ente_ui/theme/ente_theme.dart';
import 'package:ente_ui/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/info/info_item.dart';
import 'package:locker/ui/components/collection_selection_widget.dart';
import 'package:locker/ui/components/gradient_button.dart';
import 'package:locker/ui/pages/base_info_page.dart';

class PersonalNotePage extends BaseInfoPage<PersonalNoteData> {
  const PersonalNotePage({
    super.key,
    super.mode = InfoPageMode.edit,
    super.existingFile,
    super.onCancelWithoutSaving,
  });

  @override
  State<PersonalNotePage> createState() => _PersonalNotePageState();
}

class _PersonalNotePageState
    extends BaseInfoPageState<PersonalNoteData, PersonalNotePage> {
  static const double _editorMinWidth = 320.0;
  static const double _editorMaxWidth = 720.0;
  static const double _editorWidthFactor = 0.92;
  static const double _editorMinHeight = 260.0;
  static const double _editorMaxHeight = 560.0;
  static const double _editorBorderRadius = 24.0;
  static const EdgeInsets _editorContentPadding =
      EdgeInsets.symmetric(horizontal: 28, vertical: 24);
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  final ScrollController _contentScrollController = ScrollController();
  bool _isControllerSyncInProgress = false;
  String _initialContent = '';

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onTitleChanged);
    _contentController.addListener(_onContentChanged);
    _titleFocusNode.addListener(_onTitleFocusChanged);
    _contentFocusNode.addListener(_onContentFocusChanged);
  }

  @override
  void loadExistingData() {
    _syncControllers(
      triggerSetState: false,
      updateInitial: true,
    );
  }

  @override
  void refreshUIWithCurrentData() {
    super.refreshUIWithCurrentData();
    _syncControllers(
      triggerSetState: true,
      updateInitial: true,
    );
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTitleChanged);
    _contentController.removeListener(_onContentChanged);
    _titleFocusNode.removeListener(_onTitleFocusChanged);
    _contentFocusNode.removeListener(_onContentFocusChanged);
    _nameController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  @override
  String get pageTitle {
    if (isInEditMode) {
      return context.l10n.editNote;
    }

    final controllerTitle = _nameController.text.trim();
    if (controllerTitle.isNotEmpty) {
      return controllerTitle;
    }

    final dataTitle = (currentData?.title ?? '').trim();
    if (dataTitle.isNotEmpty) {
      return dataTitle;
    }

    return context.l10n.personalNote;
  }

  @override
  String get submitButtonText => context.l10n.saveRecord;

  @override
  InfoType get infoType => InfoType.note;

  @override
  bool validateForm() {
    final title = _nameController.text.trim();
    final content = _contentController.text.trim();
    return title.isNotEmpty && content.isNotEmpty;
  }

  @override
  bool get isSaveEnabled => super.isSaveEnabled && validateForm();

  @override
  PersonalNoteData createInfoData() {
    return PersonalNoteData(
      title: _nameController.text.trim(),
      content: _contentController.text.trim(),
    );
  }

  @override
  List<Widget> buildFormFields() => const <Widget>[];

  @override
  List<Widget> buildViewFields() {
    return const <Widget>[];
  }

  @override
  double get collectionSpacing => 12;

  @override
  Widget buildEditModeContent(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: _buildEditorSurface(
              context,
              constraints,
              isEditing: true,
            ),
          ),
          SizedBox(height: collectionSpacing),
          CollectionSelectionWidget(
            collections: availableCollections,
            selectedCollectionIds: selectedCollectionIds,
            onToggleCollection: toggleCollectionSelection,
            onCollectionsUpdated: updateAvailableCollections,
            titleWidget:
                showCollectionSelectionTitle ? null : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildViewModeContent(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildEditorSurface(
              context,
              constraints,
              isEditing: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorSurface(
    BuildContext context,
    BoxConstraints constraints, {
    required bool isEditing,
  }) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final dimensions = _calculateEditorDimensions(context, constraints);
    final accentBlue = Color.lerp(
      colorScheme.primary500,
      const Color(0xFF3B82F6),
      0.7,
    )!;

    _contentFocusNode.canRequestFocus = isEditing;
    if (!isEditing && _contentFocusNode.hasFocus) {
      _contentFocusNode.unfocus();
    }
    final isEditorFocused = isEditing && _contentFocusNode.hasFocus;
    final editorFillColor =
        isEditorFocused ? accentBlue.withOpacity(0.14) : colorScheme.fillFaint;

    final contentPadding = isEditing
        ? _editorContentPadding
        : _editorContentPadding + const EdgeInsets.only(bottom: 36);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: dimensions.width,
          maxWidth: dimensions.width,
        ),
        child: SizedBox(
          height: dimensions.height,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: editorFillColor,
              borderRadius: BorderRadius.circular(_editorBorderRadius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_editorBorderRadius),
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  children: [
                    Scrollbar(
                      controller: _contentScrollController,
                      child: Padding(
                        padding: contentPadding,
                        child: TextFormField(
                          controller: _contentController,
                          focusNode: _contentFocusNode,
                          scrollController: _contentScrollController,
                          readOnly: !isEditing,
                          showCursor: isEditing,
                          enableInteractiveSelection: true,
                          validator: isEditing
                              ? (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return context.l10n.pleaseEnterNoteContent;
                                  }
                                  return null;
                                }
                              : null,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          autofocus: isEditing,
                          maxLines: null,
                          minLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: textTheme.body.copyWith(height: 1.69),
                          decoration: InputDecoration.collapsed(
                            hintText: context.l10n.noteContentHint,
                            hintStyle: textTheme.body.copyWith(
                              color: colorScheme.textFaint,
                              height: 1.69,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!isEditing && _contentController.text.trim().isNotEmpty)
                      Positioned(
                        bottom: 24,
                        right: 24,
                        child: InkWell(
                          onTap: _copyContentToClipboard,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.fillBase.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.copy,
                              size: 16,
                              color: colorScheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildAppBarTitle(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final isEditing = isInEditMode;

    if (!isEditing && _titleFocusNode.hasFocus) {
      _titleFocusNode.unfocus();
    }
    _titleFocusNode.canRequestFocus = isEditing;

    final colorScheme = getEnteColorScheme(context);

    return TextField(
      controller: _nameController,
      focusNode: _titleFocusNode,
      readOnly: !isEditing,
      showCursor: isEditing,
      enableInteractiveSelection: true,
      style: textTheme.h3Bold,
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        hintText: context.l10n.noteNameHint,
        hintStyle: textTheme.h3Bold.copyWith(color: colorScheme.textFaint),
      ),
      textCapitalization: TextCapitalization.sentences,
      maxLines: 1,
    );
  }

  void _syncControllers({
    bool triggerSetState = true,
    bool updateInitial = false,
  }) {
    _isControllerSyncInProgress = true;
    try {
      final data = currentData;
      _nameController.text = data?.title ?? '';
      _contentController.text = data?.content ?? '';
      if (updateInitial) {
        _initialContent = _contentController.text;
      }
    } finally {
      _isControllerSyncInProgress = false;
    }

    if (triggerSetState && mounted) {
      setState(() {});
    }
  }

  _EditorDimensions _calculateEditorDimensions(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final availableWidth =
        constraints.hasBoundedWidth ? constraints.maxWidth : screenSize.width;
    final availableHeight = constraints.hasBoundedHeight
        ? constraints.maxHeight
        : screenSize.height;
    final width = availableWidth >= _editorMinWidth
        ? math.min(availableWidth * _editorWidthFactor, _editorMaxWidth)
        : availableWidth;
    final constrainedHeight = math.max(
      _editorMinHeight,
      math.min(_editorMaxHeight, availableHeight * 0.65),
    );
    final height = math.min(availableHeight, constrainedHeight);
    return _EditorDimensions(width, height);
  }

  void _onTitleChanged() {
    if (_isControllerSyncInProgress) {
      return;
    }
    _notifyFormChanged();
  }

  void _onContentChanged() {
    if (_isControllerSyncInProgress) {
      return;
    }
    _notifyFormChanged();
  }

  void _notifyFormChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _hasUnsavedContentChanges {
    return _contentController.text.trim() != _initialContent.trim();
  }

  void _onTitleFocusChanged() {
    if (_isControllerSyncInProgress) {
      return;
    }
    _notifyFormChanged();
  }

  void _onContentFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _copyContentToClipboard() {
    final contentText = _contentController.text;
    if (contentText.trim().isEmpty) {
      return;
    }
    Clipboard.setData(ClipboardData(text: contentText));
    showToast(
      context,
      context.l10n.copiedToClipboard(context.l10n.note),
    );
  }

  @override
  Future<bool> onEditModeBackPressed() async {
    if (!_hasUnsavedContentChanges) {
      return true;
    }

    final shouldDiscard = await _showDiscardChangesDialog();
    if (!shouldDiscard) {
      return false;
    }

    _syncControllers(
      triggerSetState: true,
      updateInitial: false,
    );
    return true;
  }

  Future<bool> _showDiscardChangesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colorScheme = getEnteColorScheme(dialogContext);
        final textTheme = getEnteTextTheme(dialogContext);

        return Dialog(
          backgroundColor: colorScheme.backgroundElevated2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.backgroundElevated2,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.unsavedNoteChangesTitle,
                        style: textTheme.h3Bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(false),
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.backgroundElevated,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.unsavedNoteChangesDescription,
                  style: textTheme.body.copyWith(
                    color: colorScheme.textMuted,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    text: context.l10n.discardChanges,
                    backgroundColor: colorScheme.warning400,
                    onTap: () => Navigator.of(dialogContext).pop(true),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }
}

class _EditorDimensions {
  final double width;
  final double height;

  const _EditorDimensions(this.width, this.height);
}
