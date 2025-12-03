/// Model for image URL response from the server
///
/// Expected JSON format: {"url": "https://images.unsplash.com/photo-1506744038136-46273834b3fb"}
class ImageResponse {
  final String url;

  ImageResponse._({required this.url});

  /// Creates an ImageResponse from JSON with comprehensive validation
  ///
  /// Throws [FormatException] if:
  /// - 'url' key is missing
  /// - 'url' is not a String
  /// - 'url' is empty
  /// - 'url' does not start with http:// or https://
  factory ImageResponse.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('url')) {
      throw const FormatException(
        'Invalid response: missing "url" field',
      );
    }

    final urlValue = json['url'];

    if (urlValue is! String) {
      throw FormatException(
        'Invalid response: "url" field must be a String, got ${urlValue.runtimeType}',
      );
    }

    if (urlValue.isEmpty) {
      throw const FormatException(
        'Invalid response: "url" field is empty',
      );
    }

    if (!urlValue.startsWith('http://') && !urlValue.startsWith('https://')) {
      throw FormatException(
        'Invalid response: "url" must start with http:// or https://, got: $urlValue',
      );
    }

    return ImageResponse._(url: urlValue);
  }
}
