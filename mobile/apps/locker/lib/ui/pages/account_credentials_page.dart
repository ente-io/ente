import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/info/info_item.dart';
import 'package:locker/ui/components/form_text_input_widget.dart';
import 'package:locker/ui/pages/base_info_page.dart';

class AccountCredentialsPage extends BaseInfoPage<AccountCredentialData> {
  const AccountCredentialsPage({
    super.key,
    super.mode = InfoPageMode.edit,
    super.existingFile,
  });

  @override
  State<AccountCredentialsPage> createState() => _AccountCredentialsPageState();
}

class _AccountCredentialsPageState
    extends BaseInfoPageState<AccountCredentialData, AccountCredentialsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _passwordVisible = false;
  final _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      setState(() {
        // Password focus state handling if needed
      });
    });
    _loadExistingData();
  }

  void _loadExistingData() {
    final data = currentData;
    if (data != null) {
      _nameController.text = data.name;
      _usernameController.text = data.username;
      _passwordController.text = data.password;
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
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  String get pageTitle => context.l10n.accountCredentials;

  @override
  String get submitButtonText => context.l10n.saveRecord;

  @override
  InfoType get infoType => InfoType.accountCredential;

  @override
  bool validateForm() {
    return _nameController.text.trim().isNotEmpty &&
        _usernameController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;
  }

  @override
  AccountCredentialData createInfoData() {
    return AccountCredentialData(
      name: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
  }

  @override
  List<Widget> buildFormFields() {
    return [
      FormTextInputWidget(
        labelText: context.l10n.credentialName,
        hintText: context.l10n.credentialNameHint,
        controller: _nameController,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return context.l10n.pleaseEnterAccountName;
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      FormTextInputWidget(
        labelText: context.l10n.username,
        hintText: context.l10n.usernameHint,
        controller: _usernameController,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return context.l10n.pleaseEnterUsername;
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      FormTextInputWidget(
        labelText: context.l10n.password,
        hintText: context.l10n.passwordHint,
        controller: _passwordController,
        obscureText: !_passwordVisible,
        suffixIcon: IconButton(
          icon: Icon(
            _passwordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _passwordVisible = !_passwordVisible;
            });
          },
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return context.l10n.pleaseEnterPassword;
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      FormTextInputWidget(
        labelText: context.l10n.credentialNotes,
        hintText: context.l10n.credentialNotesHint,
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
        label: context.l10n.credentialName,
        value: _nameController.text,
      ),
      const SizedBox(height: 16),
      buildViewField(
        label: context.l10n.username,
        value: _usernameController.text,
      ),
      const SizedBox(height: 16),
      buildViewField(
        label: context.l10n.password,
        value: _passwordController.text,
        isSecret: true,
      ),
      if (_notesController.text.isNotEmpty) ...[
        const SizedBox(height: 16),
        buildViewField(
          label: context.l10n.credentialNotes,
          value: _notesController.text,
          maxLines: 3,
        ),
      ],
    ];
  }
}
