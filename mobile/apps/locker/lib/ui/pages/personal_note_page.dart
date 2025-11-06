import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/info/info_item.dart';
import 'package:locker/ui/components/collection_selection_widget.dart';
import 'package:locker/ui/pages/base_info_page.dart';

class PersonalNotePage extends BaseInfoPage<PersonalNoteData> {
  const PersonalNotePage({
    super.key,
    super.mode = InfoPageMode.edit,
    super.existingFile,
  });

  @override
  State<PersonalNotePage> createState() => _PersonalNotePageState();
}

class _PersonalNotePageState
    extends BaseInfoPageState<PersonalNoteData, PersonalNotePage> {
  static const String _defaultTitle = 'Note title';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  bool _isControllerSyncInProgress = false;
  String _initialContent = '';

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onTitleChanged);
    _contentController.addListener(_onContentChanged);
    _titleFocusNode.addListener(_onTitleFocusChanged);
  }

  @override
  void loadExistingData() {
    _syncControllers(
      selectAllTitle: true,
      triggerSetState: false,
      updateInitial: true,
    );
  }

  @override
  void refreshUIWithCurrentData() {
    super.refreshUIWithCurrentData();
    _syncControllers(
      selectAllTitle: false,
      triggerSetState: true,
      updateInitial: true,
    );
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTitleChanged);
    _contentController.removeListener(_onContentChanged);
    _titleFocusNode.removeListener(_onTitleFocusChanged);
    _nameController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
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
    return _contentController.text.trim().isNotEmpty;
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
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.note,
                  style: textTheme.body,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: Material(
                      color: Colors.transparent,
                      child: TextFormField(
                        controller: _contentController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.l10n.pleaseEnterNoteContent;
                          }
                          return null;
                        },
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        autofocus: true,
                        maxLines: null,
                        minLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: textTheme.body,
                        decoration: InputDecoration(
                          hintText: context.l10n.noteContentHint,
                          hintStyle: textTheme.body.copyWith(
                            color: colorScheme.textFaint,
                          ),
                          filled: true,
                          fillColor: colorScheme.fillFaint,
                          contentPadding:
                              const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: colorScheme.strokeFaint,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: colorScheme.warning500,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: colorScheme.warning500,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
    );
  }

  @override
  Widget buildViewModeContent(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final contentText = _contentController.text;

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.fillFaint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 48, right: 4),
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          child: contentText.isEmpty
                              ? Text(
                                  context.l10n.noteContentHint,
                                  style: textTheme.body.copyWith(
                                    color: colorScheme.textFaint,
                                  ),
                                )
                              : SelectableText(
                                  contentText,
                                  style: textTheme.body,
                                ),
                        ),
                      ),
                    ),
                    if (contentText.trim().isNotEmpty)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: InkWell(
                          onTap: _copyContentToClipboard,
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.all(4),
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
        ],
      ),
    );
  }

  @override
  Widget buildAppBarTitle(BuildContext context) {
    if (isInEditMode) {
      final textTheme = getEnteTextTheme(context);
      return TextField(
        controller: _nameController,
        focusNode: _titleFocusNode,
        style: textTheme.h3Bold,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        textCapitalization: TextCapitalization.sentences,
        maxLines: 1,
      );
    }
    return super.buildAppBarTitle(context);
  }

  void _syncControllers({
    bool selectAllTitle = false,
    bool triggerSetState = true,
    bool updateInitial = false,
  }) {
    _isControllerSyncInProgress = true;
    try {
      final data = currentData;
      final trimmedTitle = data?.title.trim() ?? '';
      final effectiveTitle =
          trimmedTitle.isEmpty ? _defaultTitle : trimmedTitle;
      final shouldSelectAll = selectAllTitle && trimmedTitle.isEmpty;
      _updateTitleController(
        effectiveTitle,
        selectAll: shouldSelectAll,
      );
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

    final titleText = _nameController.text.trim();
    final contentText = _contentController.text.trim();
    if (titleText == _defaultTitle && contentText.isNotEmpty) {
      final generatedTitle = _formatCurrentTimestamp();
      _updateTitleController(generatedTitle);
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

  void _updateTitleController(String value, {bool selectAll = false}) {
    _nameController.value = TextEditingValue(
      text: value,
      selection: selectAll
          ? TextSelection(baseOffset: 0, extentOffset: value.length)
          : TextSelection.collapsed(offset: value.length),
    );
  }

  String _formatCurrentTimestamp() {
    final now = DateTime.now();
    final monthAbbreviation = DateFormat('MMM').format(now);
    final day = DateFormat('d').format(now);
    final year = DateFormat('yyyy').format(now);
    final time = DateFormat('h:mma').format(now).toLowerCase();
    return '$monthAbbreviation $day, $year - $time';
  }

  void _onTitleFocusChanged() {
    if (_isControllerSyncInProgress) {
      return;
    }

    if (_titleFocusNode.hasFocus) {
      if (_nameController.text.trim() == _defaultTitle) {
        _updateTitleController('');
      }
    } else {
      if (_nameController.text.trim().isEmpty) {
        _updateTitleController(_defaultTitle);
      }
    }
  }

  void _copyContentToClipboard() {
    final contentText = _contentController.text;
    if (contentText.trim().isEmpty) {
      return;
    }
    Clipboard.setData(ClipboardData(text: contentText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.copiedToClipboard(context.l10n.note)),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
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
      selectAllTitle: false,
      triggerSetState: true,
      updateInitial: false,
    );
    return true;
  }

  Future<bool> _showDiscardChangesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.unsavedNoteChangesTitle),
          content: Text(context.l10n.unsavedNoteChangesDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.keepEditing),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.discardChanges),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
