import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/info/info_item.dart';
import 'package:locker/ui/components/form_text_input_widget.dart';
import 'package:locker/ui/pages/base_info_page.dart';

class PhysicalRecordsPage extends BaseInfoPage<PhysicalRecordData> {
  const PhysicalRecordsPage({
    super.key,
    super.mode = InfoPageMode.edit,
    super.existingFile,
  });

  @override
  State<PhysicalRecordsPage> createState() => _PhysicalRecordsPageState();
}

class _PhysicalRecordsPageState
    extends BaseInfoPageState<PhysicalRecordData, PhysicalRecordsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final data = currentData;
    if (data != null) {
      _nameController.text = data.name;
      _locationController.text = data.location;
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
    _nameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  String get pageTitle => context.l10n.physicalRecords;

  @override
  String get submitButtonText => context.l10n.saveRecord;

  @override
  InfoType get infoType => InfoType.physicalRecord;

  @override
  bool validateForm() {
    return _nameController.text.trim().isNotEmpty &&
        _locationController.text.trim().isNotEmpty;
  }

  @override
  PhysicalRecordData createInfoData() {
    return PhysicalRecordData(
      name: _nameController.text.trim(),
      location: _locationController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
  }

  @override
  List<Widget> buildFormFields() {
    return [
      FormTextInputWidget(
        labelText: context.l10n.recordName,
        hintText: context.l10n.recordNameHint,
        controller: _nameController,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return context.l10n.pleaseEnterRecordName;
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      FormTextInputWidget(
        labelText: context.l10n.recordLocation,
        hintText: context.l10n.recordLocationHint,
        controller: _locationController,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return context.l10n.pleaseEnterLocation;
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      FormTextInputWidget(
        labelText: context.l10n.recordNotes,
        hintText: context.l10n.recordNotesHint,
        controller: _notesController,
        maxLines: 3,
      ),
      const SizedBox(height: 24),
    ];
  }

  @override
  List<Widget> buildViewFields() {
    return [
      buildViewField(
        label: context.l10n.recordName,
        value: _nameController.text,
      ),
      const SizedBox(height: 16),
      buildViewField(
        label: context.l10n.recordLocation,
        value: _locationController.text,
      ),
      if (_notesController.text.isNotEmpty) ...[
        const SizedBox(height: 16),
        buildViewField(
          label: context.l10n.recordNotes,
          value: _notesController.text,
          maxLines: 3,
        ),
      ],
    ];
  }
}
