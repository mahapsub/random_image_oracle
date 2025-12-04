import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:random_image_oracle/config/constants.dart';
import 'package:random_image_oracle/models/image_response.dart';

enum ImageServiceError {
  networkError,
  serverError,
}

class ImageServiceException implements Exception {
  final ImageServiceError type;
  final String message;
  final dynamic originalError;

  ImageServiceException({
    required this.type,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => message;
}

class ImageService {
  static ImageService? _instance;
  final http.Client _client;

  ImageService._internal(this._client);

  factory ImageService({http.Client? client}) {
    if (client != null) {
      return ImageService._internal(client);
    }
    _instance ??= ImageService._internal(http.Client());
    return _instance!;
  }

  Future<ImageResponse> fetchRandomImage() async {
    try {
      final response = await _client
          .get(Uri.parse(apiEndpoint))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      return ImageResponse.fromJson(jsonData);
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
    } catch (e) {
      throw ImageServiceException(
        type: ImageServiceError.serverError,
        message: 'Unable to fetch image. Please try again.',
        originalError: e,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
