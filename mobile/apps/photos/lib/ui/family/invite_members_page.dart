import 'dart:math' as math;

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/models/user_details.dart';
import 'package:photos/services/account/user_service.dart';
import 'package:photos/services/family_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/base_bottom_sheet.dart';
import 'package:photos/ui/components/buttons/button_widget_v2.dart';
import 'package:photos/ui/family/family_ui.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/share_util.dart';

class InviteMembersPageResult {
  const InviteMembersPageResult._(this.invitesSent);

  const InviteMembersPageResult.invitesSent() : this._(true);

  final bool invitesSent;
}

class InviteMembersPage extends StatefulWidget {
  const InviteMembersPage({
    required this.userDetails,
    required this.remainingSlots,
    super.key,
  });

  final UserDetails userDetails;
  final int remainingSlots;

  @override
  State<InviteMembersPage> createState() => _InviteMembersPageState();
}

class _InviteMembersPageState extends State<InviteMembersPage> {
  static const int _maxFamilyMembers = 5;

  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final List<String> _emails = [];
  late final Set<String> _existingEmails;
  late int _remainingSlots;

  String? _errorMessage;
  bool _isCheckingEmail = false;

  int get _inviteSlotsLeft => math.max(0, _remainingSlots - _emails.length);

  bool get _canAddMore => _inviteSlotsLeft > 0;

  @override
  void initState() {
    super.initState();
    _remainingSlots = widget.remainingSlots;
    _existingEmails = {
      for (final member in widget.userDetails.familyData?.members ?? [])
        member.email.trim().toLowerCase(),
    };
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = getEnteTextTheme(context);
    final inviteLimitMessage = _inviteLimitMessage(l10n);
    final inviteLimitTextStyle = textTheme.bodyMuted.copyWith(height: 1.5);

    return FamilyPageScaffold(
      title: l10n.inviteMembers,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: AlignmentDirectional.topStart,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: Text(
                      inviteLimitMessage,
                      key: ValueKey(inviteLimitMessage),
                      style: inviteLimitTextStyle,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputRow(context),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        _errorMessage!,
                        style: textTheme.small.copyWith(
                          color: getEnteColorScheme(context).redBase,
                        ),
                      ),
                    ),
                  ],
                  if (_emails.isNotEmpty) const SizedBox(height: 16),
                  for (final email in _emails) ...[
                    _EmailChip(
                      email: email,
                      onRemove: () => _removeEmail(email),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ButtonWidgetV2(
            buttonType: ButtonTypeV2.primary,
            isDisabled: _emails.isEmpty,
            labelText: _sendInvitesLabel(l10n),
            onTap: _handleSendInvites,
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final l10n = AppLocalizations.of(context);
    final hasError = _errorMessage != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 58,
            decoration: BoxDecoration(
              color: colorScheme.fill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasError
                    ? colorScheme.redBase
                    : _emailFocusNode.hasFocus
                        ? colorScheme.greenBase
                        : colorScheme.strokeSolid,
              ),
            ),
            child: TextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofocus: _canAddMore,
              enabled: !_isCheckingEmail && _canAddMore,
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
              onSubmitted: (_) => _addEmail(),
              decoration: InputDecoration(
                hintText: l10n.emailAddress,
                hintStyle: textTheme.body.copyWith(
                  color: colorScheme.contentLighter,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
              style: textTheme.body,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: (_isCheckingEmail || !_canAddMore) ? null : _addEmail,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: colorScheme.fill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.strokeSolid),
            ),
            child: Center(
              child: _isCheckingEmail
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.greenBase,
                      ),
                    )
                  : Icon(
                      Icons.add,
                      size: 24,
                      color: _canAddMore
                          ? colorScheme.content
                          : colorScheme.contentLighter,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  String _sendInvitesLabel(AppLocalizations l10n) {
    return l10n.sendCountInvites(count: _emails.length);
  }

  String _inviteLimitMessage(AppLocalizations l10n) {
    if (_inviteSlotsLeft == 0) {
      return l10n.inviteLimitReached;
    }
    return l10n.inviteSlotsLeft(count: _inviteSlotsLeft);
  }

  int _remainingSlotsFor(UserDetails details) {
    final memberCount = details.familyData?.members
            ?.where(
              (member) =>
                  member.email.trim().toLowerCase() !=
                  details.email.trim().toLowerCase(),
            )
            .length ??
        0;
    return math.max(0, _maxFamilyMembers - memberCount);
  }

  Future<void> _addEmail() async {
    if (_isCheckingEmail || !_canAddMore) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(() => _errorMessage = l10n.enterAnEmailAddress);
      return;
    }
    if (!EmailValidator.validate(email)) {
      setState(() => _errorMessage = l10n.enterAValidEmailAddress);
      return;
    }
    if (_emails.contains(email) || _existingEmails.contains(email)) {
      setState(() => _errorMessage = l10n.alreadyAdded);
      return;
    }

    setState(() {
      _isCheckingEmail = true;
      _errorMessage = null;
    });

    try {
      final publicKey = await UserService.instance.getPublicKey(email);
      if (publicKey == null) {
        if (!mounted) {
          return;
        }
        setState(() => _errorMessage = l10n.thisUserIsNotOnEnte);
        await _showInviteToEnteSheet(email);
        return;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _emails.add(email);
        _emailController.clear();
        _errorMessage = null;
      });
      _emailFocusNode.requestFocus();
    } catch (error) {
      if (!mounted) {
        return;
      }
      await showGenericErrorDialog(context: context, error: error);
    } finally {
      if (mounted) {
        setState(() => _isCheckingEmail = false);
      }
    }
  }

