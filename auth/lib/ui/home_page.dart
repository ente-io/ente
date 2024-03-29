import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/core/event_bus.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/events/codes_updated_event.dart';
import 'package:ente_auth/events/icons_changed_event.dart';
import 'package:ente_auth/events/trigger_logout_event.dart';
import "package:ente_auth/l10n/l10n.dart";
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/onboarding/view/setup_enter_secret_key_page.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:ente_auth/services/user_service.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/ui/account/logout_dialog.dart';
import 'package:ente_auth/ui/code_widget.dart';
import 'package:ente_auth/ui/common/loading_widget.dart';
import 'package:ente_auth/ui/home/coach_mark_widget.dart';
import 'package:ente_auth/ui/home/home_empty_state.dart';
import 'package:ente_auth/ui/home/speed_dial_label_widget.dart';
import 'package:ente_auth/ui/scanner_page.dart';
import 'package:ente_auth/ui/settings_page.dart';
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

  final TextEditingController _textController = TextEditingController();
  bool _showSearchBox = false;
  String _searchText = "";
  List<Code> _codes = [];
  List<Code> _filteredCodes = [];
  StreamSubscription<CodesUpdatedEvent>? _streamSubscription;
  StreamSubscription<TriggerLogoutEvent>? _triggerLogoutEvent;
  StreamSubscription<IconsChangedEvent>? _iconsChangedEvent;

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
    _showSearchBox = PreferenceService.instance.shouldAutoFocusOnSearchBar();
  }

  void _loadCodes() {
    CodeStore.instance.getAllCodes().then((codes) {
      _codes = codes;
      _hasLoaded = true;
      _applyFilteringAndRefresh();
    });
  }

  void _applyFilteringAndRefresh() {
    if (_searchText.isNotEmpty && _showSearchBox) {
      final String val = _searchText.toLowerCase();
      _filteredCodes = _codes
          .where(
            (element) => (element.account.toLowerCase().contains(val) ||
                element.issuer.toLowerCase().contains(val)),
          )
          .toList();
    } else {
      _filteredCodes = _codes;
    }
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
      if (_codes.length > 2) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      onPopInvoked: (_) async {
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
                  autofocus: _searchText.isEmpty,
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
                ),
          actions: <Widget>[
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
                    }
                    _applyFilteringAndRefresh();
                  },
                );
              },
            ),
          ],
        ),
        floatingActionButton: !_hasLoaded ||
                _codes.isEmpty ||
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
        final list = AlignedGridView.count(
          crossAxisCount: (MediaQuery.sizeOf(context).width ~/ 400)
              .clamp(1, double.infinity)
              .toInt(),
          itemBuilder: ((context, index) {
            try {
              return ClipRect(child: CodeWidget(_filteredCodes[index]));
            } catch (e) {
              return const Text("Failed");
            }
          }),
          itemCount: _filteredCodes.length,
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
                        itemBuilder: ((context, index) {
                          Code? code;
                          try {
                            code = _filteredCodes[index];
                            return CodeWidget(code);
                          } catch (e, s) {
                            _logger.severe("code widget error", e, s);
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  l10n.sorryUnableToGenCode(code?.issuer ?? ""),
                                ),
                              ),
                            );
                          }
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
      initialLink = await appLinks.getInitialAppLinkString();
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
        final newCode = Code.fromRawData(link);
        getNextTotp(newCode);
        CodeStore.instance.addCode(newCode);
        _focusNewCode(newCode);
      } catch (e, s) {
        showGenericErrorDialog(context: context);
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
      overlayColor: Theme.of(context).colorScheme.background,
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
