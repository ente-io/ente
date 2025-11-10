import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:collection/collection.dart';
import 'package:ente_accounts/services/user_service.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/events/codes_updated_event.dart';
import 'package:ente_auth/events/icons_changed_event.dart';
import 'package:ente_auth/events/multi_select_action_requested_event.dart';
import 'package:ente_auth/events/trigger_logout_event.dart';
import "package:ente_auth/l10n/l10n.dart";
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/onboarding/model/tag_enums.dart';
import 'package:ente_auth/onboarding/view/common/tag_chip.dart';
import 'package:ente_auth/onboarding/view/setup_enter_secret_key_page.dart';
import 'package:ente_auth/onboarding/view/view_qr_page.dart';
import 'package:ente_auth/services/local_backup_service.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:ente_auth/store/code_display_store.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:ente_auth/theme/text_style.dart';
import 'package:ente_auth/ui/account/logout_dialog.dart';
import 'package:ente_auth/ui/code_error_widget.dart';
import 'package:ente_auth/ui/code_widget.dart';
import 'package:ente_auth/ui/common/loading_widget.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/dialog_widget.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:ente_auth/ui/home/add_tag_sheet.dart';
import 'package:ente_auth/ui/home/coach_mark_widget.dart';
import 'package:ente_auth/ui/home/home_empty_state.dart';
import 'package:ente_auth/ui/home/speed_dial_label_widget.dart';
import 'package:ente_auth/ui/reorder_codes_page.dart';
import 'package:ente_auth/ui/scanner_page.dart';
import 'package:ente_auth/ui/settings_page.dart';
import 'package:ente_auth/ui/share/code_share.dart';
import 'package:ente_auth/ui/sort_option_menu.dart';
import 'package:ente_auth/ui/utils/icon_utils.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/gallery_import_util.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:ente_auth/utils/totp_util.dart';
import 'package:ente_events/event_bus.dart';
import 'package:ente_lock_screen/local_authentication_service.dart';
import 'package:ente_lock_screen/lock_screen_settings.dart';
import 'package:ente_lock_screen/ui/app_lock.dart';
import 'package:ente_ui/pages/base_home_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:logging/logging.dart';
import 'package:move_to_background/move_to_background.dart';

class HomePage extends BaseHomePage {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _codeDisplayStore = CodeDisplayStore.instance;
  late final _settingsPage = SettingsPage(
    emailNotifier: UserService.instance.emailValueNotifier,
    scaffoldKey: scaffoldKey,
  );
  bool _hasLoaded = false;
  bool _isSettingsOpen = false;
  bool _isImportingFromGallery = false;
  final Logger _logger = Logger("HomePage");
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Used to request focus on the search box when clicked the search icon
  late FocusNode searchBoxFocusNode;

  final TextEditingController _textController = TextEditingController();
  final bool _autoFocusSearch =
      PreferenceService.instance.shouldAutoFocusOnSearchBar();
  bool _showSearchBox = false;
  String _searchText = "";
  List<Code>? _allCodes;
  List<String> tags = [];
  List<Code> _filteredCodes = [];
  StreamSubscription<CodesUpdatedEvent>? _streamSubscription;
  StreamSubscription<TriggerLogoutEvent>? _triggerLogoutEvent;
  StreamSubscription<IconsChangedEvent>? _iconsChangedEvent;
  StreamSubscription<MultiSelectActionRequestedEvent>?
      _multiSelectActionSubscription;
  String selectedTag = "";
  bool _isTrashOpen = false;
  bool hasTrashedCodes = false;
  bool hasNonTrashedCodes = false;
  bool isCompactMode = false;
  int _currentGridColumns = 1;

