import 'dart:io';

import 'package:ente_ui/components/buttons/gradient_button.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/info/info_item.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/info_file_service.dart';
import 'package:locker/ui/components/collection_selection_widget.dart';
import 'package:locker/ui/pages/home_page.dart';

enum InfoPageMode { view, edit }

abstract class BaseInfoPage<T extends InfoData> extends StatefulWidget {
  final T? existingData;
  final InfoPageMode mode;

  const BaseInfoPage({
    super.key,
    this.existingData,
    this.mode = InfoPageMode.edit,
  });
}

abstract class BaseInfoPageState<T extends InfoData, W extends BaseInfoPage<T>>
    extends State<W> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late InfoPageMode _currentMode;

  // Collection selection state
  List<Collection> _availableCollections = [];
  Set<int> _selectedCollectionIds = {};

  // Abstract methods that subclasses must implement
  String get pageTitle;
  String get submitButtonText;
  InfoType get infoType;
  T createInfoData();
  List<Widget> buildFormFields();
  List<Widget> buildViewFields();
  bool validateForm();

  @override
  void initState() {
    super.initState();
    _currentMode = widget.mode;
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

  void _toggleMode() {
    setState(() {
      _currentMode = _currentMode == InfoPageMode.view
          ? InfoPageMode.edit
          : InfoPageMode.view;
    });
  }

  void _copyToClipboard(String text, String fieldName) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$fieldName copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget buildViewField({
    required String label,
    required String value,
    bool isSecret = false,
    int? maxLines,
  }) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label), // Use default style to match FormTextInputWidget
          const SizedBox(height: 4),
        ],
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  decoration: BoxDecoration(
                    color: colorScheme.fillFaint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSecret ? '••••••••' : value,
                    style: textTheme.body,
                    maxLines: maxLines,
                    overflow: maxLines != null ? TextOverflow.ellipsis : null,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => _copyToClipboard(value, label),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isViewMode = _currentMode == InfoPageMode.view;
    final isEditMode = _currentMode == InfoPageMode.edit;

    return PopScope(
      canPop: isViewMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isEditMode) {
          // If in edit mode and trying to go back, switch to view mode instead
          _toggleMode();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(pageTitle),
          leading: isEditMode && widget.existingData != null
              ? IconButton(
                  icon: Icon(
                    Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
                  ),
                  onPressed: _toggleMode,
                  tooltip: 'Back to view',
                )
              : IconButton(
                  icon: Icon(
                    Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                ),
          automaticallyImplyLeading: false,
          actions: [
            if (isViewMode && widget.existingData != null)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _toggleMode,
                tooltip: 'Edit',
              ),
          ],
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fields based on current mode
                          if (isViewMode)
                            ...buildViewFields()
                          else
                            ...buildFormFields(),

                          // Collection selection only in edit mode
                          if (isEditMode) ...[
                            const SizedBox(height: 24),
                            CollectionSelectionWidget(
                              collections: _availableCollections,
                              selectedCollectionIds: _selectedCollectionIds,
                              onToggleCollection: _onToggleCollection,
                              onCollectionsUpdated: _onCollectionsUpdated,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Save button only in edit mode
                if (isEditMode) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      onTap: _isLoading ? null : _saveRecord,
                      text: _isLoading
                          ? context.l10n.pleaseWait
                          : submitButtonText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
