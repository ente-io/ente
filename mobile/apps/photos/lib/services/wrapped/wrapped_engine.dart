import "package:computer/computer.dart";
import "package:logging/logging.dart";

import "candidate_builders.dart";
import "models.dart";

final Logger _engineLogger = Logger("WrappedEngine");
final Logger _computeLogger = Logger("WrappedEngineIsolate");

/// Orchestrates the single-isolate computation pipeline for Ente Wrapped.
class WrappedEngine {
  const WrappedEngine._();

  /// Schedules the compute pipeline on a worker isolate.
  static Future<WrappedResult> compute({required int year}) async {
    final DateTime now = DateTime.now();
    _engineLogger.fine("Scheduling Wrapped compute for $year at $now");

    return await Computer.shared().compute(
      _wrappedComputeIsolate,
      param: <String, Object?>{
        "year": year,
        "now": now,
      },
      taskName: "wrapped_compute_$year",
    ) as WrappedResult;
  }
}

Future<WrappedResult> _wrappedComputeIsolate(
  Map<String, Object?> args,
) async {
  final int year = args["year"] as int;
  final DateTime now = args["now"] as DateTime;

  _computeLogger.fine("Wrapped compute isolate running for $year");

  final WrappedEngineContext context = WrappedEngineContext(year: year, now: now);
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
