import 'package:flutter_test/flutter_test.dart';
import 'package:random_image_oracle/models/image_response.dart';

void main() {
  group('ImageResponse.fromJson', () {
    group('Valid scenarios', () {
      test('should parse valid HTTPS URL', () {
        // Arrange
        final json = {
          'url': 'https://example.com/image.jpg',
        };

        // Act
        final response = ImageResponse.fromJson(json);

        // Assert
        expect(response.url, 'https://example.com/image.jpg');
      });

      test('should parse valid HTTP URL', () {
        // Arrange
        final json = {
          'url': 'http://example.com/image.jpg',
        };

        // Act
        final response = ImageResponse.fromJson(json);

        // Assert
        expect(response.url, 'http://example.com/image.jpg');
      });

      test('should parse HTTPS URL with query parameters', () {
        // Arrange
        final json = {
          'url': 'https://example.com/image.jpg?width=300&height=300',
        };

        // Act
        final response = ImageResponse.fromJson(json);

        // Assert
        expect(
          response.url,
          'https://example.com/image.jpg?width=300&height=300',
        );
      });

      test('should parse HTTPS URL with path segments', () {
        // Arrange
        final json = {
          'url': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
        };

        // Act
        final response = ImageResponse.fromJson(json);

        // Assert
        expect(
          response.url,
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
        );
      });
    });

    group('Missing url field', () {
      test('should throw FormatException when url key is missing', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act & Assert
        expect(
          () => ImageResponse.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Invalid response: missing "url" field',
            ),
          ),
        );
      });

      test('should throw FormatException when json has other keys but no url',
          () {
        // Arrange
        final json = {
          'status': 'success',
          'image_id': 123,
        };

        // Act & Assert
        expect(
          () => ImageResponse.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Invalid response: missing "url" field',
            ),
          ),
        );
      });
    });

    group('Invalid url type', () {
      test('should throw FormatException when url is null', () {
        // Arrange
        final json = {
          'url': null,
        };

        // Act & Assert
        expect(
          () => ImageResponse.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('must be a String'),
            ),
          ),
        );
      });

      test('should throw FormatException when url is an integer', () {
        // Arrange
        final json = {
          'url': 12345,
        };

        // Act & Assert
        expect(
          () => ImageResponse.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('must be a String, got int'),
            ),
          ),
        );
      });

      test('should throw FormatException when url is a boolean', () {
        // Arrange
        final json = {
          'url': true,
        };

        // Act & Assert
        expect(
          () => ImageResponse.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('must be a String, got bool'),
            ),
          ),
        );
      });

      test('should throw FormatException when url is a List', () {
        // Arrange
        final json = {
          'url': ['https://example.com/image.jpg'],
        };

        // Act & Assert
        expect(
          () => ImageResponse.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('must be a String'),
            ),
          ),
        );
      });

      test('should throw FormatException when url is a Map', () {
        // Arrange
        final json = {
          'url': {'href': 'https://example.com/image.jpg'},
        };

        // Act & Assert
        expect(
          () => ImageResponse.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('must be a String'),
            ),
          ),
        );
      });
    });

    group('Empty url', () {
      test('should throw FormatException when url is empty string', () {
        // Arrange
        final json = {
          'url': '',
        };

        // Act & Assert
        expect(
          () => ImageResponse.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'Invalid response: "url" field is empty',
            ),
          ),
        );
      });
    });

    group('Invalid url format', () {
      test('should throw FormatException when url does not start with http(s)',
          () {
        // Arrange
        final json = {
          'url': 'ftp://example.com/image.jpg',
        };

        // Act & Assert
        expect(
          () => ImageResponse.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('must start with http:// or https://'),
            ),
          ),
        );
      });

      test('should throw FormatException for relative path', () {
        // Arrange
        final json = {
          'url': '/images/photo.jpg',
        };

        // Act & Assert
        expect(
          () => ImageResponse.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('must start with http:// or https://'),
            ),
          ),
        );
      });

      test('should throw FormatException for file:// protocol', () {
        // Arrange
        final json = {
          'url': 'file:///path/to/image.jpg',
        };

        // Act & Assert
        expect(
          () => ImageResponse.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('must start with http:// or https://'),
            ),
          ),
        );
      });

      test('should throw FormatException for plain domain without protocol', () {
        // Arrange
        final json = {
          'url': 'example.com/image.jpg',
        };

        // Act & Assert
        expect(
          () => ImageResponse.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('must start with http:// or https://'),
            ),
          ),
        );
      });

      test('should throw FormatException for data URL', () {
        // Arrange
        final json = {
          'url': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA',
        };

        // Act & Assert
        expect(
          () => ImageResponse.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('must start with http:// or https://'),
            ),
          ),
        );
      });

      test('should throw FormatException for malformed URL', () {
        // Arrange
        final json = {
          'url': 'ht!tp://invalid-url',
        };

        // Act & Assert
        expect(
          () => ImageResponse.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('must start with http:// or https://'),
            ),
          ),
        );
      });
    });

    group('Edge cases', () {
      test('should parse URL with special characters in query string', () {
        // Arrange
        final json = {
          'url': 'https://example.com/image.jpg?name=test%20image&size=large',
        };

        // Act
        final response = ImageResponse.fromJson(json);

        // Assert
        expect(
          response.url,
          'https://example.com/image.jpg?name=test%20image&size=large',
        );
      });

      test('should parse URL with fragment identifier', () {
        // Arrange
        final json = {
          'url': 'https://example.com/image.jpg#section1',
        };

        // Act
        final response = ImageResponse.fromJson(json);

        // Assert
        expect(response.url, 'https://example.com/image.jpg#section1');
      });

      test('should parse URL with port number', () {
        // Arrange
        final json = {
          'url': 'https://example.com:8080/image.jpg',
        };

        // Act
        final response = ImageResponse.fromJson(json);

        // Assert
        expect(response.url, 'https://example.com:8080/image.jpg');
      });

      test('should parse URL with authentication', () {
        // Arrange
        final json = {
          'url': 'https://user:pass@example.com/image.jpg',
        };

        // Act
        final response = ImageResponse.fromJson(json);

        // Assert
        expect(response.url, 'https://user:pass@example.com/image.jpg');
      });
    });
  });
}
