part of "smart_memories_service.dart";

class TripMemoriesCalculator {
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
    final List<TripMemory> memoryResults = [];
    if (allFiles.isEmpty) return (<TripMemory>[], <BaseLocation>[]);
    final nowInMicroseconds = currentTime.microsecondsSinceEpoch;
    final windowEnd =
        currentTime.add(kMemoriesUpdateFrequency).microsecondsSinceEpoch;
    final currentMonth = currentTime.month;
    final cutOffTime = currentTime.subtract(const Duration(days: 365));

    const tripRadius = 100.0;
    const overlapRadius = 10.0;

    final List<(List<EnteFile>, Location)> smallRadiusClusters = [];
    final List<(List<EnteFile>, Location)> wideRadiusClusters = [];
    for (EnteFile file in allFiles) {
      if (!file.hasLocation) continue;
      bool addedToExistingSmallCluster = false;
      for (final cluster in smallRadiusClusters) {
        final clusterLocation = cluster.$2;
        if (isFileInsideLocationTag(
          clusterLocation,
          file.location!,
          baseRadius,
        )) {
          cluster.$1.add(file);
          addedToExistingSmallCluster = true;
          break;
        }
      }
      if (!addedToExistingSmallCluster) {
        smallRadiusClusters.add(([file], file.location!));
      }
      bool addedToExistingWideCluster = false;
      for (final cluster in wideRadiusClusters) {
        final clusterLocation = cluster.$2;
        if (isFileInsideLocationTag(
          clusterLocation,
          file.location!,
          tripRadius,
        )) {
          cluster.$1.add(file);
          addedToExistingWideCluster = true;
          break;
        }
      }
      if (!addedToExistingWideCluster) {
        wideRadiusClusters.add(([file], file.location!));
      }
    }

    final List<BaseLocation> baseLocations = [];
    for (final cluster in smallRadiusClusters) {
      final files = cluster.$1;
      final location = cluster.$2;
      final creationTimes = <int>[];
      final Set<int> uniqueDays = {};
      for (final file in files) {
        creationTimes.add(file.creationTime!);
        final date = DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
        final dayStamp =
            DateTime(date.year, date.month, date.day).microsecondsSinceEpoch;
        uniqueDays.add(dayStamp);
      }
      creationTimes.sort();
      if (creationTimes.length < 10) continue;
      final firstCreationTime = DateTime.fromMicrosecondsSinceEpoch(
        creationTimes.first,
      );
      final lastCreationTime = DateTime.fromMicrosecondsSinceEpoch(
        creationTimes.last,
      );
      final daysRange = lastCreationTime.difference(firstCreationTime).inDays;
      if (daysRange < 90) {
        continue;
      }
      if (uniqueDays.length < daysRange * 0.1) continue;
      final int gapThreshold = (daysRange * 0.6).round() * microSecondsInDay;
      int maxGap = 0;
      for (int i = 1; i < creationTimes.length; i++) {
        final gap = creationTimes[i] - creationTimes[i - 1];
        if (gap > maxGap) maxGap = gap;
      }
      if (maxGap > gapThreshold) continue;
      final bool isCurrent = lastCreationTime.isAfter(
        DateTime.now().subtract(
          const Duration(days: 90),
        ),
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

    final List<TripMemory> tripLocations = [];
    clusteredLocations:
    for (final cluster in wideRadiusClusters) {
      final files = cluster.$1;
      final location = cluster.$2;
      for (final baseLocation in baseLocations) {
        if (isFileInsideLocationTag(
          baseLocation.location,
          location,
          overlapRadius,
        )) {
          continue clusteredLocations;
        }
      }

      files.sort((a, b) => a.creationTime!.compareTo(b.creationTime!));
      List<EnteFile> currentBlockFiles = [files.first];
      int blockStart = files.first.creationTime!;
      int lastTime = files.first.creationTime!;
      DateTime lastDateTime = DateTime.fromMicrosecondsSinceEpoch(lastTime);

      for (int i = 1; i < files.length; i++) {
        final currentFile = files[i];
        final currentTime = currentFile.creationTime!;
        final gap = DateTime.fromMicrosecondsSinceEpoch(currentTime)
            .difference(lastDateTime)
            .inDays;

        if (gap > 15) {
          if (gap < 90) continue clusteredLocations;

          final blockDuration = lastDateTime
              .difference(DateTime.fromMicrosecondsSinceEpoch(blockStart))
              .inDays;

          if (blockDuration >= 2 && blockDuration <= 30) {
            tripLocations.add(
              TripMemory(
                Memory.fromFiles(
                  currentBlockFiles,
                  seenTimes,
                ),
                0,
                0,
                location,
                firstCreationTime: blockStart,
                lastCreationTime: lastTime,
              ),
            );
          }

          currentBlockFiles = [];
          blockStart = currentTime;
        }

        currentBlockFiles.add(currentFile);
        lastTime = currentTime;
        lastDateTime = DateTime.fromMicrosecondsSinceEpoch(lastTime);
      }
      final lastBlockDuration = lastDateTime
          .difference(DateTime.fromMicrosecondsSinceEpoch(blockStart))
          .inDays;
      if (lastBlockDuration >= 2 && lastBlockDuration <= 30) {
        tripLocations.add(
          TripMemory(
            Memory.fromFiles(currentBlockFiles, seenTimes),
            0,
            0,
            location,
            firstCreationTime: blockStart,
            lastCreationTime: lastTime,
          ),
        );
      }
    }

    final List<TripMemory> mergedTrips = [];
    for (final trip in tripLocations) {
      final tripFirstTime = DateTime.fromMicrosecondsSinceEpoch(
        trip.firstCreationTime!,
      );
      final tripLastTime = DateTime.fromMicrosecondsSinceEpoch(
        trip.lastCreationTime!,
      );
      bool merged = false;
      for (int idx = 0; idx < mergedTrips.length; idx++) {
        final otherTrip = mergedTrips[idx];
        final otherTripFirstTime =
            DateTime.fromMicrosecondsSinceEpoch(otherTrip.firstCreationTime!);
        final otherTripLastTime =
            DateTime.fromMicrosecondsSinceEpoch(otherTrip.lastCreationTime!);
        if (tripFirstTime
                .isBefore(otherTripLastTime.add(const Duration(days: 3))) &&
            tripLastTime.isAfter(
              otherTripFirstTime.subtract(const Duration(days: 3)),
            )) {
          mergedTrips[idx] = TripMemory(
            otherTrip.memories + trip.memories,
            0,
            0,
            otherTrip.location,
            firstCreationTime:
                min(otherTrip.firstCreationTime!, trip.firstCreationTime!),
            lastCreationTime:
                max(otherTrip.lastCreationTime!, trip.lastCreationTime!),
          );
          dev.log('Merged two trip locations');
          merged = true;
          break;
        }
      }
      if (merged) continue;
      mergedTrips.add(
        TripMemory(
          trip.memories,
          0,
          0,
          trip.location,
          firstCreationTime: trip.firstCreationTime,
          lastCreationTime: trip.lastCreationTime,
        ),
      );
    }

    final List<TripMemory> validTrips = [];
    for (final trip in mergedTrips) {
      if (trip.memories.length >= 20 &&
          trip.averageCreationTime() < cutOffTime.microsecondsSinceEpoch) {
        validTrips.add(trip);
      }
    }

    if (surfaceAll) {
      for (final baseLocation in baseLocations) {
        String name =
            "Base (${baseLocation.isCurrentBase ? 'current' : 'old'})";
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
        for (final trip in trips) {
          currentMonthTrips.add(trip);
        }
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
                if (distance < overlapRadius && shownRecently) {
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
