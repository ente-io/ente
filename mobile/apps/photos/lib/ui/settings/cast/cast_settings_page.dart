import "package:collection/collection.dart";
import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/core/network/network.dart";
import "package:photos/gateways/cast/cast_gateway.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/settings/components/settings_item.dart";
import "package:photos/ui/settings/components/settings_page_scaffold.dart";
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
    final textTheme = getEnteTextTheme(context);

    return SettingsPageScaffold(
      title: l10n.castSessions,
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
            if (snapshot.data!.isEmpty) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.5 - 200,
                  ),
                  Image.asset("assets/empty_casts.png"),
                  const SizedBox(height: 16),
                  Text(l10n.noSessionsFound, style: textTheme.h4Bold),
                ],
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
                        title:
                            "$title on ${session.deviceName ?? session.deviceIP}",
                        subtitle: timeago.format(session.lastUsedAt),
                        icon: HugeIcons.strokeRoundedTvSmart,
                        showOnlyLoadingState: true,
                        trailing: IconButtonComponent(
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedCancel01,
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
    await showBottomSheetComponent<void>(
      context: context,
      builder: (sheetContext) => BottomSheetComponent(
        title: l10n.stopCastingTitle,
        message: l10n.stopCastingBody,
        illustration: Image.asset("assets/warning-grey.png"),
        actions: [
          ButtonComponent(
            label: l10n.stopCastingTitle,
            variant: ButtonComponentVariant.critical,
            onTap: () async {
              Navigator.of(sheetContext).pop();
              await gw.revokeSession(session);
              await _refresh();
            },
          ),
        ],
      ),
    );
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
