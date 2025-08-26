//
//  Generated code. Do not modify.
//  source: ente/ml/fileml.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'face.pb.dart' as $2;

class FileML extends $pb.GeneratedMessage {
  factory FileML({
    $fixnum.Int64? id,
    $core.Iterable<$core.double>? clip,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (clip != null) {
      $result.clip.addAll(clip);
    }
    return $result;
  }
  FileML._() : super();
  factory FileML.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FileML.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FileML',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ente.ml'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..p<$core.double>(2, _omitFieldNames ? '' : 'clip', $pb.PbFieldType.KD)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FileML clone() => FileML()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FileML copyWith(void Function(FileML) updates) =>
      super.copyWith((message) => updates(message as FileML)) as FileML;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FileML create() => FileML._();
  FileML createEmptyInstance() => create();
  static $pb.PbList<FileML> createRepeated() => $pb.PbList<FileML>();
  @$core.pragma('dart2js:noInline')
  static FileML getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FileML>(create);
  static FileML? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.double> get clip => $_getList(1);
}

class FileFaces extends $pb.GeneratedMessage {
  factory FileFaces({
    $core.Iterable<$2.Face>? faces,
    $core.int? height,
    $core.int? width,
    $core.int? version,
    $core.String? error,
  }) {
    final $result = create();
    if (faces != null) {
      $result.faces.addAll(faces);
    }
    if (height != null) {
      $result.height = height;
    }
    if (width != null) {
      $result.width = width;
    }
    if (version != null) {
      $result.version = version;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  FileFaces._() : super();
  factory FileFaces.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FileFaces.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FileFaces',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ente.ml'),
      createEmptyInstance: create)
    ..pc<$2.Face>(1, _omitFieldNames ? '' : 'faces', $pb.PbFieldType.PM,
        subBuilder: $2.Face.create)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'height', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'width', $pb.PbFieldType.O3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'version', $pb.PbFieldType.O3)
    ..aOS(5, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FileFaces clone() => FileFaces()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FileFaces copyWith(void Function(FileFaces) updates) =>
      super.copyWith((message) => updates(message as FileFaces)) as FileFaces;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FileFaces create() => FileFaces._();
  FileFaces createEmptyInstance() => create();
  static $pb.PbList<FileFaces> createRepeated() => $pb.PbList<FileFaces>();
  @$core.pragma('dart2js:noInline')
  static FileFaces getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FileFaces>(create);
  static FileFaces? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$2.Face> get faces => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get height => $_getIZ(1);
  @$pb.TagNumber(2)
  set height($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasHeight() => $_has(1);
  @$pb.TagNumber(2)
  void clearHeight() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get width => $_getIZ(2);
  @$pb.TagNumber(3)
  set width($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasWidth() => $_has(2);
  @$pb.TagNumber(3)
  void clearWidth() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get version => $_getIZ(3);
  @$pb.TagNumber(4)
  set version($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearVersion() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get error => $_getSZ(4);
  @$pb.TagNumber(5)
  set error($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => clearField(5);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
