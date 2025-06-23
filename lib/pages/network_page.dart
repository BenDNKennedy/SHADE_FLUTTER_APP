// File: lib/pages/network_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  final TextEditingController _ipController = TextEditingController(text: AppConstants.espIp);
  String _statusMessage = '';
  bool _isPinging = false;

  Future<void> _pingESP() async {
    setState(() {
      _isPinging = true;
      _statusMessage = 'Pinging...';
    });

    try {
      final response = await http.get(Uri.parse('http://${_ipController.text}/solar')).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = '✅ ESP Responded: ${response.body}';
        });
      } else {
        setState(() {
          _statusMessage = '⚠️ Response error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Failed to reach ESP: $e';
      });
    } finally {
      setState(() {
        _isPinging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Diagnostics')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('ESP IP Address:'),
            TextField(
              controller: _ipController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(hintText: '192.168.1.87'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isPinging ? null : _pingESP,
              child: const Text('Ping ESP'),
            ),
            const SizedBox(height: 24),
            Text(_statusMessage, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
