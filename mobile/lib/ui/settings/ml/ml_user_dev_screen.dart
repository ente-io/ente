import "package:flutter/material.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/ml/clip_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/services/machine_learning/semantic_search/semantic_search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/toast_util.dart";

class MLUserDeveloperOptions extends StatelessWidget {
  const MLUserDeveloperOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          const TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: "ML debug options",
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (delegateBuildContext, index) => Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Column(
                  children: [
                    Text(
                      "Only use if you know what you're doing",
                      textAlign: TextAlign.left,
                      style: getEnteTextTheme(context).body.copyWith(
                            color: getEnteColorScheme(context).textMuted,
                          ),
                    ),
                    const SizedBox(height: 48),
                    ButtonWidget(
                      buttonType: ButtonType.neutral,
                      labelText: "Purge empty indices",
                      onTap: () async {
                        await deleteEmptyIndices(context);
                      },
                    ),
                    const SizedBox(height: 24),
                    ButtonWidget(
                      buttonType: ButtonType.neutral,
                      labelText: "Reset all local ML",
                      onTap: () async {
                        await deleteAllLocalML(context);
                      },
                    ),
                    const SafeArea(
                      child: SizedBox(
                        height: 12,
                      ),
                    ),
                  ],
                ),
              ),
              childCount: 1,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> deleteEmptyIndices(BuildContext context) async {
    try {
      final Set<int> emptyFileIDs = await MLDataDB.instance.getErroredFileIDs();
      await MLDataDB.instance.deleteFaceIndexForFiles(emptyFileIDs.toList());
      await MLDataDB.instance.deleteEmbeddings(emptyFileIDs.toList());
      showShortToast(context, "Deleted ${emptyFileIDs.length} entries");
    } catch (e) {
      // ignore: unawaited_futures
      showGenericErrorDialog(
        context: context,
        error: e,
      );
    }
  }

  Future<void> deleteAllLocalML(BuildContext context) async {
    try {
      await MLDataDB.instance.dropClustersAndPersonTable(faces: true);
      await SemanticSearchService.instance.clearIndexes();
      Bus.instance.fire(PeopleChangedEvent());
      showShortToast(context, "All local ML cleared");
    } catch (e) {
      // ignore: unawaited_futures
      showGenericErrorDialog(
        context: context,
        error: e,
      );
    }
  }
}
