//
//  Generated code. Do not modify.
//  source: ente/ml/face.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../common/box.pb.dart' as $0;
import '../common/point.pb.dart' as $1;

class Detection extends $pb.GeneratedMessage {
  factory Detection({
    $0.CenterBox? box,
    $1.EPoint? landmarks,
  }) {
    final $result = create();
    if (box != null) {
      $result.box = box;
    }
    if (landmarks != null) {
      $result.landmarks = landmarks;
    }
    return $result;
  }
  Detection._() : super();
  factory Detection.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Detection.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Detection',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ente.ml'),
      createEmptyInstance: create)
    ..aOM<$0.CenterBox>(1, _omitFieldNames ? '' : 'box',
        subBuilder: $0.CenterBox.create)
    ..aOM<$1.EPoint>(2, _omitFieldNames ? '' : 'landmarks',
        subBuilder: $1.EPoint.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Detection clone() => Detection()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Detection copyWith(void Function(Detection) updates) =>
      super.copyWith((message) => updates(message as Detection)) as Detection;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Detection create() => Detection._();
  Detection createEmptyInstance() => create();
  static $pb.PbList<Detection> createRepeated() => $pb.PbList<Detection>();
  @$core.pragma('dart2js:noInline')
  static Detection getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Detection>(create);
  static Detection? _defaultInstance;

  @$pb.TagNumber(1)
  $0.CenterBox get box => $_getN(0);
  @$pb.TagNumber(1)
  set box($0.CenterBox v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasBox() => $_has(0);
  @$pb.TagNumber(1)
  void clearBox() => clearField(1);
  @$pb.TagNumber(1)
  $0.CenterBox ensureBox() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.EPoint get landmarks => $_getN(1);
  @$pb.TagNumber(2)
  set landmarks($1.EPoint v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasLandmarks() => $_has(1);
  @$pb.TagNumber(2)
  void clearLandmarks() => clearField(2);
  @$pb.TagNumber(2)
  $1.EPoint ensureLandmarks() => $_ensure(1);
}

class Face extends $pb.GeneratedMessage {
  factory Face({
    $core.String? id,
    Detection? detection,
    $core.double? confidence,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (detection != null) {
      $result.detection = detection;
    }
    if (confidence != null) {
      $result.confidence = confidence;
    }
    return $result;
  }
  Face._() : super();
  factory Face.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Face.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Face',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ente.ml'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOM<Detection>(2, _omitFieldNames ? '' : 'detection',
        subBuilder: Detection.create)
    ..a<$core.double>(
        3, _omitFieldNames ? '' : 'confidence', $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Face clone() => Face()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Face copyWith(void Function(Face) updates) =>
      super.copyWith((message) => updates(message as Face)) as Face;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Face create() => Face._();
  Face createEmptyInstance() => create();
  static $pb.PbList<Face> createRepeated() => $pb.PbList<Face>();
  @$core.pragma('dart2js:noInline')
  static Face getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Face>(create);
  static Face? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  Detection get detection => $_getN(1);
  @$pb.TagNumber(2)
  set detection(Detection v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasDetection() => $_has(1);
  @$pb.TagNumber(2)
  void clearDetection() => clearField(2);
  @$pb.TagNumber(2)
  Detection ensureDetection() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.double get confidence => $_getN(2);
  @$pb.TagNumber(3)
  set confidence($core.double v) {
    $_setFloat(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasConfidence() => $_has(2);
  @$pb.TagNumber(3)
  void clearConfidence() => clearField(3);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
