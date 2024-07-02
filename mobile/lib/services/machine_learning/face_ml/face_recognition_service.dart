import "dart:async" show unawaited;

import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/diff_sync_complete_event.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";

class FaceRecognitionService {
  final _logger = Logger("FaceRecognitionService");

  // Singleton pattern
  FaceRecognitionService._privateConstructor();
  static final instance = FaceRecognitionService._privateConstructor();
  factory FaceRecognitionService() => instance;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  bool _shouldSyncPeople = false;
  bool _isSyncing = false;

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }
    _logger.info("init called");

    // Listen on DiffSync
    Bus.instance.on<DiffSyncCompleteEvent>().listen((event) async {
      unawaited(sync());
    });

    // Listen on PeopleChanged
    Bus.instance.on<PeopleChangedEvent>().listen((event) {
      if (event.type == PeopleEventType.syncDone) return;
      _shouldSyncPeople = true;
    });

    _isInitialized = true;
    _logger.info('init done');
  }

  Future<void> sync() async {
    if (_isSyncing) {
      return;
    }
    _isSyncing = true;
    if (_shouldSyncPeople) {
      await PersonService.instance.reconcileClusters();
      Bus.instance.fire(PeopleChangedEvent(type: PeopleEventType.syncDone));
      _shouldSyncPeople = false;
    }
    _isSyncing = false;
  }
}
