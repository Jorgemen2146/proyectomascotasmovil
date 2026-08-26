class ForgotPasswordResponseDto {
  const ForgotPasswordResponseDto({required this.message});

  factory ForgotPasswordResponseDto.fromJson(Map<String, dynamic> json) =>
      ForgotPasswordResponseDto(message: json['message'] as String);

  final String message;
}

class VerifyResetCodeResponseDto {
  const VerifyResetCodeResponseDto({required this.valid});

  factory VerifyResetCodeResponseDto.fromJson(Map<String, dynamic> json) =>
      VerifyResetCodeResponseDto(valid: json['valid'] as bool);

  final bool valid;
}
