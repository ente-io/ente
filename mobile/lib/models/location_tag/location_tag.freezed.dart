// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'location_tag.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

LocationTag _$LocationTagFromJson(Map<String, dynamic> json) {
  return _LocationTag.fromJson(json);
}

/// @nodoc
mixin _$LocationTag {
  String get name => throw _privateConstructorUsedError;
  double get radius => throw _privateConstructorUsedError;
  double get aSquare => throw _privateConstructorUsedError;
  double get bSquare => throw _privateConstructorUsedError;
  Location get centerPoint => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LocationTagCopyWith<LocationTag> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocationTagCopyWith<$Res> {
  factory $LocationTagCopyWith(
          LocationTag value, $Res Function(LocationTag) then) =
      _$LocationTagCopyWithImpl<$Res, LocationTag>;
  @useResult
  $Res call(
      {String name,
      double radius,
      double aSquare,
      double bSquare,
      Location centerPoint});

  $LocationCopyWith<$Res> get centerPoint;
}

/// @nodoc
class _$LocationTagCopyWithImpl<$Res, $Val extends LocationTag>
    implements $LocationTagCopyWith<$Res> {
  _$LocationTagCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? radius = null,
    Object? aSquare = null,
    Object? bSquare = null,
    Object? centerPoint = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      radius: null == radius
          ? _value.radius
          : radius // ignore: cast_nullable_to_non_nullable
              as double,
      aSquare: null == aSquare
          ? _value.aSquare
          : aSquare // ignore: cast_nullable_to_non_nullable
              as double,
      bSquare: null == bSquare
          ? _value.bSquare
          : bSquare // ignore: cast_nullable_to_non_nullable
              as double,
      centerPoint: null == centerPoint
          ? _value.centerPoint
          : centerPoint // ignore: cast_nullable_to_non_nullable
              as Location,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $LocationCopyWith<$Res> get centerPoint {
    return $LocationCopyWith<$Res>(_value.centerPoint, (value) {
      return _then(_value.copyWith(centerPoint: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$LocationTagImplCopyWith<$Res>
    implements $LocationTagCopyWith<$Res> {
  factory _$$LocationTagImplCopyWith(
          _$LocationTagImpl value, $Res Function(_$LocationTagImpl) then) =
      __$$LocationTagImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      double radius,
      double aSquare,
      double bSquare,
      Location centerPoint});

  @override
  $LocationCopyWith<$Res> get centerPoint;
}

/// @nodoc
class __$$LocationTagImplCopyWithImpl<$Res>
    extends _$LocationTagCopyWithImpl<$Res, _$LocationTagImpl>
    implements _$$LocationTagImplCopyWith<$Res> {
  __$$LocationTagImplCopyWithImpl(
      _$LocationTagImpl _value, $Res Function(_$LocationTagImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? radius = null,
    Object? aSquare = null,
    Object? bSquare = null,
    Object? centerPoint = null,
  }) {
    return _then(_$LocationTagImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      radius: null == radius
          ? _value.radius
          : radius // ignore: cast_nullable_to_non_nullable
              as double,
      aSquare: null == aSquare
          ? _value.aSquare
          : aSquare // ignore: cast_nullable_to_non_nullable
              as double,
      bSquare: null == bSquare
          ? _value.bSquare
          : bSquare // ignore: cast_nullable_to_non_nullable
              as double,
      centerPoint: null == centerPoint
          ? _value.centerPoint
          : centerPoint // ignore: cast_nullable_to_non_nullable
              as Location,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LocationTagImpl extends _LocationTag {
  const _$LocationTagImpl(
      {required this.name,
      required this.radius,
      required this.aSquare,
      required this.bSquare,
      required this.centerPoint})
      : super._();

  factory _$LocationTagImpl.fromJson(Map<String, dynamic> json) =>
      _$$LocationTagImplFromJson(json);

  @override
  final String name;
  @override
  final double radius;
  @override
  final double aSquare;
  @override
  final double bSquare;
  @override
  final Location centerPoint;

  @override
  String toString() {
    return 'LocationTag(name: $name, radius: $radius, aSquare: $aSquare, bSquare: $bSquare, centerPoint: $centerPoint)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LocationTagImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.radius, radius) || other.radius == radius) &&
            (identical(other.aSquare, aSquare) || other.aSquare == aSquare) &&
            (identical(other.bSquare, bSquare) || other.bSquare == bSquare) &&
            (identical(other.centerPoint, centerPoint) ||
                other.centerPoint == centerPoint));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, radius, aSquare, bSquare, centerPoint);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LocationTagImplCopyWith<_$LocationTagImpl> get copyWith =>
      __$$LocationTagImplCopyWithImpl<_$LocationTagImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LocationTagImplToJson(
      this,
    );
  }
}

abstract class _LocationTag extends LocationTag {
  const factory _LocationTag(
      {required final String name,
      required final double radius,
      required final double aSquare,
      required final double bSquare,
      required final Location centerPoint}) = _$LocationTagImpl;
  const _LocationTag._() : super._();

  factory _LocationTag.fromJson(Map<String, dynamic> json) =
      _$LocationTagImpl.fromJson;

  @override
  String get name;
  @override
  double get radius;
  @override
  double get aSquare;
  @override
  double get bSquare;
  @override
  Location get centerPoint;
  @override
  @JsonKey(ignore: true)
  _$$LocationTagImplCopyWith<_$LocationTagImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
