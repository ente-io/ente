import "package:ente_components/ente_components.dart";
import "package:flutter/widgets.dart";
import "package:logging/logging.dart";
import "package:photos/core/network/network.dart";
import "package:photos/gateways/cast/cast_gateway.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/service_locator.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/utils/dialog_util.dart";
import "package:uuid/uuid.dart";

Future<bool> _pairWithCode(
  BuildContext context,
  Collection collection,
  String code,
) async {
  final gw = CastGateway(NetworkClient.instance.enteDio);
  final publicKey = await gw.getPublicKey(code);
  if (publicKey == null) {
    return false;
  }
  final castToken = const Uuid().v4();
  final castData = collectionsService.getCastData(
    castToken,
    collection,
    publicKey,
  );
  await gw.publishCastPayload(code, castData, collection.id, castToken);
  return true;
}

Future<void> showPairWithCodeSheet(
  BuildContext context,
  Collection collection,
) async {
  return await showBottomSheetComponent(
    context: context,
    builder: (_) => _PairWithCodeSheet(collection: collection),
  );
}

class _PairWithCodeSheet extends StatefulWidget {
  final Collection collection;

  const _PairWithCodeSheet({required this.collection});

  @override
  State<_PairWithCodeSheet> createState() => _PairWithCodeSheetState();
}

class _PairWithCodeSheetState extends State<_PairWithCodeSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final logger = Logger("PairWithCodeSheet");
    return BottomSheetComponent(
      title: l10n.castAlbum,
      content: Text(l10n.castInstruction(castUrl: flagService.castUrl)),
      actions: [
        TextInputComponent(
          controller: _controller,
          maxLength: 6,
          autocorrect: false,
          autofocus: true,
          hintText: l10n.pairUsingCode,
          keyboardType: .streetAddress,
        ),
        ButtonComponent(
          label: l10n.pair,
          variant: .primary,
          onTap: () async {
            try {
              if (!await _pairWithCode(
                context,
                widget.collection,
                _controller.text,
              )) {
                showToast(context, l10n.deviceNotFound);
              }
            } catch (e, s) {
              if (e is CastIPMismatchException) {
                await showErrorDialog(
                  context,
                  l10n.castIPMismatchTitle,
                  l10n.castIPMismatchBody,
                );
              } else {
                logger.severe('Failed to pair with code: ', e, s);
                await showGenericErrorDialog(context: context, error: e);
              }
            }
          },
        ),
      ],
    );
  }
}
