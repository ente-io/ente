import "package:logging/logging.dart";
import "package:photos/db/ml_data_db.dart";
import "package:photos/services/face_ml/face_detection/detection.dart";
import "package:photos/services/face_ml/face_feedback.dart/cluster_feedback.dart";
import "package:photos/services/face_ml/face_ml_result.dart";

class FaceFeedbackService {
  final _logger = Logger("FaceFeedbackService");

  final _mlDatabase = MlDataDB.instance;

  int executedFeedbackCount = 0;
  final int _reclusterFeedbackThreshold = 10;

  // singleton pattern
  FaceFeedbackService._privateConstructor();
  static final instance = FaceFeedbackService._privateConstructor();
  factory FaceFeedbackService() => instance;

  /// Returns the updated cluster after removing the given file from the given person's cluster.
  ///
  /// If the file is not in the cluster, returns null.
  ///
  /// The updated cluster is also updated in [MlDataDB].
  Future<ClusterResult> removePhotosFromCluster(
    List<int> fileIDs,
    int personID,
  ) async {
    // TODO: check if photo was originally added to cluster by user. If so, we should remove that addition instead of changing the embedding, because there is no embedding...
    _logger.info(
      'removePhotoFromCluster called with fileIDs $fileIDs and personID $personID',
    );

    if (fileIDs.isEmpty) {
      _logger.severe(
        "No fileIDs given, unable to add photos to cluster!",
      );
      throw ArgumentError(
        "No fileIDs given, unable to add photos to cluster!",
      );
    }

    // Get the relevant cluster
    final ClusterResult? cluster = await _mlDatabase.getClusterResult(personID);
    if (cluster == null) {
      _logger.severe(
        "No cluster found for personID $personID, unable to remove photo from non-existent cluster!",
      );
      throw ArgumentError(
        "No cluster found for personID $personID, unable to remove photo from non-existent cluster!",
      );
    }
    // Get the relevant faceMlResults
    final List<FaceMlResult> faceMlResults =
        await _mlDatabase.getSelectedFaceMlResults(fileIDs);
    if (faceMlResults.length != fileIDs.length) {
      final List<int> foundFileIDs =
          faceMlResults.map((faceMlResult) => faceMlResult.fileId).toList();
      _logger.severe(
        "Couldn't find all facemlresults for fileIDs $fileIDs, only found for $foundFileIDs. Unable to remove unindexed photos from cluster!",
      );
      throw ArgumentError(
        "Couldn't find all facemlresults for fileIDs $fileIDs, only found for $foundFileIDs. Unable to remove unindexed photos from cluster!",
      );
    }

    // Check if at least one of the files is in the cluster. If all files are already not in the cluster, return the cluster.
    final List<int> fileIDsInCluster = fileIDs
        .where((fileID) => cluster.uniqueFileIds.contains(fileID))
        .toList();
    if (fileIDsInCluster.isEmpty) {
      _logger.warning(
        "All fileIDs are already not in the cluster, unable to remove photos from cluster!",
      );
      return cluster;
    }
    final List<FaceMlResult> faceMlResultsInCluster = faceMlResults
        .where((faceMlResult) => fileIDsInCluster.contains(faceMlResult.fileId))
        .toList();
    assert(faceMlResultsInCluster.length == fileIDsInCluster.length);

    for (var i = 0; i < fileIDsInCluster.length; i++) {
      // Find the faces/embeddings associated with both the fileID and personID
      final List<String> faceIDs = faceMlResultsInCluster[i].allFaceIds;
      final List<String> faceIDsInCluster = cluster.faceIDs;
      final List<String> relevantFaceIDs =
          faceIDsInCluster.where((faceID) => faceIDs.contains(faceID)).toList();
      if (relevantFaceIDs.isEmpty) {
        _logger.severe(
          "No faces found in both cluster and file, unable to remove photo from cluster!",
        );
        throw ArgumentError(
          "No faces found in both cluster and file, unable to remove photo from cluster!",
        );
      }

      // Set the embeddings to [10, 10,..., 10] and save the updated faceMlResult
      faceMlResultsInCluster[i].setEmbeddingsToTen(relevantFaceIDs);
      await _mlDatabase.updateFaceMlResult(faceMlResultsInCluster[i]);

      // Make sure there is a manual override for [10, 10,..., 10] embeddings (not actually here, but in building the clusters, see _checkIfClusterIsDeleted function)

      // Manually remove the fileID from the cluster
      cluster.removeFileId(fileIDsInCluster[i]);
    }

    // TODO: see below
    // Re-cluster and check if this leads to more deletions. If so, save them and ask the user if they want to delete them too.
    executedFeedbackCount++;
    if (executedFeedbackCount % _reclusterFeedbackThreshold == 0) {
      // await recluster();
    }

    // Update the cluster in the database
    await _mlDatabase.updateClusterResult(cluster);

    // TODO: see below
    // Safe the given feedback to the database
    final removePhotoFeedback = RemovePhotosClusterFeedback(
      medoid: cluster.medoid,
      medoidDistanceThreshold: cluster.medoidDistanceThreshold,
      removedPhotosFileID: fileIDsInCluster,
    );
    await _mlDatabase.createClusterFeedback(
      removePhotoFeedback,
      skipIfSimilarFeedbackExists: false,
    );

    // Return the updated cluster
    return cluster;
  }

