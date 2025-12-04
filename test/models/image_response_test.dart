import 'package:flutter_test/flutter_test.dart';
import 'package:random_image_oracle/models/image_response.dart';

void main() {
  group('ImageResponse.fromJson', () {
    test('happy path - parses valid JSON with HTTPS URL correctly', () {
      final json = {'url': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb'};

      final result = ImageResponse.fromJson(json);

      expect(result.url, equals('https://images.unsplash.com/photo-1506744038136-46273834b3fb'));
    });

    test('throws FormatException when URL does not start with http:// or https://', () {
      final json = {'url': 'images.unsplash.com/photo-1506744038136-46273834b3fb'};

      expect(
        () => ImageResponse.fromJson(json),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('must start with http:// or https://'),
        )),
      );
    });

    test('throws FormatException when url field is missing', () {
      final json = <String, dynamic>{};

      expect(
        () => ImageResponse.fromJson(json),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('missing "url" field'),
        )),
      );
    });
  });
}
