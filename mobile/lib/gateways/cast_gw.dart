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
      if (e is DioError &&
          e.response != null &&
          e.response!.statusCode == 404) {
        return null;
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
      "/cast/cast-data/",
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
        "/cast/revoke-all-tokens/",
      );
    } catch (e) {
      // swallow error
    }
  }
}
