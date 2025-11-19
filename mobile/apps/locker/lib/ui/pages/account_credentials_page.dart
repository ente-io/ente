import 'package:ente_ui/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/info/info_item.dart';
import 'package:locker/ui/components/capsule_form_field.dart';
import 'package:locker/ui/pages/base_info_page.dart';

class AccountCredentialsPage extends BaseInfoPage<AccountCredentialData> {
  const AccountCredentialsPage({
    super.key,
    super.mode = InfoPageMode.edit,
    super.existingFile,
    super.onCancelWithoutSaving,
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

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _usernameController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
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
    _nameController.removeListener(_onFieldChanged);
    _usernameController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  String get pageTitle {
    if (isInEditMode) {
      if (widget.existingFile != null || currentData != null) {
        return context.l10n.editSecret;
      }
      return context.l10n.accountCredentials;
    }

    final controllerName = _nameController.text.trim();
    if (controllerName.isNotEmpty) {
      return controllerName;
    }

    final dataName = (currentData?.name ?? '').trim();
    if (dataName.isNotEmpty) {
      return dataName;
    }

    return context.l10n.accountCredentials;
  }

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
  bool get isSaveEnabled => super.isSaveEnabled && validateForm();

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
      CapsuleFormField(
        labelText: context.l10n.credentialName,
        hintText: context.l10n.credentialNameHint,
        controller: _nameController,
        textCapitalization: TextCapitalization.sentences,
        autofocus: true,
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return context.l10n.pleaseEnterAccountName;
          }
          return null;
        },
      ),
      const SizedBox(height: 24),
      CapsuleFormField(
        labelText: context.l10n.username,
        hintText: context.l10n.usernameHint,
        controller: _usernameController,
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return context.l10n.pleaseEnterUsername;
          }
          return null;
        },
      ),
      const SizedBox(height: 24),
      CapsuleFormField(
        labelText: context.l10n.password,
        hintText: context.l10n.passwordHint,
        controller: _passwordController,
        obscureText: !_passwordVisible,
        textInputAction: TextInputAction.next,
        trailing: GestureDetector(
          onTap: () {
            setState(() {
              _passwordVisible = !_passwordVisible;
            });
          },
          child: Icon(
            _passwordVisible ? Icons.visibility : Icons.visibility_off,
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return context.l10n.pleaseEnterPassword;
          }
          return null;
        },
      ),
      const SizedBox(height: 24),
      CapsuleFormField(
        labelText: context.l10n.credentialNotes,
        hintText: context.l10n.credentialNotesHint,
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

  @override
  List<Widget> buildViewFields() {
    final usernameText = _usernameController.text;
    final passwordText = _passwordController.text;
    final notesText = _notesController.text;

    final fields = <Widget>[
      CapsuleDisplayField(
        labelText: context.l10n.username,
        value: usernameText,
        onCopy: usernameText.trim().isEmpty
            ? null
            : () => _copyValue(usernameText, context.l10n.username),
      ),
      const SizedBox(height: 24),
      CapsuleDisplayField(
        labelText: context.l10n.password,
        value: passwordText,
        isSecret: true,
        onCopy: passwordText.trim().isEmpty
            ? null
            : () => _copyValue(passwordText, context.l10n.password),
      ),
    ];

    if (notesText.trim().isNotEmpty) {
      fields.addAll([
        const SizedBox(height: 24),
        CapsuleDisplayField(
          labelText: context.l10n.credentialNotes,
          value: notesText,
          maxLines: 6,
          lineHeight: 1.5,
          onCopy: () => _copyValue(
            notesText,
            context.l10n.credentialNotes,
          ),
        ),
      ]);
    }

    return fields;
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
    showToast(
      context,
      context.l10n.copiedToClipboard(label),
    );
  }
}
