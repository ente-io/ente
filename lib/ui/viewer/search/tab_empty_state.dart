import "package:flutter/material.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/backup_folder_selection_page.dart";
import "package:photos/ui/components/button_widget.dart";
import "package:photos/ui/components/empty_state_item_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/utils/navigation_util.dart";

class SearchTabEmptyState extends StatelessWidget {
  const SearchTabEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = getEnteTextTheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Fast, on-device search", style: textStyle.h3Bold),
          const SizedBox(height: 24),
          const EmptyStateItemWidget("Photo dates, descriptions"),
          const SizedBox(height: 12),
          const EmptyStateItemWidget("Albums, file names, and types"),
          const SizedBox(height: 12),
          const EmptyStateItemWidget("Location"),
          const SizedBox(height: 12),
          const EmptyStateItemWidget("Coming soon: Photo contents, faces"),
          const SizedBox(height: 32),
          ButtonWidget(
            buttonType: ButtonType.trailingIconPrimary,
            labelText: "Add your photos now",
            icon: Icons.arrow_forward_outlined,
            onTap: () async {
              routeToPage(
                context,
                const BackupFolderSelectionPage(
                  buttonText: "Backup",
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
