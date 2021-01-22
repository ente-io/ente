import 'dart:async';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class TryCatchExample {
  Future<List<int>> compressAndTryCatch(String path) async {
    List<int> result;
    try {
      result = await FlutterImageCompress.compressWithFile(path,
          format: CompressFormat.heic);
    } on UnsupportedError catch (e) {
      print(e.message);
      result = await FlutterImageCompress.compressWithFile(path,
          format: CompressFormat.jpeg);
    } on Error catch (e) {
      print(e.toString());
      print(e.stackTrace);
    } on Exception catch (e) {
      print(e.toString());
    }
    return result;
  }
}
