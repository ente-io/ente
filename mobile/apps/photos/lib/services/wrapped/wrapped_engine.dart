import "package:computer/computer.dart";
import "package:logging/logging.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/search_service.dart";
import "package:photos/services/wrapped/candidate_builders.dart";
import "package:photos/services/wrapped/models.dart";

final Logger _engineLogger = Logger("WrappedEngine");
final Logger _computeLogger = Logger("WrappedEngineIsolate");

/// Orchestrates the single-isolate computation pipeline for Ente Wrapped.
class WrappedEngine {
  const WrappedEngine._();

  /// Schedules the compute pipeline on a worker isolate.
  static Future<WrappedResult> compute({required int year}) async {
    final DateTime now = DateTime.now();
    _engineLogger.fine("Scheduling Wrapped compute for $year at $now");

    final List<EnteFile> yearFiles = await _collectFilesForYear(year);
    _engineLogger.fine(
      "Collected ${yearFiles.length} media items for Wrapped $year compute",
    );

    return await Computer.shared().compute(
      _wrappedComputeIsolate,
      param: <String, Object?>{
        "year": year,
        "now": now,
        "files": yearFiles,
      },
      taskName: "wrapped_compute_$year",
    ) as WrappedResult;
  }

  static Future<List<EnteFile>> _collectFilesForYear(int year) async {
    final List<EnteFile> allFiles =
        await SearchService.instance.getAllFilesForSearch();
    final List<EnteFile> filtered = <EnteFile>[];
    for (final EnteFile file in allFiles) {
      if (!file.isOwner) {
        continue;
      }
      final int? creationTime = file.creationTime;
      if (creationTime == null) {
        continue;
      }
      final DateTime captured =
          DateTime.fromMicrosecondsSinceEpoch(creationTime);
      if (captured.year != year) {
        continue;
      }
      filtered.add(file);
    }

    filtered.sort(
      (EnteFile a, EnteFile b) {
        final int aTime = a.creationTime ?? 0;
        final int bTime = b.creationTime ?? 0;
        if (aTime != bTime) return aTime.compareTo(bTime);
        final int aId = a.uploadedFileID ?? a.generatedID ?? 0;
        final int bId = b.uploadedFileID ?? b.generatedID ?? 0;
        return aId.compareTo(bId);
      },
    );

    return filtered;
  }
}

Future<WrappedResult> _wrappedComputeIsolate(
  Map<String, Object?> args,
) async {
  final int year = args["year"] as int;
  final DateTime now = args["now"] as DateTime;
  final List<EnteFile> files =
      (args["files"] as List<dynamic>? ?? const <dynamic>[])
          .cast<EnteFile>();

  _computeLogger.fine(
    "Wrapped compute isolate running for $year with ${files.length} media items",
  );

  final WrappedEngineContext context = WrappedEngineContext(
    year: year,
    now: now,
    files: files,
  );
  final List<WrappedCard> cards = <WrappedCard>[];
  for (final WrappedCandidateBuilder builder in wrappedCandidateBuilders) {
    _computeLogger.finer("Running candidate builder ${builder.debugLabel}");
    final List<WrappedCard> builtCards = await builder.build(context);
    if (builtCards.isEmpty) {
      continue;
    }
    cards.addAll(builtCards);
  }

  if (cards.isEmpty) {
    cards.add(
      WrappedCard(
        type: WrappedCardType.badge,
        title: "Wrapped $year is on its way",
        subtitle: "Full story coming soon.",
        meta: <String, Object?>{
          "generatedAt": now.toIso8601String(),
          "isStub": true,
        },
      ),
    );
  }

  return WrappedResult(
    cards: cards,
    year: year,
  );
}
