import 'dart:async';

import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import "package:photos/db/files_db.dart";
import 'package:photos/db/ml/base.dart';
import "package:photos/db/ml/db.dart";
import "package:photos/events/people_changed_event.dart";
import 'package:photos/events/subscription_purchased_event.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import 'package:photos/models/gallery_type.dart';
import "package:photos/models/ml/face/person.dart";
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import "package:photos/services/machine_learning/face_ml/feedback/cluster_feedback.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import "package:photos/ui/common/popup_item.dart";
import "package:photos/ui/viewer/people/cluster_breakup_page.dart";
import "package:photos/ui/viewer/people/cluster_page.dart";
import "package:photos/utils/dialog_util.dart";

class ClusterAppBar extends StatefulWidget {
  final GalleryType type;
  final String? title;
  final SelectedFiles selectedFiles;
  final String clusterID;
  final PersonEntity? person;

  const ClusterAppBar(
    this.type,
    this.title,
    this.selectedFiles,
    this.clusterID, {
    this.person,
    super.key,
  });

  @override
  State<ClusterAppBar> createState() => _AppBarWidgetState();
}

enum ClusterPopupAction {
  setCover,
  breakupCluster,
  breakupClusterDebug,
  ignore,
}

class _AppBarWidgetState extends State<ClusterAppBar> {
  final _logger = Logger("_AppBarWidgetState");
  late StreamSubscription _userAuthEventSubscription;
  late Function() _selectedFilesListener;
  String? _appBarTitle;
  late CollectionActions collectionActions;
  final GlobalKey shareButtonKey = GlobalKey();
  bool isQuickLink = false;
  late GalleryType galleryType;
  late final IMLDataDB mlDataDB = MLDataDB.instance;

  @override
  void initState() {
    super.initState();
    _selectedFilesListener = () {
      setState(() {});
    };
    collectionActions = CollectionActions(CollectionsService.instance);
    widget.selectedFiles.addListener(_selectedFilesListener);
    _userAuthEventSubscription =
        Bus.instance.on<SubscriptionPurchasedEvent>().listen((event) {
      setState(() {});
    });
    _appBarTitle = widget.title;
    galleryType = widget.type;
  }

  @override
  void dispose() {
    _userAuthEventSubscription.cancel();
    widget.selectedFiles.removeListener(_selectedFilesListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: false,
      title: Text(
        _appBarTitle!,
        style:
            Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 16),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      actions: _getDefaultActions(context),
      scrolledUnderElevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
    );
  }

  List<Widget> _getDefaultActions(BuildContext context) {
    final List<Widget> actions = <Widget>[];
    // If the user has selected files, don't show any actions
    if (widget.selectedFiles.files.isNotEmpty ||
        !Configuration.instance.hasConfiguredAccount()) {
      return actions;
    }

    final List<EntePopupMenuItem<ClusterPopupAction>> items = [];

    items.addAll(
      [
        EntePopupMenuItem(
          AppLocalizations.of(context).ignorePerson,
          value: ClusterPopupAction.ignore,
          icon: Icons.hide_image_outlined,
        ),
        EntePopupMenuItem(
          AppLocalizations.of(context).mixedGrouping,
          value: ClusterPopupAction.breakupCluster,
          icon: Icons.analytics_outlined,
        ),
      ],
    );
    if (kDebugMode) {
      items.add(
        EntePopupMenuItem(
          "Debug mixed grouping",
          value: ClusterPopupAction.breakupClusterDebug,
          icon: Icons.analytics_outlined,
        ),
      );
    }

    if (items.isNotEmpty) {
      actions.add(
        PopupMenuButton(
          itemBuilder: (context) {
            return items;
          },
          onSelected: (ClusterPopupAction value) async {
            if (value == ClusterPopupAction.breakupCluster) {
              // ignore: unawaited_futures
              await _breakUpCluster(context);
            } else if (value == ClusterPopupAction.ignore) {
              await _onIgnoredClusterClicked(context);
            } else if (value == ClusterPopupAction.breakupClusterDebug) {
              await _breakUpClusterDebug(context);
            }
            // else if (value == ClusterPopupAction.setCover) {
            //   await setCoverPhoto(context);
          },
        ),
      );
    }

    return actions;
  }

