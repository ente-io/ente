import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ente_accounts/services/user_service.dart';
import 'package:ente_crypto_api/ente_crypto_api.dart';
import 'package:ente_network/network.dart';
import 'package:ente_pure_utils/ente_pure_utils.dart';
import 'package:ente_sharing/models/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/configuration.dart';
import 'package:locker/services/feature_flag_service.dart';
import 'package:locker/services/files/upload/file_upload_service.dart';
import 'package:locker/ui/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../test_utils/configuration_test_util.dart';

void main() {
  const partSize = 20 * 1024 * 1024;
  late Directory root;
  late _UploadServer server;
  late File source;
  late _TestCrypto crypto;
  final originalNetwork = Network.instance;
  final collection = Collection(
    10,
    User(id: 1, email: 'test@example.com'),
    '',
    '',
    'Documents',
    null,
    null,
    CollectionType.folder,
    CollectionAttributes(),
    [],
    [],
    0,
  );

  setUpAll(() async {
    root = await setupLockerConfigurationForTest('multipart_upload');
    HttpOverrides.global = null;
    server = await _UploadServer.start();
    Network.instance = _TestNetwork(server.origin);
    crypto = _TestCrypto();
    registerCryptoApi(crypto);
    await Configuration.instance.setUserID(1);
    await Configuration.instance.setKey(base64Encode(Uint8List(32)));
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('remote_flags', '{}');
    FeatureFlagService.instance.init(preferences);
    await UserService.instance.init(Configuration.instance, const HomePage());
    await FileUploader.instance.init(preferences, false);
  });

  setUp(() async {
    server.reset();
    crypto.partSize = null;
    await FeatureFlagService.instance.setInternalUserDisabled(false);
    source = File('${root.path}/document.bin');
    // Three distinguishable parts, including a short final part.
    final output = await source.open(mode: FileMode.write);
    await output.writeFrom(Uint8List(partSize)..fillRange(0, partSize, 11));
    await output.writeFrom(Uint8List(partSize)..fillRange(0, partSize, 22));
    await output.writeFrom([33, 34, 35]);
    await output.close();
  });

  tearDownAll(() async {
    await server.server.close(force: true);
    Network.instance = originalNetwork;
    clearLockerConfigurationTestHandlers();
    await root.delete(recursive: true);
  });

  test(
    'internal upload sends exact parts and completes before metadata',
    () async {
      final uploaded = await FileUploader.instance.upload(source, collection);

      expect(uploaded.uploadedFileID, 42);
      expect(crypto.partSize, partSize);
      expect(server.multipartRequest, {
        'contentLength': partSize * 2 + 3,
        'partLength': partSize,
        'partMd5s': [
          await computeMd5(source.path, start: 0, end: partSize),
          await computeMd5(source.path, start: partSize, end: partSize * 2),
          await computeMd5(source.path, start: partSize * 2),
        ],
      });
      expect(server.partAttempts, {1: 1, 2: 1, 3: 1});
      expect(server.parts[1]!.toSet(), {11});
      expect(server.parts[2]!.toSet(), {22});
      expect(server.parts[3], [33, 34, 35]);
      expect(server.parts[1]!.length, partSize);
      expect(server.parts[2]!.length, partSize);
      expect(server.events.sublist(server.events.length - 2), [
        'complete',
        'metadata',
      ]);
      expect(server.completionBody, contains('<PartNumber>3</PartNumber>'));
      expect(server.completionBody, contains('etag-3'));
      expect(server.metadata!['file']['objectKey'], 'multipart-object');
    },
  );

  test('retries only the failed part within the current session', () async {
    server.partFailures = 2;
    await FileUploader.instance.upload(source, collection);

    expect(server.partAttempts, {1: 1, 2: 3, 3: 1});
    expect(server.multipartRequests, 1);
    expect(server.events.where((event) => event == 'metadata'), hasLength(1));
  });

  test(
    'stops after bounded retries without completing or saving metadata',
    () async {
      server.partFailures = 10;
      await expectLater(
        FileUploader.instance.upload(source, collection),
        throwsA(isA<DioException>()),
      );

      expect(server.partAttempts, {1: 1, 2: 3});
      expect(server.events, isNot(contains('complete')));
      expect(server.metadata, isNull);
    },
  );

  test('retries completion without uploading successful parts again', () async {
    server.completionFailures = 1;
    await FileUploader.instance.upload(source, collection);

    expect(server.partAttempts, {1: 1, 2: 1, 3: 1});
    expect(server.events.where((event) => event == 'complete'), hasLength(2));
    expect(server.metadata, isNotNull);
  });

  test(
    'does not save metadata when completion returns an S3 error in HTTP 200',
    () async {
      server.completionError = true;
      await expectLater(
        FileUploader.instance.upload(source, collection),
        throwsA(isA<Exception>()),
      );

      expect(server.metadata, isNull);
    },
  );

  test(
    'keeps large uploads on the existing path when internal is disabled',
    () async {
      await FeatureFlagService.instance.setInternalUserDisabled(true);
      await FileUploader.instance.upload(source, collection);

      expect(crypto.partSize, isNull);
      expect(server.multipartRequests, 0);
      expect(server.singleSizes, [3, partSize * 2 + 3]);
      expect(server.metadata, isNotNull);
    },
  );

  test('keeps small internal uploads on the existing path', () async {
    await source.writeAsBytes([1, 2, 3]);
    await FileUploader.instance.upload(source, collection);

    expect(crypto.partSize, isNull);
    expect(server.multipartRequests, 0);
    expect(server.singleSizes, [3, 3]);
  });
}

