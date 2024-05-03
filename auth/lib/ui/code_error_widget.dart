import 'package:ente_auth/ente_theme_data.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/services/update_service.dart';
import 'package:ente_auth/ui/common/gradient_button.dart';
import 'package:ente_auth/ui/linear_progress_widget.dart';
import 'package:ente_auth/ui/settings/app_update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CodeErrorWidget extends StatelessWidget {
  const CodeErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.codeCardBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 8,
        top: 8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 3,
              child: LinearProgressWidget(
                color: Color(0xFFF53434),
                fractionOfStorage: 1,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const SizedBox(width: 8),
                const Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.info,
                    size: 18,
                    color: Color(0xFFF53434),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.error,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF53434),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                context.l10n.somethingWentWrongUpdateApp,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 76,
                  height: 28,
                  child: GradientButton(
                    text: context.l10n.update,
                    fontSize: 10,
                    onTap: () async {
                      try {
                        await UpdateService.instance.shouldUpdate();
                        assert(
                          UpdateService.instance.getLatestVersionInfo() != null,
                        );
                        await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AppUpdateDialog(
                              UpdateService.instance.getLatestVersionInfo(),
                            );
                          },
                          barrierColor: Colors.black.withOpacity(0.85),
                        );
                      } catch (e) {
                        await Fluttertoast.showToast(
                          msg: context.l10n.updateNotAvailable,
                        );
                      }
                    },
                    borderWidth: 0.6,
                    borderRadius: 6,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