  Future<void> _onIgnoredClusterClicked(BuildContext context) async {
    await showChoiceDialog(
      context,
      title: AppLocalizations.of(context).areYouSureYouWantToIgnoreThisPerson,
      body: AppLocalizations.of(context).thePersonGroupsWillNotBeDisplayed,
      firstButtonLabel: AppLocalizations.of(context).confirm,
      firstButtonOnTap: () async {
        try {
          await ClusterFeedbackService.instance.ignoreCluster(widget.clusterID);
          Navigator.of(context).pop(); // Close the cluster page
        } catch (e, s) {
          _logger.severe('Ignoring a cluster failed', e, s);
          // await showGenericErrorDialog(context: context, error: e);
        }
      },
    );
  }

  Future<void> _breakUpCluster(BuildContext context) async {
    bool userConfirmed = false;
    List<EnteFile> biggestClusterFiles = [];
    String biggestClusterID = '';
    await showChoiceDialog(
      context,
      title: AppLocalizations.of(context).doesGroupContainMultiplePeople,
      body: AppLocalizations.of(context).automaticallyAnalyzeAndSplitGrouping,
      firstButtonLabel: AppLocalizations.of(context).confirm,
      firstButtonOnTap: () async {
        try {
          final breakupResult = await ClusterFeedbackService.instance
              .breakUpCluster(widget.clusterID);
          final Map<String, List<String>> newClusterIDToFaceIDs =
              breakupResult.newClusterIdToFaceIds;
          final Map<String, String> newFaceIdToClusterID =
              breakupResult.newFaceIdToCluster;

          // Update to delete the old clusters and save the new clusters
          await mlDataDB.deleteClusterSummary(widget.clusterID);
          await MLDataDB.instance
              .clusterSummaryUpdate(breakupResult.newClusterSummaries);
          await mlDataDB.updateFaceIdToClusterId(newFaceIdToClusterID);

          // Find the biggest cluster
          biggestClusterID = '';
          int biggestClusterSize = 0;
          for (final MapEntry<String, List<String>> clusterToFaces
              in newClusterIDToFaceIDs.entries) {
            if (clusterToFaces.value.length > biggestClusterSize) {
              biggestClusterSize = clusterToFaces.value.length;
              biggestClusterID = clusterToFaces.key;
            }
          }
          // Get the files for the biggest new cluster
          final biggestClusterFileIDs = newClusterIDToFaceIDs[biggestClusterID]!
              .map((e) => getFileIdFromFaceId<int>(e))
              .toList();
          biggestClusterFiles = await FilesDB.instance
              .getFileIDToFileFromIDs(
                biggestClusterFileIDs,
              )
              .then((mapping) => mapping.values.toList());
          // Sort the files to prevent issues with the order of the files in gallery
          biggestClusterFiles
              .sort((a, b) => b.creationTime!.compareTo(a.creationTime!));

          userConfirmed = true;
        } catch (e, s) {
          _logger.severe('Breakup cluster failed', e, s);
          // await showGenericErrorDialog(context: context, error: e);
        }
      },
    );
    if (userConfirmed) {
      // Close the old cluster page
      Navigator.of(context).pop();

      // Push the new cluster page
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ClusterPage(
            biggestClusterFiles,
            clusterID: biggestClusterID,
          ),
        ),
      );
      Bus.instance.fire(PeopleChangedEvent());
    }
  }

  Future<void> _breakUpClusterDebug(BuildContext context) async {
    final breakupResult =
        await ClusterFeedbackService.instance.breakUpCluster(widget.clusterID);

    final Map<String, List<String>> newClusterIDToFaceIDs =
        breakupResult.newClusterIdToFaceIds;

    final allFileIDs = newClusterIDToFaceIDs.values
        .expand((e) => e)
        .map((e) => getFileIdFromFaceId<int>(e))
        .toList();

    final fileIDtoFile = await FilesDB.instance.getFileIDToFileFromIDs(
      allFileIDs,
    );

    final newClusterIDToFiles = newClusterIDToFaceIDs.map(
      (key, value) => MapEntry(
        key,
        value
            .map((faceId) => fileIDtoFile[getFileIdFromFaceId<int>(faceId)]!)
            .toList(),
      ),
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClusterBreakupPage(
          newClusterIDToFiles,
          AppLocalizations.of(context).analysis,
        ),
      ),
    );
  }
}
