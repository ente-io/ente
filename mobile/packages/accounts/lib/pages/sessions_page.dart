import 'package:ente_accounts/ente_accounts.dart';
import 'package:ente_configuration/base_configuration.dart';
import 'package:ente_strings/ente_strings.dart';
import 'package:ente_ui/components/loading_widget.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:ente_ui/utils/toast_util.dart';
import 'package:ente_utils/date_time_util.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class SessionsPage extends StatefulWidget {
  final BaseConfiguration config;
  const SessionsPage(
    this.config, {
    super.key,
  });

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  Sessions? _sessions;
  final Logger _logger = Logger("SessionsPageState");

  @override
  void initState() {
    _fetchActiveSessions().onError((error, stackTrace) {
      showToast(context, "Failed to fetch active sessions");
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(context.strings.activeSessions),
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
                              .withValues(alpha: 0.8),
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
                              .withValues(alpha: 0.8),
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
    final dialog = createProgressDialog(context, context.strings.pleaseWait);
    await dialog.show();
    try {
      await UserService.instance.terminateSession(session.token);
      await _fetchActiveSessions();
      await dialog.hide();
    } catch (e) {
      await dialog.hide();
      _logger.severe('failed to terminate');
      // ignore: unawaited_futures
      showErrorDialog(
        context,
        context.strings.oops,
        context.strings.somethingWentWrongPleaseTryAgain,
      );
    }
  }

  Future<void> _fetchActiveSessions() async {
    _sessions = await UserService.instance.getActiveSessions().onError((e, s) {
      _logger.severe("failed to fetch active sessions", e, s);
      throw e!;
    });
    if (_sessions != null) {
      _sessions!.sessions.sort((first, second) {
        return second.lastUsedTime.compareTo(first.lastUsedTime);
      });
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _showSessionTerminationDialog(Session session) {
    final isLoggingOutFromThisDevice =
        session.token == widget.config.getToken();
    Widget text;
    if (isLoggingOutFromThisDevice) {
      text = Text(
        context.strings.thisWillLogYouOutOfThisDevice,
      );
    } else {
      text = SingleChildScrollView(
        child: Column(
          children: [
            Text(
              context.strings.thisWillLogYouOutOfTheFollowingDevice,
            ),
            const Padding(padding: EdgeInsets.all(8)),
            Text(
              session.ua,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }
    final AlertDialog alert = AlertDialog(
      title: Text(context.strings.terminateSession),
      content: text,
      actions: [
        TextButton(
          child: Text(
            context.strings.terminate,
            style: const TextStyle(
              color: Colors.red,
            ),
          ),
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop('dialog');
            if (isLoggingOutFromThisDevice) {
              await UserService.instance.logout(context);
            } else {
              await _terminateSession(session);
            }
          },
        ),
        TextButton(
          child: Text(
            context.strings.cancel,
            style: TextStyle(
              color: isLoggingOutFromThisDevice
                  ? getEnteColorScheme(context).alternativeColor
                  : getEnteColorScheme(context).textBase,
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
    if (session.token == widget.config.getToken()) {
      return Text(
        context.strings.thisDevice,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: getEnteColorScheme(context).alternativeColor,
        ),
      );
    }
    return Text(session.prettyUA);
  }
}
