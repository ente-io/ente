import "dart:async";
import "dart:developer";
import "dart:isolate";
import "dart:math" show max;
import "dart:typed_data";

import "package:logging/logging.dart";
import "package:ml_linalg/dtype.dart";
import "package:ml_linalg/vector.dart";
import "package:photos/generated/protos/ente/common/vector.pb.dart";
import 'package:photos/services/machine_learning/face_ml/face_clustering/cosine_distance.dart';
import "package:photos/services/machine_learning/face_ml/face_ml_result.dart";
import "package:simple_cluster/simple_cluster.dart";
import "package:synchronized/synchronized.dart";

class FaceInfo {
  final String faceID;
  final List<double>? embedding;
  final Vector? vEmbedding;
  int? clusterId;
  String? closestFaceId;
  int? closestDist;
  int? fileCreationTime;
  FaceInfo({
    required this.faceID,
    this.embedding,
    this.vEmbedding,
    this.clusterId,
    this.fileCreationTime,
  });
}

enum ClusterOperation { linearIncrementalClustering, dbscanClustering }

class FaceClusteringService {
  final _logger = Logger("FaceLinearClustering");

  Timer? _inactivityTimer;
  final Duration _inactivityDuration = const Duration(minutes: 3);
  int _activeTasks = 0;

  final _initLock = Lock();

  late Isolate _isolate;
  late ReceivePort _receivePort = ReceivePort();
  late SendPort _mainSendPort;

  bool isSpawned = false;
  bool isRunning = false;

  static const kRecommendedDistanceThreshold = 0.24;

  // singleton pattern
  FaceClusteringService._privateConstructor();

  /// Use this instance to access the FaceClustering service.
  /// e.g. `FaceLinearClustering.instance.predict(dataset)`
  static final instance = FaceClusteringService._privateConstructor();
  factory FaceClusteringService() => instance;

  Future<void> init() async {
    return _initLock.synchronized(() async {
      if (isSpawned) return;

      _receivePort = ReceivePort();

      try {
        _isolate = await Isolate.spawn(
          _isolateMain,
          _receivePort.sendPort,
        );
        _mainSendPort = await _receivePort.first as SendPort;
        isSpawned = true;

        _resetInactivityTimer();
      } catch (e) {
        _logger.severe('Could not spawn isolate', e);
        isSpawned = false;
      }
    });
  }

  Future<void> ensureSpawned() async {
    if (!isSpawned) {
      await init();
    }
  }

