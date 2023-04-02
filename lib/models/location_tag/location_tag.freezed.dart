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
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

LocationTag _$LocationTagFromJson(Map<String, dynamic> json) {
  return _LocationTag.fromJson(json);
}

/// @nodoc
mixin _$LocationTag {
  String get name => throw _privateConstructorUsedError;
  int get radius => throw _privateConstructorUsedError;
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
  $Res call({String name, int radius, Location centerPoint});

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
              as int,
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
abstract class _$$_LocationTagCopyWith<$Res>
    implements $LocationTagCopyWith<$Res> {
  factory _$$_LocationTagCopyWith(
          _$_LocationTag value, $Res Function(_$_LocationTag) then) =
      __$$_LocationTagCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, int radius, Location centerPoint});

  @override
  $LocationCopyWith<$Res> get centerPoint;
}

/// @nodoc
class __$$_LocationTagCopyWithImpl<$Res>
    extends _$LocationTagCopyWithImpl<$Res, _$_LocationTag>
    implements _$$_LocationTagCopyWith<$Res> {
  __$$_LocationTagCopyWithImpl(
      _$_LocationTag _value, $Res Function(_$_LocationTag) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? radius = null,
    Object? centerPoint = null,
  }) {
    return _then(_$_LocationTag(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      radius: null == radius
          ? _value.radius
          : radius // ignore: cast_nullable_to_non_nullable
              as int,
      centerPoint: null == centerPoint
          ? _value.centerPoint
          : centerPoint // ignore: cast_nullable_to_non_nullable
              as Location,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_LocationTag implements _LocationTag {
  const _$_LocationTag(
      {required this.name, required this.radius, required this.centerPoint});

  factory _$_LocationTag.fromJson(Map<String, dynamic> json) =>
      _$$_LocationTagFromJson(json);

  @override
  final String name;
  @override
  final int radius;
  @override
  final Location centerPoint;

  @override
  String toString() {
    return 'LocationTag(name: $name, radius: $radius, centerPoint: $centerPoint)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_LocationTag &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.radius, radius) || other.radius == radius) &&
            (identical(other.centerPoint, centerPoint) ||
                other.centerPoint == centerPoint));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, radius, centerPoint);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_LocationTagCopyWith<_$_LocationTag> get copyWith =>
      __$$_LocationTagCopyWithImpl<_$_LocationTag>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_LocationTagToJson(
      this,
    );
  }
}

abstract class _LocationTag implements LocationTag {
  const factory _LocationTag(
      {required final String name,
      required final int radius,
      required final Location centerPoint}) = _$_LocationTag;

  factory _LocationTag.fromJson(Map<String, dynamic> json) =
      _$_LocationTag.fromJson;

  @override
  String get name;
  @override
  int get radius;
  @override
  Location get centerPoint;
  @override
  @JsonKey(ignore: true)
  _$$_LocationTagCopyWith<_$_LocationTag> get copyWith =>
      throw _privateConstructorUsedError;
}
