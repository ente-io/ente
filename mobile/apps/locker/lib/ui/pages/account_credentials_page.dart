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

class AccountCredentialsPage extends StatefulWidget {
  const AccountCredentialsPage({super.key});

  @override
  State<AccountCredentialsPage> createState() => _AccountCredentialsPageState();
}

class _AccountCredentialsPageState extends State<AccountCredentialsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _showValidationErrors = false;
  final _passwordFocusNode = FocusNode();
  bool _passwordInFocus = false;

  // Collection selection state
  List<Collection> _availableCollections = [];
  Set<int> _selectedCollectionIds = {};

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      setState(() {
        _passwordInFocus = _passwordFocusNode.hasFocus;
      });
    });
    _loadCollections();
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
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.accountCredentials,
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
                      context.l10n.accountCredentialsDescription,
                      style: getEnteTextTheme(context).body.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 32),
                    FormTextInputWidget(
                      controller: _nameController,
                      labelText: context.l10n.credentialName,
                      hintText: context.l10n.credentialNameHint,
                      showValidationErrors: _showValidationErrors,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.l10n.pleaseEnterAccountName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FormTextInputWidget(
                      controller: _usernameController,
                      labelText: context.l10n.username,
                      hintText: context.l10n.usernameHint,
                      showValidationErrors: _showValidationErrors,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.l10n.pleaseEnterUsername;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(context.l10n.password),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                      child: TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: !_passwordVisible,
                        keyboardType: TextInputType.visiblePassword,
                        style: getEnteTextTheme(context).body,
                        decoration: InputDecoration(
                          fillColor: getEnteColorScheme(context).fillFaint,
                          filled: true,
                          hintText: context.l10n.passwordHint,
                          hintStyle: getEnteTextTheme(context).body.copyWith(
                                color: getEnteColorScheme(context).textMuted,
                              ),
                          contentPadding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: getEnteColorScheme(context).strokeFaint,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: getEnteColorScheme(context).primary500,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: getEnteColorScheme(context).warning500,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: getEnteColorScheme(context).warning500,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: _passwordInFocus
                              ? IconButton(
                                  icon: Icon(
                                    _passwordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Theme.of(context).iconTheme.color,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _passwordVisible = !_passwordVisible;
                                    });
                                  },
                                )
                              : null,
                          suffixIconConstraints: const BoxConstraints(
                            maxHeight: 24,
                            maxWidth: 48,
                            minHeight: 24,
                            minWidth: 48,
                          ),
                        ),
                        validator: _showValidationErrors
                            ? (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return context.l10n.pleaseEnterPassword;
                                }
                                return null;
                              }
                            : null,
                        onChanged: (value) {
                          if (_showValidationErrors) {
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    FormTextInputWidget(
                      controller: _notesController,
                      labelText: context.l10n.credentialNotes,
                      hintText: context.l10n.credentialNotesHint,
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
      // Create InfoItem for account credentials
      final credentialData = AccountCredentialData(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      final infoItem = InfoItem(
        type: InfoType.accountCredential,
        data: credentialData,
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

      if (mounted) {
        Navigator.of(context).pop(); // Go back to information page

        // Show success message
        final collectionCount = selectedCollections.length;
        final message = collectionCount == 1
            ? context.l10n.recordSavedSuccessfully
            : 'Record saved to $collectionCount collections successfully';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
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
