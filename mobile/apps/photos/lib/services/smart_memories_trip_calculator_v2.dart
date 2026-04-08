part of "smart_memories_service.dart";

class _LocationCluster {
  final List<EnteFile> files;
  double _latitudeSum;
  double _longitudeSum;
  Location _center;

  _LocationCluster(EnteFile file)
      : files = [file],
        _latitudeSum = file.location!.latitude!,
        _longitudeSum = file.location!.longitude!,
        _center = file.location!;

  _LocationCluster.fromFiles(Iterable<EnteFile> files)
      : files = List<EnteFile>.from(files),
        _latitudeSum = 0,
        _longitudeSum = 0,
        _center = const Location(latitude: 0, longitude: 0) {
    for (final file in this.files) {
      _latitudeSum += file.location!.latitude!;
      _longitudeSum += file.location!.longitude!;
    }
    _recalculateCenter();
  }

  Location get center => _center;

  int get firstCreationTime => files
      .map((file) => file.creationTime!)
      .reduce((value, element) => min(value, element));

  void addFile(EnteFile file) {
    files.add(file);
    _latitudeSum += file.location!.latitude!;
    _longitudeSum += file.location!.longitude!;
    _recalculateCenter();
  }

  void addCluster(_LocationCluster cluster) {
    files.addAll(cluster.files);
    _latitudeSum += cluster._latitudeSum;
    _longitudeSum += cluster._longitudeSum;
    _recalculateCenter();
  }

  void _recalculateCenter() {
    _center = Location(
      latitude: _latitudeSum / files.length,
      longitude: _longitudeSum / files.length,
    );
  }
}

class TripMemoriesCalculatorV2 {
  // Temporal gap to split photos into separate time windows.
  static const _maxTemporalGapDays = 15;

  // Spatial radius for clustering photos within a temporal block.
  static const _tripClusterRadius = 25.0;

  // Max hop distance for chaining clusters into road trips.
  static const _chainHopDistance = 800.0;

  // Base location overlap check radius.
  static const _baseOverlapRadius = 10.0;

  // Secondary merge radius for nearby home clusters.
  static const _baseMergeRadius = 1.5;

  // Base evidence thresholds.
  static const _minBasePhotos = 10;
  static const _minBaseActiveDays = 10;
  static const _minBaseActiveWeeks = 6;
  static const _minBaseActiveMonths = 2;
  static const _minBaseSpanDays = 45;
  static const _baseDensityWindowDays = 120;
  static const _minBaseActiveDaysInWindow = 12;

  // Trip duration bounds (in days).
  static const _minTripDays = 3;
  static const _maxTripDays = 30;

  // Minimum photos for a valid trip.
  static const _minTripPhotos = 20;

  // Minimum photos for a cluster to participate in chain merging.
  // Smaller clusters are kept as standalone candidates (and typically
  // filtered out by _isValidTrip), preventing stray photos from being
  // absorbed into legitimate trips.
  static const _minChainClusterPhotos = 5;

  // Max temporal gap (in days) for merging trips across temporal blocks.
  static const _mergeWindowDays = 2;

  // Max spatial distance (in km) for merging trips across temporal blocks.
  static const _mergeMaxDistance = 25.0;