  void _removeEmail(String email) {
    setState(() {
      _emails.remove(email);
    });
  }

  Future<void> _handleSendInvites() async {
    try {
      final result = await FamilyService.instance.inviteMembers(
        userDetails: widget.userDetails,
        emails: List<String>.from(_emails),
      );
      if (!mounted) {
        return;
      }

      if (!result.hasFailures) {
        Navigator.of(context).pop(const InviteMembersPageResult.invitesSent());
        return;
      }

      final hadAnySuccess = result.failures.length < _emails.length;
      final failedEmailSet =
          result.failures.map((failure) => failure.email).toSet();
      final successfulEmails =
          _emails.where((email) => !failedEmailSet.contains(email)).toList();
      UserDetails? refreshedDetails;
      if (hadAnySuccess) {
        try {
          refreshedDetails = await FamilyService.instance.refreshUserDetails();
        } catch (_) {}
      }

      final failedEmails =
          result.failures.map((failure) => failure.email).toList();
      setState(() {
        if (refreshedDetails != null) {
          final details = refreshedDetails;
          _remainingSlots = _remainingSlotsFor(details);
          _existingEmails
            ..clear()
            ..addAll(
              {
                for (final member in details.familyData?.members ?? [])
                  member.email.trim().toLowerCase(),
              },
            );
        } else {
          _remainingSlots = math.max(
            0,
            _remainingSlots - successfulEmails.length,
          );
          _existingEmails.addAll(successfulEmails);
        }
        _emails
          ..clear()
          ..addAll(failedEmails);
      });
      showFamilySnackBar(
        context,
        failedEmails.length == 1
            ? AppLocalizations.of(context)
                .failedToInvite(email: failedEmails.first)
            : AppLocalizations.of(context)
                .failedToInviteCount(count: failedEmails.length),
      );
      throw const _HandledInviteActionException();
    } catch (error) {
      if (error is _HandledInviteActionException) {
        rethrow;
      }
      if (!mounted) {
        throw const _HandledInviteActionException();
      }
      await showGenericErrorDialog(context: context, error: error);
      throw const _HandledInviteActionException();
    }
  }

  Future<void> _showInviteToEnteSheet(String email) {
    final l10n = AppLocalizations.of(context);
    return showBaseBottomSheet<void>(
      context,
      title: l10n.inviteToEnte,
      headerSpacing: 20,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.emailNeedsEnteAccountForFamily(email: email),
            textAlign: TextAlign.start,
            style: getEnteTextTheme(context).smallMuted,
          ),
          const SizedBox(height: 20),
          ButtonWidgetV2(
            buttonType: ButtonTypeV2.neutral,
            labelText: l10n.sendInvite,
            leadingWidget: const Icon(Icons.ios_share_outlined),
            onTap: () async {
              await shareText(l10n.shareTextRecommendUsingEnte);
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _EmailChip extends StatelessWidget {
  const _EmailChip({
    required this.email,
    required this.onRemove,
  });

  final String email;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.fillFaint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              email,
              style: textTheme.body,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 18,
              color: colorScheme.contentLighter,
            ),
          ),
        ],
      ),
    );
  }
}

class _HandledInviteActionException implements Exception {
  const _HandledInviteActionException();
}
