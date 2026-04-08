import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Latency preset configurations
class LatencyPreset {
  final String name;
  final double value;
  final String description;

  const LatencyPreset({
    required this.name,
    required this.value,
    required this.description,
  });

  static const List<LatencyPreset> presets = [
    LatencyPreset(
      name: 'Ultra Low',
      value: -50.0,
      description: 'Minimum latency for wired connections',
    ),
    LatencyPreset(
      name: 'Low',
      value: -25.0,
      description: 'Reduced latency for good BLE connections',
    ),
    LatencyPreset(
      name: 'Default',
      value: 0.0,
      description: 'Balanced performance',
    ),
    LatencyPreset(
      name: 'Medium',
      value: 50.0,
      description: 'Added buffer for stability',
    ),
    LatencyPreset(
      name: 'High',
      value: 100.0,
      description: 'Maximum buffer for unreliable connections',
    ),
    LatencyPreset(
      name: 'BLE 7.5ms',
      value: 7.5,
      description: 'BLE minimum interval compensation',
    ),
    LatencyPreset(
      name: 'BLE 15ms',
      value: 15.0,
      description: 'Common Android BLE interval',
    ),
    LatencyPreset(
      name: 'BLE 30ms',
      value: 30.0,
      description: 'Default Android BLE interval',
    ),
  ];
}

class LatencySettingsScreen extends StatefulWidget {
  final double currentLatency;
  final Function(double) onLatencyChanged;
  final double currentVolume;
  final Function(double)? onVolumeChanged;

  const LatencySettingsScreen({
    super.key,
    required this.currentLatency,
    required this.onLatencyChanged,
    this.currentVolume = 1.0,
    this.onVolumeChanged,
  });

  @override
  State<LatencySettingsScreen> createState() => _LatencySettingsScreenState();
}

