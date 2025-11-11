import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/info/info_item.dart';
import 'package:locker/ui/components/capsule_form_field.dart';
import 'package:locker/ui/pages/base_info_page.dart';

class PhysicalRecordsPage extends BaseInfoPage<PhysicalRecordData> {
  const PhysicalRecordsPage({
    super.key,
    super.mode = InfoPageMode.edit,
    super.existingFile,
    super.onCancelWithoutSaving,
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
    _nameController.addListener(_onFieldChanged);
    _locationController.addListener(_onFieldChanged);
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
    _nameController.removeListener(_onFieldChanged);
    _locationController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  String get pageTitle {
    if (isInEditMode) {
      if (widget.existingFile != null || currentData != null) {
        return context.l10n.editLocation;
      }
      return context.l10n.physicalRecords;
    }

    final controllerName = _nameController.text.trim();
    if (controllerName.isNotEmpty) {
      return controllerName;
    }

    final dataName = (currentData?.name ?? '').trim();
    if (dataName.isNotEmpty) {
      return dataName;
    }

    return context.l10n.physicalRecords;
  }

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
  bool get isSaveEnabled =>
      super.isSaveEnabled &&
      _nameController.text.trim().isNotEmpty &&
      _locationController.text.trim().isNotEmpty;

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
      CapsuleFormField(
        labelText: context.l10n.name,
        hintText: context.l10n.recordNameHint,
        controller: _nameController,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return context.l10n.pleaseEnterRecordName;
          }
          return null;
        },
      ),
      const SizedBox(height: 24),
      CapsuleFormField(
        labelText: context.l10n.recordLocation,
        hintText: context.l10n.recordLocationHint,
        controller: _locationController,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return context.l10n.pleaseEnterLocation;
          }
          return null;
        },
      ),
      const SizedBox(height: 24),
      CapsuleFormField(
        labelText: context.l10n.recordNotes,
        hintText: context.l10n.recordNotesHint,
        controller: _notesController,
        maxLines: 3,
        minLines: 3,
        textCapitalization: TextCapitalization.sentences,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        lineHeight: 1.5,
      ),
    ];
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _copyValue(String value, String label) {
    if (value.trim().isEmpty) {
      return;
    }
    Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.copiedToClipboard(label)),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  List<Widget> buildViewFields() {
    final fields = <Widget>[
      CapsuleDisplayField(
        labelText: context.l10n.recordLocation,
        value: _locationController.text,
        onCopy: _locationController.text.trim().isEmpty
            ? null
            : () => _copyValue(
                  _locationController.text,
                  context.l10n.recordLocation,
                ),
      ),
    ];

    if (_notesController.text.trim().isNotEmpty) {
      fields.addAll([
        const SizedBox(height: 24),
        CapsuleDisplayField(
          labelText: context.l10n.recordNotes,
          value: _notesController.text,
          maxLines: 6,
          lineHeight: 1.5,
          onCopy: () => _copyValue(
            _notesController.text,
            context.l10n.recordNotes,
          ),
        ),
      ]);
    }

    return fields;
  }
}
