import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image/image.dart' as img;

import 'services/image_service.dart';
import 'widgets/image_display_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Image Oracle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ImageDisplayState _currentState = ImageDisplayState.loading;
  String? _imageUrl;
  String? _errorMessage;
  bool _isLoadingNext = false;
  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    // Automatically fetch an image when the app starts
    // Use addPostFrameCallback to ensure ScaffoldMessenger is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAndDisplayImage();
    });
  }

  Future<void> _fetchAndDisplayImage() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final hasCurrentImage = _imageUrl != null;

    setState(() {
      _currentState = ImageDisplayState.loading;
      _isLoadingNext = hasCurrentImage;
      _errorMessage = null;
    });

    try {
      final response = await _imageService.fetchRandomImage();
      final newImageUrl = response.url;

      if (!mounted) return;

      try {
        await precacheImage(
          CachedNetworkImageProvider(newImageUrl),
          context,
        );
      } catch (imageError) {
        throw ImageServiceException(
          type: ImageServiceError.invalidResponse,
          message: 'Server returned invalid image URL.',
          originalError: imageError,
        );
      }

      if (mounted) {
        setState(() {
          _currentState = ImageDisplayState.success;
          _imageUrl = newImageUrl;
          _isLoadingNext = false;
        });

        _extractAndLogPalette(newImageUrl);
      }
    } on ImageServiceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Another image failed to load.'),
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      if (mounted) {
        setState(() {
          if (hasCurrentImage) {
            _currentState = ImageDisplayState.success;
          } else {
            _currentState = ImageDisplayState.error;
          }
          _errorMessage = e.message;
          _isLoadingNext = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Another image failed to load. Please try again later'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      if (mounted) {
        setState(() {
          if (hasCurrentImage) {
            _currentState = ImageDisplayState.success;
          } else {
            _currentState = ImageDisplayState.error;
          }
          _errorMessage = 'An unexpected error occurred';
          _isLoadingNext = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ImageDisplayWidget(
              state: _currentState,
              imageUrl: _imageUrl,
              errorMessage: _errorMessage,
              isLoadingNextImage: _isLoadingNext,
            ),
            const SizedBox(height: 32),
            Visibility(
              visible:
                  _imageUrl != null || _currentState == ImageDisplayState.error,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: ElevatedButton(
                onPressed: _currentState == ImageDisplayState.loading
                    ? null
                    : _fetchAndDisplayImage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  fixedSize: const Size(220, 56),
                  splashFactory: NoSplash.splashFactory,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                      width: 2,
                    ),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: _currentState == ImageDisplayState.loading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(
                          _currentState == ImageDisplayState.error
                              ? 'Try Again'
                              : 'Another',
                          key: const ValueKey('label'),
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _extractAndLogPalette(String imageUrl) async {
    final stopwatch = Stopwatch()..start();
    try {
      final cacheManager = DefaultCacheManager();
      final cachedFile = await cacheManager.getFileFromCache(imageUrl);
      final file =
          cachedFile?.file ?? await cacheManager.getSingleFile(imageUrl);

      final bytes = await file.readAsBytes();
      final colors = await compute(_generatePalette, Uint8List.fromList(bytes));
      stopwatch.stop();

      if (colors.isEmpty) {
        debugPrint(
          'Palette extraction yielded no colors after ${stopwatch.elapsedMilliseconds}ms',
        );
        return;
      }

      final formatted = colors.map(_formatColorInt).join(', ');
      debugPrint('Palette (${stopwatch.elapsedMilliseconds}ms): $formatted');
    } catch (e) {
      stopwatch.stop();
      debugPrint(
        'Palette extraction failed after ${stopwatch.elapsedMilliseconds}ms: $e',
      );
    }
  }
}

List<int> _generatePalette(Uint8List bytes) {
  final img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) return [];

  // Downscale to reduce work; average interpolation smooths noise.
  final img.Image scaled = img.copyResize(
    decoded,
    width: 64,
    height: 64,
    interpolation: img.Interpolation.average,
  );

  // Quantize to 12-bit color buckets (4 bits per channel) for fast grouping.
  final Map<int, int> bucketCounts = <int, int>{};
  for (int y = 0; y < scaled.height; y++) {
    for (int x = 0; x < scaled.width; x++) {
      final img.Pixel pixel = scaled.getPixel(x, y);
      final int r = pixel.r.toInt();
      final int g = pixel.g.toInt();
      final int b = pixel.b.toInt();
      final int bucket = ((r >> 4) << 8) | ((g >> 4) << 4) | (b >> 4);
      bucketCounts[bucket] = (bucketCounts[bucket] ?? 0) + 1;
    }
  }

  if (bucketCounts.isEmpty) return [];

  final List<MapEntry<int, int>> buckets = bucketCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  // Convert top buckets to actual colors (limit to keep distance calc cheap).
  final List<int> candidates =
      buckets.take(64).map((entry) => _bucketToColor(entry.key)).toList();

  final List<int> selected = <int>[];
  if (candidates.isEmpty) return selected;
  selected.add(candidates.first);

  while (selected.length < 3 && candidates.length > selected.length) {
    int? bestColor;
    int bestDistance = -1;

    for (final candidate in candidates) {
      if (selected.contains(candidate)) continue;

      final int minDistance = selected
          .map((color) => _colorDistanceInt(color, candidate))
          .reduce((a, b) => a < b ? a : b);

      if (minDistance > bestDistance) {
        bestDistance = minDistance;
        bestColor = candidate;
      }
    }

    if (bestColor == null) {
      break;
    }

    selected.add(bestColor);
  }

  // If we didn't get three distinct colors, pad with remaining candidates.
  for (final candidate in candidates) {
    if (selected.length == 3) break;
    if (selected.contains(candidate)) continue;
    selected.add(candidate);
  }

  return selected.take(3).toList();
}

int _bucketToColor(int bucket) {
  int expand(int nibble) => (nibble << 4) | nibble;
  final int r = expand((bucket >> 8) & 0xF);
  final int g = expand((bucket >> 4) & 0xF);
  final int b = expand(bucket & 0xF);
  return 0xFF000000 | (r << 16) | (g << 8) | b;
}

int _colorDistanceInt(int a, int b) {
  final int ar = (a >> 16) & 0xFF;
  final int ag = (a >> 8) & 0xFF;
  final int ab = a & 0xFF;

  final int br = (b >> 16) & 0xFF;
  final int bg = (b >> 8) & 0xFF;
  final int bb = b & 0xFF;

  final int dr = ar - br;
  final int dg = ag - bg;
  final int db = ab - bb;
  return dr * dr + dg * dg + db * db;
}

String _formatColorInt(int color) {
  final String hex = (color & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
  return '#${hex.toUpperCase()}';
}
