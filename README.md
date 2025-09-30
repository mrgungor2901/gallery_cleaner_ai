# Gallery Cleaner AI

AI-powered gallery cleaner app that helps users organize their photos by detecting blurry, small, and non-person images.

## Features

- 🤖 **AI-Powered Analysis**: Automatically detects blurry, small, and non-person images
- 🖼️ **Smart Gallery Management**: Live gallery access without data storage
- 🎯 **Selective Deletion**: Choose which photos to delete with preview
- 📱 **Modern UI**: Clean and intuitive Turkish interface
- ⚡ **Performance Optimized**: Efficient image processing and pagination

## Tech Stack

- **Framework**: Flutter 3.10+
- **Language**: Dart
- **State Management**: Provider
- **Gallery Access**: photo_manager
- **Image Processing**: image package
- **AI/ML**: Custom algorithms for blur and size detection
- **Permissions**: permission_handler

## Getting Started

### Prerequisites

- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code
- Android device or emulator (API level 21+)

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd gallery_cleaner_ai
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── app/                    # App configuration
│   ├── app.dart           # Main app widget
│   └── routes.dart        # Route definitions
├── core/                  # Core functionality
│   ├── constants/         # App constants
│   └── services/          # Core services
├── features/              # Feature modules
│   ├── onboarding/        # Onboarding screens
│   ├── gallery/           # Gallery management
│   └── ai_analysis/       # AI analysis features
└── shared/                # Shared components
    └── themes/            # App themes
```

## Features Overview

### AI Analysis
- **Blur Detection**: Uses Laplacian variance to detect blurry images
- **Size Detection**: Identifies low-resolution images
- **Person Detection**: Basic skin-tone based person detection (placeholder for ML model)

### Gallery Management
- Live gallery access
- Pagination for performance
- Search functionality
- Batch operations

### User Experience
- Turkish language support
- Smooth animations
- Progress tracking
- Intuitive selection interface

## Permissions

The app requires the following permissions:
- **Photos**: To access and manage gallery photos
- **Storage**: For reading image files

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue in the GitHub repository.
