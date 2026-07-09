import 'package:flutter/material.dart';
import 'package:trueid_sdk/trueid_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TrueIdSdk.initialize(apiKey: 'your-api-key');
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
  String _status = 'Ready';
  VerificationResult? _result;
  HostedVerificationResult? _hostedResult;
  NfcReadResult? _nfcResult;

  Future<void> _verifyDocument() async {
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
    setState(() => _status = 'Verifying...');

    try {
      final result = await TrueIdSdk.verify(
        config: const VerificationConfig(
          enforceFaceComparison: true,
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
      appBar: AppBar(title: const Text('TrueID SDK Example')),
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