  static Future<(List<TripMemory>, List<BaseLocation>)> compute(
    Iterable<EnteFile> allFiles,
    Map<int, EnteFile> allFileIdsToFile,
    DateTime currentTime,
    List<TripsShownLog> shownTrips, {
    bool surfaceAll = false,
    required bool isOfflineMode,
    required Map<int, int> seenTimes,
    required Map<int, List<FaceWithoutEmbedding>> fileIdToFaces,
    required Map<String, String> faceIDsToPersonID,
    required Map<int, EmbeddingVector> fileIDToImageEmbedding,
    required Vector clipPositiveTextVector,
    required List<City> cities,
  }) async {
    if (allFiles.isEmpty) return (<TripMemory>[], <BaseLocation>[]);

    final nowInMicroseconds = currentTime.microsecondsSinceEpoch;
    final windowEnd =
        currentTime.add(kMemoriesUpdateFrequency).microsecondsSinceEpoch;
    final currentMonth = currentTime.month;
    final cutOffTime = currentTime.subtract(const Duration(days: 365));

    // ── Phase 1: Base location detection ──

    final baseLocations = _detectBaseLocations(
      allFiles,
      isOfflineMode: isOfflineMode,
    );

    // ── Phase 2: Trip detection ──

    final filesWithLocation = allFiles.where((f) => f.hasLocation).toList()
      ..sort((a, b) => a.creationTime!.compareTo(b.creationTime!));

    if (filesWithLocation.isEmpty) {
      return (<TripMemory>[], baseLocations);
    }

    // Step 2a: Filter base photos out of the trip stream before
    // temporal segmentation, so repeated visits to the same place remain
    // separated by time spent back at base.
    final temporalBlocks = _segmentAwayFilesByTime(
      filesWithLocation,
      baseLocations,
    );

    // Step 2b: Spatial clustering + chain merging within each block
    final tripCandidates = <TripMemory>[];
    for (final block in temporalBlocks) {
      var spatialClusters = _clusterByLocation(
        block,
        radius: _tripClusterRadius,
      );
      spatialClusters = _mergeChainedClusters(spatialClusters);

      for (final cluster in spatialClusters) {
        final files = List<EnteFile>.from(cluster.files)
          ..sort((a, b) => a.creationTime!.compareTo(b.creationTime!));
        final location = cluster.center;

        if (!_isValidTrip(files, location, baseLocations)) continue;

        tripCandidates.add(
          TripMemory(
            Memory.fromFiles(files, seenTimes),
            0,
            0,
            location,
            firstCreationTime: files.first.creationTime!,
            lastCreationTime: files.last.creationTime!,
          ),
        );
      }
    }

    // Step 2c: Merge trips across temporal blocks (same location, close time)
    final mergedTrips = _mergeNearbyTrips(tripCandidates);

    // Step 2d: Final validation
    final validTrips = mergedTrips
        .where(
          (t) =>
              t.memories.length >= _minTripPhotos &&
              t.averageCreationTime() < cutOffTime.microsecondsSinceEpoch,
        )
        .toList();

    // ── Phase 3: Surface selection ──

    final List<TripMemory> memoryResults = [];

    if (surfaceAll) {
      return _surfaceAll(
        memoryResults,
        baseLocations,
        validTrips,
        allFileIdsToFile,
        nowInMicroseconds,
        windowEnd,
        seenTimes: seenTimes,
        isOfflineMode: isOfflineMode,
        fileIdToFaces: fileIdToFaces,
        faceIDsToPersonID: faceIDsToPersonID,
        fileIDToImageEmbedding: fileIDToImageEmbedding,
        clipPositiveTextVector: clipPositiveTextVector,
        cities: cities,
      );
    }

    return _surfaceScheduled(
      memoryResults,
      baseLocations,
      validTrips,
      currentTime,
      currentMonth,
      nowInMicroseconds,
      windowEnd,
      shownTrips,
      isOfflineMode: isOfflineMode,
      seenTimes: seenTimes,
      fileIdToFaces: fileIdToFaces,
      faceIDsToPersonID: faceIDsToPersonID,
      fileIDToImageEmbedding: fileIDToImageEmbedding,
      clipPositiveTextVector: clipPositiveTextVector,
      cities: cities,
    );
  }

  // ── Base location detection ──

