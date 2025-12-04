# Random Image Oracle

A Flutter app that displays random images with dynamic color palettes and animated borders.

**[View Screen Recording](./ScreenRecording.mov)** - See the app in action

## Features

- **Random Image Display**: Fetches random images from a remote API
- **Dynamic Color Palette**: Extracts dominant colors from each image and applies them to:
  - Animated rotating border gradient
  - Background gradient that smoothly transitions between images
- **Smart Loading States**: Maintains the current image while loading the next one
- **Color Extraction in Isolates**: Image processing runs in background threads to keep the UI smooth
- **Elegant Animations**: Smooth transitions between images with fade and scale effects

## Architecture

- **Clean Separation of Concerns**: Service layer decouples business logic from UI
- **Compute Isolates**: Heavy image processing runs on background threads
- **Stateless Components**: Modular, reusable widget architecture
- **Modern Dart**: Leverages pattern matching, sealed classes, and extension methods

## Getting Started

```bash
flutter pub get
flutter run
```

## How It Works

1. App fetches a random image URL from the API
2. Image is precached for smooth loading
3. Color palette is extracted using an isolate to prevent UI blocking
4. Dominant colors animate the border and background
5. Tap "Another" to load the next random image
