import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/ui/home_widget.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/utils/auth_util.dart';

class LockScreen extends StatefulWidget {
  LockScreen({Key key}) : super(key: key);

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _isUnlocking = false;
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
              : (
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
                    final result = await requestAuthentication();
                    if (result) {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) {
                        return HomeWidget();
                      }));
                    } else {
                      setState(() {
                        _isUnlocking = false;
                      });
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
        ),
      ),
    );
  }
}
