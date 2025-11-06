import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/info/info_item.dart';
import 'package:locker/ui/components/form_text_input_widget.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _contentController.addListener(_onFieldChanged);
    _loadExistingData();
  }

  void _loadExistingData() {
    final data = currentData;
    if (data != null) {
      _nameController.text = data.title;
      _contentController.text = data.content;
    }
  }

  @override
  void refreshUIWithCurrentData() {
    super.refreshUIWithCurrentData();
    _loadExistingData();
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _contentController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _contentController.dispose();
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
  List<Widget> buildFormFields() {
    return [
      FormTextInputWidget(
        labelText: context.l10n.noteName,
        hintText: context.l10n.noteNameHint,
        controller: _nameController,
        shouldUseTextInputWidget: false,
        validator: (_) => null,
      ),
      const SizedBox(height: 24),
      FormTextInputWidget(
        labelText: context.l10n.noteContent,
        hintText: context.l10n.noteContentHint,
        controller: _contentController,
        maxLines: 5,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return context.l10n.pleaseEnterNoteContent;
          }
          return null;
        },
      ),
      const SizedBox(height: 24),
    ];
  }

  @override
  List<Widget> buildViewFields() {
    return [
      buildViewField(
        label: context.l10n.noteContent,
        value: _contentController.text,
        maxLines: 5,
      ),
    ];
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }
}
