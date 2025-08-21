import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/empty_state_item_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/settings/backup/backup_folder_selection_page.dart";
import "package:photos/utils/navigation_util.dart";

class SearchTabEmptyState extends StatelessWidget {
  const SearchTabEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = getEnteTextTheme(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).searchHint1,
              style: textStyle.h3Bold,
            ),
            const SizedBox(height: 24),
            EmptyStateItemWidget(AppLocalizations.of(context).searchHint2),
            const SizedBox(height: 12),
            EmptyStateItemWidget(AppLocalizations.of(context).searchHint3),
            const SizedBox(height: 12),
            EmptyStateItemWidget(AppLocalizations.of(context).searchHint4),
            const SizedBox(height: 12),
            EmptyStateItemWidget(AppLocalizations.of(context).searchHint5),
            const SizedBox(height: 32),
            ButtonWidget(
              buttonType: ButtonType.trailingIconPrimary,
              labelText: AppLocalizations.of(context).addYourPhotosNow,
              icon: Icons.arrow_forward_outlined,
              onTap: () async {
                // ignore: unawaited_futures
                routeToPage(
                  context,
                  const BackupFolderSelectionPage(
                    isFirstBackup: false,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
