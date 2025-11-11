import 'package:dio/dio.dart';
import "package:ente_ui/components/title_bar_title_widget.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/info/info_item.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/services/info_file_service.dart';
import 'package:locker/ui/components/collection_selection_widget.dart';
import "package:locker/ui/components/gradient_button.dart";
import 'package:locker/ui/pages/home_page.dart';

enum InfoPageMode { view, edit }

abstract class BaseInfoPage<T extends InfoData> extends StatefulWidget {
  final InfoPageMode mode;
  final EnteFile? existingFile; // The file to edit, or null for new files
  final VoidCallback? onCancelWithoutSaving;

  const BaseInfoPage({
    super.key,
    this.mode = InfoPageMode.edit,
    this.existingFile,
    this.onCancelWithoutSaving,
  });
}

abstract class BaseInfoPageState<T extends InfoData, W extends BaseInfoPage<T>>
    extends State<W> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late InfoPageMode _currentMode;
  late InfoPageMode _initialMode;

  @protected
  InfoPageMode get currentMode => _currentMode;

  @protected
  bool get isInViewMode => _currentMode == InfoPageMode.view;

  @protected
  bool get isInEditMode => _currentMode == InfoPageMode.edit;

  // Current data state (can be updated after saving)
  T? _currentData;

  // Collection selection state
  List<Collection> _availableCollections = [];
  Set<int> _selectedCollectionIds = {};

  // Getter for current data - prioritizes updated data over existing file data
  T? get currentData {
    if (_currentData != null) {
      return _currentData;
    }

    // Extract data from existing file if available
    if (widget.existingFile != null) {
      final infoItem =
          InfoFileService.instance.extractInfoFromFile(widget.existingFile!);
      return infoItem?.data as T?;
    }

    return null;
  }

  // Override this method in subclasses to refresh UI when data changes
  void refreshUIWithCurrentData() {
    // Default implementation does nothing
    // Subclasses should override this to update their controllers/state
  }

  // Abstract methods that subclasses must implement
  String get pageTitle;
  String get submitButtonText;
  InfoType get infoType;
  T createInfoData();
  List<Widget> buildFormFields();
  List<Widget> buildViewFields();
  bool validateForm();

  bool get showCollectionSelectionTitle => true;
  double get collectionSpacing => 24;

  @protected
  bool get isSaveEnabled => !_isLoading;

  @protected
  Future<bool> onEditModeBackPressed() async {
    return true;
  }

  @protected
  Future<bool> onPopRequested() async {
    return true;
  }

  @protected
  Widget buildAppBarTitle(BuildContext context) {
    return TitleBarTitleWidget(
      title: pageTitle,
    );
  }

  @protected
  List<Collection> get availableCollections => _availableCollections;

  @protected
  Set<int> get selectedCollectionIds => _selectedCollectionIds;

  @protected
  void toggleCollectionSelection(int collectionId) {
    _onToggleCollection(collectionId);
  }

  @protected
  void updateAvailableCollections(List<Collection> collections) {
    _onCollectionsUpdated(collections);
  }

  @protected
  Widget buildEditModeContent(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...buildFormFields(),
            SizedBox(height: collectionSpacing),
            CollectionSelectionWidget(
              collections: _availableCollections,
              selectedCollectionIds: _selectedCollectionIds,
              onToggleCollection: _onToggleCollection,
              onCollectionsUpdated: _onCollectionsUpdated,
              titleWidget:
                  showCollectionSelectionTitle ? null : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  @protected
  Widget buildViewModeContent(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: buildViewFields(),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentMode = widget.mode;
    _initialMode = widget.mode;
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
        // Filter out uncategorized collection (it will be shown separately)
        _availableCollections = collections
            .where((c) => c.type != CollectionType.uncategorized)
            .toList();
        // Pre-select a default collection if available
        if (_availableCollections.isNotEmpty) {
          final defaultCollection = _availableCollections.firstWhere(
            (c) => c.name == context.l10n.informationCollectionName,
            orElse: () => _availableCollections.first,
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

      if (widget.existingFile != null) {
        // Update existing file
        await _updateExistingFile(infoItem);
      } else {
        // Create new file
        await _createNewFile(infoItem);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (widget.existingFile != null) {
          // Switch to view mode with updated data
          setState(() {
            _currentMode = InfoPageMode.view;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.recordSavedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final errorDetails = () {
          if (e is DioException) {
            final responseData = e.response?.data;
            if (responseData != null) {
              return responseData.toString();
            }
            return e.message ?? e.toString();
          }
          return e.toString();
        }();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.l10n.failedToSaveRecord}: $errorDetails',
            ),
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

  Future<void> _updateExistingFile(InfoItem infoItem) async {
    if (widget.existingFile == null) return;

    // Use InfoFileService to handle the update logic
    final success = await InfoFileService.instance.updateInfoFile(
      existingFile: widget.existingFile!,
      updatedInfoItem: infoItem,
    );

    if (!success) {
      throw Exception('Failed to update file metadata');
    }

    // Update the local data to reflect the changes in the UI
    // The metadata updater service already updated the file object locally
    // Now extract the updated info data and refresh the UI
    final updatedInfo =
        InfoFileService.instance.extractInfoFromFile(widget.existingFile!);
    if (updatedInfo != null) {
      // Update the current data state to show the new values in view mode
      setState(() {
        _currentData = updatedInfo.data as T?;
      });

      // Refresh UI with updated data
      refreshUIWithCurrentData();
    }

    // The info file service already performs a sync, so we don't need to sync again
  }

  Future<void> _createNewFile(InfoItem infoItem) async {
    if (_selectedCollectionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseSelectAtLeastOneCollection),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

    // Show success message
    final collectionCount = selectedCollections.length;
    final message = collectionCount == 1
        ? context.l10n.recordSavedSuccessfully
        : context.l10n.recordSavedToMultipleCollections(collectionCount);

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
        content: Text(context.l10n.copiedToClipboard(fieldName)),
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
          Text(
            label,
            style: textTheme.body,
          ), // Use default style to match FormTextInputWidget
          const SizedBox(height: 12),
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

  Future<void> _handleBackNavigation() async {
    if (isInEditMode) {
      final canLeaveEdit = await onEditModeBackPressed();
      if (!canLeaveEdit) {
        return;
      }

      if (currentData != null) {
        _toggleMode();
        return;
      }
    }

    final shouldPop = await onPopRequested();
    if (!shouldPop || !mounted) {
      return;
    }

    _popAndMaybeNotifyCancel();
  }

  void _popAndMaybeNotifyCancel() {
    final shouldNotify =
        widget.existingFile == null && widget.onCancelWithoutSaving != null;
    Navigator.of(context).pop();
    if (shouldNotify) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onCancelWithoutSaving?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isViewMode = _currentMode == InfoPageMode.view;
    final isEditMode = _currentMode == InfoPageMode.edit;
    final colorScheme = getEnteColorScheme(context);

    // Only intercept back gesture if:
    // - Currently in edit mode AND
    // - Was initially opened in view mode (editing existing note)
    final shouldInterceptBack = isEditMode && _initialMode == InfoPageMode.view;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.backgroundBase,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 48,
          leadingWidth: 48,
          centerTitle: false,
          titleSpacing: 0,
          title: buildAppBarTitle(context),
          leading: isEditMode && currentData != null
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_outlined,
                  ),
                  onPressed: _handleBackNavigation,
                  tooltip: context.l10n.backToView,
                )
              : IconButton(
                  icon: const Icon(
                    Icons.arrow_back_outlined,
                  ),
                  onPressed: _handleBackNavigation,
                  tooltip: context.l10n.back,
                ),
          automaticallyImplyLeading: false,
          actions: [
            if (isViewMode && currentData != null)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _toggleMode,
                tooltip: context.l10n.edit,
              ),
          ],
        ),
        backgroundColor: colorScheme.backgroundBase,
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (isViewMode) {
                        return buildViewModeContent(context, constraints);
                      }
                      return buildEditModeContent(context, constraints);
                    },
                  ),
                ),

                // Save button only in edit mode
                if (isEditMode) ...[
                  const SizedBox(height: 20),
                  SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        onTap: isSaveEnabled ? _saveRecord : null,
                        text: _isLoading
                            ? context.l10n.pleaseWait
                            : submitButtonText,
                      ),
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
