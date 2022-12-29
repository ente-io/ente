import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/sessions.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/components/dialog_widget.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({Key? key}) : super(key: key);

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  Sessions? _sessions;
  final Logger _logger = Logger("SessionsPageState");

  @override
  void initState() {
    _fetchActiveSessions();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Active sessions"),
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    if (_sessions == null) {
      return const Center(child: EnteLoadingWidget());
    }
    final List<Widget> rows = [];
    rows.add(const Padding(padding: EdgeInsets.all(4)));
    for (final session in _sessions!.sessions) {
      rows.add(_getSessionWidget(session));
    }
    return SingleChildScrollView(
      child: Column(
        children: rows,
      ),
    );
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _getUAWidget(session),
                const Padding(padding: EdgeInsets.all(4)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        session.ip,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.all(8)),
                    Flexible(
                      child: Text(
                        getFormattedTime(lastUsedTime),
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(),
      ],
    );
  }

  Future<void> _terminateSession(Session session) async {
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    try {
      await UserService.instance.terminateSession(session.token);
      await _fetchActiveSessions();
      await dialog.hide();
    } catch (e, s) {
      await dialog.hide();
      _logger.severe('failed to terminate', e, s);
      showErrorDialog(
        context,
        'Oops',
        "Something went wrong, please try again",
      );
    }
  }

  Future<void> _fetchActiveSessions() async {
    _sessions = await UserService.instance
        .getActiveSessions()
        .onError((error, stackTrace) {
      showToast(context, "Failed to fetch active sessions");
      throw error!;
    });
    if (_sessions != null) {
      _sessions!.sessions.sort((first, second) {
        return second.lastUsedTime.compareTo(first.lastUsedTime);
      });
      setState(() {});
    }
  }

  void _showSessionTerminationDialog(Session session) {
    final isLoggingOutFromThisDevice =
        session.token == Configuration.instance.getToken();
    Widget text;
    if (isLoggingOutFromThisDevice) {
      text = const Text(
        "This will log you out of this device!",
      );
    } else {
      text = SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              "This will log you out of the following device:",
            ),
            const Padding(padding: EdgeInsets.all(8)),
            Text(
              session.ua,
              style: Theme.of(context).textTheme.caption,
            ),
          ],
        ),
      );
    }
    final AlertDialog alert = AlertDialog(
      title: const Text("Terminate session?"),
      content: text,
      actions: [
        TextButton(
          child: const Text(
            "Terminate",
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
            "Cancel",
            style: TextStyle(
              color: isLoggingOutFromThisDevice
                  ? Theme.of(context).colorScheme.greenAlternative
                  : Theme.of(context).colorScheme.defaultTextColor,
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
        "This device",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.greenAlternative,
        ),
      );
    }
    return Text(session.prettyUA);
  }
}
