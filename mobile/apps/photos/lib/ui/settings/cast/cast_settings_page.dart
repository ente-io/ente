import "package:collection/collection.dart";
import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/core/network/network.dart";
import "package:photos/gateways/cast/cast_gateway.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/ui/settings/components/settings_item.dart";
import "package:photos/ui/settings/components/settings_page_scaffold.dart";
import "package:photos/utils/dialog_util.dart";
import 'package:timeago/timeago.dart' as timeago;

class CastSettingsPage extends StatefulWidget {
  const CastSettingsPage({super.key});

  @override
  State<CastSettingsPage> createState() => _CastSettingsPageState();
}

class _CastSettingsPageState extends State<CastSettingsPage> {
  Future<List<CastInfo>>? _castSessionsFuture;

  @override
  void initState() {
    super.initState();
    _castSessionsFuture = _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gw = CastGateway(NetworkClient.instance.enteDio);

    return SettingsPageScaffold(
      title: l10n.cast,
      children: [
        FutureBuilder(
          future: _castSessionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              throw snapshot.error!;
            }

            if (!snapshot.hasData || snapshot.data == null) {
              throw Exception(
                "There is no data returned by getAllCastSessions",
              );
            }

            return Column(
              children: snapshot.data!
                  .map((session) {
                    final collection = CollectionsService.instance
                        .getCollectionByID(session.collectionID);
                    final title =
                        collection?.displayName ??
                        session.collectionID.toString();
                    return [
                      SettingsItem(
                        title: "$title on ${session.deviceIP}",
                        subtitle: timeago.format(session.lastUsedAt),
                        icon: HugeIcons.strokeRoundedTv01,
                        trailing: IconButtonComponent(
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedCancel01,
                            color: context.componentColors.warning,
                            size: IconSizes.small,
                            strokeWidth: 1.6,
                          ),
                          onTap: () async {
                            await _revokeSession(gw, session);
                          },
                          shouldShowSuccessConfirmation: false,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ];
                  })
                  .flattened
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _revokeSession(CastGateway gw, CastInfo session) async {
    final l10n = AppLocalizations.of(context);
    final result = await showChoiceDialog(
      context,
      title: l10n.stopCastingTitle,
      body: l10n.stopCastingBody,
      firstButtonLabel: l10n.yes,
      secondButtonLabel: l10n.no,
    );
    if (result?.action != .first) {
      return;
    }
    await gw.revokeSession(session);
    await _refresh();
  }

  Future<List<CastInfo>> _load() {
    final gw = CastGateway(NetworkClient.instance.enteDio);
    return gw.getAllCastSessions();
  }

  Future<void> _refresh() async {
    setState(() {
      _castSessionsFuture = _load();
    });
  }
}
