import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path_provider/path_provider.dart';

class SaveMediaExample extends StatefulWidget {
  @override
  _SaveMediaExampleState createState() => _SaveMediaExampleState();
}

class _SaveMediaExampleState extends State<SaveMediaExample> {
  final imageUrl =
      "https://ww4.sinaimg.cn/bmiddle/005TR3jLly1ga48shax8zj30u02ickjl.jpg";

  final haveExifUrl = "http://172.16.100.7:2393/IMG_20200107_182905.jpg";

  final videoUrl = "http://img.ksbbs.com/asset/Mon_1703/05cacb4e02f9d9e.mp4";

  // final videoUrl = "http://192.168.31.252:51781/out.mov";
  // final videoUrl = "http://192.168.31.252:51781/out.ogv";

  String get videoName {
    final extName = Uri.parse(videoUrl).pathSegments.last.split(".").last;
    final name = DateTime.now().microsecondsSinceEpoch ~/
        Duration.microsecondsPerMillisecond;
    return "$name.$extName";
  }

  Future<String> downloadPath() async {
    final name = DateTime.now().microsecondsSinceEpoch ~/
        Duration.microsecondsPerMillisecond;

    String dir;

    if (Platform.isIOS || Platform.isMacOS) {
      dir = (await getApplicationSupportDirectory()).absolute.path;
    } else if (Platform.isAndroid) {
      dir = (await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      ))![0]
          .absolute
          .path;
    } else {
      dir = (await getDownloadsDirectory())!.absolute.path;
    }

    return "$dir/$name.jpg";
  }

  @override
  void initState() {
    super.initState();
    PhotoManager.addChangeCallback(_onChange);
    PhotoManager.startChangeNotify();
  }

  void _onChange(MethodCall call) {
    print(call.arguments);
  }

  @override
  void dispose() {
    PhotoManager.stopChangeNotify();
    PhotoManager.removeChangeCallback(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Save media page"),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            ElevatedButton(
              child: Text("Save image with bytes"),
              onPressed: saveImageWithBytes,
            ),
            ElevatedButton(
              child: Text("Save image with path"),
              onPressed: saveImageWithPath,
            ),
            ElevatedButton(
              child: Text("Save video"),
              onPressed: saveVideo,
            ),
          ],
        ),
      ),
    );
  }

  void saveVideo() async {
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse(videoUrl));
    final resp = await req.close();

    final name = this.videoName;

    final tmpDir = await getTemporaryDirectory();
    final file = File('${tmpDir.path}/$name');
    if (file.existsSync()) {
      file.deleteSync();
    }
    resp.listen((data) {
      file.writeAsBytesSync(data, mode: FileMode.append);
    }, onDone: () {
      print("file path = ${file.lengthSync()}");
      PhotoManager.editor.saveVideo(file, title: "$name");
      client.close();
    });
  }

  void saveImageWithBytes() async {
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse(imageUrl));
    final resp = await req.close();
    List<int> bytes = [];
    resp.listen((data) {
      bytes.addAll(data);
    }, onDone: () {
      final image = Uint8List.fromList(bytes);
      saveImage(image);
      client.close();
    });
  }

  void saveImage(Uint8List uint8List) async {
    final asset = await PhotoManager.editor.saveImage(uint8List);
    print(asset);
  }

  void saveImageWithPath() async {
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse(imageUrl));
    final resp = await req.close();

    File file = File(await downloadPath());

    resp.listen((data) {
      file.writeAsBytesSync(data, mode: FileMode.append);
    }, onDone: () async {
      print("write image to file success: $file");
      final asset = await PhotoManager.editor.saveImageWithPath(file.path);
      print("saved asset: $asset");
      client.close();
    });
  }
}
