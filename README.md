# TrueID SDK for Flutter

> ## ⚠️ Discontinued — migrate to the split packages
>
> `trueid_sdk` is discontinued on pub.dev. **Existing integrations keep working
> with no action required** — this package, the API it calls, and the native
> Maven artifact it depends on are all still live and maintained, so nothing
> breaks if you stay on `trueid_sdk: ^2.0.0`. There's no forced sunset date.
>
> New projects, and anyone who wants smaller installs / independent versioning
> per product, should use the split packages instead:
>
> | This package's API | Use instead |
> |---|---|
> | `TrueIdSdk.initialize()`, `captureSelfie()` | [`trueid_core`](https://pub.dev/packages/trueid_core) |
> | `TrueIdSdk.verify()`, `fastTrackVerify()` | [`trueid_nia_sdk`](https://pub.dev/packages/trueid_nia_sdk) |
> | `TrueIdSdk.launchHostedVerification()` | [`trueid_hosted_sdk`](https://pub.dev/packages/trueid_hosted_sdk) |
> | *(new — no old equivalent)* | [`trueid_document_sdk`](https://pub.dev/packages/trueid_document_sdk) — native standard document verification |
> | `TrueIdSdk.isNfcSupported()`, `isNfcEnabled()`, `readNfcChip()` | Still only here for now — the standalone `trueid_nfc_sdk` package isn't published yet (still under active development). Keep using `trueid_sdk` for NFC until it is. |
>
> Migrating is mostly a rename: swap the import and drop the `TrueIdSdk.` /
> `TrueIdVerification.` prefix for the equivalent call on the new package's own
> class — method signatures and config objects are unchanged. See each
> package's own README for full API details.

A Flutter plugin for identity verification via Ghana Card (NIA). Captures a selfie with ML Kit face detection, submits it alongside a Ghana Card PIN to TrueID, and returns the verification result.

## Features

- **Hosted document verification** — document capture + selfie with liveness via TrueID's hosted flow in a Chrome Custom Tab, one Dart call, same UI/UX as the TrueID web widget
- End-to-end verification — PIN entry, selfie capture, and NIA verification in one call
- **Fast Track verification** — re-verify a known individual with a fresh live selfie and server-side face match
- **NFC chip reading** — reads the ICAO 9303 chip on Ghana Card / ePassport-style documents (BAC/PACE, DG1/DG2/DG7/DG11) for stronger-than-OCR accuracy
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

**Required:** your `MainActivity` must extend `FlutterFragmentActivity`, not the `FlutterActivity` that `flutter create` generates — the SDK's camera and NFC screens need an androidx `ComponentActivity` host, and calls fail with `INCOMPATIBLE_ACTIVITY` otherwise:

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

## Quick Start

### 1. Initialize

```dart
import 'package:trueid_sdk/trueid_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TrueIdSdk.initialize(
    secretKey: 'sk_your_secret_key',           // for verify() / captureSelfie()
    publishableKey: 'pk_your_publishable_key', // for launchHostedVerification()
  );
  runApp(MyApp());
}
```

Both keys live on the same page (app.trueid.info → Settings → API) but are not interchangeable — the backend rejects a publishable key on secret-only endpoints and vice versa. Pass whichever your app uses; at least one is required.

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

### 5. Fast Track Verification

Use Fast Track when your authenticated backend has already selected the
individual to re-verify. Pass its internal `individualId` to the SDK; the SDK
does not expose person search from a mobile device, so organization customer
data is not discoverable in the app.

```dart
final result = await TrueIdSdk.fastTrackVerify(
  config: FastTrackVerificationConfig(
    individualId: individualIdFromYourBackend,
  ),
);

if (result?.isSuccess == true) {
  print('Fast Track record: ${result!.scanRecordId}');
}
```

By default, capture mode and active head-turn liveness follow the
organization's server policy. If active liveness is off, passive anti-spoof
checks still use the submitted burst frames.

### 6. NFC Chip Read

Reads the ICAO 9303 chip on Ghana Card / ePassport-style documents. The three BAC key fields normally come from a prior MRZ camera scan. There is no browser/widget equivalent — Web NFC cannot perform the ISO 7816 APDU exchanges an ICAO 9303 chip requires, so this is native-only.

```dart
Future<void> readChip(String documentNumber, String dob, String doe) async {
  if (!await TrueIdSdk.isNfcEnabled()) {
    print('Turn on NFC to continue');
    return;
  }

  try {
    final chip = await TrueIdSdk.readNfcChip(
      config: NfcReadConfig(
        documentNumber: documentNumber,
        dateOfBirth: dob,   // yyMMdd
        dateOfExpiry: doe,  // yyMMdd
      ),
    );

    if (chip == null) {
      print('User cancelled');
      return;
    }

    print('Chip read: ${chip.firstName} ${chip.lastName}');
  } on TrueIdException catch (e) {
    // e.code: NFC_NOT_SUPPORTED, NFC_DISABLED, NFC_TIMEOUT, NFC_READ_FAILED
    print('NFC error: ${e.code} - ${e.message}');
  }
}
```

## API Reference

### TrueIdSdk

| Method | Description |
|--------|-------------|
| `initialize({secretKey, publishableKey, environment, customBaseUrl})` | Initialize with your API key(s). `secretKey` is required for `verify()`/`captureSelfie()`; `publishableKey` is required for `launchHostedVerification()`. Call once before use. |
| `launchHostedVerification({config})` | Launch the hosted document verification flow. Returns `HostedVerificationResult` (check `.status` for `"CANCELLED"`). |
| `verify({config})` | Launch full native verification flow. Returns `VerificationResult?`. |
| `fastTrackVerify({config})` | Capture a live selfie and re-verify a known server-selected individual. Returns `FastTrackVerificationResult?`. |
| `captureSelfie({config})` | Launch standalone selfie capture. Returns `SelfieCaptureResult?`. |
| `isNfcSupported()` | Whether this device has NFC hardware at all. |
| `isNfcEnabled()` | Whether NFC hardware is present and switched on. |
| `readNfcChip({config})` | Read an ICAO 9303 chip over NFC. Returns `NfcReadResult?` (`null` if cancelled). |

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
| `transactionTypes` | `List<String>` | `[]` | Optional dropdown choices on the review screen |
| `requireLiveness` | `bool` | `true` | Guided liveness challenge (turn head left/right + countdown) |
| `showGuidelines` | `bool` | `true` | Photo Instructions screen before the camera |
| `useOrganizationCaptureSettings` | `bool` | `true` | Use the institution's `guided`, `manual`, or `auto` selfie-capture setting; passive anti-spoof remains mandatory |
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

### FastTrackVerificationConfig

| Parameter | Type | Description |
|-----------|------|-------------|
| `individualId` | `String` | Required internal individual ID from your authenticated backend. |
| `useOrganizationCaptureSettings` | `bool` | Default `true`; applies the organization capture/liveness policy. |
| `requireLiveness` | `bool` | Used only when organization settings are disabled; defaults to `true`. |
| `captureConfig` | `SelfieCaptureConfig` | Optional local camera behaviour. |

### FastTrackVerificationResult

| Field | Type | Description |
|-------|------|-------------|
| `verified` / `isSuccess` | `bool` | Whether the face match and server verification completed. |
| `scanRecordId` | `String?` | New verification record id. |
| `message` | `String?` | Server completion message. |

### NfcReadConfig

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `documentNumber` | `String` | `''` | Optional MRZ document number; empty starts native BAC-key acquisition |
| `dateOfBirth` | `String` | `''` | Optional BAC key field, `yyMMdd` |
| `dateOfExpiry` | `String` | `''` | Optional BAC key field, `yyMMdd` |
| `title` | `String` | `'Read your document chip'` | Screen title |
| `instructions` | `String` | default copy | Screen body text |
| `timeoutMs` | `int` | `60000` | How long to wait for a chip before offering a retry |
| `showReview` | `bool` | `true` | Show the SDK confirmation screen before returning |
| `useOrganizationAppearanceSettings` | `bool` | `true` | Apply organization theme and brand colors |
| `themeMode` | `NfcThemeMode` | `followSystem` | Local light/dark/system fallback |
| `primaryColor` / `secondaryColor` | `int` | TrueID defaults | Local brand-color fallbacks |
| `requireDataIntegrity` | `bool` | `true` | Require valid EF.SOD hashes and document signature |
| `allowMrzCameraScan` | `bool` | `true` | Offer checksum-validated on-device MRZ scanning |
| `allowManualEntry` | `bool` | `true` | Offer structured manual BAC-key entry |

### NfcReadResult

| Field | Type | Description |
|-------|------|-------------|
| `firstName` / `lastName` | `String` | From the chip's MRZ (DG1) |
| `gender` | `String` | From DG1 |
| `issuingState` / `nationality` | `String` | From DG1 |
| `documentNumber` / `documentCode` | `String` | From DG1 |
| `dateOfBirth` / `dateOfExpiry` | `String` | From DG1 |
| `personalNumber` | `String` | From DG1, falling back to DG11 |
| `photoBase64` | `String?` | Face image (DG2), PNG bytes base64-encoded |
| `signatureBase64` | `String?` | Signature image (DG7), when present on the chip |
| `accessProtocol` | `String` | Negotiated `PACE` or `BAC` channel |
| `dataIntegrityVerified` | `bool?` | Read data groups matched their EF.SOD hashes |
| `documentSignatureVerified` | `bool?` | EF.SOD signature verified with its embedded signing certificate |
| `verifiedDataGroups` | `List<int>` | Data-group numbers verified against EF.SOD |
| `warnings` | `List<String>` | Non-fatal omissions and trust limitations |

### Environments

```dart
// Production (default)
TrueIdSdk.initialize(secretKey: 'sk_key', publishableKey: 'pk_key');

// Staging
TrueIdSdk.initialize(
  secretKey: 'sk_key',
  publishableKey: 'pk_key',
  environment: TrueIdEnvironment.staging,
);

// Custom
TrueIdSdk.initialize(
  secretKey: 'sk_key',
  publishableKey: 'pk_key',
  environment: TrueIdEnvironment.custom,
  customBaseUrl: 'https://your-server.com',
);
```

## Permissions

The SDK handles these automatically:

- **CAMERA** — For selfie capture
- **INTERNET** — For API calls
- **NFC** — For chip reads (`readNfcChip()`); no-op on devices without NFC hardware

You must handle the runtime camera permission in your app before calling `verify()` or `captureSelfie()`.

## Getting an API Key

Sign up at [app.trueid.info](https://app.trueid.info) to get your API key.

## License

MIT License. See [LICENSE](LICENSE) for details.
