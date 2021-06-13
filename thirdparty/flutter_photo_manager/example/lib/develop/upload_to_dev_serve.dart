import 'dart:io';

import 'package:photo_manager/photo_manager.dart';

class UploadToDevServer {
  const UploadToDevServer._();

  static void upload(AssetEntity entity) async {
    final data = await entity.originBytes;
    if (data == null) {
      return;
    }
    print(data.length);
    final client = HttpClient();

    final req =
        await client.postUrl(Uri.parse("http://192.168.31.252:8090/upload"));
    req.add(data);
    await req.close();

    client.close();
  }
}
