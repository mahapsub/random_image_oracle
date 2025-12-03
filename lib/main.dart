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
  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    // Automatically fetch an image when the app starts
    _fetchAndDisplayImage();
  }

  /// Fetches a random image URL from the server and updates the UI state
  Future<void> _fetchAndDisplayImage() async {
    setState(() {
      _currentState = ImageDisplayState.loading;
      _errorMessage = null;
    });

    try {
      final response = await _imageService.fetchRandomImage();
      setState(() {
        _currentState = ImageDisplayState.success;
        _imageUrl = response.url;
      });
    } on ImageServiceException catch (e) {
      setState(() {
        _currentState = ImageDisplayState.error;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _currentState = ImageDisplayState.error;
        _errorMessage = 'An unexpected error occurred';
      });
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
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _currentState == ImageDisplayState.loading
                  ? null
                  : _fetchAndDisplayImage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _currentState == ImageDisplayState.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _currentState == ImageDisplayState.error
                          ? 'Try Again'
                          : 'Another',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
