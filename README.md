# Infinitum Down Detector

A comprehensive, free, and publicly accessible down detector application built with Flutter for monitoring Infinitum services and third-party dependencies across web, iOS, and Android platforms.

## Features

- **Public Access**: No login or sign-up required - completely free and open
- **Backend-Driven Health Checks**: Server-side monitoring via Firebase Cloud Functions (not browser-based)
- **Real-Time Updates**: Live status updates via Firestore real-time listeners
- **Triple-Check Validation**: Prevents false positives with 3 consecutive checks before marking services as down
- **Comprehensive Component Monitoring**: Monitors subcomponents for each service (Auth, API, CDN, Database, etc.)
- **Functional Health Checks**: Actual API tests for critical services (e.g., Firebase Auth functional verification)
- **Detailed Status Information**: Response times, error messages, and historical data
- **Issue Reporting System**: Users can report problems directly from the app
- **Modern, Responsive UI**: Fully responsive design for phones, tablets, desktops, and ultra-wide screens
- **Dark Mode Support**: Automatic theme switching based on system preferences
- **Automatic Periodic Health Checks**: Server-side checks every 1 minute via scheduled Cloud Functions
- **Centralized Logging System**: Comprehensive logging with debug toggle

## Services Monitored

### Infinitum Services
- iView/InfiniView (view.infinitumlive.com)
- Main Website (infinitumlive.com)
- Infinitum CRM (crm.infinitumlive.com)
- Onboarding (infinitum-onboarding.web.app)
- InfiniBoard (iboard2--infinitum-dashboard.us-east4.hosted.app)
- Infinitum Imagery (infinitumimagery.com)

### Third-Party Services

#### Firebase
- Authentication (with functional health checks)
- Cloud Firestore
- Cloud Functions
- Cloud Messaging
- Hosting
- Realtime Database
- Storage
- Console
- Crashlytics
- Performance Monitoring
- App Hosting

#### Google Services
- Gmail
- Google Drive
- Google Docs
- Google Sheets
- Google Slides
- Google Forms
- Google Calendar
- Apps Script
- AppSheet

#### AWS
- EC2
- S3
- CloudFront
- API Gateway
- RDS
- Lambda

#### Apple Services
- App Store Connect
- Apple Push Notification Service (APNs)
- Sign in with Apple
- TestFlight
- iCloud

#### Discord
- API
- Gateway
- Media Proxy
- Voice

#### TikTok
- API
- LIVE
- CDN

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

## Monitoring Architecture

### Backend-Driven Health Checks

Health checks are performed server-side by Firebase Cloud Functions, ensuring all users see the same status regardless of their location, browser, or network conditions.

**Scheduled Function**: Runs every 1 minute via Cloud Scheduler
- Checks all Infinitum services and third-party services
- Updates Firestore with latest status
- Stores historical data for charts and graphs

### Triple-Check Validation

To prevent false positives and reduce noise:

1. **First Failure** → Mark as "suspected issue"
2. **Second Check** (2 seconds later) → If still failing, continue
3. **Third Check** (4 seconds later) → If all three fail, mark as "down" or "degraded"

This ensures transient network issues don't cause false alarms.

### Component Monitoring

Each service is monitored at multiple levels:

- **Main Service**: Overall service availability
- **Subcomponents**: Individual endpoints/components (Auth, API, CDN, Database, etc.)
- **Status Aggregation**: Overall service status determined by worst component status

### Functional Health Checks

For critical services like Firebase Auth, the system performs actual functional checks:
- Tests real API endpoints
- Verifies service functionality, not just status page availability
- Cross-validates with status page information

## Usage

1. **View Status**: The main page displays all monitored services with their current status
2. **Service Details**: Tap on any service card to view detailed information including component statuses
3. **Component Status**: Expand service cards to see individual component health
4. **Report Issues**: Use the "Report Issue" button or the report button on individual service cards to report problems
5. **Real-Time Updates**: Status updates automatically via Firestore real-time listeners
6. **History**: View historical status data and charts for each service
7. **Search & Filter**: Search services by name or filter to show only services with issues

## Configuration

### Client-Side Configuration

Edit `lib/core/config.dart` to customize:
- Health check interval (client-side refresh)
- HTTP request timeout
- Retry attempts
- Service URLs
- Component definitions

### Server-Side Configuration

Edit `functions/index.js` to customize:
- Scheduled health check interval (currently 1 minute)
- Triple-check validation delays
- Service and component definitions
- Status parsing logic

### Firebase Configuration

**Firestore Collections**:
- `service_status_cache`: Current status of all services
- `service_status_history/{serviceId}/entries`: Historical status data
- `reports`: User-submitted issue reports
- `incidents`: System-generated incidents

**Security Rules**: Public read access for status data, authenticated write for reports

## Version

**Current Version**: 1.0.1 (Build 1)

Version information is consistent across:
- `pubspec.yaml`
- Android `build.gradle.kts`
- iOS `Info.plist`

## Platform Support

- ✅ **Web**: Fully responsive, works on all screen sizes (mobile to ultra-wide)
- ✅ **iOS**: Native iOS app with full feature support
- ✅ **Android**: Native Android app with full feature support

### Responsive Design

The UI automatically adapts to different screen sizes:
- **Phones** (< 600px): Single column layout, optimized spacing
- **Tablets** (600px - 1200px): Two-column layout where appropriate
- **Desktop** (> 1200px): Multi-column layouts, larger dialogs
- **Ultra-wide**: Content max-width constraints prevent excessive stretching

All text uses proper overflow handling (ellipsis, wrapping) to prevent cutoff or layout breaks.

## Author

Kevin Doyle Jr. / Infinitum Imagery LLC

## Deployment

### Web Deployment to Firebase Hosting

1. **Build the web app**:
```bash
flutter build web --release
```

2. **Deploy to Firebase Hosting**:
```bash
firebase deploy --only hosting
```

The app will be available at your Firebase Hosting URL (e.g., `https://infinitum-down-detector.web.app`)

### Cloud Functions Deployment

1. **Install dependencies**:
```bash
cd functions
npm install
```

2. **Deploy functions**:
```bash
firebase deploy --only functions
```

The scheduled health check function will automatically start running.

### Firestore Indexes

The app may require composite indexes for certain queries. Firebase will prompt you to create these when needed. You can also create them manually in the Firebase Console.

## Troubleshooting

### Services Always Showing as "Down"

- Check Cloud Functions logs: `firebase functions:log`
- Verify scheduled function is running: Check Cloud Scheduler in Firebase Console
- Ensure Firestore security rules allow public read access

### Firebase Auth Always Showing as "Down"

- The functional check uses a lightweight API endpoint test
- If consistently failing, verify Firebase project configuration
- Check Cloud Functions logs for specific error messages

### UI Layout Issues

- Ensure you're using the latest version (1.0.1)
- Clear app cache and restart
- Check browser console for errors (web platform)

## License

Free and open for public use.

## Author

Kevin Doyle Jr. / Infinitum Imagery LLC

