import 'package:ente_ui/components/buttons/gradient_button.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/info/info_item.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/info_file_service.dart';
import 'package:locker/ui/components/collection_selection_widget.dart';
import 'package:locker/ui/components/form_text_input_widget.dart';
import 'package:locker/ui/pages/home_page.dart';

class PhysicalRecordsPage extends StatefulWidget {
  final PhysicalRecordData? existingData;

  const PhysicalRecordsPage({super.key, this.existingData});

  @override
  State<PhysicalRecordsPage> createState() => _PhysicalRecordsPageState();
}

class _PhysicalRecordsPageState extends State<PhysicalRecordsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showValidationErrors = false;

  // Collection selection state
  List<Collection> _availableCollections = [];
  Set<int> _selectedCollectionIds = {};

  @override
  void initState() {
    super.initState();
    _loadCollections();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.existingData != null) {
      _nameController.text = widget.existingData!.name;
      _locationController.text = widget.existingData!.location;
      _notesController.text = widget.existingData!.notes ?? '';
    }
  }

  Future<void> _loadCollections() async {
    try {
      final collections = await CollectionService.instance.getCollections();
      setState(() {
        _availableCollections = collections;
        // Pre-select a default collection if available
        if (collections.isNotEmpty) {
          final defaultCollection = collections.firstWhere(
            (c) => c.name == 'Information',
            orElse: () => collections.first,
          );
          _selectedCollectionIds = {defaultCollection.id};
        }
      });
    } catch (e) {
      // Handle error silently or show a message
    }
  }

  void _onToggleCollection(int collectionId) {
    setState(() {
      if (_selectedCollectionIds.contains(collectionId)) {
        _selectedCollectionIds.remove(collectionId);
      } else {
        // Allow multiple selections
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
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.physicalRecords,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.physicalRecordsDescription,
                      style: getEnteTextTheme(context).body.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 32),
                    FormTextInputWidget(
                      controller: _nameController,
                      labelText: context.l10n.recordName,
                      hintText: context.l10n.recordNameHint,
                      showValidationErrors: _showValidationErrors,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.l10n.pleaseEnterRecordName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FormTextInputWidget(
                      controller: _locationController,
                      labelText: context.l10n.recordLocation,
                      hintText: context.l10n.recordLocationHint,
                      maxLines: 3,
                      showValidationErrors: _showValidationErrors,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.l10n.pleaseEnterLocation;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FormTextInputWidget(
                      controller: _notesController,
                      labelText: context.l10n.recordNotes,
                      hintText: context.l10n.recordNotesHint,
                      maxLines: 5,
                      showValidationErrors: _showValidationErrors,
                    ),
                    const SizedBox(height: 24),
                    CollectionSelectionWidget(
                      collections: _availableCollections,
                      selectedCollectionIds: _selectedCollectionIds,
                      onToggleCollection: _onToggleCollection,
                      onCollectionsUpdated: _onCollectionsUpdated,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: GradientButton(
                  onTap: _isLoading ? null : _saveRecord,
                  text: context.l10n.saveRecord,
                  paddingValue: 16.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRecord() async {
    setState(() {
      _showValidationErrors = true;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCollectionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one collection'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create InfoItem for physical record
      final recordData = PhysicalRecordData(
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      final infoItem = InfoItem(
        type: InfoType.physicalRecord,
        data: recordData,
        createdAt: DateTime.now(),
      );

      // Upload to all selected collections
      final selectedCollections = _availableCollections
          .where((c) => _selectedCollectionIds.contains(c.id))
          .toList();

      // Create and upload the info file to each selected collection
      for (final collection in selectedCollections) {
        await InfoFileService.instance.createAndUploadInfoFile(
          infoItem: infoItem,
          collection: collection,
        );
      }

      // Trigger sync after successful save
      await CollectionService.instance.sync();

      if (mounted) {
        // Show success message
        final collectionCount = selectedCollections.length;
        final message = collectionCount == 1
            ? context.l10n.recordSavedSuccessfully
            : 'Record saved to $collectionCount collections successfully';

        // Navigate to home page and clear all previous routes
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );

        // Show success message after navigation
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.failedToSaveRecord}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
