import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:ente_contacts/contacts.dart' as contacts;
import 'package:flutter_test/flutter_test.dart';
import 'package:photos/services/photos_contacts_service.dart';

void main() {
  late FakeContactsService contactsService;
  late PhotosContactsService service;
  late contacts.ContactsSession session;

  setUp(() {
    contactsService = FakeContactsService(
      localContacts: const [
        contacts.ContactRecord(
          id: 'ct_1',
          contactUserId: 7,
          email: 'alice@test.test',
          data: contacts.ContactData(contactUserId: 7, name: 'Alice'),
          profilePictureAttachmentId: null,
          isDeleted: false,
          createdAt: 1,
          updatedAt: 2,
        ),
      ],
      syncError: StateError('boom'),
    );
    service = PhotosContactsService.forTesting(contactsService: contactsService);
    session = contacts.ContactsSession(
      baseUrl: 'http://localhost:8080',
      authToken: 'token',
      userId: 1,
      accountKey: Uint8List.fromList([1, 2, 3]),
    );
  });

  test('debugOpenAndSync hydrates local cache even when sync fails', () async {
    await service.debugOpenAndSync(session);

    expect(service.hasHydratedCache, isTrue);
    expect(service.getCachedContactByUserId(7), isNotNull);
    expect(service.getCachedSavedNameByUserId(7), 'Alice');
    expect(service.getCachedResolvedEmailByUserId(7), 'alice@test.test');
    expect(contactsService.openCalls, 1);
    expect(contactsService.syncCalls, 1);
  });

  test(
    'stale in-flight debugOpenAndSync does not repopulate cache after session switch',
    () async {
      contactsService.getContactsBarrier = Completer<void>();
      contactsService.getContactsStarted = Completer<void>();
      contactsService.localContactsPages = Queue<List<contacts.ContactRecord>>.of([
        const [
          contacts.ContactRecord(
            id: 'ct_old',
            contactUserId: 7,
            email: 'alice@test.test',
            data: contacts.ContactData(contactUserId: 7, name: 'Alice'),
            profilePictureAttachmentId: null,
            isDeleted: false,
            createdAt: 1,
            updatedAt: 2,
          ),
        ],
        const [
          contacts.ContactRecord(
            id: 'ct_new',
            contactUserId: 9,
            email: 'bob@test.test',
            data: contacts.ContactData(contactUserId: 9, name: 'Bob'),
            profilePictureAttachmentId: null,
            isDeleted: false,
            createdAt: 3,
            updatedAt: 4,
          ),
        ],
      ]);
      contactsService.syncPages = Queue<List<contacts.ContactRecord>>.of([
        const [],
        const [],
      ]);

      final oldOpenAndSync = service.debugOpenAndSync(session);
      await contactsService.getContactsStarted!.future;

      final nextSession = contacts.ContactsSession(
        baseUrl: session.baseUrl,
        authToken: 'token-2',
        userId: 2,
        accountKey: Uint8List.fromList([9, 9, 9]),
      );
      await service.debugOpenAndSync(nextSession);

      expect(service.getCachedSavedNameByUserId(9), 'Bob');
      expect(service.getCachedSavedNameByUserId(7), isNull);

      contactsService.getContactsBarrier!.complete();
      await oldOpenAndSync;

      expect(service.getCachedSavedNameByUserId(9), 'Bob');
      expect(service.getCachedResolvedEmailByUserId(9), 'bob@test.test');
      expect(service.getCachedSavedNameByUserId(7), isNull);
      expect(service.getCachedResolvedEmailByUserId(7), isNull);
    },
  );
}

class FakeContactsService extends Fake implements contacts.ContactsService {
  FakeContactsService({
    required this.localContacts,
    this.syncDiff = const [],
    this.syncError,
  });

  final List<contacts.ContactRecord> localContacts;
  final List<contacts.ContactRecord> syncDiff;
  final Object? syncError;
  Queue<List<contacts.ContactRecord>>? localContactsPages;
  Queue<List<contacts.ContactRecord>>? syncPages;
  Completer<void>? getContactsBarrier;
  Completer<void>? getContactsStarted;
  int openCalls = 0;
  int syncCalls = 0;
  int getContactsCalls = 0;

  @override
  Future<void> open(contacts.ContactsSession session) async {
    openCalls += 1;
  }

  @override
  Future<List<contacts.ContactRecord>> getContacts({
    bool includeDeleted = false,
  }) async {
    getContactsCalls += 1;
    final pages = localContactsPages;
    final response = pages != null && pages.isNotEmpty
        ? pages.removeFirst()
        : localContacts;
    final started = getContactsStarted;
    if (started != null && !started.isCompleted) {
      started.complete();
    }
    final barrier = getContactsBarrier;
    if (getContactsCalls == 1 && barrier != null && !barrier.isCompleted) {
      await barrier.future;
    }
    return response;
  }

  @override
  Future<List<contacts.ContactRecord>> sync() async {
    syncCalls += 1;
    final pages = syncPages;
    if (pages != null && pages.isNotEmpty) {
      return pages.removeFirst();
    }
    final error = syncError;
    if (error != null) {
      throw error;
    }
    return syncDiff;
  }
}