  /// The main execution function of the isolate.
  static void _isolateMain(SendPort mainSendPort) async {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      final functionIndex = message[0] as int;
      final function = ClusterOperation.values[functionIndex];
      final args = message[1] as Map<String, dynamic>;
      final sendPort = message[2] as SendPort;

      try {
        switch (function) {
          case ClusterOperation.linearIncrementalClustering:
            final result = FaceClusteringService._runLinearClustering(args);
            sendPort.send(result);
            break;
          case ClusterOperation.dbscanClustering:
            final result = FaceClusteringService._runDbscanClustering(args);
            sendPort.send(result);
            break;
        }
      } catch (e, stackTrace) {
        sendPort
            .send({'error': e.toString(), 'stackTrace': stackTrace.toString()});
      }
    });
  }

  /// The common method to run any operation in the isolate. It sends the [message] to [_isolateMain] and waits for the result.
  Future<dynamic> _runInIsolate(
    (ClusterOperation, Map<String, dynamic>) message,
  ) async {
    await ensureSpawned();
    _resetInactivityTimer();
    final completer = Completer<dynamic>();
    final answerPort = ReceivePort();

    _activeTasks++;
    _mainSendPort.send([message.$1.index, message.$2, answerPort.sendPort]);

    answerPort.listen((receivedMessage) {
      if (receivedMessage is Map && receivedMessage.containsKey('error')) {
        // Handle the error
        final errorMessage = receivedMessage['error'];
        final errorStackTrace = receivedMessage['stackTrace'];
        final exception = Exception(errorMessage);
        final stackTrace = StackTrace.fromString(errorStackTrace);
        _activeTasks--;
        completer.completeError(exception, stackTrace);
      } else {
        _activeTasks--;
        completer.complete(receivedMessage);
      }
    });

    return completer.future;
  }

  /// Resets a timer that kills the isolate after a certain amount of inactivity.
  ///
  /// Should be called after initialization (e.g. inside `init()`) and after every call to isolate (e.g. inside `_runInIsolate()`)
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, () {
      if (_activeTasks > 0) {
        _logger.info('Tasks are still running. Delaying isolate disposal.');
        // Optionally, reschedule the timer to check again later.
        _resetInactivityTimer();
      } else {
        _logger.info(
          'Clustering Isolate has been inactive for ${_inactivityDuration.inSeconds} seconds with no tasks running. Killing isolate.',
        );
        dispose();
      }
    });
  }

  /// Disposes the isolate worker.
  void dispose() {
    if (!isSpawned) return;

    isSpawned = false;
    _isolate.kill();
    _receivePort.close();
    _inactivityTimer?.cancel();
  }

  /// Runs the clustering algorithm [_runLinearClustering] on the given [input], in an isolate.
  ///
  /// Returns the clustering result, which is a list of clusters, where each cluster is a list of indices of the dataset.
  ///
  /// WARNING: Make sure to always input data in the same ordering, otherwise the clustering can less less deterministic.
  Future<Map<String, int>?> predictLinear(
    Map<String, (int?, Uint8List)> input, {
    Map<int, int>? fileIDToCreationTime,
    double distanceThreshold = kRecommendedDistanceThreshold,
    int? offset,
  }) async {
    if (input.isEmpty) {
      _logger.warning(
        "Clustering dataset of embeddings is empty, returning empty list.",
      );
      return null;
    }
    if (isRunning) {
      _logger.warning("Clustering is already running, returning empty list.");
      return null;
    }

    isRunning = true;
    try {
      // Clustering inside the isolate
      _logger.info(
        "Start clustering on ${input.length} embeddings inside computer isolate",
      );
      final stopwatchClustering = Stopwatch()..start();
      // final Map<String, int> faceIdToCluster =
      //     await _runLinearClusteringInComputer(input);
      final Map<String, int> faceIdToCluster = await _runInIsolate(
        (
          ClusterOperation.linearIncrementalClustering,
          {
            'input': input,
            'fileIDToCreationTime': fileIDToCreationTime,
            'distanceThreshold': distanceThreshold,
            'offset': offset,
          }
        ),
      );
      // return _runLinearClusteringInComputer(input);
      _logger.info(
        'Clustering executed in ${stopwatchClustering.elapsed.inSeconds} seconds',
      );

      isRunning = false;
      return faceIdToCluster;
    } catch (e, stackTrace) {
      _logger.severe('Error while running clustering', e, stackTrace);
      isRunning = false;
      rethrow;
    }
  }

  Future<List<List<String>>> predictDbscan(
    Map<String, Uint8List> input, {
    Map<int, int>? fileIDToCreationTime,
    double eps = 0.3,
    int minPts = 5,
  }) async {
    if (input.isEmpty) {
      _logger.warning(
        "DBSCAN Clustering dataset of embeddings is empty, returning empty list.",
      );
      return [];
    }
    if (isRunning) {
      _logger.warning(
        "DBSCAN Clustering is already running, returning empty list.",
      );
      return [];
    }

    isRunning = true;

    // Clustering inside the isolate
    _logger.info(
      "Start DBSCAN clustering on ${input.length} embeddings inside computer isolate",
    );
    final stopwatchClustering = Stopwatch()..start();
    // final Map<String, int> faceIdToCluster =
    //     await _runLinearClusteringInComputer(input);
    final List<List<String>> clusterFaceIDs = await _runInIsolate(
      (
        ClusterOperation.dbscanClustering,
        {
          'input': input,
          'fileIDToCreationTime': fileIDToCreationTime,
          'eps': eps,
          'minPts': minPts,
        }
      ),
    );
    // return _runLinearClusteringInComputer(input);
    _logger.info(
      'DBSCAN Clustering executed in ${stopwatchClustering.elapsed.inSeconds} seconds',
    );

    isRunning = false;

    return clusterFaceIDs;
  }

  static Map<String, int> _runLinearClustering(Map args) {
    final input = args['input'] as Map<String, (int?, Uint8List)>;
    final fileIDToCreationTime = args['fileIDToCreationTime'] as Map<int, int>?;
    final distanceThreshold = args['distanceThreshold'] as double;
    final offset = args['offset'] as int?;

    log(
      "[ClusterIsolate] ${DateTime.now()} Copied to isolate ${input.length} faces",
    );

    // Organize everything into a list of FaceInfo objects
    final List<FaceInfo> faceInfos = [];
    for (final entry in input.entries) {
      faceInfos.add(
        FaceInfo(
          faceID: entry.key,
          vEmbedding: Vector.fromList(
            EVector.fromBuffer(entry.value.$2).values,
            dtype: DType.float32,
          ),
          clusterId: entry.value.$1,
          fileCreationTime:
              fileIDToCreationTime?[getFileIdFromFaceId(entry.key)],
        ),
      );
    }

    // Sort the faceInfos based on fileCreationTime, in ascending order, so oldest faces are first
    if (fileIDToCreationTime != null) {
      faceInfos.sort((a, b) {
        if (a.fileCreationTime == null && b.fileCreationTime == null) {
          return 0;
        } else if (a.fileCreationTime == null) {
          return 1;
        } else if (b.fileCreationTime == null) {
          return -1;
        } else {
          return a.fileCreationTime!.compareTo(b.fileCreationTime!);
        }
      });
    }

    // Sort the faceInfos such that the ones with null clusterId are at the end
    final List<FaceInfo> facesWithClusterID = <FaceInfo>[];
    final List<FaceInfo> facesWithoutClusterID = <FaceInfo>[];
    for (final FaceInfo faceInfo in faceInfos) {
      if (faceInfo.clusterId == null) {
        facesWithoutClusterID.add(faceInfo);
      } else {
        facesWithClusterID.add(faceInfo);
      }
    }
    final sortedFaceInfos = <FaceInfo>[];
    sortedFaceInfos.addAll(facesWithClusterID);
    sortedFaceInfos.addAll(facesWithoutClusterID);

    log(
      "[ClusterIsolate] ${DateTime.now()} Clustering ${facesWithoutClusterID.length} new faces without clusterId, and ${facesWithClusterID.length} faces with clusterId",
    );

    // Make sure the first face has a clusterId
    final int totalFaces = sortedFaceInfos.length;

    if (sortedFaceInfos.isEmpty) {
      return {};
    }

    // Start actual clustering
    log(
      "[ClusterIsolate] ${DateTime.now()} Processing $totalFaces faces in total in this round ${offset != null ? "on top of ${offset + facesWithClusterID.length} earlier processed faces" : ""}",
    );
    // set current epoch time as clusterID
    int clusterID = DateTime.now().microsecondsSinceEpoch;
    if (facesWithClusterID.isEmpty) {
      // assign a clusterID to the first face
      sortedFaceInfos[0].clusterId = clusterID;
      clusterID++;
    }
    final Map<String, int> newFaceIdToCluster = {};
    final stopwatchClustering = Stopwatch()..start();
    for (int i = 1; i < totalFaces; i++) {
      // Incremental clustering, so we can skip faces that already have a clusterId
      if (sortedFaceInfos[i].clusterId != null) {
        clusterID = max(clusterID, sortedFaceInfos[i].clusterId!);
        continue;
      }

      int closestIdx = -1;
      double closestDistance = double.infinity;
      if (i % 250 == 0) {
        log("[ClusterIsolate] ${DateTime.now()} Processed ${offset != null ? i + offset : i} faces");
      }
      for (int j = i - 1; j >= 0; j--) {
        late double distance;
        if (sortedFaceInfos[i].vEmbedding != null) {
          distance = 1.0 -
              sortedFaceInfos[i]
                  .vEmbedding!
                  .dot(sortedFaceInfos[j].vEmbedding!);
        } else {
          distance = cosineDistForNormVectors(
            sortedFaceInfos[i].embedding!,
            sortedFaceInfos[j].embedding!,
          );
        }
        if (distance < closestDistance) {
          closestDistance = distance;
          closestIdx = j;
          // if (distance < distanceThreshold) {
          //   if (sortedFaceInfos[j].faceID.startsWith("14914702") ||
          //       sortedFaceInfos[j].faceID.startsWith("15488756")) {
          //     log('[XXX] faceIDs: ${sortedFaceInfos[j].faceID} and ${sortedFaceInfos[i].faceID} with distance $distance');
          //   }
          // }
        }
      }

      if (closestDistance < distanceThreshold) {
        if (sortedFaceInfos[closestIdx].clusterId == null) {
          // Ideally this should never happen, but just in case log it
          log(
            " [ClusterIsolate] [WARNING] ${DateTime.now()} Found new cluster $clusterID",
          );
          clusterID++;
          sortedFaceInfos[closestIdx].clusterId = clusterID;
          newFaceIdToCluster[sortedFaceInfos[closestIdx].faceID] = clusterID;
        }
        // if (sortedFaceInfos[i].faceID.startsWith("14914702") ||
        //     sortedFaceInfos[i].faceID.startsWith("15488756")) {
        //   log(
        //     "[XXX]  [ClusterIsolate] ${DateTime.now()} Found similar face ${sortedFaceInfos[i].faceID} to ${sortedFaceInfos[closestIdx].faceID} with distance $closestDistance",
        //   );
        // }
        sortedFaceInfos[i].clusterId = sortedFaceInfos[closestIdx].clusterId;
        newFaceIdToCluster[sortedFaceInfos[i].faceID] =
            sortedFaceInfos[closestIdx].clusterId!;
      } else {
        // if (sortedFaceInfos[i].faceID.startsWith("14914702") ||
        //     sortedFaceInfos[i].faceID.startsWith("15488756")) {
        //   log(
        //     "[XXX]  [ClusterIsolate] ${DateTime.now()} Found new cluster $clusterID for face ${sortedFaceInfos[i].faceID}",
        //   );
        // }
        clusterID++;
        sortedFaceInfos[i].clusterId = clusterID;
        newFaceIdToCluster[sortedFaceInfos[i].faceID] = clusterID;
      }
    }

    stopwatchClustering.stop();
    log(
      ' [ClusterIsolate] ${DateTime.now()} Clustering for ${sortedFaceInfos.length} embeddings executed in ${stopwatchClustering.elapsedMilliseconds}ms',
    );

    // analyze the results
    FaceClusteringService._analyzeClusterResults(sortedFaceInfos);

    return newFaceIdToCluster;
  }

  static void _analyzeClusterResults(List<FaceInfo> sortedFaceInfos) {
    final stopwatch = Stopwatch()..start();

    final Map<String, int> faceIdToCluster = {};
    for (final faceInfo in sortedFaceInfos) {
      faceIdToCluster[faceInfo.faceID] = faceInfo.clusterId!;
    }

    //  Find faceIDs that are part of a cluster which is larger than 5 and are new faceIDs
    final Map<int, int> clusterIdToSize = {};
    faceIdToCluster.forEach((key, value) {
      if (clusterIdToSize.containsKey(value)) {
        clusterIdToSize[value] = clusterIdToSize[value]! + 1;
      } else {
        clusterIdToSize[value] = 1;
      }
    });

    // print top 10 cluster ids and their sizes based on the internal cluster id
    final clusterIds = faceIdToCluster.values.toSet();
    final clusterSizes = clusterIds.map((clusterId) {
      return faceIdToCluster.values.where((id) => id == clusterId).length;
    }).toList();
    clusterSizes.sort();
    // find clusters whose size is greater than 1
    int oneClusterCount = 0;
    int moreThan5Count = 0;
    int moreThan10Count = 0;
    int moreThan20Count = 0;
    int moreThan50Count = 0;
    int moreThan100Count = 0;

    for (int i = 0; i < clusterSizes.length; i++) {
      if (clusterSizes[i] > 100) {
        moreThan100Count++;
      } else if (clusterSizes[i] > 50) {
        moreThan50Count++;
      } else if (clusterSizes[i] > 20) {
        moreThan20Count++;
      } else if (clusterSizes[i] > 10) {
        moreThan10Count++;
      } else if (clusterSizes[i] > 5) {
        moreThan5Count++;
      } else if (clusterSizes[i] == 1) {
        oneClusterCount++;
      }
    }

    // print the metrics
    log(
      "[ClusterIsolate]  Total clusters ${clusterIds.length}: \n oneClusterCount $oneClusterCount \n moreThan5Count $moreThan5Count \n moreThan10Count $moreThan10Count \n moreThan20Count $moreThan20Count \n moreThan50Count $moreThan50Count \n moreThan100Count $moreThan100Count",
    );
    stopwatch.stop();
    log(
      "[ClusterIsolate]  Clustering additional analysis took ${stopwatch.elapsedMilliseconds} ms",
    );
  }

  static List<List<String>> _runDbscanClustering(Map args) {
    final input = args['input'] as Map<String, Uint8List>;
    final fileIDToCreationTime = args['fileIDToCreationTime'] as Map<int, int>?;
    final eps = args['eps'] as double;
    final minPts = args['minPts'] as int;

    log(
      "[ClusterIsolate] ${DateTime.now()} Copied to isolate ${input.length} faces",
    );

    final DBSCAN dbscan = DBSCAN(
      epsilon: eps,
      minPoints: minPts,
      distanceMeasure: cosineDistForNormVectors,
    );

    // Organize everything into a list of FaceInfo objects
    final List<FaceInfo> faceInfos = [];
    for (final entry in input.entries) {
      faceInfos.add(
        FaceInfo(
          faceID: entry.key,
          embedding: EVector.fromBuffer(entry.value).values,
          fileCreationTime:
              fileIDToCreationTime?[getFileIdFromFaceId(entry.key)],
        ),
      );
    }

    // Sort the faceInfos based on fileCreationTime, in ascending order, so oldest faces are first
    if (fileIDToCreationTime != null) {
      faceInfos.sort((a, b) {
        if (a.fileCreationTime == null && b.fileCreationTime == null) {
          return 0;
        } else if (a.fileCreationTime == null) {
          return 1;
        } else if (b.fileCreationTime == null) {
          return -1;
        } else {
          return a.fileCreationTime!.compareTo(b.fileCreationTime!);
        }
      });
    }

    // Get the embeddings
    final List<List<double>> embeddings =
        faceInfos.map((faceInfo) => faceInfo.embedding!).toList();

    // Run the DBSCAN clustering
    final List<List<int>> clusterOutput = dbscan.run(embeddings);
    final List<List<FaceInfo>> clusteredFaceInfos = clusterOutput
        .map((cluster) => cluster.map((idx) => faceInfos[idx]).toList())
        .toList();
    final List<List<String>> clusteredFaceIDs = clusterOutput
        .map((cluster) => cluster.map((idx) => faceInfos[idx].faceID).toList())
        .toList();

    return clusteredFaceIDs;
  }
}
