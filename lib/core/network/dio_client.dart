import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exception.dart';

Dio createDio(String baseUrl) {
  final normalized = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  final dio = Dio(
    BaseOptions(
      baseUrl: normalized,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      responseType: ResponseType.json,
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => debugPrint(object.toString()),
      ),
    );
  }

  return dio;
}

String messageFromDio(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'The server took too long to respond. Try again.';
    case DioExceptionType.connectionError:
      return 'Unable to reach the server. Check the connection and API address.';
    case DioExceptionType.cancel:
      return 'The request was cancelled.';
    case DioExceptionType.badCertificate:
      return 'The server certificate could not be verified.';
    case DioExceptionType.badResponse:
      return _messageForStatus(error.response?.statusCode);
    case DioExceptionType.unknown:
      return 'Something went wrong while contacting the server.';
  }
}

String _messageForStatus(int? statusCode) {
  switch (statusCode) {
    case 404:
      return 'Visitor not found.';
    case 400:
    case 422:
      return 'The server rejected the visitor details.';
    case 401:
    case 403:
      return 'The server refused this request.';
    default:
      if (statusCode != null && statusCode >= 500) {
        return 'The server had a problem. Try again.';
      }
      if (statusCode == null) {
        return 'The server returned an unexpected response.';
      }
      return 'The server returned an error ($statusCode).';
  }
}

Never _throwAsApi(Object error) {
  if (error is ApiException) throw error;
  if (error is DioException) throw ApiException(messageFromDio(error));
  if (error is FormatException) {
    throw const ApiException('The server returned an unexpected response.');
  }
  throw const ApiException('Something went wrong. Please try again.');
}

/// Runs [action] and converts network failures into [ApiException].
Future<T> guardApi<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (error) {
    _throwAsApi(error);
  }
}
