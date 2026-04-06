class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class UnauthorizedException extends AppException {
  const UnauthorizedException() : super('로그인이 필요합니다.');
}

class NetworkException extends AppException {
  const NetworkException() : super('인터넷 연결을 확인해주세요.');
}

class ServerException extends AppException {
  const ServerException([String msg = '서버 오류가 발생했습니다.']) : super(msg);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}
