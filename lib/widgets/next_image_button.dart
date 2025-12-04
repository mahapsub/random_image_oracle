import 'package:flutter/material.dart';

import 'image_display_widget.dart';

class NextImageButton extends StatelessWidget {
  final ImageDisplayState state;
  final bool hasImage;
  final VoidCallback onPressed;

  const NextImageButton({
    super.key,
    required this.state,
    required this.hasImage,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = Theme.of(context).colorScheme.primary;

    return Visibility(
      visible: hasImage || state == ImageDisplayState.error,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: ElevatedButton(
        onPressed: state == ImageDisplayState.loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 48,
            vertical: 16,
          ),
          fixedSize: const Size(220, 56),
          splashFactory: NoSplash.splashFactory,
          foregroundColor: labelColor,
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
          child: state == ImageDisplayState.loading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Text(
                  state == ImageDisplayState.error ? 'Try Again' : 'Another',
                  key: const ValueKey('label'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: labelColor),
                ),
        ),
      ),
    );
  }
}