  Future<ClusterResult> addPhotosToCluster(List<int> fileIDs, personID) async {
    _logger.info(
      'addPhotosToCluster called with fileIDs $fileIDs and personID $personID',
    );

    if (fileIDs.isEmpty) {
      _logger.severe(
        "No fileIDs given, unable to add photos to cluster!",
      );
      throw ArgumentError(
        "No fileIDs given, unable to add photos to cluster!",
      );
    }

    // Get the relevant cluster
    final ClusterResult? cluster = await _mlDatabase.getClusterResult(personID);
    if (cluster == null) {
      _logger.severe(
        "No cluster found for personID $personID, unable to add photos to non-existent cluster!",
      );
      throw ArgumentError(
        "No cluster found for personID $personID, unable to add photos to non-existent cluster!",
      );
    }

    // Check if at least one of the files is not in the cluster. If all files are already in the cluster, return the cluster.
    final List<int> fileIDsNotInCluster = fileIDs
        .where((fileID) => !cluster.uniqueFileIds.contains(fileID))
        .toList();
    if (fileIDsNotInCluster.isEmpty) {
      _logger.warning(
        "All fileIDs are already in the cluster, unable to add new photos to cluster!",
      );
      return cluster;
    }
    final List<String> faceIDsNotInCluster = fileIDsNotInCluster
        .map((fileID) => FaceDetectionRelative.toFaceIDEmpty(fileID: fileID))
        .toList();

    // Add the new files to the cluster
    cluster.addFileIDsAndFaceIDs(fileIDsNotInCluster, faceIDsNotInCluster);

    // Update the cluster in the database
    await _mlDatabase.updateClusterResult(cluster);

    // Build the addPhotoFeedback
    final AddPhotosClusterFeedback addPhotosFeedback = AddPhotosClusterFeedback(
      medoid: cluster.medoid,
      medoidDistanceThreshold: cluster.medoidDistanceThreshold,
      addedPhotoFileIDs: fileIDsNotInCluster,
    );

    // TODO: check for exact match and update feedback if necessary

    // Save the addPhotoFeedback to the database
    await _mlDatabase.createClusterFeedback(
      addPhotosFeedback,
      skipIfSimilarFeedbackExists: false,
    );

    // Return the updated cluster
    return cluster;
  }