  static List<BaseLocation> _detectBaseLocations(
    Iterable<EnteFile> allFiles, {
    required bool isOfflineMode,
  }) {
    final filesWithLocation = allFiles
        .where((file) => file.hasLocation)
        .toList()
      ..sort((a, b) => a.creationTime!.compareTo(b.creationTime!));
    final smallRadiusClusters = _mergeNearbyLocationClusters(
      _clusterByLocation(
        filesWithLocation,
        radius: baseRadius,
      ),
      radius: _baseMergeRadius,
    );

    final List<BaseLocation> baseLocations = [];
    for (final cluster in smallRadiusClusters) {
      final files = cluster.files;
      final location = cluster.center;
      if (!_isValidBaseLocation(files)) continue;

      final creationTimes = files.map((file) => file.creationTime!).toList()
        ..sort();
      final lastCreationTime = DateTime.fromMicrosecondsSinceEpoch(
        creationTimes.last,
      );
      final bool isCurrent = lastCreationTime.isAfter(
        DateTime.now().subtract(const Duration(days: 90)),
      );
      baseLocations.add(
        BaseLocation(
          files
              .map(
                (file) => SmartMemoriesService._memoryFileId(
                  file,
                  isOfflineMode: isOfflineMode,
                ),
              )
              .whereType<int>()
              .toList(),
          location,
          isCurrent,
        ),
      );
    }
    return baseLocations;
  }

  // ── Temporal segmentation ──

  static List<List<EnteFile>> _segmentAwayFilesByTime(
    List<EnteFile> sortedFiles,
    List<BaseLocation> baseLocations,
  ) {
    final blocks = <List<EnteFile>>[];
    var currentBlock = <EnteFile>[];
    EnteFile? lastAwayFile;
    var sawBasePhotoSinceLastAway = false;

    for (final file in sortedFiles) {
      if (_isNearAnyBase(file.location!, baseLocations)) {
        if (currentBlock.isNotEmpty) {
          sawBasePhotoSinceLastAway = true;
        }
        continue;
      }

      if (currentBlock.isEmpty) {
        currentBlock = [file];
        lastAwayFile = file;
        sawBasePhotoSinceLastAway = false;
        continue;
      }

      final gapMicros = file.creationTime! - lastAwayFile!.creationTime!;
      final gapDays = gapMicros ~/ microSecondsInDay;
      if (gapDays > _maxTemporalGapDays || sawBasePhotoSinceLastAway) {
        blocks.add(currentBlock);
        currentBlock = [file];
      } else {
        currentBlock.add(file);
      }
      lastAwayFile = file;
      sawBasePhotoSinceLastAway = false;
    }

    if (currentBlock.isNotEmpty) {
      blocks.add(currentBlock);
    }
    return blocks;
  }

  // ── Spatial clustering within a temporal block ──

  static List<_LocationCluster> _clusterByLocation(
    Iterable<EnteFile> files, {
    required double radius,
  }) {
    final clusters = <_LocationCluster>[];
    for (final file in files) {
      bool added = false;
      for (final cluster in clusters) {
        if (isFileInsideLocationTag(cluster.center, file.location!, radius)) {
          cluster.addFile(file);
          added = true;
          break;
        }
      }
      if (!added) {
        clusters.add(_LocationCluster(file));
      }
    }
    return clusters;
  }

  static List<_LocationCluster> _mergeNearbyLocationClusters(
    List<_LocationCluster> clusters, {
    required double radius,
  }) {
    final mergedClusters = List<_LocationCluster>.from(clusters);
    bool didMerge = true;
    while (didMerge) {
      didMerge = false;
      for (int i = 0; i < mergedClusters.length; i++) {
        for (int j = i + 1; j < mergedClusters.length; j++) {
          final distance = calculateDistance(
            mergedClusters[i].center,
            mergedClusters[j].center,
          );
          if (distance > radius) continue;

          mergedClusters[i].addCluster(mergedClusters[j]);
          mergedClusters.removeAt(j);
          didMerge = true;
          break;
        }
        if (didMerge) break;
      }
    }
    return mergedClusters;
  }

  // ── Chain merge for road trips ──

