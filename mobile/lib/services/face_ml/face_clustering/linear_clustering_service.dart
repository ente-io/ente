import "dart:async";
import "dart:developer";
import "dart:isolate";
import "dart:math" show max;
import "dart:typed_data";

import "package:logging/logging.dart";
import "package:photos/generated/protos/ente/common/vector.pb.dart";
import "package:photos/services/face_ml/face_clustering/cosine_distance.dart";
import "package:synchronized/synchronized.dart";

class FaceInfo {
  final String faceID;
  final List<double> embedding;
  int? clusterId;
  String? closestFaceId;
  int? closestDist;
  FaceInfo({
    required this.faceID,
    required this.embedding,
    this.clusterId,
  });
}

enum ClusterOperation { linearIncrementalClustering }

class FaceLinearClustering {
  final _logger = Logger("FaceLinearClustering");

  Timer? _inactivityTimer;
  final Duration _inactivityDuration = const Duration(seconds: 30);
  int _activeTasks = 0;


  final _initLock = Lock();

  late Isolate _isolate;
  late ReceivePort _receivePort = ReceivePort();
  late SendPort _mainSendPort;

  bool isSpawned = false;
  bool isRunning = false;

  static const recommendedDistanceThreshold = 0.3;

  // singleton pattern
  FaceLinearClustering._privateConstructor();

