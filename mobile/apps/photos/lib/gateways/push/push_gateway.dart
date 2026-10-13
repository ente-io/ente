import "package:dio/dio.dart";

class PushGateway {
  final Dio _enteDio;

  PushGateway(this._enteDio);

  Future<void> registerToken({
    required String fcmToken,
    required String platform,
    String? apnsToken,
    required Map<String, Object>? notification,
  }) async {
    await _enteDio.post(
      "/push/token",
      data: {
        "fcmToken": fcmToken,
        "platform": platform,
        "apnsToken": apnsToken,
        if (platform == 'ios') "notification": notification,
      },
    );
  }
}
