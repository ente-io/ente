import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:logging/logging.dart';

class DeduplicationService {
  final _logger = Logger("DeduplicationService");

  DeduplicationService._privateConstructor();

  static final DeduplicationService instance =
      DeduplicationService._privateConstructor();

  Future<List<DuplicateCodes>> getDuplicateCodes() async {
    try {
      final List<DuplicateCodes> result = await _getDuplicateCodes();
      return result;
    } catch (e, s) {
      _logger.severe("failed to get dedupeCode", e, s);
      rethrow;
    }
  }

  Future<List<DuplicateCodes>> _getDuplicateCodes() async {
    final codes = await CodeStore.instance.getAllCodes();
    final List<DuplicateCodes> duplicateCodes = [];
    final Map<String, List<Code>> groupedCodes = {};

    for (final code in codes) {
      if (code.hasError || code.isTrashed) continue;

      final uniqueKey = _buildDuplicateKey(code);

      if (groupedCodes.containsKey(uniqueKey)) {
        groupedCodes[uniqueKey]!.add(code);
      } else {
        groupedCodes[uniqueKey] = [code];
      }
    }
    for (final entry in groupedCodes.entries) {
      if (entry.value.length > 1) {
        duplicateCodes.add(DuplicateCodes(entry.key, entry.value));
      }
    }
    return duplicateCodes;
  }

  String _buildDuplicateKey(Code code) {
    final normalizedIssuer = code.issuer.trim().toLowerCase();
    final normalizedSecret = code.secret.trim();
    return [
      normalizedSecret,
      normalizedIssuer,
      code.type.name,
      code.algorithm.name,
      code.digits.toString(),
      code.period.toString(),
    ].join("_");
  }
}

class DuplicateCodes {
  String hash;
  final List<Code> codes;

  DuplicateCodes(
    this.hash,
    this.codes,
  );
}
