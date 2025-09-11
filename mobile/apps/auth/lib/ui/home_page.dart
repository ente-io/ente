import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:collection/collection.dart';
import 'package:ente_accounts/services/user_service.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/events/codes_updated_event.dart';
import 'package:ente_auth/events/icons_changed_event.dart';
import 'package:ente_auth/events/trigger_logout_event.dart';
import "package:ente_auth/l10n/l10n.dart";
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/onboarding/model/tag_enums.dart';
import 'package:ente_auth/onboarding/view/common/tag_chip.dart';
import 'package:ente_auth/onboarding/view/setup_enter_secret_key_page.dart';
import 'package:ente_auth/onboarding/view/view_qr_page.dart';
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
import 'package:ente_auth/utils/platform_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:ente_auth/utils/totp_util.dart';
import 'package:ente_events/event_bus.dart';
import 'package:ente_lock_screen/local_authentication_service.dart';
import 'package:ente_lock_screen/lock_screen_settings.dart';
import 'package:ente_lock_screen/ui/app_lock.dart';
import 'package:ente_qr/ente_qr.dart';
import 'package:ente_ui/pages/base_home_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
  String selectedTag = "";
  bool _isTrashOpen = false;
  bool hasTrashedCodes = false;
  bool hasNonTrashedCodes = false;
  bool isCompactMode = false;

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
  final selectedCodes = _allCodes?.where((c) => selectedIds.contains(c.secret)).toList() ?? [];

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
    final codesToRestore = _allCodes?.where((c) => selectedIds.contains(c.secret)).toList() ?? [];
    for (final code in codesToRestore) {
      final updatedCode = code.copyWith(display: code.display.copyWith(trashed: false));
      unawaited(CodeStore.instance.updateCode(code, updatedCode));
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
        final codesToDelete = _allCodes?.where((c) => selectedIds.contains(c.secret)).toList() ?? [];
        for (final code in codesToDelete) {
          await CodeStore.instance.removeCode(code);
        }
      } 
      catch (e) {
        if (mounted) {
          showGenericErrorDialog(context: context, error: e).ignore();
        }
      } 
      
      finally {
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
        _buildClearActionButton(Icons.restore,context.l10n.restore, _onRestoreSelectedPressed,),
        _buildClearActionButton(Icons.delete_forever,context.l10n.delete, _onDeleteForeverPressed),
      ],
    ),
  );
}

  Future<void> _onPinSelectedPressed() async {
  final selectedIds = _codeDisplayStore.selectedCodeIds.value;
  if (selectedIds.isEmpty) return;

  final codesToUpdate = _allCodes?.where((c) => selectedIds.contains(c.secret)).toList() ?? [];
  if (codesToUpdate.isEmpty) return;

  // Determine the state of the current selection (pinned/unpinned)
  final bool allArePinned = codesToUpdate.every((code) => code.isPinned);

  if (allArePinned) {
    // if all are pinned, unpin all
    for (final code in codesToUpdate) {
      final updatedCode = code.copyWith(display: code.display.copyWith(pinned: false));
      unawaited(CodeStore.instance.updateCode(code, updatedCode));
    }

    if (codesToUpdate.length == 1) {
      showToast(context, context.l10n.unpinnedCodeMessage(codesToUpdate.first.issuer));
    } else {
      showToast(context, 'Unpinned ${codesToUpdate.length} item(s)');
    }
  } else {
    int pinnedCount = 0;
    for (final code in codesToUpdate) {
      if (!code.isPinned) { // Only pin the codes that are currently unpinned
        final updatedCode = code.copyWith(display: code.display.copyWith(pinned: true));
        unawaited(CodeStore.instance.updateCode(code, updatedCode));
        pinnedCount++;
      }
    }

    if (pinnedCount == 1) {
      final pinnedCode = codesToUpdate.firstWhere((c) => !c.isPinned);
      showToast(context, context.l10n.pinnedCodeMessage(pinnedCode.issuer));
    } else if (pinnedCount > 0) {
      showToast(context, 'Pinned $pinnedCount item(s)');
    }
  }

  _codeDisplayStore.clearSelection();
}


  Future<void> _onUnpinSelectedPressed() async {
  final selectedIds = _codeDisplayStore.selectedCodeIds.value;
  if (selectedIds.isEmpty) return;

  final codesToUpdate = _allCodes?.where((c) => selectedIds.contains(c.secret)).toList() ?? [];
  if (codesToUpdate.isEmpty) return;

  int unpinnedCount = 0;
  for (final code in codesToUpdate) {
    if (code.isPinned) { // only unpin the codes that are currently pinned
      final updatedCode = code.copyWith(display: code.display.copyWith(pinned: false));
      unawaited(CodeStore.instance.updateCode(code, updatedCode));
      unpinnedCount++;
    }
  }

  if (unpinnedCount == 1) {
    final unpinnedCode = codesToUpdate.firstWhere((c) => c.isPinned);
    showToast(context, context.l10n.unpinnedCodeMessage(unpinnedCode.issuer));
  } else if (unpinnedCount > 0) {
    showToast(context, 'Unpinned $unpinnedCount item(s)');
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

    body: ((){
      if (selectedIds.length == 1){
        final code = _allCodes!.firstWhere((c) => c.secret == selectedIds.first);
        final issuerAccount = code.account.isNotEmpty ? '${code.issuer} (${code.account})' : code.issuer;
        return l10n.trashCodeMessage(issuerAccount);
      } 
      else{
        return l10n.moveMultipleToTrashMessage(selectedIds.length);
      }
    })(),
    
    firstButtonLabel: l10n.trash,
    isCritical: true, 
    firstButtonOnTap: () async {
      try {
        final codesToTrash = _allCodes?.where((c) => selectedIds.contains(c.secret)).toList() ?? [];

        for (final code in codesToTrash) {
          final updatedCode = code.copyWith(
            display: code.display.copyWith(trashed: true),
          );
          unawaited(CodeStore.instance.updateCode(code, updatedCode));
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

      if (updatedCode != null){
        await CodeStore.instance.updateCode(code, updatedCode);
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

Widget _buildClearActionButton(IconData icon, String label, VoidCallback onTap) {
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
            Icon(icon, color: colorScheme.textBase, size: 18),  //bottom row icon props
            const SizedBox(height: 8),
            Text(label, style: textTheme.small.copyWith(color: colorScheme.textBase, fontSize: 11)),
          ],
        ),
      ),
    ),
  );
}
Widget _buildSingleSelectActions(Code code) {
  final colorScheme = getEnteColorScheme(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          _buildActionButton(Icons.edit_outlined, context.l10n.edit, () => _onEditPressed(code)),
          const SizedBox(width: 10),
          _buildActionButton(Icons.share_outlined, context.l10n.share, () => _onSharePressed(code)),
          const SizedBox(width: 10),
          _buildActionButton(Icons.qr_code, context.l10n.qrCode, () => _onShowQrPressed(code)),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
    ? colorScheme.backgroundElevated2 
    : const Color(0xFFF7F7F7),
 //color of the bottom button row on single select
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ValueListenableBuilder<Set<String>>(
  valueListenable: _codeDisplayStore.selectedCodeIds,
  builder: (context, selectedIds, child) {
    if (selectedIds.isEmpty) return const Expanded(child: SizedBox.shrink());

    final selectedCodes = _allCodes?.where((c) => selectedIds.contains(c.secret)).toList() ?? [];
    if (selectedCodes.isEmpty) return const Expanded(child: SizedBox.shrink());

    final bool allArePinned = selectedCodes.every((code) => code.isPinned);
    
    return _buildClearActionButton(
      allArePinned ? Icons.push_pin : Icons.push_pin_outlined,
      allArePinned ? context.l10n.unpinText : context.l10n.pinText,
      _onPinSelectedPressed,
    );
  },
),
            _buildClearActionButton(Icons.label_outline, context.l10n.addTag, _onAddTagPressed),
            _buildClearActionButton(Icons.delete_outline, context.l10n.trash, _onTrashSelectedPressed),
          ],
        ),
      ),
    ],
  );
}

