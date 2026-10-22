import 'package:ente_sharing/models/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locker/services/collections/collection_selectors.dart';
import 'package:locker/services/collections/models/collection.dart';

Collection collection(
  int id, {
  required int ownerID,
  required CollectionType type,
  String? name,
  bool isDeleted = false,
}) => Collection(
  id,
  User(id: ownerID, email: '$ownerID@example.com'),
  '',
  null,
  name,
  null,
  null,
  type,
  CollectionAttributes(),
  const [],
  const [],
  0,
  isDeleted: isDeleted,
);

void main() {
  for (final (type, name) in const [
    (CollectionType.favorites, null),
    (CollectionType.folder, 'Documents'),
  ]) {
    group('$type default', () {
      final foreign = collection(1, ownerID: 2, type: type, name: name);
      final owned = collection(2, ownerID: 1, type: type, name: name);
      final deleted = collection(
        3,
        ownerID: 1,
        type: type,
        name: name,
        isDeleted: true,
      );

      Collection? select(Iterable<Collection> collections, int ownerID) =>
          findOwnedCollection(
            collections,
            ownerID: ownerID,
            type: type,
            name: name,
          );

      test('selects the live owned match', () {
        final wrongType = collection(
          4,
          ownerID: 1,
          type: CollectionType.uncategorized,
          name: name,
        );
        expect(select([foreign, deleted, wrongType, owned], 1), same(owned));
      });

      test('returns no match when only foreign or deleted defaults exist', () {
        expect(select([foreign, deleted], 1), isNull);
      });

      test('uses the current account owner', () {
        expect(select([owned, foreign], 2), same(foreign));
      });
    });
  }

  test('Documents requires its exact folder name', () {
    final otherFolder = collection(
      1,
      ownerID: 1,
      type: CollectionType.folder,
      name: 'Other',
    );
    expect(
      findOwnedCollection(
        [otherFolder],
        ownerID: 1,
        type: CollectionType.folder,
        name: 'Documents',
      ),
      isNull,
    );
  });
}
