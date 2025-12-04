import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image/image.dart' as img;

class PaletteService {
  Future<List<Color>> extractPalette(String imageUrl) async {
    try {
      final cacheManager = DefaultCacheManager();
      final cachedFile = await cacheManager.getFileFromCache(imageUrl);
      final file =
          cachedFile?.file ?? await cacheManager.getSingleFile(imageUrl);

      final bytes = await file.readAsBytes();
      // Using isolate for extraction to prevent blocking the main UI thread.
      final colors = await compute(_generatePalette, Uint8List.fromList(bytes));

      return colors.map((c) => Color(c)).toList();
    } catch (e) {
      debugPrint('Palette extraction failed: $e');
      return const [];
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
