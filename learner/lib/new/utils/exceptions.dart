/// Custom exceptions for HTTP error handling
class HttpException implements Exception {
  final int statusCode;
  final String message;
  final String? endpoint;

  const HttpException({
    required this.statusCode,
    required this.message,
    this.endpoint,
  });

  @override
  String toString() {
    return 'HttpException: $message (Status: $statusCode)${endpoint != null ? ' - $endpoint' : ''}';
  }
}

/// Server is down or unavailable (502, 503)
class ServerUnavailableException extends HttpException {
  const ServerUnavailableException({required super.statusCode, super.endpoint})
    : super(message: '伺服器暫時無法使用，請稍後再試');
}

/// Server error when processing request (500)
class ServerErrorException extends HttpException {
  const ServerErrorException({super.endpoint})
    : super(statusCode: 500, message: '伺服器處理請求時發生錯誤');
}

/// Payload too large (413)
class PayloadTooLargeException extends HttpException {
  const PayloadTooLargeException({super.endpoint})
    : super(statusCode: 413, message: '檔案過大，請選擇較小的檔案');
}

/// Invalid user input or no words found in image (422)
class InvalidInputException extends HttpException {
  const InvalidInputException({required super.message, super.endpoint})
    : super(statusCode: 422);
}

/// Network connectivity issues
class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  String toString() {
    return 'NetworkException: $message';
  }
}

/// Utility class to create exceptions from HTTP status codes
class HttpExceptionFactory {
  static Exception fromStatusCode(
    int statusCode, {
    String? endpoint,
    String? customMessage,
  }) {
    switch (statusCode) {
      case 413:
        return PayloadTooLargeException(endpoint: endpoint);
      case 422:
        return InvalidInputException(
          message: customMessage ?? '輸入的資料無效或圖片中未找到錯字',
          endpoint: endpoint,
        );
      case 500:
        return ServerErrorException(endpoint: endpoint);
      case 502:
      case 503:
        return ServerUnavailableException(
          statusCode: statusCode,
          endpoint: endpoint,
        );
      default:
        return HttpException(
          statusCode: statusCode,
          message: customMessage ?? '請求失敗 (HTTP $statusCode)',
          endpoint: endpoint,
        );
    }
  }
}