  /// Merges spatial clusters within the same temporal block if they form
  /// a chronological chain with hops <= [_chainHopDistance].
  static List<_LocationCluster> _mergeChainedClusters(
    List<_LocationCluster> clusters,
  ) {
    if (clusters.length <= 1) return clusters;

    // Sort clusters by their earliest photo time
    final sortedClusters = List<_LocationCluster>.from(clusters)
      ..sort((a, b) => a.firstCreationTime.compareTo(b.firstCreationTime));

    // Separate clusters large enough to chain from tiny ones that should
    // stay standalone (they'll be filtered out later by _isValidTrip).
    final chainable = <_LocationCluster>[];
    final tooSmall = <_LocationCluster>[];
    for (final cluster in sortedClusters) {
      if (cluster.files.length >= _minChainClusterPhotos) {
        chainable.add(cluster);
      } else {
        tooSmall.add(cluster);
      }
    }

    if (chainable.isEmpty) return clusters;

    final merged = <_LocationCluster>[];
    var currentCluster = _LocationCluster.fromFiles(chainable.first.files);

    for (int i = 1; i < chainable.length; i++) {
      final next = chainable[i];
      final distance = calculateDistance(currentCluster.center, next.center);
      final allFiles = [...currentCluster.files, ...next.files];
      final times = allFiles.map((f) => f.creationTime!);
      final spanDays = DateTime.fromMicrosecondsSinceEpoch(times.reduce(max))
          .difference(DateTime.fromMicrosecondsSinceEpoch(times.reduce(min)))
          .inDays;
      if (distance <= _chainHopDistance && spanDays <= _maxTripDays) {
        currentCluster.addCluster(next);
      } else {
        merged.add(currentCluster);
        currentCluster = _LocationCluster.fromFiles(next.files);
      }
    }
    merged.add(currentCluster);

    // Return both chained results and the too-small standalone clusters
    return [...merged, ...tooSmall];
  }

  // ── Trip validation ──

  static bool _isValidTrip(
    List<EnteFile> files,
    Location location,
    List<BaseLocation> bases,
  ) {
    if (files.length < _minTripPhotos) return false;

    final times = files.map((f) => f.creationTime!).toList()..sort();
    final first = DateTime.fromMicrosecondsSinceEpoch(times.first);
    final last = DateTime.fromMicrosecondsSinceEpoch(times.last);
    final days = last.difference(first).inDays;
    if (days < _minTripDays) return false;

    return !_isNearAnyBase(location, bases);
  }

  static bool _isValidBaseLocation(List<EnteFile> files) {
    if (files.length < _minBasePhotos) return false;

    final creationTimes = files.map((file) => file.creationTime!).toList()
      ..sort();
    final uniqueDays = <int>{};
    final uniqueWeeks = <int>{};
    final uniqueMonths = <int>{};

    for (final creationTime in creationTimes) {
      final date = DateTime.fromMicrosecondsSinceEpoch(creationTime);
      uniqueDays.add(
        DateTime(date.year, date.month, date.day).microsecondsSinceEpoch,
      );
      final weekStart = DateTime(
        date.year,
        date.month,
        date.day,
      ).subtract(Duration(days: date.weekday - 1));
      uniqueWeeks.add(weekStart.microsecondsSinceEpoch);
      uniqueMonths.add(date.year * 100 + date.month);
    }

    final firstCreationTime = DateTime.fromMicrosecondsSinceEpoch(
      creationTimes.first,
    );
    final lastCreationTime = DateTime.fromMicrosecondsSinceEpoch(
      creationTimes.last,
    );
    final daysRange = lastCreationTime.difference(firstCreationTime).inDays;
    final sortedUniqueDays = uniqueDays.toList()..sort();

    return uniqueDays.length >= _minBaseActiveDays &&
        uniqueWeeks.length >= _minBaseActiveWeeks &&
        uniqueMonths.length >= _minBaseActiveMonths &&
        _hasDenseResidenceWindow(sortedUniqueDays) &&
        daysRange >= _minBaseSpanDays;
  }

