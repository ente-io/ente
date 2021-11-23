import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
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
    return InkWell(
      onTap: () async {
        _showSessionTerminationDialog(session);
      },
      child: Column(
        children: [
          Padding(padding: EdgeInsets.all(8)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getPrettyUA(session)),
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
          Padding(padding: EdgeInsets.all(8)),
          Divider(),
        ],
      ),
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
    for (final session in _sessions.sessions) {
      Logger("Test").info(session.token);
    }
    setState(() {});
  }

  void _showSessionTerminationDialog(Session session) {
    AlertDialog alert = AlertDialog(
      title: Text("terminate session?"),
      content: Text(
        "this will log you out of the selected device",
      ),
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
            _terminateSession(session);
          },
        ),
        TextButton(
          child: Text(
            "cancel",
            style: TextStyle(
              color: Colors.white,
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

  String _getPrettyUA(Session session) {
    final parsedUA = _userAgentParser.parseResult(session.userAgent);
    return parsedUA.browser == null
        ? "Mobile"
        : "Browser (" + parsedUA.browser.name + ")";
  }
}