Widget _buildMultiSelectActions(Set<String> selectedIds) {
  final colorScheme = getEnteColorScheme(context);
  return Container(
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

        final selectedCodes = _allCodes?.where((c) => selectedIds.contains(c.secret)).toList() ?? [];
        if (selectedCodes.isEmpty) return const SizedBox.shrink();

        final bool allArePinned = selectedCodes.every((code) => code.isPinned);
        final bool allAreUnpinned = selectedCodes.every((code) => !code.isPinned);
        final bool isMixed = !allArePinned && !allAreUnpinned;

        if (isMixed) {
          //mixed state: when selection contains both pinned and unpinned codes
          return Row(
            children: [
              _buildClearActionButton(
                Icons.push_pin_outlined,
                context.l10n.pinText,
                _onPinSelectedPressed,
              ),
              _buildClearActionButton(
                Icons.push_pin,
                context.l10n.unpinText,
                _onUnpinSelectedPressed,
              ),
              _buildClearActionButton(
                Icons.label_outline,
                context.l10n.addTag,
                _onAddTagPressed,
              ),
              _buildClearActionButton(
                Icons.delete_outline,
                context.l10n.trash,
                _onTrashSelectedPressed,
              ),
            ],
          );
        } else {
          //when selection contains either only pinned OR only unpinned codes
          return Row(
            children: [
              _buildClearActionButton(
                allArePinned ? Icons.push_pin : Icons.push_pin_outlined,
                allArePinned ? context.l10n.unpinText : context.l10n.pinText,
                _onPinSelectedPressed,
              ),
              _buildClearActionButton(
                Icons.label_outline,
                context.l10n.addTag,
                _onAddTagPressed,
              ),
              _buildClearActionButton(
                Icons.delete_outline,
                context.l10n.trash,
                _onTrashSelectedPressed,
              ),
            ],
          );
        }
      },
    ),
  );
}

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
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
              Icon(icon, color: colorScheme.textBase, size: 18),    //top row icon props
              const SizedBox(height: 8),
              Text(
                label,
                style: textTheme.small.copyWith(color: colorScheme.textBase, fontSize: 11),
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

      if (selectedIds.length == 1) {
        final selectedCode = _allCodes?.firstWhereOrNull(
          (c) => c.secret == selectedIds.first,
        );
        if (selectedCode == null) return const SizedBox.shrink();
        return _buildSingleSelectActions(selectedCode);
      } else {
        return _buildMultiSelectActions(selectedIds);
      }
    },
  );
}

  Widget _buildSelectionActionBar() {
  final bottomPadding = MediaQuery.of(context).padding.bottom;
  final colorScheme = getEnteColorScheme(context);

  return ConstrainedBox(
    constraints: BoxConstraints(
    maxHeight: MediaQuery.of(context).size.height * 0.4,
  ),
    child: Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      elevation: 4,
      color: Theme.of(context).brightness == Brightness.dark
    ? colorScheme.fillFaint
    : colorScheme.backgroundElevated2,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
  Row(
    children: [
    //Select all pill
      Material(
        shape: StadiumBorder(
          side: BorderSide(color: colorScheme.strokeMuted, width: 0.5),
        ),
        color: colorScheme.backgroundElevated2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            final allVisibleCodeIds =
            _filteredCodes.map((c) => c.secret).toSet();
            _codeDisplayStore.selectedCodeIds.value = allVisibleCodeIds;
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline_outlined,
                  color: Colors.grey,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(context.l10n.selectAll, style: const TextStyle(fontSize: 11)),
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
                  ?.where((c) => selectedIds.contains(c.secret))
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
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: IconUtils.instance
                      .getIcon(context, iconData.trim(), width: 17),
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
            side: BorderSide(color: colorScheme.strokeMuted, width: 0.5),
          ),
          color: colorScheme.backgroundElevated2,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              _codeDisplayStore.clearSelection();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${selectedIds.length} selected',
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
    debugPrint("[HOME_DEBUG] _loadCodes triggered!");
    CodeStore.instance.getAllCodes().then((codes) {
      _allCodes = codes;
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
        }
      }
      _filteredCodes = issuerMatch;
      _filteredCodes.addAll(accountMatch);
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
    final l10n = AppLocalizations.of(context);

    if (_isImportingFromGallery) {
      return;
    }

    _isImportingFromGallery = true;

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final String imagePath = result.files.single.path!;
      final enteQr = EnteQr();
      final QrScanResult qrResult = await enteQr.scanQrFromImage(imagePath);

      if (qrResult.success && qrResult.content != null) {
        try {
          final newCode = Code.fromOTPAuthUrl(qrResult.content!);
          await CodeStore.instance.addCode(newCode, shouldSync: false);
          // Focus the new code by searching
          if ((_allCodes?.where((e) => !e.hasError).length ?? 0) > 2) {
            _focusNewCode(newCode);
          }
        } catch (e) {
          _logger.severe('Error adding code from QR scan', e);
          await showErrorDialog(
            context,
            l10n.errorInvalidQRCode,
            l10n.errorInvalidQRCodeBody,
          );
        }
      } else {
        _logger.warning('QR scan failed: ${qrResult.error}');
        await showErrorDialog(
          context,
          l10n.errorNoQRCode,
          qrResult.error ?? l10n.errorNoQRCode,
        );
      }
    } catch (e) {
      await showErrorDialog(
        context,
        l10n.errorGenericTitle,
        l10n.errorGenericBody,
      );
    } finally {
      _isImportingFromGallery = false;
    }
  }

  Future<void> _redirectToScannerPage() async {
    final Code? code = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return const ScannerPage();
        },
      ),
    );
    if (code != null) {
      await CodeStore.instance.addCode(code);
      // Focus the new code by searching
      if ((_allCodes?.where((e) => !e.hasError).length ?? 0) > 2) {
        _focusNewCode(code);
      }
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
          bottomNavigationBar: isSelecting ? _buildSelectionActionBar() : null,
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
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
            centerTitle: PlatformUtil.isDesktop() ? false : true,
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SortCodeMenuWidget(
                  currentKey: PreferenceService.instance.codeSortKey(),
                  onSelected: (newOrder) async {
                    await PreferenceService.instance.setCodeSortKey(newOrder);
                    if (newOrder == CodeSortKey.manual &&
                        newOrder == _codeSortKey) {
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
              if (PlatformUtil.isDesktop())
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
          ),
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

  Widget _getBody() {
    final l10n = context.l10n;
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
              child: AlignedGridView.count(
                crossAxisCount: (MediaQuery.sizeOf(context).width ~/ 400)
                    .clamp(1, double.infinity)
                    .toInt(),
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
                    ),
                  );
                }),
                itemCount: _filteredCodes.length + indexOffset,
              ),
            ),
          ],
        );
        if (!PreferenceService.instance.hasShownCoachMark()) {
          return Stack(
            children: [
              list,
              const CoachMarkWidget(),
            ],
          );
        } else if (_showSearchBox) {
          return Column(
            children: [
              Expanded(
                child: _filteredCodes.isNotEmpty
                    ? AlignedGridView.count(
                        crossAxisCount:
                            (MediaQuery.sizeOf(context).width ~/ 400)
                                .clamp(1, double.infinity)
                                .toInt(),
                        padding: const EdgeInsets.only(bottom: 80),
                        itemBuilder: ((context, index) {
                          final codeState = _filteredCodes[index];
                          return CodeWidget(
                            key: ValueKey('${codeState.hashCode}_$index'),
                            codeState,
                            isCompactMode: isCompactMode,
                            sortKey: _codeSortKey,
                          );
                        }),
                        itemCount: _filteredCodes.length,
                      )
                    : Center(child: (Text(l10n.noResult))),
              ),
            ],
          );
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
          child: const Icon(Icons.qr_code),
          foregroundColor: Theme.of(context).colorScheme.fabForegroundColor,
          backgroundColor: Theme.of(context).colorScheme.fabBackgroundColor,
          labelWidget: SpeedDialLabelWidget(context.l10n.scanAQrCode),
          onTap: _redirectToScannerPage,
        ),
        SpeedDialChild(
          child: const Icon(Icons.keyboard),
          foregroundColor: Theme.of(context).colorScheme.fabForegroundColor,
          backgroundColor: Theme.of(context).colorScheme.fabBackgroundColor,
          labelWidget: SpeedDialLabelWidget(context.l10n.enterDetailsManually),
          onTap: _redirectToManualEntryPage,
        ),
        if (PlatformUtil.isMobile())
          SpeedDialChild(
            child: const Icon(Icons.image),
            backgroundColor: Theme.of(context).colorScheme.fabBackgroundColor,
            foregroundColor: Theme.of(context).colorScheme.fabForegroundColor,
            labelWidget: SpeedDialLabelWidget(context.l10n.importFromGallery),
            onTap: _importFromGalleryNative,
          ),
      ],
    );
  }
}