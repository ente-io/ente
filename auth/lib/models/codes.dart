import 'package:ente_auth/models/code.dart';

class AllCodes {
  final List<Code> codes;
  final AllCodesState state;

  AllCodes({required this.codes, required this.state});
}

enum AllCodesState {
  value,
  error,
}
