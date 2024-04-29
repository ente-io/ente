import 'package:ente_auth/models/code.dart';

class CodeState {
  final Code? code;
  final String? error;

  CodeState({
    required this.code,
    required this.error,
  }) : assert(code != null || error != null);
}

class Codes {
  final List<CodeState> allCodes;
  final List<String> tags;

  Codes({
    required this.allCodes,
    required this.tags,
  });

  List<Code> get validCodes => allCodes
      .where((element) => element.code != null)
      .map((e) => e.code!)
      .toList();
}
