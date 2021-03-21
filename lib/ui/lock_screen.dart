import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/ui/app_lock.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/utils/auth_util.dart';

class LockScreen extends StatefulWidget {
  LockScreen({Key key}) : super(key: key);

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _logger = Logger("LockScreen");
  bool _isUnlocking = true;

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
            child: _isUnlocking
                ? Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: loadWidget,
                  )
                : RaisedButton(
                    child: Text(
                      "unlock",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    onPressed: () async {
                      setState(() {
                        _isUnlocking = true;
                      });
                      _showLockScreen();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  )),
      ),
    );
  }

  Future<void> _showLockScreen() async {
    _logger.info("Showing lockscreen");
    try {
      final result = await requestAuthentication();
      if (result) {
        AppLock.of(context).didUnlock();
      } else {
        setState(() {
          _isUnlocking = false;
        });
      }
    } catch (e) {
      _logger.severe(e);
      setState(() {
        _isUnlocking = false;
      });
    }
  }
}
