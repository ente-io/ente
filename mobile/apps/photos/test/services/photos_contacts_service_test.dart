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
    expect(service.getCachedSavedNameByUserId(7), 'Alice');
    expect(service.getCachedResolvedEmailByUserId(7), 'alice@test.test');
    expect(await service.getContactByUserId(7), isNotNull);
    expect(contactsService.openCalls, 1);
    expect(contactsService.syncCalls, 1);
  });
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
  int openCalls = 0;
  int syncCalls = 0;

  @override
  Future<void> open(contacts.ContactsSession session) async {
    openCalls += 1;
  }

  @override
  Future<List<contacts.ContactRecord>> getContacts({
    bool includeDeleted = false,
  }) async {
    return localContacts;
  }

  @override
  Future<List<contacts.ContactRecord>> sync() async {
    syncCalls += 1;
    final error = syncError;
    if (error != null) {
      throw error;
    }
    return syncDiff;
  }
}
