import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

enum ImageDisplayState {
  idle, // Initial state, no image fetched yet
  loading, // Fetching URL or loading image
  success, // Image loaded successfully
  error, // Error occurred
}

class ImageDisplayWidget extends StatelessWidget {
  final ImageDisplayState state;
  final String? imageUrl;
  final String? errorMessage;
  final bool isLoadingNextImage;
  final List<Color> paletteColors;

  const ImageDisplayWidget({
    super.key,
    required this.state,
    this.imageUrl,
    this.errorMessage,
    this.isLoadingNextImage = false,
    this.paletteColors = const [],
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = (screenWidth * 0.85).clamp(200.0, 500.0);
    final bool showTransparentBackground =
        paletteColors.isNotEmpty ||
            state == ImageDisplayState.success ||
            (state == ImageDisplayState.loading && isLoadingNextImage);

    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        color: showTransparentBackground
            ? null
            : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (paletteColors.isNotEmpty) _buildPaletteBackground(),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (state) {
      case ImageDisplayState.idle:
        return _buildPlaceholder(context);
      case ImageDisplayState.loading:
        return isLoadingNextImage && imageUrl != null
            ? _buildImage(context)
            : _buildLoadingIndicator();
      case ImageDisplayState.success:
        return _buildImage(context);
      case ImageDisplayState.error:
        return _buildError(context);
    }
  }

  /// Builds the idle state placeholder (initial state)
  Widget _buildPlaceholder(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = (screenWidth * 0.85).clamp(200.0, 500.0);
    final iconSize = imageSize * 0.33;

    return Center(
      child: Icon(
        Icons.image_outlined,
        size: iconSize,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: SizedBox(
        height: 30,
        width: 30,
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Builds the success state with cached network image
  Widget _buildImage(BuildContext context) {
    if (imageUrl == null) {
      return _buildError(context);
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = (screenWidth * 0.85).clamp(200.0, 500.0);
    final errorIconSize = (imageSize * 0.16).clamp(32.0, 64.0);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
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

  /// Builds the error state display (errors shown via SnackBar)
  Widget _buildError(BuildContext context) {
    // Error state shows placeholder icon since errors are displayed via SnackBar
    return _buildPlaceholder(context);
  }

  Widget _buildPaletteBackground() {
    final base = paletteColors;
    if (base.isEmpty) {
      return const SizedBox.shrink();
    }

    final Color primary = base[0];
    final Color secondary = base.length > 1 ? base[1] : base[0];
    final Color accent = base.length > 2 ? base[2] : base[0];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.25,
          colors: [
            primary.withOpacity(0.6),
            secondary.withOpacity(0.35),
            accent.withOpacity(0.2),
          ],
          stops: const [0, 0.55, 1],
        ),
      ),
    );
  }
}
