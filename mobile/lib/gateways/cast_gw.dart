import "package:dio/dio.dart";

class CastGateway {
  final Dio _enteDio;

  CastGateway(this._enteDio);

  Future<String?> getPublicKey(String deviceCode) async {
    try {
      final response = await _enteDio.get(
        "/cast/device-info/$deviceCode",
      );
      return response.data["publicKey"];
    } catch (e) {
      if (e is DioException && e.response != null) {
        if (e.response!.statusCode == 404) {
          return null;
        } else if (e.response!.statusCode == 403) {
          throw CastIPMismatchException();
        } else {
          rethrow;
        }
      }
      rethrow;
    }
  }

  Future<void> publishCastPayload(
    String code,
    String castPayload,
    int collectionID,
    String castToken,
  ) {
    return _enteDio.post(
      "/cast/cast-data",
      data: {
        "deviceCode": code,
        "encPayload": castPayload,
        "collectionID": collectionID,
        "castToken": castToken,
      },
    );
  }

  Future<void> revokeAllTokens() async {
    try {
      await _enteDio.delete(
        "/cast/revoke-all-tokens",
      );
    } catch (e) {
      // swallow error
    }
  }
}

class CastIPMismatchException implements Exception {
  CastIPMismatchException();
}
