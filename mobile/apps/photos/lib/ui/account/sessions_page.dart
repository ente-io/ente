import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/ente_theme_data.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/api/user/sessions.dart';
import 'package:photos/services/account/user_service.dart';
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/notification/toast.dart';
import 'package:photos/utils/dialog_util.dart';
import "package:photos/utils/standalone/date_time.dart";

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
      showToast(
        context,
        AppLocalizations.of(context).failedToFetchActiveSessions,
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(AppLocalizations.of(context).activeSessions),
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
                        getFormattedTime(context, lastUsedTime),
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
        Divider(
          color: getEnteColorScheme(context).strokeFaint,
        ),
      ],
    );
  }

  Future<void> _terminateSession(Session session) async {
    final dialog =
        createProgressDialog(context, AppLocalizations.of(context).pleaseWait);
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
        AppLocalizations.of(context).oops,
        AppLocalizations.of(context).somethingWentWrongPleaseTryAgain,
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
        AppLocalizations.of(context).thisWillLogYouOutOfThisDevice,
      );
    } else {
      text = SingleChildScrollView(
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)
                  .thisWillLogYouOutOfTheFollowingDevice,
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
      title: Text(AppLocalizations.of(context).terminateSession),
      content: text,
      actions: [
        TextButton(
          child: Text(
            AppLocalizations.of(context).terminate,
            style: const TextStyle(
              color: Colors.red,
            ),
          ),
          onPressed: () async {
            Navigator.of(context).pop('dialog');
            if (isLoggingOutFromThisDevice) {
              await UserService.instance.logout(context);
            } else {
              await _terminateSession(session);
            }
          },
        ),
        TextButton(
          child: Text(
            AppLocalizations.of(context).cancel,
            style: TextStyle(
              color: isLoggingOutFromThisDevice
                  ? Theme.of(context).colorScheme.greenAlternative
                  : Theme.of(context).colorScheme.defaultTextColor,
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop('dialog');
          },
        ),
      ],
    );

    showDialog(
      useRootNavigator: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Widget _getUAWidget(Session session) {
    if (session.token == Configuration.instance.getToken()) {
      return Text(
        AppLocalizations.of(context).thisDevice,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.greenAlternative,
        ),
      );
    }
    return Text(session.prettyUA);
  }
}
