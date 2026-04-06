class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const String s3Base =
      'https://velona.s3.ap-northeast-2.amazonaws.com/shorts';
}
