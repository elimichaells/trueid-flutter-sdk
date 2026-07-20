import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trueid_core/trueid_core.dart';
import 'package:trueid_nia_sdk/trueid_nia_sdk.dart';
import 'package:trueid_hosted_sdk/trueid_hosted_sdk.dart';
import 'package:trueid_document_sdk/trueid_document_sdk.dart';
import 'package:trueid_nfc_sdk/trueid_nfc_sdk.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrueID SDK Example',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1A6DAB),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _prefSecretKey = 'trueid_example_secret_key';
  static const _prefPublishableKey = 'trueid_example_publishable_key';

  String _status = 'Ready';
  String _secretKey = '';
  String _publishableKey = '';
  VerificationResult? _result;
  HostedVerificationResult? _hostedResult;
  NfcReadResult? _nfcResult;
  DocumentVerificationResult? _docResult;

  @override
  void initState() {
    super.initState();
    _loadApiKeysAndInit();
  }

  String _shorten(String key) =>
      key.length > 6 ? '…${key.substring(key.length - 6)}' : key;

  Future<void> _loadApiKeysAndInit() async {
    final prefs = await SharedPreferences.getInstance();
    final secret = prefs.getString(_prefSecretKey)?.trim() ?? '';
    final publishable = prefs.getString(_prefPublishableKey)?.trim() ?? '';
    if (secret.isEmpty && publishable.isEmpty) {
      setState(() => _status = 'Set your API keys via ⚙ (top right) to begin');
      return;
    }
    await _initializeSdk(secret, publishable);
  }

  Future<void> _initializeSdk(String secretKey, String publishableKey) async {
    try {
      await TrueIdSdk.initialize(
        secretKey: secretKey.isEmpty ? null : secretKey,
        publishableKey: publishableKey.isEmpty ? null : publishableKey,
      );
      setState(() {
        _secretKey = secretKey;
        _publishableKey = publishableKey;
        final parts = [
          if (secretKey.isNotEmpty) 'sk ${_shorten(secretKey)}',
          if (publishableKey.isNotEmpty) 'pk ${_shorten(publishableKey)}',
        ];
        _status = 'Ready (${parts.join(', ')})';
      });
    } catch (e) {
      setState(() => _status = 'SDK init failed: $e');
    }
  }

  bool _requireSecretKey() {
    if (_secretKey.isNotEmpty) return true;
    setState(() => _status =
        'Native NIA Verification needs your SECRET key — tap ⚙ first');
    return false;
  }

  bool _requirePublishableKey() {
    if (_publishableKey.isNotEmpty) return true;
    setState(() => _status =
        'Hosted Verification needs your PUBLISHABLE key — tap ⚙ first');
    return false;
  }

  Future<void> _openApiKeySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final secretController = TextEditingController(
      text: prefs.getString(_prefSecretKey) ?? '',
    );
    final publishableController = TextEditingController(
      text: prefs.getString(_prefPublishableKey) ?? '',
    );
    if (!mounted) return;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Keys'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'From app.trueid.info → Settings → API. Stored on this device only.\n\n'
              '• SECRET key (sk_…) — Native NIA Verification & Capture Selfie.\n'
              '• PUBLISHABLE key (pk_…) — Hosted Document Verification.\n\n'
              'Set both once; each button automatically uses the right one.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: secretController,
              autofocus: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Secret key',
                hintText: 'sk_...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: publishableController,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Publishable key',
                hintText: 'pk_...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    final secret = secretController.text.trim();
    final publishable = publishableController.text.trim();
    await prefs.setString(_prefSecretKey, secret);
    await prefs.setString(_prefPublishableKey, publishable);
    if (secret.isEmpty && publishable.isEmpty) {
      setState(() {
        _secretKey = '';
        _publishableKey = '';
        _status = 'API keys cleared — set them via ⚙ to begin';
      });
      return;
    }
    await _initializeSdk(secret, publishable);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API keys saved')),
      );
    }
  }

  Future<void> _verifyDocument() async {
    if (!_requirePublishableKey()) return;
    setState(() => _status = 'Opening hosted verification...');

    try {
      final result = await TrueIdHostedVerification.launch(
        config: const HostedVerificationConfig(mode: 'standard'),
      );

      setState(() {
        _hostedResult = result;
        _status = switch (result.status) {
          'CANCELLED' => 'Cancelled',
          _ when result.isSuccess => 'Verified: ${result.scanRecordId}',
          _ => 'Failed: ${result.status} ${result.errorMessage ?? ''}',
        };
      });
    } on TrueIdException catch (e) {
      setState(() => _status = 'Error: ${e.message}');
    }
  }

  Future<void> _verify() async {
    if (!_requireSecretKey()) return;
    setState(() => _status = 'Verifying...');

    try {
      final result = await TrueIdNiaVerification.verify(
        config: const VerificationConfig(
          enforceFaceComparison: true,
          transactionTypes: [
            'Cash Withdrawal',
            'Loan Application',
            'Account Opening',
            'SIM Registration',
            'Remittance Collection',
            'Other',
          ],
        ),
      );

      if (result == null) {
        setState(() => _status = 'Cancelled');
        return;
      }

      setState(() {
        _result = result;
        _status = result.isSuccess
            ? 'Verified: ${result.fullName}'
            : 'Failed: ${result.errorMessage}';
      });
    } on TrueIdException catch (e) {
      setState(() => _status = 'Error: ${e.message}');
    }
  }

  Future<void> _verifyStandardDocument() async {
    if (!_requireSecretKey()) return;
    setState(() => _status = 'Opening document verification...');

    try {
      final result = await TrueIdDocumentSdk.verifyDocument();

      if (result == null) {
        setState(() => _status = 'Cancelled');
        return;
      }

      setState(() {
        _docResult = result;
        _status = result.isSuccess
            ? 'Verified: ${result.fullName}'
            : 'Failed: ${result.errorMessage}';
      });
    } on TrueIdDocumentException catch (e) {
      setState(() => _status = 'Error: ${e.message}');
    }
  }

  Future<void> _captureSelfie() async {
    setState(() => _status = 'Capturing...');

    try {
      final result = await TrueIdSdk.captureSelfie(
        config: const SelfieCaptureConfig(
          resultFormat: ResultFormat.base64,
        ),
      );

      setState(() {
        _status = result != null
            ? 'Selfie captured (${result.base64?.length ?? 0} chars)'
            : 'Cancelled';
      });
    } on TrueIdException catch (e) {
      setState(() => _status = 'Error: ${e.message}');
    }
  }

  Future<void> _readNfc() async {
    setState(() => _status = 'Checking NFC…');

    final supported = await TrueIdNfc.isSupported();
    if (!supported) {
      setState(() => _status = 'This device has no NFC hardware');
      return;
    }
    setState(() => _status = 'Reading chip…');

    try {
      final result = await TrueIdNfc.readChip(
        // The native SDK now acquires the BAC keys in Step 1: scan the MRZ
        // with the camera or enter the three fields manually.
        config: const NfcReadConfig(),
      );

      setState(() {
        _nfcResult = result;
        _status = result != null
            ? 'Chip read: ${result.firstName} ${result.lastName}'
            : 'Cancelled';
      });
    } on TrueIdException catch (e) {
      setState(() => _status = 'NFC error: ${e.code} - ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrueID SDK Example'),
        actions: [
          IconButton(
            onPressed: _openApiKeySettings,
            tooltip: 'API key',
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_status, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _verifyDocument,
              child: const Text('Hosted Document Verification'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _verify,
              child: const Text('Native NIA Verification'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _verifyStandardDocument,
              child: const Text('Native Document Verification'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _captureSelfie,
              child: const Text('Capture Selfie Only'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _readNfc,
              child: const Text('Read NFC Chip'),
            ),
            if (_hostedResult != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              Text('Status: ${_hostedResult!.status}'),
              Text('Scan Record: ${_hostedResult!.scanRecordId ?? 'N/A'}'),
            ],
            if (_nfcResult != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              Text('Name: ${_nfcResult!.firstName} ${_nfcResult!.lastName}'),
              Text('Document: ${_nfcResult!.documentNumber}'),
              Text('Nationality: ${_nfcResult!.nationality}'),
            ],
            if (_result != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              Text('Name: ${_result!.fullName ?? 'N/A'}'),
              Text('Document: ${_result!.documentNumber ?? 'N/A'}'),
              Text('DOB: ${_result!.dateOfBirth ?? 'N/A'}'),
              Text('Gender: ${_result!.gender ?? 'N/A'}'),
              Text('Nationality: ${_result!.nationality ?? 'N/A'}'),
            ],
            if (_docResult != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              Text('Scan Record: ${_docResult!.scanRecordId ?? 'N/A'}'),
              Text('Name: ${_docResult!.fullName ?? 'N/A'}'),
              Text('Document: ${_docResult!.documentNumber ?? 'N/A'}'),
              Text('Nationality: ${_docResult!.nationality ?? 'N/A'}'),
              Text('Phone: ${_docResult!.phoneNumber ?? 'N/A'}'),
              Text('Email: ${_docResult!.email ?? 'N/A'}'),
            ],
          ],
        ),
      ),
    );
  }
}
