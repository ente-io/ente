import 'package:ente_ui/components/buttons/gradient_button.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/info/info_item.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/info_file_service.dart';
import 'package:locker/ui/components/collection_selection_widget.dart';
import 'package:locker/ui/pages/home_page.dart';

abstract class BaseInfoPage<T extends InfoData> extends StatefulWidget {
  final T? existingData;

  const BaseInfoPage({super.key, this.existingData});
}

abstract class BaseInfoPageState<T extends InfoData, W extends BaseInfoPage<T>>
    extends State<W> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Collection selection state
  List<Collection> _availableCollections = [];
  Set<int> _selectedCollectionIds = {};

  // Abstract methods that subclasses must implement
  String get pageTitle;
  String get submitButtonText;
  InfoType get infoType;
  T createInfoData();
  List<Widget> buildFormFields();
  bool validateForm();

  @override
  void initState() {
    super.initState();
    _loadCollections();
    loadExistingData();
  }

  void loadExistingData() {
    // Override in subclasses if needed
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

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate() || !validateForm()) {
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
      // Create InfoItem using the subclass implementation
      final infoData = createInfoData();
      final infoItem = InfoItem(
        type: infoType,
        data: infoData,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Form fields implemented by subclass
                      ...buildFormFields(),
                      const SizedBox(height: 24),
                      // Collection selection
                      Text(
                        'Select collections',
                        style: getEnteTextTheme(context).body,
                      ),
                      const SizedBox(height: 12),
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  onTap: _isLoading ? null : _saveRecord,
                  text: _isLoading ? context.l10n.pleaseWait : submitButtonText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