  static bool _hasDenseResidenceWindow(List<int> sortedUniqueDays) {
    if (sortedUniqueDays.length < _minBaseActiveDaysInWindow) {
      return false;
    }

    var windowStart = 0;
    for (int windowEnd = 0; windowEnd < sortedUniqueDays.length; windowEnd++) {
      while (sortedUniqueDays[windowEnd] - sortedUniqueDays[windowStart] >
          _baseDensityWindowDays * microSecondsInDay) {
        windowStart++;
      }
      if (windowEnd - windowStart + 1 >= _minBaseActiveDaysInWindow) {
        return true;
      }
    }
    return false;
  }

  // ── Merge trips across temporal blocks ──

  static List<TripMemory> _mergeNearbyTrips(List<TripMemory> trips) {
    final sortedTrips = List<TripMemory>.from(trips)
      ..sort(
        (a, b) => a.firstCreationTime!.compareTo(b.firstCreationTime!),
      );
    final merged = <TripMemory>[];
    for (final trip in sortedTrips) {
      final tripFirst = DateTime.fromMicrosecondsSinceEpoch(
        trip.firstCreationTime!,
      );
      final tripLast = DateTime.fromMicrosecondsSinceEpoch(
        trip.lastCreationTime!,
      );
      bool didMerge = false;
      for (int i = 0; i < merged.length; i++) {
        final other = merged[i];
        final otherFirst = DateTime.fromMicrosecondsSinceEpoch(
          other.firstCreationTime!,
        );
        final otherLast = DateTime.fromMicrosecondsSinceEpoch(
          other.lastCreationTime!,
        );
        final timeClose = tripFirst.isBefore(
              otherLast.add(const Duration(days: _mergeWindowDays)),
            ) &&
            tripLast.isAfter(
              otherFirst.subtract(const Duration(days: _mergeWindowDays)),
            );
        final spaceClose = calculateDistance(trip.location, other.location) <
            _mergeMaxDistance;
        final mergedFirst =
            tripFirst.isBefore(otherFirst) ? tripFirst : otherFirst;
        final mergedLast = tripLast.isAfter(otherLast) ? tripLast : otherLast;
        final mergedSpanDays = mergedLast.difference(mergedFirst).inDays;
        if (timeClose && spaceClose && mergedSpanDays <= _maxTripDays) {
          final combinedMemories = other.memories + trip.memories;
          merged[i] = TripMemory(
            combinedMemories,
            0,
            0,
            _representativeLocationFromMemories(combinedMemories),
            firstCreationTime:
                min(other.firstCreationTime!, trip.firstCreationTime!),
            lastCreationTime:
                max(other.lastCreationTime!, trip.lastCreationTime!),
          );
          didMerge = true;
          break;
        }
      }
      if (!didMerge) merged.add(trip);
    }
    return merged;
  }

  static bool _isNearAnyBase(
    Location location,
    List<BaseLocation> baseLocations,
  ) {
    for (final baseLocation in baseLocations) {
      if (isFileInsideLocationTag(
        baseLocation.location,
        location,
        _baseOverlapRadius,
      )) {
        return true;
      }
    }
    return false;
  }

  static Location _representativeLocationFromMemories(List<Memory> memories) {
    return _representativeLocationFromFiles(Memory.filesFromMemories(memories));
  }

  static Location _representativeLocationFromFiles(Iterable<EnteFile> files) {
    final filesWithLocation =
        files.where((file) => file.hasLocation).toList(growable: false);
    assert(filesWithLocation.isNotEmpty);

    double latitudeSum = 0;
    double longitudeSum = 0;
    for (final file in filesWithLocation) {
      latitudeSum += file.location!.latitude!;
      longitudeSum += file.location!.longitude!;
    }

    return Location(
      latitude: latitudeSum / filesWithLocation.length,
      longitude: longitudeSum / filesWithLocation.length,
    );
  }

