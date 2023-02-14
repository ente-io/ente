import "package:flutter/material.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/button_widget.dart";
import "package:photos/ui/components/empty_state_item_widget.dart";
import "package:photos/ui/components/models/button_type.dart";

class NewSharedCollectionsGallery extends StatelessWidget {
  const NewSharedCollectionsGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget();
  }
}

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 114),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Private sharing",
                    style: textTheme.h3Bold,
                    textAlign: TextAlign.start,
                  ),
                  const SizedBox(height: 24),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      EmptyStateItemWidget(
                        "Share only with the people you want",
                      ),
                      SizedBox(height: 12),
                      EmptyStateItemWidget(
                        "Use public links for people not on ente",
                      ),
                      SizedBox(height: 12),
                      EmptyStateItemWidget(
                        "Allow people to add photos",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  ButtonWidget(
                    buttonType: ButtonType.trailingIconPrimary,
                    labelText: "Share an album now",
                    icon: Icons.arrow_forward_outlined,
                  ),
                  SizedBox(height: 6),
                  ButtonWidget(
                    buttonType: ButtonType.trailingIconSecondary,
                    labelText: "Collect event photos",
                    icon: Icons.add_photo_alternate_outlined,
                  ),
                  SizedBox(height: 6),
                  ButtonWidget(
                    buttonType: ButtonType.trailingIconSecondary,
                    labelText: "Invite your friends",
                    icon: Icons.ios_share_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
