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
import 'package:ente_auth/ui/home/coach_mark_widget.dart';
import 'package:ente_auth/ui/home/home_empty_state.dart';
import 'package:ente_auth/ui/home/speed_dial_label_widget.dart';
import 'package:ente_auth/ui/reorder_codes_page.dart';
import 'package:ente_auth/ui/scanner_page.dart';
import 'package:ente_auth/ui/settings_page.dart';
import 'package:ente_auth/ui/sort_option_menu.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:ente_auth/utils/totp_util.dart';
import 'package:ente_events/event_bus.dart';
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
      await AppLock.of(context)!.showLockScreen();
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

    return PopScope(
      onPopInvokedWithResult: (_, result) async {
        if (_isSettingsOpen) {
          scaffoldKey.currentState!.closeDrawer();
          return;
        } else if (!Platform.isAndroid) {
          Navigator.of(context).pop();
          return;
        }
        await MoveToBackground.moveTaskToBack();
      },
      canPop: false,
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
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
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
        floatingActionButton: !_hasLoaded ||
                (_allCodes?.isEmpty ?? true) ||
                !PreferenceService.instance.hasShownCoachMark()
            ? null
            : _getFab(),
      ),
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
