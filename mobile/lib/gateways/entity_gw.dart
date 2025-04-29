import "package:dio/dio.dart";
import "package:photos/models/api/entity/data.dart";
import "package:photos/models/api/entity/key.dart";
import "package:photos/models/api/entity/type.dart";

class EntityGateway {
  final Dio _enteDio;

  EntityGateway(this._enteDio);

  Future<void> createKey(
    EntityType entityType,
    String encKey,
    String header,
  ) async {
    await _enteDio.post(
      "/user-entity/key",
      data: {
        "type": entityType.typeToString(),
        "encryptedKey": encKey,
        "header": header,
      },
    );
  }

  Future<EntityKey> getKey(EntityType type) async {
    try {
      final response = await _enteDio.get(
        "/user-entity/key",
        queryParameters: {
          "type": type.typeToString(),
        },
      );
      return EntityKey.fromMap(response.data);
    } on DioException catch (e) {
      if (e.response != null && (e.response!.statusCode ?? 0) == 404) {
        throw EntityKeyNotFound();
      } else {
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<EntityData> createEntity(
    EntityType type,
    String encryptedData,
    String header,
  ) async {
    final response = await _enteDio.post(
      "/user-entity/entity",
      data: {
        "encryptedData": encryptedData,
        "header": header,
        "type": type.typeToString(),
      },
    );
    return EntityData.fromMap(response.data);
  }

  Future<EntityData> updateEntity(
    EntityType type,
    String id,
    String encryptedData,
    String header,
  ) async {
    final response = await _enteDio.put(
      "/user-entity/entity",
      data: {
        "id": id,
        "encryptedData": encryptedData,
        "header": header,
        "type": type.typeToString(),
      },
    );
    return EntityData.fromMap(response.data);
  }

  Future<void> deleteEntity(
    String id,
  ) async {
    await _enteDio.delete(
      "/user-entity/entity",
      queryParameters: {
        "id": id,
      },
    );
  }

  Future<List<EntityData>> getDiff(
    EntityType type,
    int sinceTime, {
    int limit = 500,
  }) async {
    final response = await _enteDio.get(
      "/user-entity/entity/diff",
      queryParameters: {
        "sinceTime": sinceTime,
        "limit": limit,
        "type": type.typeToString(),
      },
    );
    final List<EntityData> authEntities = <EntityData>[];
    final diff = response.data["diff"] as List;
    for (var entry in diff) {
      final EntityData entity = EntityData.fromMap(entry);
      authEntities.add(entity);
    }
    return authEntities;
  }
}

class EntityKeyNotFound extends Error {}
