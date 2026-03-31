import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/memory_share/memory_share.dart";
import "package:photos/services/memory_share_service.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/sharing/memory_link_details_sheet.dart";
import "package:photos/ui/tabs/shared/memory_link_item.dart";

class AllMemoryLinksPage extends StatefulWidget {
  final List<MemoryShare> memoryShares;
  final String titleHeroTag;

  const AllMemoryLinksPage({
    required this.memoryShares,
    required this.titleHeroTag,
    super.key,
  });

  @override
  State<AllMemoryLinksPage> createState() => _AllMemoryLinksPageState();
}

class _AllMemoryLinksPageState extends State<AllMemoryLinksPage> {
  Future<void> _openMemoryLink(MemoryShare share) async {
    final deleted = await showMemoryLinkDetailsSheet(
      context,
      shareUrl: share.url,
      shareId: share.id,
    );
    if (deleted != true || !mounted) {
      return;
    }

    setState(() {
      widget.memoryShares
          .removeWhere((memoryShare) => memoryShare.id == share.id);
    });

    if (widget.memoryShares.isEmpty && mounted) {
      Navigator.of(context).pop();
    }
  }

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
          child: const Icon(Icons.arrow_back_outlined),
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
                  title: AppLocalizations.of(context).memoryLinks,
                  heroTag: widget.titleHeroTag,
                ),
                Text(widget.memoryShares.length.toString()),
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
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final share = widget.memoryShares[index];
                  final title =
                      MemoryShareService.instance.getMemoryShareTitle(share) ??
                          "Memory link";
                  return GestureDetector(
                    onTap: () async {
                      await _openMemoryLink(share);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: MemoryLinkAlbumItem(
                      title: title,
                      fileCount: share.fileCount,
                      previewUploadedFileID: share.previewUploadedFileID,
                    ),
                  );
                },
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 10);
                },
                itemCount: widget.memoryShares.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
