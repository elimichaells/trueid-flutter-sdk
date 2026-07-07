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

  /// Selfie capture settings.
  final SelfieCaptureConfig captureConfig;

  const VerificationConfig({
    this.forceNia = false,
    this.enforceFaceComparison = true,
    this.livenessPassed,
    this.transactionType,
    this.captureConfig = const SelfieCaptureConfig(),
  });

  Map<String, dynamic> toMap() => {
        'forceNia': forceNia,
        'enforceFaceComparison': enforceFaceComparison,
        'livenessPassed': livenessPassed,
        'transactionType': transactionType,
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
