// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LocationTagImpl _$$LocationTagImplFromJson(Map<String, dynamic> json) =>
    _$LocationTagImpl(
      name: json['name'] as String,
      radius: (json['radius'] as num).toDouble(),
      aSquare: (json['aSquare'] as num).toDouble(),
      bSquare: (json['bSquare'] as num).toDouble(),
      centerPoint:
          Location.fromJson(json['centerPoint'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$LocationTagImplToJson(_$LocationTagImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'radius': instance.radius,
      'aSquare': instance.aSquare,
      'bSquare': instance.bSquare,
      'centerPoint': instance.centerPoint,
    };
