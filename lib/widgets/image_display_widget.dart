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

  const ImageDisplayWidget({
    super.key,
    required this.state,
    this.imageUrl,
    this.errorMessage,
    this.isLoadingNextImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = (screenWidth * 0.85).clamp(200.0, 500.0);

    return Container(
      width: imageSize,
      height: imageSize,
      decoration: BoxDecoration(
        color: state == ImageDisplayState.success
            ? null
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoadingNextImage && imageUrl != null) {
      return Stack(
        children: [
          _buildImage(context),
          Positioned.fill(
            child: _buildLoadingIndicator(),
          ),
        ],
      );
    }

    switch (state) {
      case ImageDisplayState.idle:
        return _buildPlaceholder(context);
      case ImageDisplayState.loading:
        return _buildLoadingIndicator();
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
    return Container(
      height: 30,
      width: 30,
      color: Colors.black.withValues(alpha: 0.6),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
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

    return SizedBox(
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
    );
  }

  /// Builds the error state display (errors shown via SnackBar)
  Widget _buildError(BuildContext context) {
    // Error state shows placeholder icon since errors are displayed via SnackBar
    return _buildPlaceholder(context);
  }
}
