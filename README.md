# Infinitum Down Detector

A comprehensive, free, and publicly accessible down detector application built with Flutter for monitoring Infinitum services and third-party dependencies across web, iOS, and Android platforms.

## Features

- **Public Access**: No login or sign-up required - completely free and open
- Real-time monitoring of Infinitum services
- Third-party service status checks (Firebase, Google, Apple, Discord, TikTok)
- Detailed status information with response times and error messages
- Issue reporting system for users to report problems
- Modern, responsive UI with dark mode support
- Automatic periodic health checks (every 60 seconds)
- Centralized logging system

## Services Monitored

### Infinitum Services
- iView/InfiniView (view.infinitumlive.com)
- Main Website (infinitumlive.com)
- Infinitum CRM (crm.infinitumlive.com)
- Onboarding (infinitum-onboarding.web.app)
- InfiniBoard (iboard.duckdns.org)
- InfiniBoard 2 (iboard2--infinitum-dashboard.us-east4.hosted.app)
- Infinitum Imagery (infinitumimagery.com)

### Third-Party Services
- Firebase
- Google Services
- Apple Services
- Discord
- TikTok

## Setup

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Firebase project (optional - for report storage)

### Installation

1. **Install Flutter dependencies:**
```bash
flutter pub get
```

2. **Configure Firebase (Optional):**
   
   If you want to use Firebase for storing reports:
   
   a. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
   
   b. Configure Firebase:
   ```bash
   flutterfire configure --project=infinitum-down-detector
   ```
   
   This will automatically generate `lib/firebase_options.dart` with your Firebase configuration.
   
   **Note:** The app will work without Firebase - reports will be logged to the console only.

3. **Run the application:**
```bash
# For web
flutter run -d chrome

# For iOS
flutter run -d ios

# For Android
flutter run -d android
```

### Firebase Setup (Web Deployment)

If deploying to Firebase Hosting:

1. **Install Firebase CLI:**
```bash
npm install -g firebase-tools
```

2. **Login to Firebase:**
```bash
firebase login
```

3. **Initialize Firebase Hosting:**
```bash
firebase init hosting
```

4. **Build and deploy:**
```bash
flutter build web
firebase deploy
```

Your app will be available at: `https://infinitum-down-detector.web.app`

## Project Structure

```
lib/
├── core/               # Core utilities (logger, config)
├── models/             # Data models (service_status)
├── providers/          # State management (service_status_provider)
├── screens/            # UI screens (status_page)
├── services/           # Business logic (health_check, report_service)
├── widgets/            # Reusable widgets (service_status_card, report_dialog)
├── firebase_options.dart  # Firebase configuration
└── main.dart           # App entry point
```

## Usage

1. **View Status**: The main page displays all monitored services with their current status
2. **Service Details**: Tap on any service card to view detailed information
3. **Report Issues**: Use the "Report Issue" button or the report button on individual service cards to report problems
4. **Auto-Refresh**: Services are automatically checked every 60 seconds
5. **Manual Refresh**: Use the refresh button in the app bar to manually check all services

## Configuration

Edit `lib/core/config.dart` to customize:
- Health check interval
- HTTP request timeout
- Retry attempts
- Service URLs

## Platform Support

- ✅ Web
- ✅ iOS
- ✅ Android

## Author

Kevin Doyle Jr. / Infinitum Imagery LLC

## License

Free and open for public use.

