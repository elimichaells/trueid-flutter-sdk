/// Environment for the TrueID SDK.
enum TrueIdEnvironment {
  production,
  staging,
  custom,
}

/// Capture mode for the selfie camera.
enum CaptureMode {
  auto,
  manual,
}

/// Camera facing direction.
enum CameraFacing {
  front,
  back,
}

/// Result format for standalone selfie capture.
enum ResultFormat {
  byteArray,
  filePath,
  base64,
  all,
}

/// Configuration for the verification flow.
class VerificationConfig {
  /// Force NIA lookup even if a local match exists.
  final bool forceNia;

  /// Require face match on local lookups.
  final bool enforceFaceComparison;

  /// Optional active-challenge liveness outcome supplied by the host app.
  final bool? livenessPassed;

  /// Optional transaction type label for your records.
  final String? transactionType;

  /// Optional choices shown as a dropdown on the review screen; when empty
  /// the row is hidden and [transactionType] is used as-is.
  final List<String> transactionTypes;

  /// Run the guided liveness challenge (turn head left/right + countdown)
  /// during selfie capture.
  final bool requireLiveness;

  /// Show the Photo Instructions screen before opening the camera.
  final bool showGuidelines;

  /// Use the institution's server-managed `selfieCapture` setting. This maps
  /// `guided`, `manual`, and `auto` to the native flow. Disable only when the
  /// integration must use the local capture options below.
  final bool useOrganizationCaptureSettings;

  /// Selfie capture settings.
  final SelfieCaptureConfig captureConfig;

  const VerificationConfig({
    this.forceNia = false,
    this.enforceFaceComparison = true,
    this.livenessPassed,
    this.transactionType,
    this.transactionTypes = const [],
    this.requireLiveness = true,
    this.showGuidelines = true,
    this.useOrganizationCaptureSettings = true,
    this.captureConfig = const SelfieCaptureConfig(),
  });

  Map<String, dynamic> toMap() => {
        'forceNia': forceNia,
        'enforceFaceComparison': enforceFaceComparison,
        'livenessPassed': livenessPassed,
        'transactionType': transactionType,
        'transactionTypes': transactionTypes,
        'requireLiveness': requireLiveness,
        'showGuidelines': showGuidelines,
        'useOrganizationCaptureSettings': useOrganizationCaptureSettings,
        'captureMode': captureConfig.captureMode.name,
        'initialCamera': captureConfig.initialCamera.name,
        'allowCameraSwitch': captureConfig.allowCameraSwitch,
        'showFaceMesh': captureConfig.showFaceMesh,
        'outputWidth': captureConfig.outputWidth,
        'outputHeight': captureConfig.outputHeight,
        'jpegQuality': captureConfig.jpegQuality,
        'burstFrameCount': captureConfig.burstFrameCount,
        'burstFrameDelayMs': captureConfig.burstFrameDelayMs,
      };
}

/// Configuration for the selfie camera.
class SelfieCaptureConfig {
  final CaptureMode captureMode;
  final CameraFacing initialCamera;
  final bool allowCameraSwitch;
  final bool showFaceMesh;
  final int outputWidth;
  final int outputHeight;
  final int jpegQuality;
  final int burstFrameCount;
  final int burstFrameDelayMs;
  final ResultFormat resultFormat;

  const SelfieCaptureConfig({
    this.captureMode = CaptureMode.auto,
    this.initialCamera = CameraFacing.front,
    this.allowCameraSwitch = true,
    this.showFaceMesh = true,
    this.outputWidth = 600,
    this.outputHeight = 800,
    this.jpegQuality = 94,
    this.burstFrameCount = 4,
    this.burstFrameDelayMs = 90,
    this.resultFormat = ResultFormat.base64,
  });

  Map<String, dynamic> toMap() => {
        'captureMode': captureMode.name,
        'initialCamera': initialCamera.name,
        'allowCameraSwitch': allowCameraSwitch,
        'showFaceMesh': showFaceMesh,
        'outputWidth': outputWidth,
        'outputHeight': outputHeight,
        'jpegQuality': jpegQuality,
        'burstFrameCount': burstFrameCount,
        'burstFrameDelayMs': burstFrameDelayMs,
        'resultFormat': resultFormat.name,
      };
}

/// Result of an identity verification.
class VerificationResult {
  final bool verified;
  final String? lookupSource;
  final String? scanRecordId;
  final String? fullName;
  final String? documentNumber;
  final String? nationality;
  final String? dateOfBirth;
  final String? gender;
  final String? expiryDate;
  final String? phoneNumber;
  final String? email;
  final String? selfieUrl;
  final String? niaPhotoUrl;
  final String? transactionType;
  final String? errorMessage;
  final String? errorCode;

