import "package:dio/dio.dart";
import "package:photos/models/api/storage_bonus/storage_bonus.dart";

class StorageBonusGateway {
  final Dio _enteDio;

  StorageBonusGateway(this._enteDio);

  Future<ReferralView> getReferralView() async {
    final response = await _enteDio.get("/storage-bonus/referral-view");
    return ReferralView.fromJson(response.data);
  }

  Future<void> claimReferralCode(String code) {
    return _enteDio.post("/storage-bonus/referral-claim?code=$code");
  }

  Future<BonusDetails> getBonusDetails() async {
    final response = await _enteDio.get("/storage-bonus/details");
    return BonusDetails.fromJson(response.data);
  }
}
