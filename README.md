# TrueID SDK for Flutter

A Flutter plugin for identity verification via Ghana Card (NIA). Captures a selfie with ML Kit face detection, submits it alongside a Ghana Card PIN to TrueID, and returns the verification result.

## Features

- **Hosted document verification** — document capture + selfie with liveness via TrueID's hosted flow in a Chrome Custom Tab, one Dart call, same UI/UX as the TrueID web widget
- End-to-end verification — PIN entry, selfie capture, and NIA verification in one call
- Standalone selfie capture — Use just the camera + face detection
- ML Kit face detection with real-time alignment guidance
- Simple async Dart API

## Platform Support

| Platform | Supported |
|----------|-----------|
| Android  | Yes       |
| iOS      | No (planned) |

## Installation

```yaml
dependencies:
  trueid_sdk: ^1.0.0
```

Then run:

```bash
flutter pub get
```

### Android Setup

Add the TrueID Maven repository to your `android/settings.gradle.kts`:

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://app.trueid.info/sdk/android") }
    }
}
```

On-prem institutions: replace `app.trueid.info` with your TrueID server origin.

JitPack (`maven { url = uri("https://jitpack.io") }`, `com.github.elimichaells:trueid-selfie-sdk`) is still supported as a legacy fallback if you can't reach the self-hosted repo.

Ensure your `minSdkVersion` is at least **24** in `android/app/build.gradle`:

```groovy
android {
    defaultConfig {
        minSdkVersion 24
    }
}
```

## Quick Start

### 1. Initialize

```dart
import 'package:trueid_sdk/trueid_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TrueIdSdk.initialize(apiKey: 'your-api-key');
  runApp(MyApp());
}
```

### 2. Hosted Document Verification (recommended)

Full document verification — document capture, selfie with liveness, review — using TrueID's hosted flow in a Chrome Custom Tab. No camera UI to build; same UI/UX as the TrueID web widget.

```dart
Future<void> verifyDocument() async {
  final result = await TrueIdSdk.launchHostedVerification(
    config: HostedVerificationConfig(
      mode: 'standard',           // or 'pin_selfie', 'identity_lookup'
      documentType: 'auto',        // optional preselect
      referenceId: 'your-ref-123', // optional correlation id
    ),
  );

  switch (result.status) {
    case 'CANCELLED':
      print('User cancelled');
      break;
    default:
      if (result.isSuccess) {
        // Send result.scanRecordId to your backend, then fetch the full
        // record with your secret key: GET /api/v1/scan-records/{id}
      } else {
        print('Failed: ${result.status} ${result.errorMessage}');
      }
  }
}
```

For production-grade key hygiene, create the session from your backend (`POST /api/widget-sessions` with your API key) and hand the app only the session url + token:

```dart
TrueIdSdk.launchHostedVerification(
  config: HostedVerificationConfig(sessionUrl: url, sessionToken: token),
);
```

### 3. Native NIA Verification

```dart
Future<void> verifyIdentity() async {
  try {
    final result = await TrueIdSdk.verify(
      config: VerificationConfig(
        forceNia: false,
        enforceFaceComparison: true,
        transactionType: 'onboarding',
      ),
    );

    if (result == null) {
      print('User cancelled');
      return;
    }

    if (result.isSuccess) {
      print('Verified: ${result.fullName}');
      print('Document: ${result.documentNumber}');
      print('DOB: ${result.dateOfBirth}');
    } else {
      print('Failed: ${result.errorMessage}');
    }
  } on TrueIdException catch (e) {
    print('Error: ${e.code} - ${e.message}');
  }
}
```

### 4. Standalone Selfie Capture

No API key required for just the camera:

```dart
Future<void> takeSelfie() async {
  final result = await TrueIdSdk.captureSelfie(
    config: SelfieCaptureConfig(
      captureMode: CaptureMode.auto,
      resultFormat: ResultFormat.base64,
    ),
  );

  if (result != null) {
    print('Got selfie: ${result.base64?.length} chars');
  }
}
```

## API Reference

### TrueIdSdk

| Method | Description |
|--------|-------------|
| `initialize({apiKey, environment, customBaseUrl})` | Initialize with your API key. Call once before `verify()` or `launchHostedVerification()`. |
| `launchHostedVerification({config})` | Launch the hosted document verification flow. Returns `HostedVerificationResult` (check `.status` for `"CANCELLED"`). |
| `verify({config})` | Launch full native verification flow. Returns `VerificationResult?`. |
| `captureSelfie({config})` | Launch standalone selfie capture. Returns `SelfieCaptureResult?`. |

### HostedVerificationConfig

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `sessionUrl` | `String?` | `null` | Hosted verification URL from a backend-created session |
| `sessionToken` | `String?` | `null` | Session token matching `sessionUrl`; used to watch for completion |
| `mode` | `String` | `'standard'` | Flow when the SDK creates the session: `'standard'`, `'pin_selfie'` or `'identity_lookup'` |
| `documentType` | `String?` | `null` | Preselected document type (e.g. `'ghana_card'`, `'auto'`) |
| `theme` | `String?` | `null` | `'light'`, `'dark'` or `'auto'` |
| `referenceId` | `String?` | `null` | Your own correlation id, echoed back on the scan record |
| `completionGraceMillis` | `int` | `4000` | How long to keep watching for a result after the browser tab closes |

### HostedVerificationResult

| Field | Type | Description |
|-------|------|-------------|
| `isSuccess` | `bool` | Whether the flow completed successfully |
| `status` | `String` | `COMPLETED`, `EXPIRED`, `CANCELLED` or `FAILED` |
| `scanRecordId` | `String?` | Record ID to retrieve full results server-side |
| `sessionToken` | `String?` | The widget session token |
| `errorMessage` | `String?` | Error description (if failed) |

### VerificationConfig

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `forceNia` | `bool` | `false` | Force NIA lookup even if local match exists |
| `enforceFaceComparison` | `bool` | `true` | Require face match on local lookups |
| `transactionType` | `String?` | `null` | Optional label for your records |
| `captureConfig` | `SelfieCaptureConfig` | default | Selfie camera settings |

### VerificationResult

| Field | Type | Description |
|-------|------|-------------|
| `verified` | `bool` | Whether identity was verified |
| `isSuccess` | `bool` | `verified && errorMessage == null` |
| `fullName` | `String?` | Full name from Ghana Card |
| `documentNumber` | `String?` | Ghana Card number |
| `nationality` | `String?` | Nationality |
| `dateOfBirth` | `String?` | Date of birth |
| `gender` | `String?` | Gender |
| `expiryDate` | `String?` | Card expiry date |
| `phoneNumber` | `String?` | Phone number on record |
| `email` | `String?` | Email on record |
| `selfieUrl` | `String?` | URL of captured selfie |
| `niaPhotoUrl` | `String?` | URL of NIA photo on file |
| `errorMessage` | `String?` | Error description (if failed) |
| `errorCode` | `String?` | Error code (if failed) |

### Environments

```dart
// Production (default)
TrueIdSdk.initialize(apiKey: 'key');

// Staging
TrueIdSdk.initialize(
  apiKey: 'key',
  environment: TrueIdEnvironment.staging,
);

// Custom
TrueIdSdk.initialize(
  apiKey: 'key',
  environment: TrueIdEnvironment.custom,
  customBaseUrl: 'https://your-server.com',
);
```

## Permissions

The SDK handles these automatically:

- **CAMERA** — For selfie capture
- **INTERNET** — For API calls

You must handle the runtime camera permission in your app before calling `verify()` or `captureSelfie()`.

## Getting an API Key

Sign up at [app.trueid.info](https://app.trueid.info) to get your API key.

## License

MIT License. See [LICENSE](LICENSE) for details.