  late CodeSortKey _codeSortKey;
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};

  @override
  void initState() {
    super.initState();
    _codeSortKey = PreferenceService.instance.codeSortKey();
    _textController.addListener(_applyFilteringAndRefresh);
    _loadCodes();
    _streamSubscription = Bus.instance.on<CodesUpdatedEvent>().listen((event) {
      _loadCodes();
    });
    _multiSelectActionSubscription = Bus.instance
        .on<MultiSelectActionRequestedEvent>()
        .listen(_handleMultiSelectAction);
    _triggerLogoutEvent =
        Bus.instance.on<TriggerLogoutEvent>().listen((event) async {
      await autoLogoutAlert(context);
    });

    _initDeepLinks();
    Future.delayed(
      const Duration(seconds: 1),
      () async => await CodeStore.instance.importOfflineCodes(),
    );
    _iconsChangedEvent = Bus.instance.on<IconsChangedEvent>().listen((event) {
      setState(() {});
    });
    _showSearchBox = _autoFocusSearch;

    searchBoxFocusNode = FocusNode();
    ServicesBinding.instance.keyboard.addHandler(_handleKeyEvent);
  }

  void _onAddTagPressed() {
    final selectedIds = _codeDisplayStore.selectedCodeIds.value;
    final selectedCodes = _allCodes
            ?.where((c) => selectedIds.contains(c.selectionKey))
            .toList() ??
        [];

    if (selectedCodes.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return AddTagSheet(selectedCodes: selectedCodes);
      },
    ).then((_) {
      _codeDisplayStore.clearSelection();
    });
  }

  Future<void> _onRestoreSelectedPressed() async {
    final selectedIds = _codeDisplayStore.selectedCodeIds.value;
    if (selectedIds.isEmpty) return;

    FocusScope.of(context).requestFocus();

    try {
      final codesToRestore = _allCodes
              ?.where((c) => selectedIds.contains(c.selectionKey))
              .toList() ??
          [];
      for (final code in codesToRestore) {
        final updatedCode =
            code.copyWith(display: code.display.copyWith(trashed: false));
        unawaited(CodeStore.instance.addCode(updatedCode));
      }
    } catch (e) {
      if (mounted) {
        showGenericErrorDialog(context: context, error: e).ignore();
      }
    } finally {
      _codeDisplayStore.clearSelection();
    }
  }

  Future<void> _onDeleteForeverPressed() async {
    final l10n = context.l10n;
    final selectedIds = _codeDisplayStore.selectedCodeIds.value;
    if (selectedIds.isEmpty) return;

    bool isAuthSuccessful =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      context.l10n.deleteCodeAuthMessage,
    );

    if (!isAuthSuccessful) return;

    FocusScope.of(context).requestFocus();
    await showChoiceActionSheet(
      context,
      title: l10n.deleteCodeTitle,
      body: l10n.deleteCodeMessage,
      firstButtonLabel: l10n.delete,
      isCritical: true,
      firstButtonOnTap: () async {
        try {
          final codesToDelete = _allCodes
                  ?.where((c) => selectedIds.contains(c.selectionKey))
                  .toList() ??
              [];
          for (final code in codesToDelete) {
            await CodeStore.instance.removeCode(code);
          }
        } catch (e) {
          if (mounted) {
            showGenericErrorDialog(context: context, error: e).ignore();
          }
        } finally {
          _codeDisplayStore.clearSelection();
        }
      },
    );
  }

  Widget _buildTrashSelectActions() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? const Color(0xFFF7F7F7)
            : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildClearActionButton(
            context.l10n.restore,
            _onRestoreSelectedPressed,
            iconWidget: HugeIcon(
              icon: HugeIcons.strokeRoundedRestoreBin,
              size: 21,
              color: getEnteColorScheme(context).textBase,
            ),
          ),
          _buildClearActionButton(
            context.l10n.delete,
            _onDeleteForeverPressed,
            iconWidget: HugeIcon(
              icon: HugeIcons.strokeRoundedDelete04,
              size: 21,
              color: getEnteColorScheme(context).textBase,
            ),
          ),
        ],
      ),
    );
  }

  List<Code> _selectedCodesForContextMenu() {
    final selectedIds = _codeDisplayStore.selectedCodeIds.value;
    if (selectedIds.isEmpty) return const <Code>[];

    return _allCodes
            ?.where((code) => selectedIds.contains(code.selectionKey))
            .toList() ??
        const <Code>[];
  }

  int _calculateGridColumnCount(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final double tileWidth = isCompactMode ? 320 : 400;
    final int computedCount = width ~/ tileWidth;
    return computedCount <= 0 ? 1 : computedCount;
  }

  Future<void> _onPinSelectedPressed() async {
    final selectedIds = _codeDisplayStore.selectedCodeIds.value;
    if (selectedIds.isEmpty) return;

    final codesToUpdate = _allCodes
            ?.where((c) => selectedIds.contains(c.selectionKey))
            .toList() ??
        [];
    if (codesToUpdate.isEmpty) return;

    // Determine the state of the current selection (pinned/unpinned)
    final bool allArePinned = codesToUpdate.every((code) => code.isPinned);

    if (allArePinned) {
      // if all are pinned, unpin all
      for (final code in codesToUpdate) {
        final updatedCode =
            code.copyWith(display: code.display.copyWith(pinned: false));
        unawaited(CodeStore.instance.addCode(updatedCode));
      }

      if (codesToUpdate.length == 1) {
        showToast(
          context,
          context.l10n.unpinnedCodeMessage(codesToUpdate.first.issuer),
        );
      } else {
        showToast(context, context.l10n.unpinnedCount(codesToUpdate.length));
      }
    } else {
      int pinnedCount = 0;
      for (final code in codesToUpdate) {
        if (!code.isPinned) {
          // Only pin the codes that are currently unpinned
          final updatedCode =
              code.copyWith(display: code.display.copyWith(pinned: true));
          unawaited(CodeStore.instance.addCode(updatedCode));
          pinnedCount++;
        }
      }

      if (pinnedCount == 1) {
        final pinnedCode = codesToUpdate.firstWhere((c) => !c.isPinned);
        showToast(context, context.l10n.pinnedCodeMessage(pinnedCode.issuer));
      } else if (pinnedCount > 0) {
        showToast(context, context.l10n.pinnedCount(pinnedCount));
      }
    }

    _codeDisplayStore.clearSelection();
  }

  Future<void> _onUnpinSelectedPressed() async {
    final selectedIds = _codeDisplayStore.selectedCodeIds.value;
    if (selectedIds.isEmpty) return;

    final codesToUpdate = _allCodes
            ?.where((c) => selectedIds.contains(c.selectionKey))
            .toList() ??
        [];
    if (codesToUpdate.isEmpty) return;

    int unpinnedCount = 0;
    for (final code in codesToUpdate) {
      if (code.isPinned) {
        // only unpin the codes that are currently pinned
        final updatedCode =
            code.copyWith(display: code.display.copyWith(pinned: false));
        unawaited(CodeStore.instance.addCode(updatedCode));
        unpinnedCount++;
      }
    }

    if (unpinnedCount == 1) {
      final unpinnedCode = codesToUpdate.firstWhere((c) => c.isPinned);
      showToast(context, context.l10n.unpinnedCodeMessage(unpinnedCode.issuer));
    } else if (unpinnedCount > 0) {
      showToast(context, context.l10n.unpinnedCount(unpinnedCount));
    }

    _codeDisplayStore.clearSelection();
  }

  Future<void> _onTrashSelectedPressed() async {
    final l10n = context.l10n;
    final selectedIds = _codeDisplayStore.selectedCodeIds.value;
    if (selectedIds.isEmpty) return;

    bool isAuthSuccessful =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      context.l10n.deleteCodeAuthMessage,
    );
    if (!isAuthSuccessful) return;

    FocusScope.of(context).requestFocus();
    await showChoiceActionSheet(
      context,
      title: l10n.trashCode,
      body: (() {
        if (selectedIds.length == 1) {
          final code =
              _allCodes!.firstWhere((c) => c.selectionKey == selectedIds.first);
          final issuerAccount = code.account.isNotEmpty
              ? '${code.issuer} (${code.account})'
              : code.issuer;
          return l10n.trashCodeMessage(issuerAccount);
        } else {
          return l10n.moveMultipleToTrashMessage(selectedIds.length);
        }
      })(),
      firstButtonLabel: l10n.trash,
      isCritical: true,
      firstButtonOnTap: () async {
        try {
          final codesToTrash = _allCodes
                  ?.where((c) => selectedIds.contains(c.selectionKey))
                  .toList() ??
              [];

          for (final code in codesToTrash) {
            final updatedCode = code.copyWith(
              display: code.display.copyWith(trashed: true),
            );
            unawaited(CodeStore.instance.addCode(updatedCode));
          }
        } catch (e) {
          _logger.severe('Failed to trash code(s): ${e.toString()}');
          if (mounted) {
            showGenericErrorDialog(context: context, error: e).ignore();
          }
        } finally {
          _codeDisplayStore.clearSelection();
        }
      },
    );
  }

  Future<void> _onEditPressed(Code code) async {
    bool isAuthSuccessful = await LocalAuthenticationService.instance
        .requestLocalAuthentication(context, context.l10n.editCodeAuthMessage);
    await PlatformUtil.refocusWindows();
    if (!isAuthSuccessful) return;

    _codeDisplayStore.clearSelection();
    final Code? updatedCode = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return SetupEnterSecretKeyPage(code: code);
        },
      ),
    );

    if (updatedCode != null) {
      await CodeStore.instance.addCode(updatedCode);
    }
  }

  Future<void> _onSharePressed(Code code) async {
    bool isAuthSuccessful = await LocalAuthenticationService.instance
        .requestLocalAuthentication(context, context.l10n.authenticateGeneric);
    await PlatformUtil.refocusWindows();
    if (!isAuthSuccessful) return;

    _codeDisplayStore.clearSelection();
    showShareDialog(context, code);
  }

  Future<void> _onShowQrPressed(Code code) async {
    bool isAuthSuccessful = await LocalAuthenticationService.instance
        .requestLocalAuthentication(context, context.l10n.showQRAuthMessage);
    await PlatformUtil.refocusWindows();
    if (!isAuthSuccessful) return;

    _codeDisplayStore.clearSelection();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return ViewQrPage(code: code);
        },
      ),
    );
  }

  Widget _buildClearActionButton(
    String label,
    VoidCallback onTap, {
    IconData? icon,
    Widget? iconWidget,
  }) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        highlightColor: colorScheme.textBase.withValues(alpha: 0.1),
        splashColor: colorScheme.textBase.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget ?? Icon(icon!, color: colorScheme.textBase, size: 21),
              const SizedBox(height: 8),
              Text(
                label,
                style: textTheme.small
                    .copyWith(color: colorScheme.textBase, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleSelectActions(Code code) {
    final colorScheme = getEnteColorScheme(context);
    return Column(
      key: const ValueKey('single_select_actions'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildActionButton(
              context.l10n.edit,
              () => _onEditPressed(code),
              iconWidget: HugeIcon(
                icon: HugeIcons.strokeRoundedEdit03,
                size: 21,
                color: getEnteColorScheme(context).textBase,
              ),
            ),
            const SizedBox(width: 10),
            _buildActionButton(
              context.l10n.share,
              () => _onSharePressed(code),
              iconWidget: HugeIcon(
                icon: HugeIcons.strokeRoundedNavigation03,
                size: 21,
                color: getEnteColorScheme(context).textBase,
              ),
            ),
            const SizedBox(width: 10),
            _buildActionButton(
              context.l10n.qrCode,
              () => _onShowQrPressed(code),
              iconWidget: HugeIcon(
                icon: HugeIcons.strokeRoundedQrCode,
                size: 21,
                color: getEnteColorScheme(context).textBase,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? colorScheme.backgroundElevated2
                : const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              ValueListenableBuilder<Set<String>>(
                valueListenable: _codeDisplayStore.selectedCodeIds,
                builder: (context, selectedIds, child) {
                  if (selectedIds.isEmpty) {
                    return const Expanded(child: SizedBox.shrink());
                  }
                  final selectedCodes = _allCodes
                          ?.where((c) => selectedIds.contains(c.selectionKey))
                          .toList() ??
                      [];
                  if (selectedCodes.isEmpty) {
                    return const Expanded(child: SizedBox.shrink());
                  }
                  final bool allArePinned =
                      selectedCodes.every((code) => code.isPinned);

                  return _buildClearActionButton(
                    allArePinned
                        ? context.l10n.unpinText
                        : context.l10n.pinText,
                    _onPinSelectedPressed,
                    iconWidget: HugeIcon(
                      icon: allArePinned
                          ? HugeIcons.strokeRoundedPinOff
                          : HugeIcons.strokeRoundedPin,
                      size: 21,
                      color: getEnteColorScheme(context).textBase,
                    ),
                  );
                },
              ),
              _buildClearActionButton(
                context.l10n.addTag,
                _onAddTagPressed,
                iconWidget: HugeIcon(
                  icon: HugeIcons.strokeRoundedTags,
                  size: 21,
                  color: getEnteColorScheme(context).textBase,
                ),
              ),
              _buildClearActionButton(
                context.l10n.trash,
                _onTrashSelectedPressed,
                iconWidget: HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  size: 21,
                  color: getEnteColorScheme(context).textBase,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelectActions(Set<String> selectedIds) {
    final colorScheme = getEnteColorScheme(context);
    return Container(
      key: const ValueKey('multi_select_actions'),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? colorScheme.backgroundElevated2
            : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: _codeDisplayStore.selectedCodeIds,
        builder: (context, selectedIds, child) {
          if (selectedIds.isEmpty) return const SizedBox.shrink();

          final selectedCodes = _allCodes
                  ?.where((c) => selectedIds.contains(c.selectionKey))
                  .toList() ??
              [];
          if (selectedCodes.isEmpty) return const SizedBox.shrink();

          final bool allArePinned =
              selectedCodes.every((code) => code.isPinned);
          final bool isMixed =
              !allArePinned && !selectedCodes.every((code) => !code.isPinned);

          if (isMixed) {
            // Mixed state: when selection contains both pinned and unpinned codes
            return Row(
              children: [
                _buildClearActionButton(
                  context.l10n.pinText,
                  _onPinSelectedPressed,
                  iconWidget: HugeIcon(
                    icon: HugeIcons.strokeRoundedPin,
                    size: 21,
                    color: getEnteColorScheme(context).textBase,
                  ),
                ),
                _buildClearActionButton(
                  context.l10n.unpinText,
                  _onUnpinSelectedPressed,
                  iconWidget: HugeIcon(
                    icon: HugeIcons.strokeRoundedPinOff,
                    size: 21,
                    color: getEnteColorScheme(context).textBase,
                  ),
                ),
                _buildClearActionButton(
                  context.l10n.addTag,
                  _onAddTagPressed,
                  iconWidget: HugeIcon(
                    icon: HugeIcons.strokeRoundedTags,
                    size: 21,
                    color: getEnteColorScheme(context).textBase,
                  ),
                ),
                _buildClearActionButton(
                  context.l10n.trash,
                  _onTrashSelectedPressed,
                  iconWidget: HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    size: 21,
                    color: getEnteColorScheme(context).textBase,
                  ),
                ),
              ],
            );
          } else {
            // When selection contains either only pinned OR only unpinned codes
            return Row(
              children: [
                _buildClearActionButton(
                  allArePinned ? context.l10n.unpinText : context.l10n.pinText,
                  _onPinSelectedPressed,
                  iconWidget: HugeIcon(
                    icon: allArePinned
                        ? HugeIcons.strokeRoundedPinOff
                        : HugeIcons.strokeRoundedPin,
                    size: 21,
                    color: getEnteColorScheme(context).textBase,
                  ),
                ),
                _buildClearActionButton(
                  context.l10n.addTag,
                  _onAddTagPressed,
                  iconWidget: HugeIcon(
                    icon: HugeIcons.strokeRoundedTags,
                    size: 21,
                    color: getEnteColorScheme(context).textBase,
                  ),
                ),
                _buildClearActionButton(
                  context.l10n.trash,
                  _onTrashSelectedPressed,
                  iconWidget: HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    size: 21,
                    color: getEnteColorScheme(context).textBase,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    VoidCallback onTap, {
    IconData? icon,
    Widget? iconWidget,
  }) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? colorScheme.backgroundElevated2
              : const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          highlightColor: colorScheme.textBase.withValues(alpha: 0.7),
          splashColor: colorScheme.textBase.withValues(alpha: 0.7),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget ??
                    Icon(icon!, color: colorScheme.textBase, size: 21),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: textTheme.small
                      .copyWith(color: colorScheme.textBase, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isTrashOpen) {
      return _buildTrashSelectActions();
    }
    return ValueListenableBuilder<Set<String>>(
      valueListenable: _codeDisplayStore.selectedCodeIds,
      builder: (context, selectedIds, child) {
        if (selectedIds.isEmpty) {
          return const SizedBox.shrink();
        }

        final Widget actionWidget;
        if (selectedIds.length == 1) {
          final selectedCode = _allCodes?.firstWhereOrNull(
            (c) => c.selectionKey == selectedIds.first,
          );
          if (selectedCode == null) return const SizedBox.shrink();
          actionWidget = _buildSingleSelectActions(selectedCode);
        } else {
          actionWidget = _buildMultiSelectActions(selectedIds);
        }
        final double containerHeight;
        if (selectedIds.isEmpty) {
          containerHeight = 0.0;
        } else if (selectedIds.length == 1) {
          containerHeight = 160.0;
        } else {
          containerHeight = 80.0;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          height: containerHeight,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: containerHeight,
                maxHeight: containerHeight,
              ),
              child: actionWidget,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionActionBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final colorScheme = getEnteColorScheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          side: BorderSide(
            color: colorScheme.strokeMuted.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        shadowColor: isDarkMode
            ? Colors.black.withValues(alpha: 0.7)
            : Colors.grey.withValues(alpha: 0.5),
        elevation: 4,
        color: isDarkMode
            ? colorScheme.fillFaint
            : colorScheme.backgroundElevated2,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 28 + bottomPadding),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    //Select all pill
                    Material(
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: colorScheme.strokeMuted,
                          width: 0.5,
                        ),
                      ),
                      color: colorScheme.backgroundElevated2,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          final allVisibleCodeIds =
                              _filteredCodes.map((c) => c.selectionKey).toSet();
                          _codeDisplayStore.selectedCodeIds.value =
                              allVisibleCodeIds;
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.l10n.selectAll,
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(width: 6),
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedTickDouble02,
                                color: Colors.grey,
                                size: 15,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Center code logo icon
                    Expanded(
                      child: ValueListenableBuilder<Set<String>>(
                        valueListenable: _codeDisplayStore.selectedCodeIds,
                        builder: (context, selectedIds, child) {
                          if (selectedIds.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final selectedCodes = _allCodes
                                  ?.where(
                                    (c) => selectedIds.contains(c.selectionKey),
                                  )
                                  .toList() ??
                              [];
                          final codesToShow = selectedCodes.take(3).toList();
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ...codesToShow.map((code) {
                                final iconData = code.display.isCustomIcon
                                    ? code.display.iconID
                                    : code.issuer;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: IconUtils.instance.getIcon(
                                    context,
                                    iconData.trim(),
                                    width: 17,
                                  ),
                                );
                              }),
                              if (selectedIds.length > 3)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4.0),
                                  child: Text(
                                    '+${selectedIds.length - 3}',
                                    style: const TextStyle(),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),

                    // N selected pill
                    ValueListenableBuilder<Set<String>>(
                      valueListenable: _codeDisplayStore.selectedCodeIds,
                      builder: (context, selectedIds, child) {
                        return Material(
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: colorScheme.strokeMuted,
                              width: 0.5,
                            ),
                          ),
                          color: colorScheme.backgroundElevated2,
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              _codeDisplayStore.clearSelection();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    context.l10n.nSelected(selectedIds.length),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.close,
                                    size: 15,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
      bool isMetaKeyPressed = Platform.isMacOS || Platform.isIOS
          ? (_pressedKeys.contains(LogicalKeyboardKey.metaLeft) ||
              _pressedKeys.contains(LogicalKeyboardKey.meta) ||
              _pressedKeys.contains(LogicalKeyboardKey.metaRight))
          : (_pressedKeys.contains(LogicalKeyboardKey.controlLeft) ||
              _pressedKeys.contains(LogicalKeyboardKey.control) ||
              _pressedKeys.contains(LogicalKeyboardKey.controlRight));

      if (isMetaKeyPressed && event.logicalKey == LogicalKeyboardKey.keyF) {
        setState(() {
          _showSearchBox = true;
          searchBoxFocusNode.requestFocus();
        });
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() {
          _textController.clear();
          _searchText = "";
          _showSearchBox = false;
          _applyFilteringAndRefresh();
        });
        return true;
      }
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }
    return false;
  }

  void _loadCodes() {
    CodeStore.instance.getAllCodes().then((codes) {
      _allCodes = codes;
      CodeDisplayStore.instance.reconcileSelections(codes);
      hasTrashedCodes = false;
      hasNonTrashedCodes = false;

      for (final c in _allCodes ?? []) {
        if (c.isTrashed) {
          hasTrashedCodes = true;
        } else {
          hasNonTrashedCodes = true;
        }

        if (hasTrashedCodes && hasNonTrashedCodes) {
          break;
        }
      }
      if (!hasTrashedCodes) {
        _isTrashOpen = false;
      }
      if (!hasNonTrashedCodes && hasTrashedCodes) {
        _isTrashOpen = true;
      }

      CodeDisplayStore.instance.getAllTags(allCodes: _allCodes).then((value) {
        tags = value;
        if (mounted) {
          if (!tags.contains(selectedTag)) {
            selectedTag = "";
          }
          _hasLoaded = true;
          _applyFilteringAndRefresh();
        }
      });
    }).onError((error, stackTrace) {
      _logger.severe('Error while loading codes', error, stackTrace);
    });
  }

  void _applyFilteringAndRefresh() {
    if (_searchText.isNotEmpty && _showSearchBox && _allCodes != null) {
      final String val = _searchText.toLowerCase();
      // Prioritize issuer match above account for better UX while searching
      // for a specific TOTP for email providers. Searching for "emailProvider" like (gmail, proton) should
      // show the email provider first instead of other accounts where protonmail
      // is the account name.
      final List<Code> issuerMatch = [];
      final List<Code> accountMatch = [];
      final List<Code> noteMatch = [];

      for (final Code codeState in _allCodes!) {
        if (codeState.hasError ||
            selectedTag != "" &&
                !codeState.display.tags.contains(selectedTag) ||
            (codeState.isTrashed != _isTrashOpen)) {
          continue;
        }

        if (codeState.issuer.toLowerCase().contains(val)) {
          issuerMatch.add(codeState);
        } else if (codeState.account.toLowerCase().contains(val)) {
          accountMatch.add(codeState);
        } else if (codeState.note.toLowerCase().contains(val)) {
          noteMatch.add(codeState);
        }
      }
      _filteredCodes = issuerMatch;
      _filteredCodes.addAll(accountMatch);
      _filteredCodes.addAll(noteMatch);
    } else if (_isTrashOpen) {
      _filteredCodes = _allCodes
              ?.where(
                (element) => !element.hasError && element.isTrashed,
              )
              .toList() ??
          [];
    } else {
      _filteredCodes = _allCodes
              ?.where(
                (element) =>
                    !element.hasError &&
                    !element.isTrashed &&
                    (selectedTag == "" ||
                        element.display.tags.contains(selectedTag)),
              )
              .toList() ??
          [];
    }

    sortFilteredCodes(_filteredCodes, _codeSortKey);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _triggerLogoutEvent?.cancel();
    _iconsChangedEvent?.cancel();
    _multiSelectActionSubscription?.cancel();
    _textController.dispose();
    _textController.removeListener(_applyFilteringAndRefresh);
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyEvent);
    searchBoxFocusNode.dispose();

    super.dispose();
  }

  void sortFilteredCodes(List<Code> codes, CodeSortKey sortKey) {
    switch (sortKey) {
      case CodeSortKey.issuerName:
        codes.sort((a, b) => compareAsciiLowerCaseNatural(a.issuer, b.issuer));
        break;
      case CodeSortKey.accountName:
        codes
            .sort((a, b) => compareAsciiLowerCaseNatural(a.account, b.account));
        break;
      case CodeSortKey.mostFrequentlyUsed:
        codes.sort((a, b) => b.display.tapCount.compareTo(a.display.tapCount));
        break;
      case CodeSortKey.recentlyUsed:
        codes.sort(
          (a, b) => b.display.lastUsedAt.compareTo(a.display.lastUsedAt),
        );
        break;
      case CodeSortKey.manual:
        codes.sort((a, b) => a.display.position.compareTo(b.display.position));
        break;
    }
    if (sortKey != CodeSortKey.manual) {
      // move pinned codes to the using
      int insertIndex = 0;
      for (int i = 0; i < codes.length; i++) {
        if (codes[i].isPinned) {
          final code = codes.removeAt(i);
          codes.insert(insertIndex, code);
          insertIndex++;
        }
      }
    }
  }

  Future<void> _importFromGalleryNative() async {
    if (_isImportingFromGallery) {
      return;
    }

    _isImportingFromGallery = true;

    try {
      final Code? newCode =
          await pickCodeFromGallery(context, logger: _logger);
      if (newCode == null) {
        return;
      }
      await CodeStore.instance.addCode(newCode, shouldSync: false);
      // Focus the new code by searching
      if ((_allCodes?.where((e) => !e.hasError).length ?? 0) > 2) {
        _focusNewCode(newCode);
      }
      LocalBackupService.instance.triggerAutomaticBackup().ignore();
    } finally {
      _isImportingFromGallery = false;
    }
  }

  Future<void> _redirectToScannerPage() async {
    final ScannerPageResult? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return const ScannerPage();
        },
      ),
    );
    if (result != null) {
      await CodeStore.instance.addCode(
        result.code,
        shouldSync: result.fromGallery ? false : true,
      );
      // Focus the new code by searching
      if ((_allCodes?.where((e) => !e.hasError).length ?? 0) > 2) {
        _focusNewCode(result.code);
      }
      LocalBackupService.instance.triggerAutomaticBackup().ignore();
    }
  }

  Future<void> _redirectToManualEntryPage() async {
    final Code? code = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return SetupEnterSecretKeyPage();
        },
      ),
    );
    if (code != null) {
      await CodeStore.instance.addCode(code);
      LocalBackupService.instance.triggerAutomaticBackup().ignore();
    }
  }

  Future<void> navigateToLockScreen() async {
    final bool shouldShowLockScreen =
        await LockScreenSettings.instance.shouldShowLockScreen();
    if (shouldShowLockScreen) {
      // Manual lock: do not auto-prompt Touch ID; wait for user tap
      await AppLock.of(context)!.showManualLockScreen();
    } else {
      await showDialogWidget(
        context: context,
        title: context.l10n.appLockNotEnabled,
        body: context.l10n.appLockNotEnabledDescription,
        isDismissible: true,
        buttons: const [
          ButtonWidget(
            buttonType: ButtonType.secondary,
            labelText: "OK",
            isInAlert: true,
          ),
        ],
      );
    }
  }

  Future<void> navigateToReorderPage(List<Code> allCodes) async {
    List<Code> sortCandidate = allCodes
        .where((element) => !element.hasError && !element.isTrashed)
        .toList();
    sortCandidate
        .sort((a, b) => a.display.position.compareTo(b.display.position));
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return ReorderCodesPage(codes: sortCandidate);
        },
      ),
    ).then((value) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    LockScreenSettings.instance
        .setLightMode(getEnteColorScheme(context).isLightTheme);
    final l10n = context.l10n;
    isCompactMode = PreferenceService.instance.isCompactMode();

    return ValueListenableBuilder<bool>(
      valueListenable: _codeDisplayStore.isSelectionModeActive,
      builder: (context, isSelecting, child) {
        final bool isDesktop = PlatformUtil.isDesktop();
        final appBar = _buildStandardAppBar(l10n, isDesktop);
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (_, result) async {
            if (isSelecting) {
              _codeDisplayStore.clearSelection();
              return;
            }

            if (_isSettingsOpen) {
              scaffoldKey.currentState!.closeDrawer();
              return;
            } else if (!Platform.isAndroid) {
              Navigator.of(context).pop();
              return;
            }
            await MoveToBackground.moveTaskToBack();
          },
          child: Scaffold(
            key: scaffoldKey,
            drawerEnableOpenDragGesture: !Platform.isAndroid,
            drawer: Drawer(
              width: 428,
              child: _settingsPage,
            ),
            onDrawerChanged: (isOpened) => _isSettingsOpen = isOpened,
            body: SafeArea(
              bottom: false,
              child: Builder(
                builder: (context) {
                  return _getBody();
                },
              ),
            ),
            bottomNavigationBar: isSelecting
                ? (isDesktop && _currentGridColumns > 1
                    ? _buildDesktopSelectionBottomBar()
                    : _buildSelectionActionBar())
                : null,
            resizeToAvoidBottomInset: false,
            appBar: appBar,
            floatingActionButton: isSelecting
                ? null
                : (!_hasLoaded ||
                        (_allCodes?.isEmpty ?? true) ||
                        !PreferenceService.instance.hasShownCoachMark()
                    ? null
                    : _getFab()),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildStandardAppBar(
    AppLocalizations l10n,
    bool isDesktop,
  ) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      title: !_showSearchBox
          ? const Text('Ente Auth', style: brandStyleMedium)
          : TextField(
              autocorrect: false,
              enableSuggestions: false,
              autofocus: _autoFocusSearch,
              controller: _textController,
              onChanged: (val) {
                _searchText = val;
                _applyFilteringAndRefresh();
              },
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              focusNode: searchBoxFocusNode,
            ),
      centerTitle: isDesktop ? false : true,
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SortCodeMenuWidget(
            currentKey: PreferenceService.instance.codeSortKey(),
            onSelected: (newOrder) async {
              await PreferenceService.instance.setCodeSortKey(newOrder);
              if (newOrder == CodeSortKey.manual) {
                await navigateToReorderPage(_allCodes!);
              }
              setState(() {
                _codeSortKey = newOrder;
              });
              if (mounted) {
                _applyFilteringAndRefresh();
              }
            },
          ),
        ),
        if (isDesktop)
          IconButton(
            icon: const Icon(Icons.lock),
            tooltip: l10n.appLock,
            padding: const EdgeInsets.all(8.0),
            onPressed: () async {
              await navigateToLockScreen();
            },
          ),
        IconButton(
          icon: _showSearchBox
              ? const Icon(Icons.clear)
              : const Icon(Icons.search),
          tooltip: l10n.search,
          padding: const EdgeInsets.all(8.0),
          onPressed: () {
            setState(() {
              _showSearchBox = !_showSearchBox;
              if (!_showSearchBox) {
                _textController.clear();
                _searchText = "";
              } else {
                _searchText = _textController.text;
                searchBoxFocusNode.requestFocus();
              }
              _applyFilteringAndRefresh();
            });
          },
        ),
      ],
    );
  }

  Widget _buildDesktopSelectionBottomBar() {
    final l10n = context.l10n;
    final visibleIds = _filteredCodes.map((c) => c.selectionKey).toSet();
    final colorScheme = getEnteColorScheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ValueListenableBuilder<Set<String>>(
      valueListenable: _codeDisplayStore.selectedCodeIds,
      builder: (context, selectedIds, _) {
        final bool allVisibleSelected =
            visibleIds.isNotEmpty && selectedIds.containsAll(visibleIds);
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? colorScheme.fillFaint
                : colorScheme.backgroundElevated2,
            border: Border(
              top: BorderSide(
                color: colorScheme.strokeMuted.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.grey.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomPadding),
          child: Row(
            children: [
              // Close button and count
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.cancel,
                onPressed: () => _codeDisplayStore.clearSelection(),
                padding: const EdgeInsets.all(12),
              ),
              const SizedBox(width: 8),
              Text(
                '${selectedIds.length} ${l10n.selected}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              // Action buttons in center
              _buildDesktopActionRow(context),
              const Spacer(),
              // Select all chip
              _buildSelectAllChip(
                context: context,
                enabled: !allVisibleSelected,
                onPressed: allVisibleSelected
                    ? null
                    : () {
                        final newSelection = Set<String>.from(visibleIds);
                        _codeDisplayStore.selectedCodeIds.value = newSelection;
                        _codeDisplayStore.isSelectionModeActive.value =
                            newSelection.isNotEmpty;
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getBody() {
    final l10n = context.l10n;
    final crossAxisCount = _calculateGridColumnCount(context);
    _currentGridColumns = crossAxisCount;
    if (_hasLoaded) {
      if (_filteredCodes.isEmpty && _searchText.isEmpty) {
        return HomeEmptyStateWidget(
          onScanTap: _redirectToScannerPage,
          onManuallySetupTap: _redirectToManualEntryPage,
        );
      } else {
        final anyCodeHasError =
            _allCodes?.firstWhereOrNull((element) => element.hasError) != null;
        final indexOffset = anyCodeHasError ? 1 : 0;
        final itemCount = (hasNonTrashedCodes ? tags.length + 1 : 0) +
            (hasTrashedCodes ? 1 : 0);

        final list = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!anyCodeHasError)
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (index == 0 && hasNonTrashedCodes) {
                      return TagChip(
                        label: l10n.all,
                        state: selectedTag == "" && _isTrashOpen == false
                            ? TagChipState.selected
                            : TagChipState.unselected,
                        onTap: () {
                          _codeDisplayStore.clearSelection();
                          selectedTag = "";
                          _isTrashOpen = false;

                          setState(() {});
                          _applyFilteringAndRefresh();
                        },
                      );
                    }

                    if (index == itemCount - 1 && hasTrashedCodes) {
                      return TagChip(
                        label: l10n.trash,
                        state: _isTrashOpen
                            ? TagChipState.selected
                            : TagChipState.unselected,
                        onTap: () {
                          _codeDisplayStore.clearSelection();
                          selectedTag = "";
                          _isTrashOpen = !_isTrashOpen;
                          setState(() {});
                          _applyFilteringAndRefresh();
                        },
                        iconData: Icons.delete,
                      );
                    }
                    final customTagIndex = index - 1;
                    if (customTagIndex >= 0 && customTagIndex < tags.length) {
                      return TagChip(
                        label: tags[customTagIndex],
                        action: TagChipAction.menu,
                        state: selectedTag == tags[customTagIndex]
                            ? TagChipState.selected
                            : TagChipState.unselected,
                        onTap: () {
                          _codeDisplayStore.clearSelection();
                          _isTrashOpen = false;
                          if (selectedTag == tags[customTagIndex]) {
                            selectedTag = "";
                            setState(() {});
                            _applyFilteringAndRefresh();
                            return;
                          }
                          selectedTag = tags[customTagIndex];
                          setState(() {});
                          _applyFilteringAndRefresh();
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final gridView = AlignedGridView.count(
                    crossAxisCount: crossAxisCount,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: ((context, index) {
                      if (index == 0 && anyCodeHasError) {
                        return CodeErrorWidget(
                          errors: _allCodes
                                  ?.where((element) => element.hasError)
                                  .toList() ??
                              [],
                        );
                      }
                      final newIndex = index - indexOffset;

                      final code = _filteredCodes[newIndex];

                      return ClipRect(
                        child: CodeWidget(
                          key: ValueKey(
                            '${code.hashCode}_${newIndex}_$_codeSortKey',
                          ),
                          code,
                          isCompactMode: isCompactMode,
                          sortKey: _codeSortKey,
                          enableDesktopContextActions: PlatformUtil.isDesktop(),
                          selectedCodesBuilder: _selectedCodesForContextMenu,
                        ),
                      );
                    }),
                    itemCount: _filteredCodes.length + indexOffset,
                  );

                  if (PlatformUtil.isDesktop() && crossAxisCount > 1) {
                    return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapUp: (_) {
                        if (_codeDisplayStore
                            .selectedCodeIds.value.isNotEmpty) {
                          _codeDisplayStore.clearSelection();
                        }
                      },
                      child: gridView,
                    );
                  }

                  return gridView;
                },
              ),
            ),
          ],
        );
        if (!PreferenceService.instance.hasShownCoachMark()) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: list),
              const CoachMarkWidget(),
            ],
          );
        } else if (_showSearchBox) {
          final searchContent = Column(
            children: [
              Expanded(
                child: _filteredCodes.isNotEmpty
                    ? AlignedGridView.count(
                        crossAxisCount: crossAxisCount,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemBuilder: ((context, index) {
                          final codeState = _filteredCodes[index];
                          return CodeWidget(
                            key: ValueKey('${codeState.hashCode}_$index'),
                            codeState,
                            isCompactMode: isCompactMode,
                            sortKey: _codeSortKey,
                            enableDesktopContextActions:
                                PlatformUtil.isDesktop(),
                            selectedCodesBuilder: _selectedCodesForContextMenu,
                          );
                        }),
                        itemCount: _filteredCodes.length,
                      )
                    : Center(child: (Text(l10n.noResult))),
              ),
            ],
          );
          return searchContent;
        } else {
          return list;
        }
      }
    } else {
      return const EnteLoadingWidget();
    }
  }

  Future<bool> _initDeepLinks() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    final appLinks = AppLinks();
    try {
      String? initialLink;
      initialLink = await appLinks.getInitialLinkString();
      // Parse the link and warn the user, if it is not correct,
      // but keep in mind it could be `null`.
      if (initialLink != null) {
        _handleDeeplink(context, initialLink);
        return true;
      } else {
        _logger.info("No initial link received.");
      }
    } on PlatformException {
      // Handle exception by warning the user their action did not succeed
      // return?
      _logger.severe("PlatformException thrown while getting initial link");
    }

    // Attach a listener to the stream
    if (!kIsWeb && !Platform.isLinux) {
      appLinks.stringLinkStream.listen(
        (link) {
          _handleDeeplink(context, link);
        },
        onError: (err) {
          _logger.severe(err);
        },
      );
    }
    return false;
  }

  int lastScanTime = DateTime.now().millisecondsSinceEpoch - 1000;
  void _handleDeeplink(BuildContext context, String? link) {
    bool isAccountConfigured = Configuration.instance.hasConfiguredAccount();
    bool isOfflineModeEnabled =
        Configuration.instance.hasOptedForOfflineMode() &&
            Configuration.instance.getOfflineSecretKey() != null;
    if (!(isAccountConfigured || isOfflineModeEnabled) || link == null) {
      return;
    }
    if (DateTime.now().millisecondsSinceEpoch - lastScanTime < 1000) {
      _logger.info("Ignoring potential event for same deeplink");
      return;
    }
    lastScanTime = DateTime.now().millisecondsSinceEpoch;
    if (mounted && link.toLowerCase().startsWith("otpauth://")) {
      try {
        final newCode = Code.fromOTPAuthUrl(link);
        getNextTotp(newCode);
        CodeStore.instance.addCode(newCode, shouldSync: false);
        _focusNewCode(newCode);
      } catch (e, s) {
        showGenericErrorDialog(
          context: context,
          error: e,
        );
        _logger.severe("error while handling deeplink", e, s);
      }
    }
  }

  void _focusNewCode(Code newCode) {
    _showSearchBox = true;
    _textController.text = newCode.account;
    _searchText = newCode.account;
    _applyFilteringAndRefresh();
  }

  Widget _buildDesktopActionRow(BuildContext context) {
    final selectedCodes = _selectedCodesForContextMenu();
    if (selectedCodes.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool allTrashed = selectedCodes.every((code) => code.isTrashed);
    final bool allPinned = selectedCodes.every((code) => code.isPinned);
    final bool anyPinned = selectedCodes.any((code) => code.isPinned);
    final bool isMixedPinned = anyPinned && !allPinned;
    final bool singleSelection = selectedCodes.length == 1;
    final Code? singleCode = singleSelection ? selectedCodes.first : null;

    final List<Widget> actionButtons = <Widget>[];

    void addButton(
      String tooltip,
      IconData icon,
      VoidCallback? onPressed, {
      Widget? iconWidget,
    }) {
      if (actionButtons.isNotEmpty) {
        actionButtons.add(const SizedBox(width: 16));
      }
      actionButtons.add(
        _buildSelectionIconButton(
          context: context,
          tooltip: tooltip,
          icon: icon,
          iconWidget: iconWidget,
          onPressed: onPressed,
        ),
      );
    }

    if (!allTrashed) {
      if (isMixedPinned) {
        addButton(
          context.l10n.pinText,
          Icons.push_pin,
          () => _onPinSelectedPressed(),
        );
        addButton(
          context.l10n.unpinText,
          Icons.push_pin,
          () => _onUnpinSelectedPressed(),
          iconWidget: _buildUnpinIcon(context),
        );
      } else if (allPinned) {
        addButton(
          context.l10n.unpinText,
          Icons.push_pin,
          () => _onUnpinSelectedPressed(),
          iconWidget: _buildUnpinIcon(context),
        );
      } else {
        addButton(
          context.l10n.pinText,
          Icons.push_pin,
          () => _onPinSelectedPressed(),
        );
      }

      addButton(
        context.l10n.addTag,
        Icons.local_offer_outlined,
        _onAddTagPressed,
      );
      addButton(
        context.l10n.trash,
        Icons.delete_outline,
        () => _onTrashSelectedPressed(),
      );

      if (singleCode != null) {
        addButton(
          context.l10n.share,
          Icons.adaptive.share_outlined,
          () => _onSharePressed(singleCode),
        );
        addButton(
          context.l10n.qr,
          Icons.qr_code_2_outlined,
          () => _onShowQrPressed(singleCode),
        );
        addButton(
          context.l10n.edit,
          Icons.edit_outlined,
          () => _onEditPressed(singleCode),
        );
      }
    } else {
      addButton(
        context.l10n.restore,
        Icons.restore_outlined,
        () => _onRestoreSelectedPressed(),
      );
      addButton(
        context.l10n.delete,
        Icons.delete_forever_outlined,
        () => _onDeleteForeverPressed(),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actionButtons,
    );
  }

  Widget _buildSelectionIconButton({
    required BuildContext context,
    required String tooltip,
    required IconData icon,
    Widget? iconWidget,
    required VoidCallback? onPressed,
  }) {
    final colorScheme = getEnteColorScheme(context);
    final bool enabled = onPressed != null;
    final Color iconColor = enabled
        ? colorScheme.textBase
        : colorScheme.textMuted.withValues(alpha: 0.5);
    final Color backgroundColor = enabled
        ? colorScheme.fillFaint
        : colorScheme.fillFaint.withValues(alpha: 0.6);
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(12),
            child: iconWidget ?? Icon(icon, size: 24, color: iconColor),
          ),
        ),
      ),
    );
  }

  Widget _buildUnpinIcon(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.push_pin_outlined, size: 24, color: colorScheme.textBase),
        Transform.rotate(
          angle: 0.785398, // 45 degrees in radians
          child: Container(
            width: 18,
            height: 2,
            color: colorScheme.textBase,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectAllChip({
    required BuildContext context,
    required bool enabled,
    required VoidCallback? onPressed,
  }) {
    final colorScheme = getEnteColorScheme(context);
    final textColor = enabled
        ? colorScheme.textBase
        : colorScheme.textMuted.withValues(alpha: 0.6);
    return Material(
      shape: StadiumBorder(
        side: BorderSide(
          color: colorScheme.strokeMuted.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      color: colorScheme.backgroundElevated2,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.selectAll,
                style: TextStyle(fontSize: 12, color: textColor),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.done_all,
                size: 18,
                color: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getFab() {
    if (PlatformUtil.isDesktop()) {
      return FloatingActionButton(
        onPressed: () => _redirectToManualEntryPage(),
        child: const Icon(Icons.add),
        elevation: 8.0,
        shape: const CircleBorder(),
      );
    }
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      spacing: 3,
      childPadding: const EdgeInsets.all(5),
      spaceBetweenChildren: 4,
      tooltip: context.l10n.addCode,
      foregroundColor: Theme.of(context).colorScheme.fabForegroundColor,
      backgroundColor: Theme.of(context).colorScheme.fabBackgroundColor,
      overlayOpacity: 0.5,
      overlayColor: Theme.of(context).colorScheme.surface,
      elevation: 8.0,
      animationCurve: Curves.elasticInOut,
      children: [
        SpeedDialChild(
          child: const HugeIcon(icon: HugeIcons.strokeRoundedQrCode),
          foregroundColor: Theme.of(context).colorScheme.fabForegroundColor,
          backgroundColor: Theme.of(context).colorScheme.fabBackgroundColor,
          labelWidget: SpeedDialLabelWidget(context.l10n.scanAQrCode),
          onTap: _redirectToScannerPage,
        ),
        SpeedDialChild(
          child: const Icon(Icons.keyboard_alt_outlined),
          foregroundColor: Theme.of(context).colorScheme.fabForegroundColor,
          backgroundColor: Theme.of(context).colorScheme.fabBackgroundColor,
          labelWidget: SpeedDialLabelWidget(context.l10n.enterDetailsManually),
          onTap: _redirectToManualEntryPage,
        ),
        if (PlatformUtil.isMobile())
          SpeedDialChild(
            child: const HugeIcon(icon: HugeIcons.strokeRoundedAlbum02),
            backgroundColor: Theme.of(context).colorScheme.fabBackgroundColor,
            foregroundColor: Theme.of(context).colorScheme.fabForegroundColor,
            labelWidget: SpeedDialLabelWidget(context.l10n.importFromGallery),
            onTap: _importFromGalleryNative,
          ),
      ],
    );
  }

  void _handleMultiSelectAction(
    MultiSelectActionRequestedEvent event,
  ) {
    switch (event.action) {
      case MultiSelectAction.pinToggle:
        unawaited(_onPinSelectedPressed());
        break;
      case MultiSelectAction.unpin:
        unawaited(_onUnpinSelectedPressed());
        break;
      case MultiSelectAction.addTag:
        _onAddTagPressed();
        break;
      case MultiSelectAction.trash:
        unawaited(_onTrashSelectedPressed());
        break;
      case MultiSelectAction.restore:
        unawaited(_onRestoreSelectedPressed());
        break;
      case MultiSelectAction.deleteForever:
        unawaited(_onDeleteForeverPressed());
        break;
    }
  }
}
