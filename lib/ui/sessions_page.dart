import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/sessions.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:user_agent_parser/user_agent_parser.dart';

class SessionsPage extends StatefulWidget {
  SessionsPage({Key key}) : super(key: key);

  @override
  _SessionsPageState createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  final _userAgentParser = UserAgentParser();
  Sessions _sessions;

  @override
  void initState() {
    _fetchActiveSessions();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("active sessions"),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    if (_sessions == null) {
      return Center(child: loadWidget);
    }
    List<Widget> rows = [];
    for (final session in _sessions.sessions) {
      rows.add(_getSessionWidget(session));
    }
    return Column(children: rows);
  }

  Widget _getSessionWidget(Session session) {
    final lastUsedTime =
        DateTime.fromMicrosecondsSinceEpoch(session.lastUsedTime);
    return Column(
      children: [
        InkWell(
          onTap: () async {
            _showSessionTerminationDialog(session);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _getUAWidget(session),
                    Padding(padding: EdgeInsets.all(4)),
                    Text(
                      session.ip,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                Text(getFormattedTime(lastUsedTime)),
              ],
            ),
          ),
        ),
        Divider(),
      ],
    );
  }

  Future<void> _terminateSession(Session session) async {
    final dialog = createProgressDialog(context, "please wait...");
    await dialog.show();
    await UserService.instance.terminateSession(session.token);
    await _fetchActiveSessions();
    await dialog.hide();
  }

  Future<void> _fetchActiveSessions() async {
    _sessions = await UserService.instance.getActiveSessions();
    _sessions.sessions.sort((first, second) {
      return second.lastUsedTime.compareTo(first.lastUsedTime);
    });
    setState(() {});
  }

  void _showSessionTerminationDialog(Session session) {
    final isLoggingOutFromThisDevice =
        session.token == Configuration.instance.getToken();
    Widget text;
    if (isLoggingOutFromThisDevice) {
      text = Text(
        "this will log you out of this device!",
      );
    } else {
      text = SingleChildScrollView(
        child: Column(
          children: [
            Text(
              "this will log you out of the following device:",
            ),
            Padding(padding: EdgeInsets.all(8)),
            Text(
              session.userAgent,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    AlertDialog alert = AlertDialog(
      title: Text("terminate session?"),
      content: text,
      actions: [
        TextButton(
          child: Text(
            "terminate",
            style: TextStyle(
              color: Colors.red,
            ),
          ),
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop('dialog');
            if (isLoggingOutFromThisDevice) {
              await UserService.instance.logout(context);
            } else {
              _terminateSession(session);
            }
          },
        ),
        TextButton(
          child: Text(
            "cancel",
            style: TextStyle(
              color: isLoggingOutFromThisDevice
                  ? Theme.of(context).buttonColor
                  : Colors.white,
            ),
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop('dialog');
          },
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Widget _getUAWidget(Session session) {
    if (session.token == Configuration.instance.getToken()) {
      return Text(
        "this device",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).buttonColor,
        ),
      );
    }
    final parsedUA = _userAgentParser.parseResult(session.userAgent);
    return Text(parsedUA.browser == null
        ? "Mobile"
        : "Browser (" + parsedUA.browser.name + ")");
  }
}