  /// True when the identity was verified and no error occurred.
  bool get isSuccess => verified && errorMessage == null;

  const VerificationResult({
    required this.verified,
    this.lookupSource,
    this.scanRecordId,
    this.fullName,
    this.documentNumber,
    this.nationality,
    this.dateOfBirth,
    this.gender,
    this.expiryDate,
    this.phoneNumber,
    this.email,
    this.selfieUrl,
    this.niaPhotoUrl,
    this.transactionType,
    this.errorMessage,
    this.errorCode,
  });

  factory VerificationResult.fromMap(Map<dynamic, dynamic> map) {
    return VerificationResult(
      verified: map['verified'] as bool? ?? false,
      lookupSource: map['lookupSource'] as String?,
      scanRecordId: map['scanRecordId'] as String?,
      fullName: map['fullName'] as String?,
      documentNumber: map['documentNumber'] as String?,
      nationality: map['nationality'] as String?,
      dateOfBirth: map['dateOfBirth'] as String?,
      gender: map['gender'] as String?,
      expiryDate: map['expiryDate'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      email: map['email'] as String?,
      selfieUrl: map['selfieUrl'] as String?,
      niaPhotoUrl: map['niaPhotoUrl'] as String?,
      transactionType: map['transactionType'] as String?,
      errorMessage: map['errorMessage'] as String?,
      errorCode: map['errorCode'] as String?,
    );
  }

  @override
  String toString() =>
      'VerificationResult(verified: $verified, fullName: $fullName, documentNumber: $documentNumber)';
}

/// Result of a standalone selfie capture.
class SelfieCaptureResult {
  /// Raw image bytes (when resultFormat includes BYTE_ARRAY or ALL).
  final List<int>? imageBytes;

  /// Base64-encoded principal selfie (when resultFormat includes BASE64 or ALL).
  final String? base64;

  /// Base64-encoded burst frames captured around the principal selfie.
  final List<String>? burstFrames;

  /// File path to saved image (when resultFormat includes FILE_PATH or ALL).
  final String? filePath;

  const SelfieCaptureResult({
    this.imageBytes,
    this.base64,
    this.burstFrames,
    this.filePath,
  });

  factory SelfieCaptureResult.fromMap(Map<dynamic, dynamic> map) {
    return SelfieCaptureResult(
      imageBytes: (map['imageBytes'] as List<dynamic>?)?.cast<int>(),
      base64: map['base64'] as String?,
      burstFrames: (map['burstFrames'] as List<dynamic>?)?.cast<String>(),
      filePath: map['filePath'] as String?,
    );
  }
}

/// Configuration for the hosted verification flow — document capture + selfie
/// with liveness, opened in a Chrome Custom Tab. Same UI/UX as the TrueID web
/// widget and hosted component.
///
/// Two ways to provide a session:
///
/// 1. **Backend-created session (recommended):** create a widget session from
///    your backend (`POST /api/widget-sessions`) and pass its [sessionUrl] and
///    [sessionToken] here. Your API key never ships in the app.
///
/// 2. **SDK-created session:** leave [sessionUrl] null and the SDK creates the
///    session with the key from [TrueIdSdk.initialize]. Use a publishable
///    (`pk_...`) key for this.
class HostedVerificationConfig {
  /// Hosted verification URL from a backend-created session.
  final String? sessionUrl;

  /// Session token matching [sessionUrl]; used to watch for completion.
  final String? sessionToken;

  /// Flow when the SDK creates the session: "standard", "pin_selfie" or "identity_lookup".
  final String mode;

  /// Preselected document type (e.g. "ghana_card", "auto").
  final String? documentType;

  /// "light", "dark" or "auto".
  final String? theme;

  /// Your own correlation id, echoed back on the scan record.
  final String? referenceId;

  /// How long to keep watching for a result after the browser tab closes, in milliseconds.
  final int completionGraceMillis;

  const HostedVerificationConfig({
    this.sessionUrl,
    this.sessionToken,
    this.mode = 'standard',
    this.documentType,
    this.theme,
    this.referenceId,
    this.completionGraceMillis = 4000,
  });

