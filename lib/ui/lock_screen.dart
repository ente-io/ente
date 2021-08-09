import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/ui/app_lock.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/utils/auth_util.dart';

class LockScreen extends StatefulWidget {
  LockScreen({Key key}) : super(key: key);

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _logger = Logger("LockScreen");

  @override
  void initState() {
    _showLockScreen();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: double.infinity,
          height: 64,
          padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
          child: button(
            "unlock",
            fontSize: 18,
            onPressed: () async {
              _showLockScreen();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showLockScreen() async {
    _logger.info("Showing lockscreen");
    try {
      final result = await requestAuthentication();
      if (result) {
        AppLock.of(context).didUnlock();
      }
    } catch (e, s) {
      _logger.severe(e, s);
    }
  }
}