  /// Deletes the given cluster completely.
  Future<void> deleteCluster(int personID) async {
    _logger.info(
      'deleteCluster called with personID $personID',
    );

    // Get the relevant cluster
    final cluster = await _mlDatabase.getClusterResult(personID);
    if (cluster == null) {
      _logger.severe(
        "No cluster found for personID $personID, unable to delete non-existent cluster!",
      );
      throw ArgumentError(
        "No cluster found for personID $personID, unable to delete non-existent cluster!",
      );
    }

    // Delete the cluster from the database
    await _mlDatabase.deleteClusterResult(cluster.personId);

    // TODO: look into the right threshold distance.
    // Build the deleteClusterFeedback
    final DeleteClusterFeedback deleteClusterFeedback = DeleteClusterFeedback(
      medoid: cluster.medoid,
      medoidDistanceThreshold: cluster.medoidDistanceThreshold,
    );

    // TODO: maybe I should merge the two feedbacks if they are similar enough? Or alternatively, I keep them both?
    // Check if feedback doesn't already exist
    if (await _mlDatabase
        .doesSimilarClusterFeedbackExist(deleteClusterFeedback)) {
      _logger.warning(
        "Feedback already exists for deleting cluster $personID, unable to delete cluster!",
      );
      return;
    }

    // Save the deleteClusterFeedback to the database
    await _mlDatabase.createClusterFeedback(deleteClusterFeedback);
  }

  /// Renames the given cluster and/or sets the thumbnail of the given cluster.
  ///
  /// Requires either a [customName] or a [customFaceID]. If both are given, both are used. If neither are given, an error is thrown.
  Future<ClusterResult> renameOrSetThumbnailCluster(
    int personID, {
    String? customName,
    String? customFaceID,
  }) async {
    _logger.info(
      'renameOrSetThumbnailCluster called with personID $personID, customName $customName, and customFaceID $customFaceID',
    );

    if (customFaceID != null &&
        FaceDetectionRelative.isFaceIDEmpty(customFaceID)) {
      _logger.severe(
        "customFaceID $customFaceID is belongs to empty detection, unable to set as thumbnail of cluster!",
      );
      customFaceID = null;
    }
    if (customName == null && customFaceID == null) {
      _logger.severe(
        "No name or faceID given, unable to rename or set thumbnail of cluster!",
      );
      throw ArgumentError(
        "No name or faceID given, unable to rename or set thumbnail of cluster!",
      );
    }

    // Get the relevant cluster
    final cluster = await _mlDatabase.getClusterResult(personID);
    if (cluster == null) {
      _logger.severe(
        "No cluster found for personID $personID, unable to delete non-existent cluster!",
      );
      throw ArgumentError(
        "No cluster found for personID $personID, unable to delete non-existent cluster!",
      );
    }

    // Update the cluster
    if (customName != null) cluster.setUserDefinedName = customName;
    if (customFaceID != null) cluster.setThumbnailFaceId = customFaceID;

    // Update the cluster in the database
    await _mlDatabase.updateClusterResult(cluster);

    // Build the RenameOrCustomThumbnailClusterFeedback
    final RenameOrCustomThumbnailClusterFeedback renameClusterFeedback =
        RenameOrCustomThumbnailClusterFeedback(
      medoid: cluster.medoid,
      medoidDistanceThreshold: cluster.medoidDistanceThreshold,
      customName: customName,
      customThumbnailFaceId: customFaceID,
    );

    // TODO: maybe I should merge the two feedbacks if they are similar enough?
    // Check if feedback doesn't already exist
    final matchingFeedbacks =
        await _mlDatabase.getAllMatchingClusterFeedback(renameClusterFeedback);
    for (final matchingFeedback in matchingFeedbacks) {
      // Update the current feedback wherever possible
      renameClusterFeedback.customName ??= matchingFeedback.customName;
      renameClusterFeedback.customThumbnailFaceId ??=
          matchingFeedback.customThumbnailFaceId;

      // Delete the old feedback (since we want the user to be able to overwrite their earlier feedback)
      await _mlDatabase.deleteClusterFeedback(matchingFeedback);
    }

    // Save the RenameOrCustomThumbnailClusterFeedback to the database
    await _mlDatabase.createClusterFeedback(renameClusterFeedback);

    // Return the updated cluster
    return cluster;
  }

