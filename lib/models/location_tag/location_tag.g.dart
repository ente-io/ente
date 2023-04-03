// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_LocationTag _$$_LocationTagFromJson(Map<String, dynamic> json) =>
    _$_LocationTag(
      name: json['name'] as String,
      radius: json['radius'] as int,
      aSquare: (json['aSquare'] as num).toDouble(),
      bSquare: (json['bSquare'] as num).toDouble(),
      centerPoint:
          Location.fromJson(json['centerPoint'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_LocationTagToJson(_$_LocationTag instance) =>
    <String, dynamic>{
      'name': instance.name,
      'radius': instance.radius,
      'aSquare': instance.aSquare,
      'bSquare': instance.bSquare,
      'centerPoint': instance.centerPoint,
    };