class _LatencySettingsScreenState extends State<LatencySettingsScreen>
    with SingleTickerProviderStateMixin {
  late double _latency;
  late double _volume;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  static const double minLatency = -100.0;
  static const double maxLatency = 200.0;
  static const int divisions = 60; // 5ms increments

  static const double minVolume = 0.0;
  static const double maxVolume = 2.0; // Up to 200% for boost

  bool _isSaving = false;
  String? _savedPresetName;

  @override
  void initState() {
    super.initState();
    _latency = widget.currentLatency;
    _volume = widget.currentVolume;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateVolume(double newVolume) {
    setState(() {
      _volume = newVolume;
    });
    widget.onVolumeChanged?.call(newVolume);
    HapticFeedback.selectionClick();

    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  void _updateLatency(double newLatency) {
    setState(() {
      _latency = newLatency;
    });
    widget.onLatencyChanged(newLatency);
    HapticFeedback.selectionClick();

    // Trigger animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  Future<void> _saveLatencyToSupabase() async {
    setState(() => _isSaving = true);

    try {
      // Always save to local storage first
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('latency_setting', _latency);
      await prefs.setDouble('volume_setting', _volume);

      // Try to sync with Supabase if available
      try {
        final supabase = Supabase.instance.client;

        await supabase.from('latency_settings').upsert({
          'latency': _latency,
          'volume': _volume,
          'updated_at': DateTime.now().toIso8601String(),
        }).timeout(const Duration(seconds: 5));

        _showSuccessMessage('Settings saved and synced');
      } catch (e) {
        // Supabase not available, but local save succeeded
        _showSuccessMessage('Settings saved locally');
        print('Supabase sync skipped: $e');
      }
    } catch (e) {
      _showErrorMessage('Failed to save: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _savePreset(String name) async {
    try {
      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getString('latency_presets') ?? '[]';
      final List<dynamic> presets = jsonDecode(presetsJson);

      presets.add({
        'name': name,
        'latency': _latency,
        'created_at': DateTime.now().toIso8601String(),
      });

      await prefs.setString('latency_presets', jsonEncode(presets));

      // Try to sync with Supabase if available
      try {
        final supabase = Supabase.instance.client;

        await supabase.from('latency_presets').insert({
          'name': name,
          'latency': _latency,
          'created_at': DateTime.now().toIso8601String(),
        }).timeout(const Duration(seconds: 5));
      } catch (e) {
        print('Supabase sync skipped: $e');
      }

      setState(() => _savedPresetName = name);
      _showSuccessMessage('Preset "$name" saved');
    } catch (e) {
      _showErrorMessage('Failed to save preset: $e');
    }
  }

  void _showSuccessMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Icon(
          CupertinoIcons.checkmark_circle_fill,
          color: CupertinoColors.systemGreen,
          size: 48,
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSavePresetDialog() {
    final controller = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Save Preset'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Preset name',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                _savePreset(controller.text);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAdvancedSettings() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Advanced Latency Settings'),
        message: const Text(
          'Fine-tune BLE connection parameters and audio buffer settings',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showBLEIntervalInfo();
            },
            child: const Text('BLE Connection Intervals'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showBufferSizeSettings();
            },
            child: const Text('Audio Buffer Settings'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showPacketOptimization();
            },
            child: const Text('Packet Optimization'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _resetToDefault();
            },
            child: const Text('Reset to Default'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showBLEIntervalInfo() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('BLE Connection Intervals'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12),
              Text(
                'Bluetooth Low Energy Connection Info:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Minimum interval: 7.5ms (theoretical)'),
              Text('• Typical Android: 15-30ms'),
              Text('• Budget devices: 30-50ms'),
              SizedBox(height: 12),
              Text(
                'These intervals cause latency and jitter due to buffer limitations.',
              ),
              SizedBox(height: 12),
              Text(
                'For best performance:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Use WIDI Uhost or WIDI Bud Pro'),
              Text('• Clear Bluetooth cache regularly'),
              Text('• Stay within 10m of the device'),
              Text('• Avoid interference from WiFi'),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showBufferSizeSettings() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Audio Buffer Settings'),
        content: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12),
            Text('Buffer size affects audio latency and quality:'),
            SizedBox(height: 8),
            Text('• Smaller buffer = Lower latency'),
            Text('• Larger buffer = More stable playback'),
            SizedBox(height: 12),
            Text('Current buffer is optimized for your device.'),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPacketOptimization() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Packet Optimization'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12),
              Text(
                'BLE-MIDI Reliability Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('✓ Packet queue enabled (max 100)'),
              Text('✓ 5ms processing interval'),
              Text('✓ Batch processing active'),
              SizedBox(height: 12),
              Text(
                'Known Issues:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• No error correction in BLE-MIDI'),
              Text('• Dropped packets cause hanging notes'),
              Text('• Android BLE stack varies by device'),
              SizedBox(height: 12),
              Text(
                'Optimizations:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• CC messages throttled'),
              Text('• SysEx sent in 32-byte chunks'),
              Text('• 15ms spacing between chunks'),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _resetToDefault() {
    _updateLatency(0.0);
    _showSuccessMessage('Latency reset to default (0ms)');
  }

  Color _getLatencyColor() {
    if (_latency < -25) {
      return CupertinoColors.systemPurple;
    } else if (_latency < 0) {
      return CupertinoColors.systemBlue;
    } else if (_latency == 0) {
      return CupertinoColors.systemGreen;
    } else if (_latency < 75) {
      return CupertinoColors.systemYellow;
    } else {
      return CupertinoColors.systemOrange;
    }
  }

  String _getLatencyLabel() {
    if (_latency < -25) {
      return 'Ultra Low Latency';
    } else if (_latency < 0) {
      return 'Low Latency';
    } else if (_latency == 0) {
      return 'Balanced';
    } else if (_latency < 75) {
      return 'Moderate Buffer';
    } else {
      return 'High Buffer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Latency Settings'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSaving ? null : _saveLatencyToSupabase,
          child: _isSaving
              ? const CupertinoActivityIndicator()
              : const Text('Save'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current Latency Display
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getLatencyColor(),
                      _getLatencyColor().withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _getLatencyColor().withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      CupertinoIcons.timer,
                      size: 48,
                      color: CupertinoColors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_latency.toStringAsFixed(1)}ms',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getLatencyLabel(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Latency Slider
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Latency Adjustment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adjust timing to match your Bluetooth connection',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Volume Control Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.volume_up,
                              color: CupertinoColors.systemBlue,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Volume Control',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Current: ${(_volume * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (_volume > 1.0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemOrange
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.bolt_fill,
                                      size: 12,
                                      color: CupertinoColors.systemOrange,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'BOOST',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoColors.systemOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Volume Labels
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Icon(CupertinoIcons.volume_mute, size: 20),
                                SizedBox(height: 4),
                                Text(
                                  'Mute',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '0%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: const [
                                Icon(CupertinoIcons.volume_down, size: 20),
                                SizedBox(height: 4),
                                Text(
                                  'Normal',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '100%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: const [
                                Icon(
                                  CupertinoIcons.bolt_fill,
                                  size: 20,
                                  color: CupertinoColors.systemOrange,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Boost',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '200%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Volume Slider
                        material.Slider(
                          value: _volume,
                          min: minVolume,
                          max: maxVolume,
                          divisions: 40,
                          onChanged: _updateVolume,
                          activeColor: _volume > 1.0
                              ? CupertinoColors.systemOrange
                              : CupertinoColors.systemBlue,
                          inactiveColor: CupertinoColors.systemGrey4,
                        ),

                        const SizedBox(height: 16),

                        // Volume Presets
                        Row(
                          children: [
                            Expanded(
                              child: CupertinoButton(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                color: CupertinoColors.systemGrey5,
                                onPressed: () => _updateVolume(0.5),
                                child: const Text(
                                  '50%\nQuiet',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: CupertinoColors.black),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CupertinoButton(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                color: CupertinoColors.systemGrey5,
                                onPressed: () => _updateVolume(1.0),
                                child: const Text(
                                  '100%\nNormal',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: CupertinoColors.black),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CupertinoButton(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                color: CupertinoColors.systemOrange
                                    .withOpacity(0.2),
                                onPressed: () => _updateVolume(1.5),
                                child: const Text(
                                  '150%\nBoost',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: CupertinoColors.systemOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CupertinoButton(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                color: CupertinoColors.systemOrange
                                    .withOpacity(0.3),
                                onPressed: () => _updateVolume(2.0),
                                child: const Text(
                                  '200%\nMax',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: CupertinoColors.systemOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Slider Labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(CupertinoIcons.bolt_fill, size: 20),
                          SizedBox(height: 4),
                          Text(
                            'Faster',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            '-100ms',
                            style: TextStyle(
                              fontSize: 10,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Icon(CupertinoIcons.tortoise_fill, size: 20),
                          SizedBox(height: 4),
                          Text(
                            'Slower',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            '+200ms',
                            style: TextStyle(
                              fontSize: 10,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Slider
                  material.Slider(
                    value: _latency,
                    min: minLatency,
                    max: maxLatency,
                    divisions: divisions,
                    onChanged: _updateLatency,
                    activeColor: _getLatencyColor(),
                    inactiveColor: CupertinoColors.systemGrey4,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Presets
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Presets',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LatencyPreset.presets.map((preset) {
                      final isSelected = (_latency - preset.value).abs() < 0.1;
                      return CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        color: isSelected
                            ? CupertinoColors.systemBlue
                            : CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () => _updateLatency(preset.value),
                        child: Column(
                          children: [
                            Text(
                              preset.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${preset.value.toStringAsFixed(1)}ms',
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? CupertinoColors.white.withOpacity(0.8)
                                    : CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _showAdvancedSettings,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.gear_alt_fill, size: 20),
                        SizedBox(width: 8),
                        Text('Advanced Settings'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: CupertinoColors.systemGrey5,
                    onPressed: _showSavePresetDialog,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.floppy_disk,
                          size: 20,
                          color: CupertinoColors.black,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Save as Preset',
                          style: TextStyle(color: CupertinoColors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CupertinoColors.systemBlue.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.info_circle_fill,
                        color: CupertinoColors.systemBlue,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'About Latency',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.systemBlue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '• Negative values (-) reduce latency by speeding up playback slightly',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• Positive values (+) add delay to compensate for network jitter',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• Start with 0ms and adjust based on your hearing',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• BLE connection interval is typically 7.5-30ms on Android',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
