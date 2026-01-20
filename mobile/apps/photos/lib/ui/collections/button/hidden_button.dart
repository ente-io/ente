import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/services/local_authentication_service.dart';
import 'package:photos/ui/viewer/gallery/hidden_page.dart';
import 'package:photos/utils/navigation_util.dart';

class HiddenCollectionsButtonWidget extends StatelessWidget {
  final TextStyle textStyle;

  const HiddenCollectionsButtonWidget(
    this.textStyle, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(0),
        side: BorderSide(
          width: 0.5,
          color: Theme.of(context).iconTheme.color!.withValues(alpha: 0.24),
        ),
      ),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.visibility_off,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  const Padding(padding: EdgeInsets.all(6)),
                  RichText(
                    text: TextSpan(
                      style: textStyle,
                      children: [
                        TextSpan(
                          text: AppLocalizations.of(context).hidden,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const TextSpan(text: "  \u2022  "),
                        WidgetSpan(
                          child: Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: Theme.of(context).iconTheme.color,
                          ),
                        ),
                        //need to query in db and bring this value
                      ],
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).iconTheme.color,
              ),
            ],
          ),
        ),
      ),
      onPressed: () async {
        final hasAuthenticated = await LocalAuthenticationService.instance
            .requestLocalAuthentication(
          context,
          AppLocalizations.of(context).authToViewYourHiddenFiles,
        );
        if (hasAuthenticated) {
          // ignore: unawaited_futures
          routeToPage(
            context,
            const HiddenPage(),
          );
        }
      },
    );
  }
}
