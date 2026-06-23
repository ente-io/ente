import "package:ente_components/ente_components.dart";
import "package:flutter/widgets.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";
import "package:photos/ui/common/loading_widget.dart";

Future<void> _pairWithAuto() async {}

Future<void> showPairWithAutoSheet(BuildContext context) async {}

class PairWithAutoSheet extends StatefulWidget {
  const PairWithAutoSheet({super.key});

  @override
  State<PairWithAutoSheet> createState() => _PairWithAutoSheetState();
}

class _PairWithAutoSheetState extends State<PairWithAutoSheet> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BottomSheetComponent(
      title: l10n.connectToDevice,
      content: Text(
        l10n.autoCastDialogBody + "\n" + l10n.autoCastiOSPermission,
      ),
      actions: [
        FutureBuilder(
          future: castService.searchDevices(),
          builder: (_, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error.toString()}'));
            }
            if (!snapshot.hasData) {
              return const EnteLoadingWidget();
            }
            if (snapshot.data!.isEmpty) {
              return Center(child: Text(l10n.noDeviceFound));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: snapshot.data!.map((result) {
                final device = result.$2;
                final name = result.$1;
                return ButtonComponent(label: name, onTap: () async {});
              }),
            );
          },
        ),
        ButtonComponent(
          label: l10n.pair,
          variant: ButtonComponentVariant.primary,
          onTap: () async {
            await _pairWithAuto();
          },
        ),
      ],
    );
  }
}