  // ── Surface all (debug mode) ──

  static Future<(List<TripMemory>, List<BaseLocation>)> _surfaceAll(
    List<TripMemory> memoryResults,
    List<BaseLocation> baseLocations,
    List<TripMemory> validTrips,
    Map<int, EnteFile> allFileIdsToFile,
    int nowInMicroseconds,
    int windowEnd, {
    required Map<int, int> seenTimes,
    required bool isOfflineMode,
    required Map<int, List<FaceWithoutEmbedding>> fileIdToFaces,
    required Map<String, String> faceIDsToPersonID,
    required Map<int, EmbeddingVector> fileIDToImageEmbedding,
    required Vector clipPositiveTextVector,
    required List<City> cities,
  }) async {
    for (final baseLocation in baseLocations) {
      String name = "Base (${baseLocation.isCurrentBase ? 'current' : 'old'})";
      final files = baseLocation.fileIDs
          .map((fileID) => allFileIdsToFile[fileID]!)
          .toList();
      final String? locationName = SmartMemoriesService._tryFindLocationName(
        Memory.fromFiles(files, seenTimes),
        cities,
        base: true,
      );
      if (locationName != null) {
        name =
            "$locationName (Base, ${baseLocation.isCurrentBase ? 'current' : 'old'})";
      }
      memoryResults.add(
        TripMemory(
          Memory.fromFiles(files, seenTimes),
          nowInMicroseconds,
          windowEnd,
          baseLocation.location,
          locationName: name,
        ),
      );
    }
    for (final trip in validTrips) {
      final year = DateTime.fromMicrosecondsSinceEpoch(
        trip.averageCreationTime(),
      ).year;
      final String? locationName = SmartMemoriesService._tryFindLocationName(
        trip.memories,
        cities,
      );
      final photoSelection = await SmartMemoriesService._bestSelection(
        trip.memories,
        isOfflineMode: isOfflineMode,
        fileIdToFaces: fileIdToFaces,
        faceIDsToPersonID: faceIDsToPersonID,
        fileIDToImageEmbedding: fileIDToImageEmbedding,
        clipPositiveTextVector: clipPositiveTextVector,
      );
      memoryResults.add(
        trip.copyWith(
          memories: photoSelection,
          tripYear: year,
          locationName: locationName,
          firstDateToShow: nowInMicroseconds,
          lastDateToShow: windowEnd,
        ),
      );
    }
    return (memoryResults, baseLocations);
  }

  // ── Surface scheduled (production mode) ──

