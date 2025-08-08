import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/sessions.dart';
import 'package:ente_auth/services/user_service.dart';
import 'package:ente_auth/ui/common/loading_widget.dart';
import 'package:ente_auth/utils/date_time_util.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

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
        title: Text(context.l10n.activeSessions),
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
    final dialog = createProgressDialog(context, context.l10n.pleaseWait);
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
        context.l10n.oops,
        context.l10n.somethingWentWrongPleaseTryAgain,
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
        session.token == Configuration.instance.getToken();
    Widget text;
    if (isLoggingOutFromThisDevice) {
      text = Text(
        context.l10n.thisWillLogYouOutOfThisDevice,
      );
    } else {
      text = SingleChildScrollView(
        child: Column(
          children: [
            Text(
              context.l10n.thisWillLogYouOutOfTheFollowingDevice,
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
      title: Text(context.l10n.terminateSession),
      content: text,
      actions: [
        TextButton(
          child: Text(
            context.l10n.terminate,
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
            context.l10n.cancel,
            style: TextStyle(
              color: isLoggingOutFromThisDevice
                  ? Theme.of(context).colorScheme.alternativeColor
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
        context.l10n.thisDevice,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.alternativeColor,
        ),
      );
    }
    return Text(session.prettyUA);
  }
}
