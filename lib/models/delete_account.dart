// @dart=2.9

import 'package:flutter/foundation.dart';

class DeleteChallengeResponse {
  final bool allowDelete;
  final String encryptedChallenge;

  DeleteChallengeResponse({
    @required this.allowDelete,
    this.encryptedChallenge,
  });
}
