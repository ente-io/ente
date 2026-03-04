import 'package:flutter/material.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/ui/common/backup_flow_helper.dart';
import 'package:photos/ui/common/gradient_button.dart';

class StartBackupHookWidget extends StatelessWidget {
  final Widget headerWidget;

  const StartBackupHookWidget({super.key, required this.headerWidget});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                headerWidget,
                Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: Image.asset(
                    "assets/onboarding_safe.png",
                    height: 206,
                  ),
                ),
                Text(
                  AppLocalizations.of(context).noPhotosAreBeingBackedUpRightNow,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontFamily: 'Inter-Medium', fontSize: 16),
                ),
                Center(
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      width: double.infinity,
                      height: 64,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: GradientButton(
                        onTap: () async {
                          await handleLimitedOrFolderBackupFlow(
                            context,
                            isFirstBackup: true,
                          );
                        },
                        text: AppLocalizations.of(context).startBackup,
                      ),
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.all(50)),
              ],
            ),
          ),
        );
      },
    );
  }
}