class _UploadServer {
  final HttpServer server;
  String get origin => 'http://127.0.0.1:${server.port}';
  final events = <String>[];
  final parts = <int, List<int>>{};
  final partAttempts = <int, int>{};
  final singleSizes = <int>[];
  int multipartRequests = 0;
  int partFailures = 0;
  int completionFailures = 0;
  bool completionError = false;
  Map<String, dynamic>? multipartRequest;
  Map<String, dynamic>? metadata;
  String? completionBody;

  _UploadServer(this.server);

  static Future<_UploadServer> start() async {
    final fixture = _UploadServer(
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
    );
    fixture.server.listen(fixture.handle);
    return fixture;
  }

  void reset() {
    events.clear();
    parts.clear();
    partAttempts.clear();
    singleSizes.clear();
    multipartRequests = partFailures = completionFailures = 0;
    completionError = false;
    multipartRequest = metadata = null;
    completionBody = null;
  }

  Future<void> handle(HttpRequest request) async {
    final buffer = await request.fold<BytesBuilder>(
      BytesBuilder(copy: false),
      (buffer, chunk) => buffer..add(chunk),
    );
    final bytes = buffer.takeBytes();
    final path = request.uri.path;
    Object response = {};
    if (path == '/files/upload-url') {
      response = {'url': '$origin/single', 'objectKey': 'single-object'};
    } else if (path == '/single') {
      singleSizes.add(bytes.length);
    } else if (path == '/files/multipart-upload-url') {
      multipartRequests++;
      multipartRequest = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      response = {
        'objectKey': 'multipart-object',
        'partURLs': [for (var i = 1; i <= 3; i++) '$origin/part/$i'],
        'completeURL': '$origin/complete',
      };
    } else if (path.startsWith('/part/')) {
      final part = int.parse(path.split('/').last);
      partAttempts.update(part, (value) => value + 1, ifAbsent: () => 1);
      expect(request.contentLength, bytes.length);
      expect(
        request.headers.value('Content-MD5'),
        multipartRequest!['partMd5s'][part - 1],
      );
      if (part == 2 && partFailures-- > 0) {
        request.response.statusCode = 408;
        response = '<Error><Code>RequestTimeout</Code></Error>';
      } else {
        parts[part] = bytes;
        request.response.headers.set('ETag', '"etag-$part"');
      }
    } else if (path == '/complete') {
      events.add('complete');
      completionBody = utf8.decode(bytes);
      if (completionFailures-- > 0) {
        request.response.statusCode = 503;
      }
      response = completionError
          ? '<Error><Code>InternalError</Code></Error>'
          : '<CompleteMultipartUploadResult><ETag>"completed"</ETag></CompleteMultipartUploadResult>';
    } else if (path == '/files') {
      events.add('metadata');
      metadata = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      response = {'id': 42, 'ownerID': 1, 'updationTime': 1};
    }
    request.response.headers.contentType = response is String
        ? ContentType('application', 'xml')
        : ContentType.json;
    request.response.write(
      response is String ? response : jsonEncode(response),
    );
    await request.response.close();
  }
}

class _TestNetwork extends Fake implements Network {
  final Dio client;
  _TestNetwork(String origin) : client = Dio(BaseOptions(baseUrl: origin));
  @override
  Dio get enteDio => client;
  @override
  Dio getDio() => client;
}

// Keep encryption deterministic so these tests can inspect transport bytes.
class _TestCrypto extends Fake implements CryptoApi {
  int? partSize;
  @override
  String bin2base64(Uint8List bin, {bool urlSafe = false}) => base64Encode(bin);
  @override
  Uint8List base642bin(String b64) => base64Decode(b64);
  @override
  Uint8List decryptSync(Uint8List cipher, Uint8List key, Uint8List nonce) =>
      Uint8List(32);
  @override
  EncryptionResult encryptSync(Uint8List source, Uint8List key) =>
      EncryptionResult(encryptedData: source, nonce: Uint8List(24));
  @override
  Future<EncryptionResult> encryptData(Uint8List source, Uint8List key) async =>
      EncryptionResult(
        encryptedData: Uint8List.fromList([7, 8, 9]),
        header: Uint8List(24),
      );
  @override
  Future<FileEncryptResult> encryptFileWithMd5(
    String sourceFilePath,
    String destinationFilePath, {
    Uint8List? key,
    int? multiPartChunkSizeInBytes,
  }) async {
    partSize = multiPartChunkSizeInBytes;
    final file = await File(sourceFilePath).copy(destinationFilePath);
    final size = await file.length();
    final md5s = <String>[];
    if (partSize != null) {
      for (var start = 0; start < size; start += partSize!) {
        md5s.add(
          await computeMd5(
            file.path,
            start: start,
            end: (start + partSize!).clamp(0, size),
          ),
        );
      }
    }
    return FileEncryptResult(
      key: Uint8List(32),
      header: Uint8List(24),
      fileMd5: partSize == null ? await computeMd5(file.path) : null,
      partMd5s: partSize == null ? null : md5s,
      partSize: partSize,
    );
  }
}
