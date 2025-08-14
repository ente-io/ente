//
//  Generated code. Do not modify.
//  source: ente/ml/fileml.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use fileMLDescriptor instead')
const FileML$json = {
  '1': 'FileML',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '9': 0, '10': 'id', '17': true},
    {'1': 'clip', '3': 2, '4': 3, '5': 1, '10': 'clip'},
  ],
  '8': [
    {'1': '_id'},
  ],
};

/// Descriptor for `FileML`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileMLDescriptor = $convert.base64Decode(
    'CgZGaWxlTUwSEwoCaWQYASABKANIAFICaWSIAQESEgoEY2xpcBgCIAMoAVIEY2xpcEIFCgNfaW'
    'Q=');

@$core.Deprecated('Use fileFacesDescriptor instead')
const FileFaces$json = {
  '1': 'FileFaces',
  '2': [
    {
      '1': 'faces',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ente.ml.Face',
      '10': 'faces'
    },
    {'1': 'height', '3': 2, '4': 1, '5': 5, '9': 0, '10': 'height', '17': true},
    {'1': 'width', '3': 3, '4': 1, '5': 5, '9': 1, '10': 'width', '17': true},
    {
      '1': 'version',
      '3': 4,
      '4': 1,
      '5': 5,
      '9': 2,
      '10': 'version',
      '17': true
    },
    {'1': 'error', '3': 5, '4': 1, '5': 9, '9': 3, '10': 'error', '17': true},
  ],
  '8': [
    {'1': '_height'},
    {'1': '_width'},
    {'1': '_version'},
    {'1': '_error'},
  ],
};

/// Descriptor for `FileFaces`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fileFacesDescriptor = $convert.base64Decode(
    'CglGaWxlRmFjZXMSIwoFZmFjZXMYASADKAsyDS5lbnRlLm1sLkZhY2VSBWZhY2VzEhsKBmhlaW'
    'dodBgCIAEoBUgAUgZoZWlnaHSIAQESGQoFd2lkdGgYAyABKAVIAVIFd2lkdGiIAQESHQoHdmVy'
    'c2lvbhgEIAEoBUgCUgd2ZXJzaW9uiAEBEhkKBWVycm9yGAUgASgJSANSBWVycm9yiAEBQgkKB1'
    '9oZWlnaHRCCAoGX3dpZHRoQgoKCF92ZXJzaW9uQggKBl9lcnJvcg==');
