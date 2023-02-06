// ignore_for_file: import_of_legacy_library_into_null_safe

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:ente_auth/core/event_bus.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/events/codes_updated_event.dart';
import "package:ente_auth/l10n/l10n.dart";
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/onboarding/view/setup_enter_secret_key_page.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:ente_auth/services/user_service.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/ui/code_widget.dart';
import 'package:ente_auth/ui/common/loading_widget.dart';
import 'package:ente_auth/ui/scanner_page.dart';
import 'package:ente_auth/ui/settings_page.dart';
import 'package:ente_auth/utils/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:move_to_background/move_to_background.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static final _settingsPage = SettingsPage(
    emailNotifier: UserService.instance.emailValueNotifier,
  );
  bool _hasLoaded = false;
  bool _isSettingsOpen = false;

  final TextEditingController _textController = TextEditingController();
  bool _showSearchBox = false;
  String _searchText = "";
  List<Code> _codes = [];
  List<Code> _filteredCodes = [];
  StreamSubscription<CodesUpdatedEvent>? _streamSubscription;

  @override
  void initState() {
    _textController.addListener(_applyFiltering);
    _loadCodes();
    _streamSubscription = Bus.instance.on<CodesUpdatedEvent>().listen((event) {
      _loadCodes();
    });
    super.initState();
  }

  void _loadCodes() {
    CodeStore.instance.getAllCodes().then((codes) {
      _codes = codes;
      _filteredCodes = codes;

      _hasLoaded = true;
      setState(() {});
    });
  }

  void _applyFiltering() {
    if (_searchText.isNotEmpty) {
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
    _textController.removeListener(_applyFiltering);
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
      CodeStore.instance.addCode(code);
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
      CodeStore.instance.addCode(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSettingsOpen) {
          Navigator.pop(context);
          return false;
        }
        if (Platform.isAndroid) {
          MoveToBackground.moveTaskToBack();
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        drawerEnableOpenDragGesture: true,
        drawer: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 428),
          child: Drawer(
            width: double.infinity,
            child: _settingsPage,
          ),
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
          title: const Text('ente Authenticator'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search',
              onPressed: () {
                setState(
                  () {
                    _showSearchBox = !_showSearchBox;
                    if (!_showSearchBox) {
                      _searchText = "";
                      _applyFiltering();
                    } else if (_textController.text.isNotEmpty) {
                      _searchText = _textController.text;
                      _applyFiltering();
                    }
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
    if (_hasLoaded) {
      if (_filteredCodes.isEmpty && _searchText.isEmpty) {
        return _getEmptyState();
      } else {
        final list = ListView.builder(
          itemBuilder: ((context, index) {
            return CodeWidget(_filteredCodes[index]);
          }),
          itemCount: _filteredCodes.length,
        );
        if (!PreferenceService.instance.hasShownCoachMark()) {
          return Stack(
            children: [
              list,
              _getCoachMarkWidget(),
            ],
          );
        } else if (_showSearchBox) {
          return Column(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: TextField(
                    autofocus: _searchText.isEmpty,
                    controller: _textController,
                    onChanged: (val) {
                      _searchText = val;
                      _applyFiltering();
                    },
                    decoration: InputDecoration(
                      // prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _textController.clear();
                          _searchText = "";
                          _applyFiltering();
                        },
                      ),
                      hintText: 'Search...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              _filteredCodes.isNotEmpty
                  ? Expanded(
                      child: ListView.builder(
                        itemBuilder: ((context, index) {
                          return CodeWidget(_filteredCodes[index]);
                        }),
                        itemCount: _filteredCodes.length,
                      ),
                    )
                  : (const Text("No result")),
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

  Widget _getFab() {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      spacing: 3,
      childPadding: const EdgeInsets.all(5),
      spaceBetweenChildren: 4,
      tooltip: 'Add Code',
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
          labelWidget: const SpeedDialLabelWidget("Scan a QR Code"),
          onTap: _redirectToScannerPage,
        ),
        SpeedDialChild(
          child: const Icon(Icons.keyboard),
          foregroundColor: Theme.of(context).colorScheme.fabForegroundColor,
          backgroundColor: Theme.of(context).colorScheme.fabBackgroundColor,
          labelWidget: const SpeedDialLabelWidget("Enter details manually"),
          onTap: _redirectToManualEntryPage,
        ),
      ],
    );
  }

  Widget _getEmptyState() {
    final l10n = context.l10n;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(height: 800, width: 450),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Image.asset(
                    "assets/wallet-front-gradient.png",
                    width: 200,
                    height: 200,
                  ),
                  Text(
                    l10n.setupFirstAccount,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headline4,
                  ),
                  const SizedBox(height: 64),
                  SizedBox(
                    width: 400,
                    child: OutlinedButton(
                      onPressed: _redirectToScannerPage,
                      child: Text(l10n.importScanQrCode),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 400,
                    child: OutlinedButton(
                      onPressed: _redirectToManualEntryPage,
                      child: Text(l10n.importEnterSetupKey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getCoachMarkWidget() {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: () async {
        await PreferenceService.instance.setHasShownCoachMark(true);
        setState(() {});
      },
      child: Row(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.background.withOpacity(0.1),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.swipe_left,
                          size: 42,
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        Text(
                          l10n.swipeHint,
                          style: Theme.of(context).textTheme.headline6,
                        ),
                        const SizedBox(
                          height: 36,
                        ),
                        SizedBox(
                          width: 160,
                          child: OutlinedButton(
                            onPressed: () async {
                              await PreferenceService.instance
                                  .setHasShownCoachMark(true);
                              setState(() {});
                            },
                            child: Text(l10n.ok),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SpeedDialLabelWidget extends StatelessWidget {
  final String label;

  const SpeedDialLabelWidget(
    this.label, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.fabBackgroundColor,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.fabForegroundColor,
        ),
      ),
    );
  }
}
