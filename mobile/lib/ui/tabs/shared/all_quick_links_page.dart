import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/tabs/shared/quick_link_album_item.dart";

class AllQuickLinksPage extends StatelessWidget {
  final List<Collection> quickLinks;
  final String titleHeroTag;
  const AllQuickLinksPage({
    required this.quickLinks,
    required this.titleHeroTag,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_outlined,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitleBarTitleWidget(
                  title: S.of(context).quickLinks,
                  heroTag: titleHeroTag,
                ),
                Text(quickLinks.length.toString()),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 16,
              ),
              child: ListView.separated(
                itemBuilder: (context, index) {
                  return QuickLinkAlbumItem(c: quickLinks[index]);
                },
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 10);
                },
                itemCount: quickLinks.length,
                physics: const BouncingScrollPhysics(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