  static Future<(List<TripMemory>, List<BaseLocation>)> _surfaceScheduled(
    List<TripMemory> memoryResults,
    List<BaseLocation> baseLocations,
    List<TripMemory> validTrips,
    DateTime currentTime,
    int currentMonth,
    int nowInMicroseconds,
    int windowEnd,
    List<TripsShownLog> shownTrips, {
    required bool isOfflineMode,
    required Map<int, int> seenTimes,
    required Map<int, List<FaceWithoutEmbedding>> fileIdToFaces,
    required Map<String, String> faceIDsToPersonID,
    required Map<int, EmbeddingVector> fileIDToImageEmbedding,
    required Vector clipPositiveTextVector,
    required List<City> cities,
  }) async {
    final Map<int, Map<int, List<TripMemory>>> tripsByMonthYear = {};
    for (final trip in validTrips) {
      final tripDate =
          DateTime.fromMicrosecondsSinceEpoch(trip.averageCreationTime());
      tripsByMonthYear
          .putIfAbsent(tripDate.month, () => {})
          .putIfAbsent(tripDate.year, () => [])
          .add(trip);
    }

    final List<TripMemory> currentMonthTrips = [];
    if (tripsByMonthYear.containsKey(currentMonth)) {
      for (final trips in tripsByMonthYear[currentMonth]!.values) {
        currentMonthTrips.addAll(trips);
      }
    }

    if (currentMonthTrips.isNotEmpty) {
      currentMonthTrips.sort(
        (a, b) => b.averageCreationTime().compareTo(a.averageCreationTime()),
      );
      final tripsToShow = currentMonthTrips.take(2);
      for (final trip in tripsToShow) {
        final year =
            DateTime.fromMicrosecondsSinceEpoch(trip.averageCreationTime())
                .year;
        final String? locationName = SmartMemoriesService._tryFindLocationName(
          trip.memories,
          cities,
        );
        final photoSelection = await SmartMemoriesService._bestSelection(
          trip.memories,
          isOfflineMode: isOfflineMode,
          fileIdToFaces: fileIdToFaces,
          faceIDsToPersonID: faceIDsToPersonID,
          fileIDToImageEmbedding: fileIDToImageEmbedding,
          clipPositiveTextVector: clipPositiveTextVector,
        );
        final firstCreationDate = DateTime.fromMicrosecondsSinceEpoch(
          trip.firstCreationTime!,
        );
        final firstDateToShow = DateTime(
          currentTime.year,
          firstCreationDate.month,
          firstCreationDate.day,
        ).subtract(kMemoriesMargin).microsecondsSinceEpoch;
        final lastCreationDate = DateTime.fromMicrosecondsSinceEpoch(
          trip.lastCreationTime!,
        );
        final lastDateToShow = DateTime(
          currentTime.year,
          lastCreationDate.month,
          lastCreationDate.day,
        ).add(kMemoriesMargin).microsecondsSinceEpoch;
        memoryResults.add(
          trip.copyWith(
            memories: photoSelection,
            tripYear: year,
            locationName: locationName,
            firstDateToShow: firstDateToShow,
            lastDateToShow: lastDateToShow,
          ),
        );
      }
    } else {
      final sortedUpcomingMonths =
          List<int>.generate(6, (i) => ((currentMonth + i) % 12) + 1);
      checkUpcomingMonths:
      for (final month in sortedUpcomingMonths) {
        if (tripsByMonthYear.containsKey(month)) {
          final List<TripMemory> thatMonthTrips = [];
          for (final trips in tripsByMonthYear[month]!.values) {
            thatMonthTrips.addAll(trips);
          }
          if (thatMonthTrips.length >= 3) {
            thatMonthTrips.sort(
              (a, b) =>
                  a.averageCreationTime().compareTo(b.averageCreationTime()),
            );
            checkPotentialTrips:
            for (final trip in thatMonthTrips.sublist(2)) {
              for (final shownTrip in shownTrips) {
                final distance =
                    calculateDistance(trip.location, shownTrip.location);
                final shownTripDate = DateTime.fromMicrosecondsSinceEpoch(
                  shownTrip.lastTimeShown,
                );
                final shownRecently =
                    currentTime.difference(shownTripDate) < kTripShowTimeout;
                if (distance < _baseOverlapRadius && shownRecently) {
                  continue checkPotentialTrips;
                }
              }
              final year = DateTime.fromMicrosecondsSinceEpoch(
                trip.averageCreationTime(),
              ).year;
              final String? locationName =
                  SmartMemoriesService._tryFindLocationName(
                trip.memories,
                cities,
              );
              final photoSelection = await SmartMemoriesService._bestSelection(
                trip.memories,
                isOfflineMode: isOfflineMode,
                fileIdToFaces: fileIdToFaces,
                faceIDsToPersonID: faceIDsToPersonID,
                fileIDToImageEmbedding: fileIDToImageEmbedding,
                clipPositiveTextVector: clipPositiveTextVector,
              );
              memoryResults.add(
                trip.copyWith(
                  memories: photoSelection,
                  tripYear: year,
                  locationName: locationName,
                  firstDateToShow: nowInMicroseconds,
                  lastDateToShow: windowEnd,
                ),
              );
              break checkUpcomingMonths;
            }
          }
        }
      }
    }
    return (memoryResults, baseLocations);
  }
}
