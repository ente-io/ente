import 'dart:io';
import 'dart:typed_data';

import 'package:ente_contacts/contacts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  late ContactsDatabase database;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ente_contacts_db_test');
    database = ContactsDatabase(directoryResolver: () async => tempDir);
  });

  tearDown(() async {
    await database.clearTable();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('stores contacts in user-scoped databases', () async {
    await database.configure(userId: 1);
    await database.upsertContacts([
      const ContactRecord(
        id: 'ct_1',
        contactUserId: 200,
        email: 'a@test.test',
        data: ContactData(contactUserId: 200, name: 'A'),
        profilePictureAttachmentId: null,
        isDeleted: false,
        createdAt: 10,
        updatedAt: 20,
      ),
    ]);

    expect((await database.getContacts()).length, 1);

    await database.configure(userId: 2);
    expect(await database.getContacts(), isEmpty);

    await database.configure(userId: 1);
    expect((await database.getContacts()).single.id, 'ct_1');
    expect((await database.getContacts()).single.email, 'a@test.test');
  });

  test('clearTable removes all contacts databases', () async {
    await database.configure(userId: 1);
    await database.upsertContacts([
      const ContactRecord(
        id: 'ct_1',
        contactUserId: 200,
        email: 'a@test.test',
        data: ContactData(contactUserId: 200, name: 'A'),
        profilePictureAttachmentId: null,
        isDeleted: false,
        createdAt: 10,
        updatedAt: 20,
      ),
    ]);
    await database.configure(userId: 2);
    await database.upsertContacts([
      const ContactRecord(
        id: 'ct_2',
        contactUserId: 201,
        email: 'b@test.test',
        data: ContactData(contactUserId: 201, name: 'B'),
        profilePictureAttachmentId: null,
        isDeleted: false,
        createdAt: 11,
        updatedAt: 21,
      ),
    ]);

    await database.clearTable();

    final remaining = tempDir
        .listSync()
        .map((entity) => entity.path.split(Platform.pathSeparator).last)
        .where((name) => name.startsWith('ente.contacts.'))
        .toList();
    expect(remaining, isEmpty);
  });

  test('stores, fetches, deletes, and prunes cached attachments', () async {
    await database.configure(userId: 1);
    await database.upsertContacts([
      const ContactRecord(
        id: 'ct_1',
        contactUserId: 200,
        email: 'a@test.test',
        data: ContactData(contactUserId: 200, name: 'A'),
        profilePictureAttachmentId: 'att_keep',
        isDeleted: false,
        createdAt: 10,
        updatedAt: 20,
      ),
    ]);
    await database.upsertCachedAttachment(
      'att_keep',
      Uint8List.fromList([1, 2, 3]),
    );
    await database.upsertCachedAttachment(
      'att_drop',
      Uint8List.fromList([4, 5, 6]),
    );

    expect(
      await database.getCachedAttachment('att_keep'),
      Uint8List.fromList([1, 2, 3]),
    );

    await database.deleteCachedAttachment('att_keep');
    expect(await database.getCachedAttachment('att_keep'), isNull);

    await database.upsertCachedAttachment(
      'att_keep',
      Uint8List.fromList([1, 2, 3]),
    );
    await database.deleteUnreferencedCachedAttachments();

    expect(
      await database.getCachedAttachment('att_keep'),
      Uint8List.fromList([1, 2, 3]),
    );
    expect(await database.getCachedAttachment('att_drop'), isNull);
  });
}
