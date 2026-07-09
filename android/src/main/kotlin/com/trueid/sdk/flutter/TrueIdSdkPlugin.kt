package com.trueid.sdk.flutter

import android.app.Activity
import android.content.Context
import android.content.Intent
import androidx.activity.ComponentActivity
import com.trueid.sdk.selfie.CameraFacing
import com.trueid.sdk.selfie.CaptureMode
import com.trueid.sdk.selfie.HostedVerificationCallback
import com.trueid.sdk.selfie.HostedVerificationConfig
import com.trueid.sdk.selfie.HostedVerificationResult
import com.trueid.sdk.selfie.NfcReadCallback
import com.trueid.sdk.selfie.NfcReadConfig
import com.trueid.sdk.selfie.NfcReadError
import com.trueid.sdk.selfie.NfcReadResult
import com.trueid.sdk.selfie.ResultFormat
import com.trueid.sdk.selfie.SelfieCaptureCallback
import com.trueid.sdk.selfie.SelfieCaptureConfig
import com.trueid.sdk.selfie.SelfieCaptureError
import com.trueid.sdk.selfie.SelfieCaptureResult
import com.trueid.sdk.selfie.TrueIDHostedVerification
import com.trueid.sdk.selfie.TrueIDNfcVerification
import com.trueid.sdk.selfie.TrueIDSdk
import com.trueid.sdk.selfie.TrueIDSelfieCapture
import com.trueid.sdk.selfie.TrueIDVerification
import com.trueid.sdk.selfie.VerificationCallback
import com.trueid.sdk.selfie.VerificationConfig
import com.trueid.sdk.selfie.VerificationError
import com.trueid.sdk.selfie.VerificationResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class TrueIdSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context
    private var activity: Activity? = null
    private var pendingResult: Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.trueid.sdk/flutter")
        channel.setMethodCallHandler(this)
        appContext = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener { requestCode, resultCode, data ->
            handleActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener { requestCode, resultCode, data ->
            handleActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> handleInitialize(call, result)
            "verify" -> handleVerify(call, result)
            "captureSelfie" -> handleCaptureSelfie(call, result)
            "launchHostedVerification" -> handleLaunchHostedVerification(call, result)
            "isNfcSupported" -> result.success(TrueIDNfcVerification.isNfcSupported(appContext))
            "isNfcEnabled" -> result.success(TrueIDNfcVerification.isNfcEnabled(appContext))
            "readNfcChip" -> handleReadNfcChip(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleInitialize(call: MethodCall, result: Result) {
        val apiKey = call.argument<String>("apiKey")
        if (apiKey.isNullOrBlank()) {
            result.error("INVALID_ARGUMENT", "apiKey is required", null)
            return
        }

        val envName = call.argument<String>("environment") ?: "production"
        val customBaseUrl = call.argument<String>("customBaseUrl")

        val environment = when (envName) {
            "staging" -> TrueIDSdk.Environment.STAGING
            "custom" -> TrueIDSdk.Environment.CUSTOM
            else -> TrueIDSdk.Environment.PRODUCTION
        }

        try {
            TrueIDSdk.initialize(
                apiKey = apiKey,
                environment = environment,
                customBaseUrl = customBaseUrl,
            )
            result.success(null)
        } catch (e: Exception) {
            result.error("INIT_ERROR", e.message, null)
        }
    }

    private fun handleVerify(call: MethodCall, result: Result) {
        val currentActivity = activity
        if (currentActivity !is ComponentActivity) {
            result.error("INCOMPATIBLE_ACTIVITY", "Activity must be a ComponentActivity", null)
            return
        }

        if (pendingResult != null) {
            result.error("ALREADY_ACTIVE", "A verification is already in progress", null)
            return
        }

        pendingResult = result

        val config = VerificationConfig(
            forceNia = call.argument<Boolean>("forceNia") ?: false,
            enforceFaceComparison = call.argument<Boolean>("enforceFaceComparison") ?: true,
            livenessPassed = call.argument<Boolean>("livenessPassed"),
            transactionType = call.argument<String>("transactionType"),
            captureConfig = SelfieCaptureConfig(
                captureMode = when (call.argument<String>("captureMode")) {
                    "manual" -> CaptureMode.MANUAL
                    else -> CaptureMode.AUTO
                },
                initialCamera = when (call.argument<String>("initialCamera")) {
                    "back" -> CameraFacing.BACK
                    else -> CameraFacing.FRONT
                },
                allowCameraSwitch = call.argument<Boolean>("allowCameraSwitch") ?: true,
                showFaceMesh = call.argument<Boolean>("showFaceMesh") ?: true,
                outputWidth = call.argument<Int>("outputWidth") ?: 600,
                outputHeight = call.argument<Int>("outputHeight") ?: 800,
                jpegQuality = call.argument<Int>("jpegQuality") ?: 94,
                burstFrameCount = call.argument<Int>("burstFrameCount") ?: 4,
                burstFrameDelayMs = (call.argument<Int>("burstFrameDelayMs") ?: 90).toLong(),
                resultFormat = ResultFormat.BASE64,
            ),
        )

        val callback = object : VerificationCallback {
            override fun onCompleted(verificationResult: VerificationResult) {
                val map = hashMapOf<String, Any?>(
                    "verified" to verificationResult.verified,
                    "lookupSource" to verificationResult.lookupSource,
                    "scanRecordId" to verificationResult.scanRecordId,
                    "fullName" to verificationResult.fullName,
                    "documentNumber" to verificationResult.documentNumber,
                    "nationality" to verificationResult.nationality,
                    "dateOfBirth" to verificationResult.dateOfBirth,
                    "gender" to verificationResult.gender,
                    "expiryDate" to verificationResult.expiryDate,
                    "phoneNumber" to verificationResult.phoneNumber,
                    "email" to verificationResult.email,
                    "selfieUrl" to verificationResult.selfieUrl,
                    "niaPhotoUrl" to verificationResult.niaPhotoUrl,
                    "transactionType" to verificationResult.transactionType,
                    "errorMessage" to verificationResult.errorMessage,
                    "errorCode" to verificationResult.errorCode,
                )
                pendingResult?.success(map)
                pendingResult = null
            }

            override fun onCancelled() {
                pendingResult?.success(null)
                pendingResult = null
            }

            override fun onError(error: VerificationError) {
                val code = when (error) {
                    is VerificationError.SdkNotInitialized -> "SDK_NOT_INITIALIZED"
                    is VerificationError.NetworkError -> "NETWORK_ERROR"
                    is VerificationError.ApiError -> error.code ?: "API_ERROR"
                    is VerificationError.CaptureError -> "CAPTURE_ERROR"
                }
                pendingResult?.error(code, error.message, null)
                pendingResult = null
            }
        }

        TrueIDVerification.launch(currentActivity, config, callback)
    }

    private fun handleCaptureSelfie(call: MethodCall, result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "Plugin is not attached to an activity", null)
            return
        }

        if (pendingResult != null) {
            result.error("ALREADY_ACTIVE", "A capture is already in progress", null)
            return
        }

        pendingResult = result

        val resultFormat = when (call.argument<String>("resultFormat") ?: "base64") {
            "byteArray" -> ResultFormat.BYTE_ARRAY
            "filePath" -> ResultFormat.FILE_PATH
            "all" -> ResultFormat.ALL
            else -> ResultFormat.BASE64
        }

        val config = SelfieCaptureConfig(
            captureMode = when (call.argument<String>("captureMode")) {
                "manual" -> CaptureMode.MANUAL
                else -> CaptureMode.AUTO
            },
            initialCamera = when (call.argument<String>("initialCamera")) {
                "back" -> CameraFacing.BACK
                else -> CameraFacing.FRONT
            },
            allowCameraSwitch = call.argument<Boolean>("allowCameraSwitch") ?: true,
            showFaceMesh = call.argument<Boolean>("showFaceMesh") ?: true,
            outputWidth = call.argument<Int>("outputWidth") ?: 600,
            outputHeight = call.argument<Int>("outputHeight") ?: 800,
            jpegQuality = call.argument<Int>("jpegQuality") ?: 94,
            burstFrameCount = call.argument<Int>("burstFrameCount") ?: 4,
            burstFrameDelayMs = (call.argument<Int>("burstFrameDelayMs") ?: 90).toLong(),
            resultFormat = resultFormat,
        )

        val callback = object : SelfieCaptureCallback {
            override fun onCaptured(captureResult: SelfieCaptureResult) {
                val map = hashMapOf<String, Any?>(
                    "base64" to captureResult.base64,
                    "filePath" to captureResult.filePath,
                    "burstFrames" to captureResult.burstFrames,
                )
                if (captureResult.imageBytes != null) {
                    map["imageBytes"] = captureResult.imageBytes!!.toList()
                }
                pendingResult?.success(map)
                pendingResult = null
            }

            override fun onCancelled() {
                pendingResult?.success(null)
                pendingResult = null
            }

            override fun onError(error: SelfieCaptureError) {
                pendingResult?.error("CAPTURE_ERROR", error.message, null)
                pendingResult = null
            }
        }

        if (currentActivity is ComponentActivity) {
            TrueIDSelfieCapture.launch(currentActivity, config, callback)
        } else {
            result.error("INCOMPATIBLE_ACTIVITY", "Activity must be a ComponentActivity", null)
            pendingResult = null
        }
    }

    private fun handleLaunchHostedVerification(call: MethodCall, result: Result) {
        val currentActivity = activity
        if (currentActivity !is ComponentActivity) {
            result.error("INCOMPATIBLE_ACTIVITY", "Activity must be a ComponentActivity", null)
            return
        }

        if (pendingResult != null) {
            result.error("ALREADY_ACTIVE", "A verification is already in progress", null)
            return
        }

        pendingResult = result

        val config = HostedVerificationConfig(
            sessionUrl = call.argument<String>("sessionUrl"),
            sessionToken = call.argument<String>("sessionToken"),
            mode = call.argument<String>("mode") ?: "standard",
            documentType = call.argument<String>("documentType"),
            theme = call.argument<String>("theme"),
            referenceId = call.argument<String>("referenceId"),
            completionGraceMillis = (call.argument<Int>("completionGraceMillis") ?: 4000).toLong(),
        )

        val callback = object : HostedVerificationCallback {
            override fun onResult(hostedResult: HostedVerificationResult) {
                val map = hashMapOf<String, Any?>(
                    "isSuccess" to hostedResult.isSuccess,
                    "status" to hostedResult.status,
                    "scanRecordId" to hostedResult.scanRecordId,
                    "sessionToken" to hostedResult.sessionToken,
                    "errorMessage" to hostedResult.errorMessage,
                )
                pendingResult?.success(map)
                pendingResult = null
            }
        }

        try {
            TrueIDHostedVerification.launch(currentActivity, config, callback)
        } catch (e: IllegalStateException) {
            pendingResult?.error("SDK_NOT_INITIALIZED", e.message, null)
            pendingResult = null
        }
    }

    private fun handleReadNfcChip(call: MethodCall, result: Result) {
        val currentActivity = activity
        if (currentActivity !is ComponentActivity) {
            result.error("INCOMPATIBLE_ACTIVITY", "Activity must be a ComponentActivity", null)
            return
        }

        if (pendingResult != null) {
            result.error("ALREADY_ACTIVE", "An NFC read is already in progress", null)
            return
        }

        val documentNumber = call.argument<String>("documentNumber")
        val dateOfBirth = call.argument<String>("dateOfBirth")
        val dateOfExpiry = call.argument<String>("dateOfExpiry")
        if (documentNumber.isNullOrBlank() || dateOfBirth.isNullOrBlank() || dateOfExpiry.isNullOrBlank()) {
            result.error("INVALID_ARGUMENT", "documentNumber, dateOfBirth and dateOfExpiry are required", null)
            return
        }

        pendingResult = result

        val config = NfcReadConfig(
            documentNumber = documentNumber,
            dateOfBirth = dateOfBirth,
            dateOfExpiry = dateOfExpiry,
            title = call.argument<String>("title") ?: "Scan your document chip",
            instructions = call.argument<String>("instructions")
                ?: "Hold your document against the back of your phone and keep it still.",
            timeoutMs = (call.argument<Int>("timeoutMs") ?: 20000).toLong(),
        )

        val callback = object : NfcReadCallback {
            override fun onRead(nfcResult: NfcReadResult) {
                val map = hashMapOf<String, Any?>(
                    "firstName" to nfcResult.firstName,
                    "lastName" to nfcResult.lastName,
                    "gender" to nfcResult.gender,
                    "issuingState" to nfcResult.issuingState,
                    "nationality" to nfcResult.nationality,
                    "documentNumber" to nfcResult.documentNumber,
                    "documentCode" to nfcResult.documentCode,
                    "dateOfBirth" to nfcResult.dateOfBirth,
                    "dateOfExpiry" to nfcResult.dateOfExpiry,
                    "personalNumber" to nfcResult.personalNumber,
                    "photoBase64" to nfcResult.photoBase64,
                    "signatureBase64" to nfcResult.signatureBase64,
                )
                pendingResult?.success(map)
                pendingResult = null
            }

            override fun onCancelled() {
                pendingResult?.success(null)
                pendingResult = null
            }

            override fun onError(error: NfcReadError) {
                val code = when (error) {
                    is NfcReadError.NfcNotSupported -> "NFC_NOT_SUPPORTED"
                    is NfcReadError.NfcDisabled -> "NFC_DISABLED"
                    is NfcReadError.Timeout -> "NFC_TIMEOUT"
                    is NfcReadError.ReadFailed -> "NFC_READ_FAILED"
                }
                pendingResult?.error(code, error.message, null)
                pendingResult = null
            }
        }

        TrueIDNfcVerification.launch(currentActivity, config, callback)
    }

    @Suppress("DEPRECATION")
    private fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return false
    }
}
