// File: lib/pages/setup_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/setup_config.dart';
import '../services/prefs_service.dart';


class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final TextEditingController _roofAreaController = TextEditingController();
  final TextEditingController _efficiencyController = TextEditingController();
  bool _mpptEnabled = false;
  String _selectedPanelType = '370';
  bool _showAdvanced = false;

  double _totalPowerWatts = 0.0;

  final List<String> _panelOptions = ['300', '370', '450'];



  static const double defaultPanelArea = 1.7;
  static const double defaultPackingFactor = 0.85;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final config = await PrefsService().loadConfig();
    if (config != null) {
      setState(() {
        _roofAreaController.text = config.roofArea.toString();
        _efficiencyController.text = config.panelEfficiency.toString();
        _selectedPanelType = config.panelWattage.toString();

        // ✅ Ensure loaded wattage matches dropdown options
        if (!_panelOptions.contains(_selectedPanelType)) {
          _selectedPanelType = _panelOptions.first;
        }

        _mpptEnabled = config.mpptEnabled;
        _calculatePower();
      });
    }
  }


  Future<void> _savePreferences() async {
    final config = SetupConfig(
      roofArea: double.tryParse(_roofAreaController.text) ?? 0,
      panelEfficiency: double.tryParse(_efficiencyController.text) ?? 0.2,
      panelWattage: double.tryParse(_selectedPanelType) ?? 370,
      mpptEnabled: _mpptEnabled,
    );

    await PrefsService().saveConfig(config);
  }

  void _calculatePower() {
    final roofArea = double.tryParse(_roofAreaController.text) ?? 0.0;
    final panelEfficiency = double.tryParse(_efficiencyController.text) ?? 0.2;
    final panelWattage = double.tryParse(_selectedPanelType) ?? 370.0;

    final usableArea = roofArea * defaultPackingFactor;
    final panelCount = (usableArea / defaultPanelArea).floor();

    final basePower = panelCount * panelWattage;
    final mpptFactor = _mpptEnabled ? 1.05 : 1.0;

    _totalPowerWatts = basePower * panelEfficiency * mpptFactor;
  }

  @override
  Widget build(BuildContext context) {
    _calculatePower();
    return Scaffold(
      appBar: AppBar(title: const Text('System Setup (Auto Mode)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _roofAreaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Roof Area (m²)',
              ),
              onChanged: (_) => setState(_calculatePower),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPanelType,
              items: _panelOptions.map((watt) => DropdownMenuItem<String>(
                value: watt,
                child: Text('$watt W Panel'),
              )).toList(),
              onChanged: (value) => setState(() {
                _selectedPanelType = value ?? '370';
                _calculatePower();
              }),
              decoration: const InputDecoration(labelText: 'Select Panel Type'),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Show Advanced Settings'),
              value: _showAdvanced,
              onChanged: (value) => setState(() => _showAdvanced = value),
            ),
            if (_showAdvanced) ...[
              TextField(
                controller: _efficiencyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Panel Efficiency (0.0–1.0)',
                ),
                onChanged: (_) => setState(_calculatePower),
              ),
              SwitchListTile(
                title: const Text('Enable MPPT'),
                value: _mpptEnabled,
                onChanged: (value) => setState(() {
                  _mpptEnabled = value;
                  _calculatePower();
                }),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Estimated System Power: ${_totalPowerWatts.toStringAsFixed(2)} W',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _savePreferences();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Setup saved.')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