  Map<String, dynamic> toMap() => {
        'sessionUrl': sessionUrl,
        'sessionToken': sessionToken,
        'mode': mode,
        'documentType': documentType,
        'theme': theme,
        'referenceId': referenceId,
        'completionGraceMillis': completionGraceMillis,
      };
}

/// Result of a hosted verification flow.
///
/// When [isSuccess] is true, exchange [scanRecordId] (or [sessionToken]) for
/// the full verification record from your backend using your secret key:
/// `GET /api/v1/scan-records/{scanRecordId}`.
class HostedVerificationResult {
  final bool isSuccess;

  /// Final session status: COMPLETED, EXPIRED, CANCELLED or FAILED.
  final String status;

  /// Scan record id to retrieve full results server-side.
  final String? scanRecordId;

  /// The widget session token.
  final String? sessionToken;

  final String? errorMessage;

  const HostedVerificationResult({
    required this.isSuccess,
    required this.status,
    this.scanRecordId,
    this.sessionToken,
    this.errorMessage,
  });

  factory HostedVerificationResult.fromMap(Map<dynamic, dynamic> map) {
    return HostedVerificationResult(
      isSuccess: map['isSuccess'] as bool? ?? false,
      status: map['status'] as String? ?? 'FAILED',
      scanRecordId: map['scanRecordId'] as String?,
      sessionToken: map['sessionToken'] as String?,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  @override
  String toString() =>
      'HostedVerificationResult(status: $status, isSuccess: $isSuccess, scanRecordId: $scanRecordId)';
}

/// Error from the TrueID SDK.
class TrueIdException implements Exception {
  final String code;
  final String message;

  const TrueIdException({required this.code, required this.message});

  @override
  String toString() => 'TrueIdException($code): $message';
}

/// BAC key inputs for an NFC chip read, plus the on-screen copy for the
/// tap-to-scan step. [documentNumber], [dateOfBirth] and [dateOfExpiry]
/// normally come from a prior MRZ camera scan.
///
/// NFC chip reads only run natively — there is no browser/widget equivalent,
/// since Web NFC cannot perform ISO 7816 APDU exchanges.
class NfcReadConfig {
  final String documentNumber;

  /// yyMMdd, matching the MRZ date format.
  final String dateOfBirth;

  /// yyMMdd, matching the MRZ date format.
  final String dateOfExpiry;

  final String title;
  final String instructions;
  final int timeoutMs;

  const NfcReadConfig({
    required this.documentNumber,
    required this.dateOfBirth,
    required this.dateOfExpiry,
    this.title = 'Scan your document chip',
    this.instructions =
        'Hold your document against the back of your phone and keep it still.',
    this.timeoutMs = 20000,
  });

  Map<String, dynamic> toMap() => {
        'documentNumber': documentNumber,
        'dateOfBirth': dateOfBirth,
        'dateOfExpiry': dateOfExpiry,
        'title': title,
        'instructions': instructions,
        'timeoutMs': timeoutMs,
      };
}

/// Parsed contents of an ICAO 9303 chip read (DG1 MRZ + DG2 face + DG7
/// signature + DG11 additional details).
class NfcReadResult {
  final String firstName;
  final String lastName;
  final String gender;
  final String issuingState;
  final String nationality;
  final String documentNumber;
  final String documentCode;
  final String dateOfBirth;
  final String dateOfExpiry;
  final String personalNumber;

  /// Face image (DG2), PNG bytes base64-encoded.
  final String? photoBase64;

  /// Signature image (DG7), PNG bytes base64-encoded, when present on the chip.
  final String? signatureBase64;

  const NfcReadResult({
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.issuingState,
    required this.nationality,
    required this.documentNumber,
    required this.documentCode,
    required this.dateOfBirth,
    required this.dateOfExpiry,
    required this.personalNumber,
    this.photoBase64,
    this.signatureBase64,
  });

  factory NfcReadResult.fromMap(Map<dynamic, dynamic> map) {
    return NfcReadResult(
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      gender: map['gender'] as String? ?? '',
      issuingState: map['issuingState'] as String? ?? '',
      nationality: map['nationality'] as String? ?? '',
      documentNumber: map['documentNumber'] as String? ?? '',
      documentCode: map['documentCode'] as String? ?? '',
      dateOfBirth: map['dateOfBirth'] as String? ?? '',
      dateOfExpiry: map['dateOfExpiry'] as String? ?? '',
      personalNumber: map['personalNumber'] as String? ?? '',
      photoBase64: map['photoBase64'] as String?,
      signatureBase64: map['signatureBase64'] as String?,
    );
  }

  @override
  String toString() =>
      'NfcReadResult(documentNumber: $documentNumber, nationality: $nationality)';
}
