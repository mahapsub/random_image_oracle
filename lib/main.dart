import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
}
