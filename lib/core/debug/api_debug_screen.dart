import 'package:flutter/material.dart';
import '../services/approval_service.dart';

/// Debug screen to test API connectivity
class ApiDebugScreen extends StatefulWidget {
  const ApiDebugScreen({super.key});

  @override
  State<ApiDebugScreen> createState() => _ApiDebugScreenState();
}

class _ApiDebugScreenState extends State<ApiDebugScreen> {
  final ApprovalService _service = ApprovalService();
  final TextEditingController _identifierController = TextEditingController();
  String _output = 'Enter an identifier and tap Test';
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _testLookup() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      setState(() => _output = 'Please enter an identifier');
      return;
    }

    setState(() {
      _isLoading = true;
      _output = 'Testing lookup for: $identifier...';
    });

    try {
      print('\n========== API TEST START ==========');
      print('Testing identifier: $identifier');

      // Test 1: Lookup inflCode
      print('\n--- Test 1: Lookup inflCode ---');
      final inflCode = await _service.lookupInflCode(identifier);
      print('✅ Lookup successful! inflCode: $inflCode');

      // Test 2: Get details
      print('\n--- Test 2: Get Registration Details ---');
      final details = await _service.getRegistrationDetails(inflCode);
      print('✅ Details retrieved! Name: ${details.name}');

      print('\n========== API TEST SUCCESS ==========\n');

      setState(() {
        _output =
            '''
✅ SUCCESS!

Lookup Result:
  inflCode: $inflCode

Details:
  ID: ${details.id}
  Name: ${details.name}
  Type: ${details.type}
  Status: ${details.status}
  Mobile: ${details.mobile}
  Email: ${details.email}
  Full Name: ${details.fullName}
  Company: ${details.companyName}
  License: ${details.licenseNumber}
  TRN: ${details.trnNumber}
  Account Holder: ${details.accountHolder}
  IBAN: ${details.iban}
  Bank: ${details.bankName}
  Branch: ${details.branch}
  Address: ${details.address}
  Reference: ${details.reference}
  Submitted: ${details.submittedDate}
  Avatar: ${details.avatar}
  Success Flag: ${details.success}
''';
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('\n❌ API TEST FAILED');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('========== API TEST END ==========\n');

      setState(() {
        _output =
            '''
❌ FAILED!

Error:
$e

Check console for full details.
''';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Debug Tool'),
        backgroundColor: Colors.cyan,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test API Connectivity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _identifierController,
              decoration: const InputDecoration(
                labelText: 'Identifier (Name or ID)',
                hintText: 'e.g., John',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testLookup,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isLoading ? 'Testing...' : 'Test API'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Output:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _output,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'API Base URL: ${ApprovalService.baseUrl}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
