import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'services/image_service.dart';
import 'services/palette_service.dart';
import 'widgets/image_display_widget.dart';
import 'widgets/next_image_button.dart';

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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ImageDisplayState _currentState = ImageDisplayState.loading;
  String? _imageUrl;
  bool _isLoadingNext = false;
  List<Color> _paletteColors = const [];
  final ImageService _imageService = ImageService();
  final PaletteService _paletteService = PaletteService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAndDisplayImage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              decoration: _buildBackgroundDecoration(context),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ImageDisplayWidget(
                  state: _currentState,
                  imageUrl: _imageUrl,
                  isLoadingNextImage: _isLoadingNext,
                  paletteColors: _paletteColors,
                ),
                const SizedBox(height: 32),
                NextImageButton(
                  state: _currentState,
                  hasImage: _imageUrl != null,
                  onPressed: _fetchAndDisplayImage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchAndDisplayImage() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final hasCurrentImage = _imageUrl != null;

    setState(() {
      _currentState = ImageDisplayState.loading;
      _isLoadingNext = hasCurrentImage;
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
        throw Exception('Failed to load image from URL');
      }

      final paletteColors = await _paletteService.extractPalette(newImageUrl);

      if (mounted) {
        setState(() {
          _currentState = ImageDisplayState.success;
          _imageUrl = newImageUrl;
          _paletteColors = paletteColors;
          _isLoadingNext = false;
        });
      }
    } on ImageServiceException catch (e) {
      _showErrorSnackBar(e.message);
      _handleFetchError(hasCurrentImage);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
      _handleFetchError(hasCurrentImage);
    }
  }

  BoxDecoration _buildBackgroundDecoration(BuildContext context) {
    final fallback = Theme.of(context).scaffoldBackgroundColor;
    if (_paletteColors.isEmpty) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            fallback.withValues(alpha: 0.9),
            fallback,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }

    final Color primary = _paletteColors[0];
    final Color secondary =
        _paletteColors.length > 1 ? _paletteColors[1] : _paletteColors[0];
    final Color accent =
        _paletteColors.length > 2 ? _paletteColors[2] : _paletteColors[0];

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary.withValues(alpha: 0.6),
          secondary.withValues(alpha: 0.5),
          accent.withValues(alpha: 0.45),
        ],
        stops: const [0.0, 0.55, 1.0],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleFetchError(bool hasCurrentImage) {
    if (!mounted) return;

    setState(() {
      _currentState =
          hasCurrentImage ? ImageDisplayState.success : ImageDisplayState.error;
      _isLoadingNext = false;
    });
  }
}
