import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trueid_sdk/trueid_sdk.dart';

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
  static const _prefApiKey = 'trueid_example_api_key';

  String _status = 'Ready';
  String _apiKey = '';
  VerificationResult? _result;
  HostedVerificationResult? _hostedResult;
  NfcReadResult? _nfcResult;

  @override
  void initState() {
    super.initState();
    _loadApiKeyAndInit();
  }

  Future<void> _loadApiKeyAndInit() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefApiKey)?.trim() ?? '';
    if (saved.isEmpty) {
      setState(() => _status = 'Set your API key via ⚙ (top right) to begin');
      return;
    }
    await _initializeSdk(saved);
  }

  Future<void> _initializeSdk(String key) async {
    try {
      await TrueIdSdk.initialize(apiKey: key);
      setState(() {
        _apiKey = key;
        _status = 'Ready (key …${key.length > 6 ? key.substring(key.length - 6) : key})';
      });
    } catch (e) {
      setState(() => _status = 'SDK init failed: $e');
    }
  }

  bool _requireApiKey() {
    if (_apiKey.isNotEmpty) return true;
    setState(() => _status = 'No API key set — tap ⚙ in the top right first');
    return false;
  }

  Future<void> _openApiKeySettings() async {
    final prefs = await SharedPreferences.getInstance();
    final controller = TextEditingController(
      text: prefs.getString(_prefApiKey) ?? '',
    );
    if (!mounted) return;

    final saved = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'From app.trueid.info → Settings → API. Stored on this device only.\n\n'
              '• Native NIA Verification needs your SECRET key '
              '(publishable keys are rejected by /selfie-verify).\n'
              '• Hosted Document Verification needs your PUBLISHABLE key.\n\n'
              'These are two different values — swap the key here to test '
              'each button correctly.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'secret or publishable key',
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
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == null) return;
    await prefs.setString(_prefApiKey, saved);
    if (saved.isEmpty) {
      setState(() {
        _apiKey = '';
        _status = 'API key cleared — set one via ⚙ to begin';
      });
      return;
    }
    await _initializeSdk(saved);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key saved')),
      );
    }
  }

  Future<void> _verifyDocument() async {
    if (!_requireApiKey()) return;
    setState(() => _status = 'Opening hosted verification...');

    try {
      final result = await TrueIdSdk.launchHostedVerification(
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
    if (!_requireApiKey()) return;
    setState(() => _status = 'Verifying...');

    try {
      final result = await TrueIdSdk.verify(
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

    final supported = await TrueIdSdk.isNfcSupported();
    if (!supported) {
      setState(() => _status = 'This device has no NFC hardware');
      return;
    }
    if (!await TrueIdSdk.isNfcEnabled()) {
      setState(() => _status = 'NFC is turned off');
      return;
    }

    setState(() => _status = 'Reading chip…');

    try {
      // These three fields normally come from a prior MRZ camera scan.
      final result = await TrueIdSdk.readNfcChip(
        config: const NfcReadConfig(
          documentNumber: 'GHA-000000000',
          dateOfBirth: '900101',
          dateOfExpiry: '300101',
        ),
      );

      setState(() {
        _nfcResult = result;
        _status = result != null ? 'Chip read: ${result.firstName} ${result.lastName}' : 'Cancelled';
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
      body: Padding(
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
          ],
        ),
      ),
    );
  }
}
