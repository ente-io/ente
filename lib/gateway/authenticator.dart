import 'package:dio/dio.dart';
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/core/errors.dart';
import 'package:ente_auth/models/authenticator/auth_entity.dart';
import 'package:ente_auth/models/authenticator/auth_key.dart';

class AuthenticatorGateway {
  final Dio _dio;
  final Configuration _config;
  late String _basedEndpoint;

  AuthenticatorGateway(this._dio, this._config) {
    _basedEndpoint = _config.getHttpEndpoint() + "/authenticator";
  }

  Future<void> createKey(String encKey, String header) async {
    await _dio.post(
      _basedEndpoint + "/key",
      data: {
        "encryptedKey": encKey,
        "header": header,
      },
      options: Options(
        headers: {
          "X-Auth-Token": _config.getToken(),
        },
      ),
    );
  }

  Future<AuthKey> getKey() async {
    try {
      final response = await _dio.get(
        _basedEndpoint + "/key",
        options: Options(
          headers: {
            "X-Auth-Token": _config.getToken(),
          },
        ),
      );
      return AuthKey.fromMap(response.data);
    } on DioError catch (e) {
      if (e.response != null && (e.response!.statusCode ?? 0) == 404) {
        throw AuthenticatorKeyNotFound();
      } else {
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthEntity> createEntity(String encryptedData, String header) async {
    final response = await _dio.post(
      _basedEndpoint + "/entity",
      data: {
        "encryptedData": encryptedData,
        "header": header,
      },
      options: Options(
        headers: {
          "X-Auth-Token": _config.getToken(),
        },
      ),
    );
    return AuthEntity.fromMap(response.data);
  }

  Future<void> updateEntity(
    String id,
    String encryptedData,
    String header,
  ) async {
    await _dio.put(
      _basedEndpoint + "/entity",
      data: {
        "id": id,
        "encryptedData": encryptedData,
        "header": header,
      },
      options: Options(
        headers: {
          "X-Auth-Token": _config.getToken(),
        },
      ),
    );
  }

  Future<void> deleteEntity(
    String id,
  ) async {
    await _dio.delete(
      _basedEndpoint + "/entity",
      queryParameters: {
        "id": id,
      },
      options: Options(
        headers: {
          "X-Auth-Token": _config.getToken(),
        },
      ),
    );
  }

  Future<List<AuthEntity>> getDiff(int sinceTime, {int limit = 500}) async {
    final response = await _dio.get(
      _basedEndpoint + "/entity/diff",
      queryParameters: {
        "sinceTime": sinceTime,
        "limit": limit,
      },
      options: Options(
        headers: {
          "X-Auth-Token": _config.getToken(),
        },
      ),
    );
    final List<AuthEntity> authEntities = <AuthEntity>[];
    final diff = response.data["diff"] as List;
    for (var entry in diff) {
      final AuthEntity entity = AuthEntity.fromMap(entry);
      authEntities.add(entity);
    }
    return authEntities;
  }
}
