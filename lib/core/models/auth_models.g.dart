// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  identifier: json['identifier'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'identifier': instance.identifier,
      'password': instance.password,
    };

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      password: json['password'] as String,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'phone': instance.phone,
      'password': instance.password,
    };

VerifyOtpRequest _$VerifyOtpRequestFromJson(Map<String, dynamic> json) =>
    VerifyOtpRequest(
      identifier: json['identifier'] as String,
      otpType: json['otp_type'] as String,
      code: json['code'] as String,
    );

Map<String, dynamic> _$VerifyOtpRequestToJson(VerifyOtpRequest instance) =>
    <String, dynamic>{
      'identifier': instance.identifier,
      'otp_type': instance.otpType,
      'code': instance.code,
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  message: json['message'] as String,
  data: json['data'] == null
      ? null
      : UserModel.fromJson(json['data'] as Map<String, dynamic>),
  token: json['token'] as String?,
  requiresOtp: json['requires_otp'] as bool? ?? false,
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'data': instance.data,
      'token': instance.token,
      'requires_otp': instance.requiresOtp,
    };

ForgotPasswordRequest _$ForgotPasswordRequestFromJson(
  Map<String, dynamic> json,
) => ForgotPasswordRequest(email: json['email'] as String);

Map<String, dynamic> _$ForgotPasswordRequestToJson(
  ForgotPasswordRequest instance,
) => <String, dynamic>{'email': instance.email};

ResetPasswordRequest _$ResetPasswordRequestFromJson(
  Map<String, dynamic> json,
) => ResetPasswordRequest(
  email: json['email'] as String,
  token: json['token'] as String,
  newPassword: json['password'] as String,
  passwordConfirmation: json['password_confirmation'] as String,
);

Map<String, dynamic> _$ResetPasswordRequestToJson(
  ResetPasswordRequest instance,
) => <String, dynamic>{
  'email': instance.email,
  'token': instance.token,
  'password': instance.newPassword,
  'password_confirmation': instance.passwordConfirmation,
};
