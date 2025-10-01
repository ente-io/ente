//
//  Generated code. Do not modify.
//  source: ente/ml/face.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use detectionDescriptor instead')
const Detection$json = {
  '1': 'Detection',
  '2': [
    {
      '1': 'box',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ente.common.CenterBox',
      '9': 0,
      '10': 'box',
      '17': true
    },
    {
      '1': 'landmarks',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ente.common.EPoint',
      '9': 1,
      '10': 'landmarks',
      '17': true
    },
  ],
  '8': [
    {'1': '_box'},
    {'1': '_landmarks'},
  ],
};

/// Descriptor for `Detection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List detectionDescriptor = $convert.base64Decode(
    'CglEZXRlY3Rpb24SLQoDYm94GAEgASgLMhYuZW50ZS5jb21tb24uQ2VudGVyQm94SABSA2JveI'
    'gBARI2CglsYW5kbWFya3MYAiABKAsyEy5lbnRlLmNvbW1vbi5FUG9pbnRIAVIJbGFuZG1hcmtz'
    'iAEBQgYKBF9ib3hCDAoKX2xhbmRtYXJrcw==');

@$core.Deprecated('Use faceDescriptor instead')
const Face$json = {
  '1': 'Face',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'id', '17': true},
    {
      '1': 'detection',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ente.ml.Detection',
      '9': 1,
      '10': 'detection',
      '17': true
    },
    {
      '1': 'confidence',
      '3': 3,
      '4': 1,
      '5': 2,
      '9': 2,
      '10': 'confidence',
      '17': true
    },
  ],
  '8': [
    {'1': '_id'},
    {'1': '_detection'},
    {'1': '_confidence'},
  ],
};

/// Descriptor for `Face`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List faceDescriptor = $convert.base64Decode(
    'CgRGYWNlEhMKAmlkGAEgASgJSABSAmlkiAEBEjUKCWRldGVjdGlvbhgCIAEoCzISLmVudGUubW'
    'wuRGV0ZWN0aW9uSAFSCWRldGVjdGlvbogBARIjCgpjb25maWRlbmNlGAMgASgCSAJSCmNvbmZp'
    'ZGVuY2WIAQFCBQoDX2lkQgwKCl9kZXRlY3Rpb25CDQoLX2NvbmZpZGVuY2U=');
