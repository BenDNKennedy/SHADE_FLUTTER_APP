import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  Map<String, dynamic>? solarData;
  bool isLoading = true;
  String errorMessage = '';

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('http://192.168.1.174/solar'));
      if (response.statusCode == 200) {
        setState(() {
          solarData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Connection')),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : errorMessage.isNotEmpty
            ? Text('Error: $errorMessage')
            : solarData == null
            ? const Text('No data')
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Voltage: ${solarData!['voltage']} V'),
            Text('Current: ${solarData!['current']} A'),
            Text('Power: ${solarData!['power']} W'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchData,
              child: const Text('Refresh'),
            )
          ],
        ),
      ),
    );
  }
}