  /// Merges the given clusters. The largest cluster is kept and the other clusters are deleted.
  ///
  /// Requires either a [clusters] or [personIDs]. If both are given, the [clusters] are used.
  Future<ClusterResult> mergeClusters(List<int> personIDs) async {
    _logger.info(
      'mergeClusters called with personIDs $personIDs',
    );

    // Get the relevant clusters
    final List<ClusterResult> clusters =
        await _mlDatabase.getSelectedClusterResults(personIDs);
    if (clusters.length <= 1) {
      _logger.severe(
        "${clusters.length} clusters found for personIDs $personIDs, unable to merge non-existent clusters!",
      );
      throw ArgumentError(
        "${clusters.length} clusters found for personIDs $personIDs, unable to merge non-existent clusters!",
      );
    }

    // Find the largest cluster
    clusters.sort((a, b) => b.clusterSize.compareTo(a.clusterSize));
    final ClusterResult largestCluster = clusters.first;

    // Now iterate through the clusters to be merged and deleted
    for (var i = 1; i < clusters.length; i++) {
      final ClusterResult clusterToBeMerged = clusters[i];

      // Add the files and faces of the cluster to be merged to the largest cluster
      largestCluster.addFileIDsAndFaceIDs(
        clusterToBeMerged.fileIDsIncludingPotentialDuplicates,
        clusterToBeMerged.faceIDs,
      );

      // TODO: maybe I should wrap the logic below in a separate function, since it's also used in renameOrSetThumbnailCluster
      // Merge any names and thumbnails if the largest cluster doesn't have them
      bool shouldCreateNamingFeedback = false;
      String? nameToBeMerged;
      String? thumbnailToBeMerged;
      if (!largestCluster.hasUserDefinedName &&
          clusterToBeMerged.hasUserDefinedName) {
        largestCluster.setUserDefinedName = clusterToBeMerged.userDefinedName!;
        nameToBeMerged = clusterToBeMerged.userDefinedName!;
        shouldCreateNamingFeedback = true;
      }
      if (!largestCluster.thumbnailFaceIdIsUserDefined &&
          clusterToBeMerged.thumbnailFaceIdIsUserDefined) {
        largestCluster.setThumbnailFaceId = clusterToBeMerged.thumbnailFaceId;
        thumbnailToBeMerged = clusterToBeMerged.thumbnailFaceId;
        shouldCreateNamingFeedback = true;
      }
      if (shouldCreateNamingFeedback) {
        final RenameOrCustomThumbnailClusterFeedback renameClusterFeedback =
            RenameOrCustomThumbnailClusterFeedback(
          medoid: largestCluster.medoid,
          medoidDistanceThreshold: largestCluster.medoidDistanceThreshold,
          customName: nameToBeMerged,
          customThumbnailFaceId: thumbnailToBeMerged,
        );
        // Check if feedback doesn't already exist
        final matchingFeedbacks = await _mlDatabase
            .getAllMatchingClusterFeedback(renameClusterFeedback);
        for (final matchingFeedback in matchingFeedbacks) {
          // Update the current feedback wherever possible
          renameClusterFeedback.customName ??= matchingFeedback.customName;
          renameClusterFeedback.customThumbnailFaceId ??=
              matchingFeedback.customThumbnailFaceId;

          // Delete the old feedback (since we want the user to be able to overwrite their earlier feedback)
          await _mlDatabase.deleteClusterFeedback(matchingFeedback);
        }

        // Save the RenameOrCustomThumbnailClusterFeedback to the database
        await _mlDatabase.createClusterFeedback(renameClusterFeedback);
      }

      // Build the mergeClusterFeedback
      final MergeClusterFeedback mergeClusterFeedback = MergeClusterFeedback(
        medoid: clusterToBeMerged.medoid,
        medoidDistanceThreshold: clusterToBeMerged.medoidDistanceThreshold,
        medoidToMoveTo: largestCluster.medoid,
      );

      // Save the mergeClusterFeedback to the database and delete any old matching feedbacks
      final matchingFeedbacks =
          await _mlDatabase.getAllMatchingClusterFeedback(mergeClusterFeedback);
      for (final matchingFeedback in matchingFeedbacks) {
        await _mlDatabase.deleteClusterFeedback(matchingFeedback);
      }
      await _mlDatabase.createClusterFeedback(mergeClusterFeedback);

      // Delete the cluster from the database
      await _mlDatabase.deleteClusterResult(clusterToBeMerged.personId);
    }

    // TODO: should I update the medoid of this new cluster? My intuition says no, but I'm not sure.
    // Update the largest cluster in the database
    await _mlDatabase.updateClusterResult(largestCluster);

    // Return the merged cluster
    return largestCluster;
  }
}
