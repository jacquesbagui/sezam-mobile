import 'package:json_annotation/json_annotation.dart';

part 'nationality_model.g.dart';

@JsonSerializable()
class NationalityModel {
  final String id;
  final String name;
  
  @JsonKey(name: 'country_code')
  final String countryCode;

  NationalityModel({
    required this.id,
    required this.name,
    required this.countryCode,
  });

  factory NationalityModel.fromJson(Map<String, dynamic> json) =>
      _$NationalityModelFromJson(json);

  Map<String, dynamic> toJson() => _$NationalityModelToJson(this);
}

