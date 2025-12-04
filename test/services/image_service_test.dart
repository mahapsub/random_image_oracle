import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:random_image_oracle/config/constants.dart';
import 'package:random_image_oracle/models/image_response.dart';
import 'package:random_image_oracle/services/image_service.dart';

void main() {
  group('ImageService', () {
    test('Successfully fetches url response from the server', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), apiEndpoint);
        return http.Response(
          '{"url": "https://images.unsplash.com/photo-1506744038136-46273834b3fb"}',
          200,
        );
      });

      final service = ImageService(client: mockClient);
      final result = await service.fetchRandomImage();

      expect(result, isA<ImageResponse>());
      expect(result.url,
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb');
    });

    test('Throws NetworkError on network failure', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('No internet connection');
      });

      final service = ImageService(client: mockClient);

      expect(
        () => service.fetchRandomImage(),
        throwsA(
          isA<ImageServiceException>()
              .having((e) => e.type, 'type', ImageServiceError.networkError)
              .having(
                (e) => e.message,
                'message',
                contains('No internet connection'),
              ),
        ),
      );
    });

    test('Throws ServerError on server error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = ImageService(client: mockClient);

      expect(
        () => service.fetchRandomImage(),
        throwsA(
          isA<ImageServiceException>()
              .having((e) => e.type, 'type', ImageServiceError.serverError)
              .having(
                (e) => e.message,
                'message',
                contains('Unable to fetch image'),
              ),
        ),
      );
    });
  });
}
