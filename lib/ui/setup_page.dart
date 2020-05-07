import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ui/sign_in_widget.dart';
import 'package:photos/utils/endpoint_finder.dart';

class SetupPage extends StatefulWidget {
  SetupPage({key}) : super(key: key);

  @override
  _SetupPageState createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  bool _errorFindingEndpoint = false;
  String _enteredEndpoint = "";

  @override
  Widget build(BuildContext context) {
    if (Configuration.instance.getEndpoint() == null &&
        !_errorFindingEndpoint) {
      EndpointFinder.instance.findEndpoint().then((endpoint) {
        if (mounted) {
          setState(() {
            Configuration.instance.setEndpoint(endpoint);
          });
        }
      }).catchError((e) {
        if (mounted) {
          setState(() {
            _errorFindingEndpoint = true;
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Setup"),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    if (Configuration.instance.getEndpoint() == null &&
        !_errorFindingEndpoint) {
      return _getSearchScreen();
    } else if (Configuration.instance.getEndpoint() == null &&
        _errorFindingEndpoint) {
      return _getManualEndpointEntryScreen();
    } else {
      return SignInWidget(() {
        setState(() {});
      });
    }
  }

  Widget _getManualEndpointEntryScreen() {
    return Container(
      margin: EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          Text("Please enter the IP address of the ente server manually."),
          TextField(
            decoration: InputDecoration(
              hintText: '192.168.1.1',
              contentPadding: EdgeInsets.all(20),
            ),
            autofocus: true,
            autocorrect: false,
            onChanged: (value) {
              setState(() {
                _enteredEndpoint = value;
              });
            },
          ),
          CupertinoButton(
            child: Text("Connect"),
            onPressed: () async {
              try {
                bool success =
                    await EndpointFinder.instance.ping(_enteredEndpoint);
                if (success) {
                  setState(() {
                    _errorFindingEndpoint = false;
                    Configuration.instance.setEndpoint(_enteredEndpoint);
                  });
                } else {
                  _showPingErrorDialog();
                }
              } catch (e) {
                _showPingErrorDialog();
              }
            },
          ),
        ],
      ),
    );
  }

  Center _getSearchScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          AnimatedSearchIconWidget(),
          Text("Searching for ente server..."),
        ],
      ),
    );
  }

  void _showPingErrorDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Connection failed'),
          content: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
            child: Text(
                'Please make sure that the server is running and reachable.'),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class AnimatedSearchIconWidget extends StatefulWidget {
  AnimatedSearchIconWidget({
    Key key,
  }) : super(key: key);

  @override
  _AnimatedSearchIconWidgetState createState() =>
      _AnimatedSearchIconWidgetState();
}

class _AnimatedSearchIconWidgetState extends State<AnimatedSearchIconWidget>
    with SingleTickerProviderStateMixin {
  Animation<double> _animation;
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(seconds: 1), vsync: this);
    _animation = Tween<double>(begin: 100, end: 200).animate(_controller)
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _controller.forward();
        }
      });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Icon(
        Icons.search,
        size: _animation.value,
      ),
      width: 200,
      height: 200,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
