import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageDisplayConstants {
  static const double imageScaleFactor = 0.85;
  static const double minImageSize = 200.0;
  static const double maxImageSize = 500.0;
  static const double outerBorderRadius = 12.0;
  static const double innerBorderRadius = 10.0;
  static const double contentBorderRadius = 8.0;
  static const double borderPadding = 3.0;
  static const double borderWidth = 1.5;
  static const Duration animationDuration = Duration(seconds: 12);
}

double calculateImageSize(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  return (screenWidth * ImageDisplayConstants.imageScaleFactor).clamp(
      ImageDisplayConstants.minImageSize, ImageDisplayConstants.maxImageSize);
}

extension ColorListExt on List<Color> {
  Color getOrFirst(int index) => index < length ? this[index] : first;
}

class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final imageSize = calculateImageSize(context);
    final iconSize = imageSize * 0.33;

    return Center(
      child: Icon(
        Icons.image_outlined,
        size: iconSize,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Loading indicator widget
class ImageLoadingIndicator extends StatelessWidget {
  const ImageLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        height: 30,
        width: 30,
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class ImageDisplay extends StatelessWidget {
  final String? imageUrl;

  const ImageDisplay({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return const ImagePlaceholder();
    }

    final imageSize = calculateImageSize(context);
    final errorIconSize = (imageSize * 0.16).clamp(32.0, 64.0);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeIn,
        );
        final scaleAnimation = Tween<double>(
          begin: 0.97,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      child: SizedBox(
        key: ValueKey(imageUrl),
        width: imageSize,
        height: imageSize,
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorWidget: (context, url, error) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: errorIconSize,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to load image',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaletteBackground extends StatelessWidget {
  final List<Color> colors;

  const PaletteBackground({
    super.key,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.25,
          colors: [
            colors[0].withValues(alpha: 0.6),
            colors.getOrFirst(1).withValues(alpha: 0.35),
            colors.getOrFirst(2).withValues(alpha: 0.2),
          ],
          stops: const [0, 0.55, 1],
        ),
      ),
    );
  }
}

class AnimatedBorderContainer extends StatelessWidget {
  final double size;
  final double angle;
  final List<Color> paletteColors;
  final Widget child;

  const AnimatedBorderContainer({
    super.key,
    required this.size,
    required this.angle,
    required this.paletteColors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: paletteColors.isNotEmpty
          ? _buildPaletteBorder()
          : _buildDefaultBorder(context),
      child: child,
    );
  }

  BoxDecoration _buildPaletteBorder() {
    return BoxDecoration(
      borderRadius:
          BorderRadius.circular(ImageDisplayConstants.outerBorderRadius),
      gradient: SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        transform: GradientRotation(angle),
        colors: [
          paletteColors[0].withValues(alpha: 0.95),
          paletteColors.getOrFirst(1).withValues(alpha: 0.85),
          paletteColors.getOrFirst(2).withValues(alpha: 0.75),
          paletteColors[0].withValues(alpha: 0.95),
        ],
        stops: const [0.0, 0.45, 0.75, 1.0],
      ),
    );
  }

  BoxDecoration _buildDefaultBorder(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius:
          BorderRadius.circular(ImageDisplayConstants.outerBorderRadius),
      border: Border.all(
        color: Theme.of(context).colorScheme.outline,
        width: ImageDisplayConstants.borderWidth,
      ),
    );
  }
}

class ImageContentContainer extends StatelessWidget {
  final bool showTransparentBackground;
  final Widget child;

  const ImageContentContainer({
    super.key,
    required this.showTransparentBackground,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ImageDisplayConstants.borderPadding),
      child: Container(
        decoration: BoxDecoration(
          color: showTransparentBackground
              ? null
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius:
              BorderRadius.circular(ImageDisplayConstants.innerBorderRadius),
          border: Border.all(color: Colors.transparent),
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(ImageDisplayConstants.contentBorderRadius),
          child: child,
        ),
      ),
    );
  }
}