  /// Use this instance to access the FaceClustering service.
  /// e.g. `FaceLinearClustering.instance.predict(dataset)`
  static final instance = FaceLinearClustering._privateConstructor();
  factory FaceLinearClustering() => instance;

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
            final input = args['input'] as Map<String, (int?, Uint8List)>;
            final result = FaceLinearClustering._runLinearClustering(input);
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
        completer.completeError(exception, stackTrace);
      } else {
        completer.complete(receivedMessage);
      }
    });
    _activeTasks--;

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

  /// Runs the clustering algorithm on the given [input], in an isolate.
  ///
  /// Returns the clustering result, which is a list of clusters, where each cluster is a list of indices of the dataset.
  ///
  /// WARNING: Make sure to always input data in the same ordering, otherwise the clustering can less less deterministic.
  Future<Map<String, int>?> predict(
    Map<String, (int?, Uint8List)> input,
  ) async {
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

    // Clustering inside the isolate
    _logger.info(
      "Start clustering on ${input.length} embeddings inside computer isolate",
    );
    final stopwatchClustering = Stopwatch()..start();
    // final Map<String, int> faceIdToCluster =
    //     await _runLinearClusteringInComputer(input);
    final Map<String, int> faceIdToCluster = await _runInIsolate(
      (ClusterOperation.linearIncrementalClustering, {'input': input}),
    );
    // return _runLinearClusteringInComputer(input);
    _logger.info(
      'Clustering executed in ${stopwatchClustering.elapsed.inSeconds} seconds',
    );

    isRunning = false;

    return faceIdToCluster;
  }

  static Map<String, int> _runLinearClustering(
    Map<String, (int?, Uint8List)> x,
  ) {
    log(
      "[ClusterIsolate] ${DateTime.now()} Copied to isolate ${x.length} faces",
    );
    final List<FaceInfo> faceInfos = [];
    for (final entry in x.entries) {
      faceInfos.add(
        FaceInfo(
          faceID: entry.key,
          embedding: EVector.fromBuffer(entry.value.$2).values,
          clusterId: entry.value.$1,
        ),
      );
    }
    // Sort the faceInfos such that the ones with null clusterId are at the end
    faceInfos.sort((a, b) {
      if (a.clusterId == null && b.clusterId == null) {
        return 0;
      } else if (a.clusterId == null) {
        return 1;
      } else if (b.clusterId == null) {
        return -1;
      } else {
        return 0;
      }
    });
    // Count the amount of null values at the end
    int nullCount = 0;
    for (final faceInfo in faceInfos.reversed) {
      if (faceInfo.clusterId == null) {
        nullCount++;
      } else {
        break;
      }
    }
    log(
      "[ClusterIsolate] ${DateTime.now()} Clustering $nullCount new faces without clusterId, and ${faceInfos.length - nullCount} faces with clusterId",
    );
    for (final clusteredFaceInfo
        in faceInfos.sublist(0, faceInfos.length - nullCount)) {
      assert(clusteredFaceInfo.clusterId != null);
    }

    final int totalFaces = faceInfos.length;
    int clusterID = 1;
    if (faceInfos.isNotEmpty) {
      faceInfos.first.clusterId = clusterID;
    }
    log(
      "[ClusterIsolate] ${DateTime.now()} Processing $totalFaces faces",
    );
    final stopwatchClustering = Stopwatch()..start();
    for (int i = 1; i < totalFaces; i++) {
      // Incremental clustering, so we can skip faces that already have a clusterId
      if (faceInfos[i].clusterId != null) {
        clusterID = max(clusterID, faceInfos[i].clusterId!);
        continue;
      }
      final currentEmbedding = faceInfos[i].embedding;
      int closestIdx = -1;
      double closestDistance = double.infinity;
      if (i % 250 == 0) {
        log("[ClusterIsolate] ${DateTime.now()} Processing $i faces");
      }
      for (int j = 0; j < i; j++) {
        final double distance = cosineDistForNormVectors(
          currentEmbedding,
          faceInfos[j].embedding,
        );
        if (distance < closestDistance) {
          closestDistance = distance;
          closestIdx = j;
        }
      }

      if (closestDistance < recommendedDistanceThreshold) {
        if (faceInfos[closestIdx].clusterId == null) {
          // Ideally this should never happen, but just in case log it
          log(
            " [ClusterIsolate] ${DateTime.now()} Found new cluster $clusterID",
          );
          clusterID++;
          faceInfos[closestIdx].clusterId = clusterID;
        }
        faceInfos[i].clusterId = faceInfos[closestIdx].clusterId;
      } else {
        clusterID++;
        faceInfos[i].clusterId = clusterID;
      }
    }
    final Map<String, int> result = {};
    for (final faceInfo in faceInfos) {
      result[faceInfo.faceID] = faceInfo.clusterId!;
    }
    stopwatchClustering.stop();
    log(
      ' [ClusterIsolate] ${DateTime.now()} Clustering for ${faceInfos.length} embeddings (${faceInfos[0].embedding.length} size) executed in ${stopwatchClustering.elapsedMilliseconds}ms, clusters $clusterID',
    );
    // return result;

    // NOTe: The main clustering logic is done, the following is just filtering and logging
    final input = x;
    final faceIdToCluster = result;
    stopwatchClustering.reset();
    stopwatchClustering.start();

    final Set<String> newFaceIds = <String>{};
    input.forEach((key, value) {
      if (value.$1 == null) {
        newFaceIds.add(key);
      }
    });

    //  Find faceIDs that are part of a cluster which is larger than 5 and are new faceIDs
    final Map<int, int> clusterIdToSize = {};
    faceIdToCluster.forEach((key, value) {
      if (clusterIdToSize.containsKey(value)) {
        clusterIdToSize[value] = clusterIdToSize[value]! + 1;
      } else {
        clusterIdToSize[value] = 1;
      }
    });
    final Map<String, int> faceIdToClusterFiltered = {};
    for (final entry in faceIdToCluster.entries) {
      if (clusterIdToSize[entry.value]! > 0 && newFaceIds.contains(entry.key)) {
        faceIdToClusterFiltered[entry.key] = entry.value;
      }
    }

    // print top 10 cluster ids and their sizes based on the internal cluster id
    final clusterIds = faceIdToCluster.values.toSet();
    final clusterSizes = clusterIds.map((clusterId) {
      return faceIdToCluster.values.where((id) => id == clusterId).length;
    }).toList();
    clusterSizes.sort();
    // find clusters whose size is graeter than 1
    int oneClusterCount = 0;
    int moreThan5Count = 0;
    int moreThan10Count = 0;
    int moreThan20Count = 0;
    int moreThan50Count = 0;
    int moreThan100Count = 0;

    // for (int i = 0; i < clusterSizes.length; i++) {
    //   if (clusterSizes[i] > 100) {
    //     moreThan100Count++;
    //   } else if (clusterSizes[i] > 50) {
    //     moreThan50Count++;
    //   } else if (clusterSizes[i] > 20) {
    //     moreThan20Count++;
    //   } else if (clusterSizes[i] > 10) {
    //     moreThan10Count++;
    //   } else if (clusterSizes[i] > 5) {
    //     moreThan5Count++;
    //   } else if (clusterSizes[i] == 1) {
    //     oneClusterCount++;
    //   }
    // }
    for (int i = 0; i < clusterSizes.length; i++) {
      if (clusterSizes[i] > 100) {
        moreThan100Count++;
      }
      if (clusterSizes[i] > 50) {
        moreThan50Count++;
      }
      if (clusterSizes[i] > 20) {
        moreThan20Count++;
      }
      if (clusterSizes[i] > 10) {
        moreThan10Count++;
      }
      if (clusterSizes[i] > 5) {
        moreThan5Count++;
      }
      if (clusterSizes[i] == 1) {
        oneClusterCount++;
      }
    }
    // print the metrics
    log(
      '[ClusterIsolate]  Total clusters ${clusterIds.length}, '
      'oneClusterCount $oneClusterCount, '
      'moreThan5Count $moreThan5Count, '
      'moreThan10Count $moreThan10Count, '
      'moreThan20Count $moreThan20Count, '
      'moreThan50Count $moreThan50Count, '
      'moreThan100Count $moreThan100Count',
    );
    stopwatchClustering.stop();
    log(
      "[ClusterIsolate]  Clustering additional steps took ${stopwatchClustering.elapsedMilliseconds} ms",
    );

    // log('Top clusters count ${clusterSizes.reversed.take(10).toList()}');
    return faceIdToClusterFiltered;
  }
}
