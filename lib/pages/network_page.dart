// File: lib/pages/network_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../services/prefs_service.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}
class _NetworkPageState extends State<NetworkPage> {
  late TextEditingController _ipController;
  String _statusMessage = '';
  bool _isPinging = false;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController();

    // ✅ Load saved IP (or fallback) asynchronously
    AppConstants.espIp.then((ip) {
      setState(() {
        _ipController.text = ip;
      });
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _pingESP() async {
    setState(() {
      _isPinging = true;
      _statusMessage = 'Pinging...';
    });

    try {
      final ip = _ipController.text.trim();
      final response = await http
          .get(Uri.parse('http://$ip/solar'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        await PrefsService.instance.saveEspIp(ip);

        setState(() {
          _statusMessage = '✅ ESP Responded and IP saved: $ip';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ESP IP set to $ip')),
          );
        }
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
