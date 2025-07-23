import "package:photos/src/rust/frb_generated.dart";

bool _isInitFrb = false;

Future<void> initFrb() async {
  if (_isInitFrb) return;
  await RustLib.init();
  _isInitFrb = true;
}
