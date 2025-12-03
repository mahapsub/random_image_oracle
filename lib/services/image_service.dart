import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:random_image_oracle/config/constants.dart';
import 'package:random_image_oracle/models/image_response.dart';

enum ImageServiceError {
  networkError,
  serverError,
  invalidResponse,
  unknown,
}

class ImageServiceException implements Exception {
  final ImageServiceError type;
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ImageServiceException({
    required this.type,
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

class ImageService {
  static final ImageService _instance = ImageService._internal();
  final http.Client _client = http.Client();

  ImageService._internal();

  factory ImageService() => _instance;

  /// Fetches a random image URL from the server
  ///
  /// Returns [ImageResponse] with the image URL on success.
  ///
  /// Throws [ImageServiceException] with appropriate error type and message:
  /// - NetworkError: No internet connection or request timeout
  /// - ServerError: Server returned non-200 status code
  /// - InvalidResponse: JSON parsing failed or invalid data format
  /// - Unknown: Unexpected errors
  Future<ImageResponse> fetchRandomImage() async {
    try {
      final response = await _client
          .get(Uri.parse(apiEndpoint))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw ImageServiceException(
          type: ImageServiceError.serverError,
          message:
              'Server error (code: ${response.statusCode}). Please try again later.',
          statusCode: response.statusCode,
        );
      }

      // Parse JSON response
      final Map<String, dynamic> jsonData;
      try {
        jsonData = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw ImageServiceException(
          type: ImageServiceError.invalidResponse,
          message: 'Invalid server response format.',
          originalError: e,
        );
      }

      try {
        return ImageResponse.fromJson(jsonData);
      } on FormatException catch (e) {
        throw ImageServiceException(
          type: ImageServiceError.invalidResponse,
          message: 'Server returned invalid image URL.',
          originalError: e,
        );
      }
    } on SocketException catch (e) {
      throw ImageServiceException(
        type: ImageServiceError.networkError,
        message: 'No internet connection. Please check your network.',
        originalError: e,
      );
    } on TimeoutException catch (e) {
      throw ImageServiceException(
        type: ImageServiceError.networkError,
        message: 'Request timed out. Please try again.',
        originalError: e,
      );
    } on ImageServiceException {
      rethrow;
    } catch (e) {
      throw ImageServiceException(
        type: ImageServiceError.unknown,
        message: 'An unexpected error occurred.',
        originalError: e,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
