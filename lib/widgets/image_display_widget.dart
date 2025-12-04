import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'image_display_components.dart';

enum ImageDisplayState {
  idle, // Initial state, no image fetched yet
  loading, // Fetching URL or loading image
  success, // Image loaded successfully
  error, // Error occurred
}

class ImageDisplayWidget extends StatefulWidget {
  final ImageDisplayState state;
  final String? imageUrl;
  final bool isLoadingNextImage;
  final List<Color> paletteColors;

  const ImageDisplayWidget({
    super.key,
    required this.state,
    this.imageUrl,
    this.isLoadingNextImage = false,
    this.paletteColors = const [],
  });

  @override
  State<ImageDisplayWidget> createState() => _ImageDisplayWidgetState();
}

class _ImageDisplayWidgetState extends State<ImageDisplayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _borderController;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: ImageDisplayConstants.animationDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _borderController.dispose();
    super.dispose();
  }

  bool get _shouldShowTransparentBackground {
    return widget.paletteColors.isNotEmpty ||
        widget.state == ImageDisplayState.success ||
        (widget.state == ImageDisplayState.loading &&
            widget.isLoadingNextImage);
  }

  @override
  Widget build(BuildContext context) {
    final imageSize = calculateImageSize(context);

    final hasPalette = widget.paletteColors.isNotEmpty;
    final palette =
        hasPalette ? widget.paletteColors : _fallbackPalette(context);

    return AnimatedBuilder(
      animation: _borderController,
      builder: (context, _) {
        final double angle = _borderController.value * 2 * math.pi;

        return AnimatedBorderContainer(
          size: imageSize,
          angle: angle,
          paletteColors: widget.paletteColors,
          child: ImageContentContainer(
            showTransparentBackground: _shouldShowTransparentBackground,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasPalette) PaletteBackground(colors: palette),
                switch (widget.state) {
                  ImageDisplayState.idle => const ImagePlaceholder(),
                  ImageDisplayState.loading =>
                    widget.isLoadingNextImage && widget.imageUrl != null
                        ? ImageDisplay(imageUrl: widget.imageUrl)
                        : const ImageLoadingIndicator(),
                  ImageDisplayState.success =>
                    ImageDisplay(imageUrl: widget.imageUrl),
                  ImageDisplayState.error => const ImagePlaceholder(),
                },
              ],
            ),
          ),
        );
      },
    );
  }

  List<Color> _fallbackPalette(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return [
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
    ];
  }
}
