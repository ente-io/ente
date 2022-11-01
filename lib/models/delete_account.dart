class DeleteChallengeResponse {
  final bool allowDelete;
  final String encryptedChallenge;

  DeleteChallengeResponse({
    required this.allowDelete,
    required this.encryptedChallenge,
  });
}
