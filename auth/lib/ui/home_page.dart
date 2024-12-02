import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:collection/collection.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/core/event_bus.dart';
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
import 'package:ente_auth/services/user_service.dart';
import 'package:ente_auth/store/code_display_store.dart';
import 'package:ente_auth/store/code_store.dart';
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
import 'package:ente_auth/ui/tools/app_lock.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:ente_auth/utils/totp_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import 'package:move_to_background/move_to_background.dart';

class HomePage extends StatefulWidget {
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
  bool _isFavouriteOpen = false;
  bool hasFavouriteCodes = false;
  bool hasNonFavouriteCodes = false;

  @override
  void initState() {
    super.initState();
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
  }

  void _loadCodes() {
    CodeStore.instance.getAllCodes().then((codes) {
      _allCodes = codes;
      hasTrashedCodes = false;
      hasNonTrashedCodes = false;
      hasNonFavouriteCodes = false;
      hasFavouriteCodes = false;

      for (final c in _allCodes ?? []) {
        if (c.isTrashed) {
          hasTrashedCodes = true;
        } else {
          hasNonTrashedCodes = true;
        }
        if (!c.isTrashed) {
          if (c.isPinned) {
            hasFavouriteCodes = true;
          } else {
            hasNonFavouriteCodes = true;
          }
        }
        if (hasTrashedCodes &&
            hasNonTrashedCodes &&
            hasFavouriteCodes &&
            hasNonFavouriteCodes) {
          break;
        }
      }
      if (!hasTrashedCodes) {
        _isTrashOpen = false;
      }
      if (!hasNonTrashedCodes && hasTrashedCodes) {
        _isTrashOpen = true;
      }
      if (!hasFavouriteCodes) {
        _isFavouriteOpen = false;
      }
      if (!hasNonFavouriteCodes && hasFavouriteCodes) {
        _isFavouriteOpen = true;
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
            (codeState.isTrashed != _isTrashOpen) ||
            (codeState.isPinned != _isFavouriteOpen)) {
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
    } else if (_isFavouriteOpen) {
      _filteredCodes = _allCodes
              ?.where(
                (element) =>
                    !element.hasError && !element.isTrashed && element.isPinned,
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

    _filteredCodes
        .sort((a, b) => a.display.position.compareTo(b.display.position));

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _triggerLogoutEvent?.cancel();
    _iconsChangedEvent?.cancel();
    _textController.removeListener(_applyFilteringAndRefresh);

    searchBoxFocusNode.dispose();

    super.dispose();
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
        await Configuration.instance.shouldShowLockScreen();
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
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return ReorderCodesPage(codes: _filteredCodes);
        },
      ),
    ).then((value) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
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
              ? const Text('Ente Auth')
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
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: l10n.edit,
              onPressed: () {
                navigateToReorderPage(_allCodes!);
              },
            ),
            PlatformUtil.isDesktop()
                ? IconButton(
                    icon: const Icon(Icons.lock),
                    tooltip: l10n.appLock,
                    onPressed: () async {
                      await navigateToLockScreen();
                    },
                  )
                : const SizedBox.shrink(),
            const SizedBox(
              width: 4,
            ),
            IconButton(
              icon: _showSearchBox
                  ? const Icon(Icons.clear)
                  : const Icon(Icons.search),
              tooltip: l10n.search,
              onPressed: () {
                setState(
                  () {
                    _showSearchBox = !_showSearchBox;
                    if (!_showSearchBox) {
                      _textController.clear();
                      _searchText = "";
                    } else {
                      _searchText = _textController.text;

                      // Request focus on the search box
                      searchBoxFocusNode.requestFocus();
                    }
                    _applyFilteringAndRefresh();
                  },
                );
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
            (hasTrashedCodes ? 1 : 0) +
            (hasFavouriteCodes ? 1 : 0);

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
                        state: selectedTag == "" &&
                                _isTrashOpen == false &&
                                _isFavouriteOpen == false
                            ? TagChipState.selected
                            : TagChipState.unselected,
                        onTap: () {
                          selectedTag = "";
                          _isTrashOpen = false;
                          _isFavouriteOpen = false;
                          setState(() {});
                          _applyFilteringAndRefresh();
                        },
                      );
                    }
                    if (index == 1 && hasFavouriteCodes) {
                      return TagChip(
                        label: "Favourite",
                        state: _isFavouriteOpen
                            ? TagChipState.selected
                            : TagChipState.unselected,
                        onTap: () {
                          selectedTag = "";
                          _isTrashOpen = false;
                          _isFavouriteOpen = !_isFavouriteOpen;
                          setState(() {});
                          _applyFilteringAndRefresh();
                        },
                        iconData: Icons.star,
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
                          _isFavouriteOpen = false;
                          setState(() {});
                          _applyFilteringAndRefresh();
                        },
                        iconData: Icons.delete,
                      );
                    }
                    final customTagIndex =
                        hasFavouriteCodes ? index - 2 : index - 1;
                    if (customTagIndex >= 0 && customTagIndex < tags.length) {
                      return TagChip(
                        label: tags[customTagIndex],
                        action: TagChipAction.menu,
                        state: selectedTag == tags[customTagIndex]
                            ? TagChipState.selected
                            : TagChipState.unselected,
                        onTap: () {
                          _isTrashOpen = false;
                          _isFavouriteOpen = false;
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
                      key: ValueKey('${code.hashCode}_$newIndex'),
                      code,
                      isCompactMode: isCompactMode,
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

  void _handleDeeplink(BuildContext context, String? link) {
    if (!Configuration.instance.hasConfiguredAccount() || link == null) {
      return;
    }
    if (mounted && link.toLowerCase().startsWith("otpauth://")) {
      try {
        final newCode = Code.fromOTPAuthUrl(link);
        getNextTotp(newCode);
        CodeStore.instance.addCode(newCode);
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
      ],
    );
  }
}
