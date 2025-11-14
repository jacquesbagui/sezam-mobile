// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nationality_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NationalityModel _$NationalityModelFromJson(Map<String, dynamic> json) =>
    NationalityModel(
      id: json['id'] as String,
      name: json['name'] as String,
      countryCode: json['country_code'] as String,
    );

Map<String, dynamic> _$NationalityModelToJson(NationalityModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'country_code': instance.countryCode,
    };
