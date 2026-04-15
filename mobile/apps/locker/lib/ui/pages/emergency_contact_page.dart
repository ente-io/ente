import 'package:ente_ui/components/text_input_widget_v2.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/info/info_item.dart';
import 'package:locker/ui/pages/base_info_page.dart';

class EmergencyContactPage extends BaseInfoPage<EmergencyContactData> {
  const EmergencyContactPage({
    super.key,
    super.mode = InfoPageMode.edit,
    super.existingFile,
    super.onCancelWithoutSaving,
  });

  @override
  State<EmergencyContactPage> createState() => _EmergencyContactPageState();
}

class _EmergencyContactPageState
    extends BaseInfoPageState<EmergencyContactData, EmergencyContactPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactDetailsController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _contactDetailsController.addListener(_onFieldChanged);
    _loadExistingData();
  }

  void _loadExistingData() {
    final data = currentData;
    if (data != null) {
      _nameController.text = data.name;
      _contactDetailsController.text = data.contactDetails;
      _notesController.text = data.notes ?? '';
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
    _contactDetailsController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _contactDetailsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  String get pageTitle => context.l10n.emergencyContact;

  @override
  String get submitButtonText => context.l10n.saveRecord;

  @override
  InfoType get infoType => InfoType.emergencyContact;

  @override
  bool validateForm() {
    return _nameController.text.trim().isNotEmpty &&
        _contactDetailsController.text.trim().isNotEmpty;
  }

  @override
  bool get isSaveEnabled => super.isSaveEnabled && validateForm();

  @override
  EmergencyContactData createInfoData() {
    return EmergencyContactData(
      name: _nameController.text.trim(),
      contactDetails: _contactDetailsController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
  }

  @override
  List<Widget> buildFormFields() {
    return [
      TextInputWidgetV2(
        label: context.l10n.contactName,
        hintText: context.l10n.contactNameHint,
        textEditingController: _nameController,
        autoFocus: true,
        textCapitalization: TextCapitalization.words,
      ),
      const SizedBox(height: 24),
      TextInputWidgetV2(
        label: context.l10n.contactDetails,
        hintText: context.l10n.contactDetailsHint,
        textEditingController: _contactDetailsController,
        textCapitalization: TextCapitalization.sentences,
      ),
      const SizedBox(height: 24),
      TextInputWidgetV2(
        label: context.l10n.contactNotes,
        hintText: context.l10n.contactNotesHint,
        textEditingController: _notesController,
        maxLines: 3,
        minLines: 3,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
      ),
      const SizedBox(height: 24),
    ];
  }

  @override
  List<Widget> buildViewFields() {
    return [
      buildViewField(
        label: context.l10n.contactName,
        value: _nameController.text,
      ),
      const SizedBox(height: 24),
      buildViewField(
        label: context.l10n.contactDetails,
        value: _contactDetailsController.text,
      ),
      if (_notesController.text.isNotEmpty) ...[
        const SizedBox(height: 24),
        buildViewField(
          label: context.l10n.contactNotes,
          value: _notesController.text,
          maxLines: 3,
        ),
      ],
    ];
  }
}
