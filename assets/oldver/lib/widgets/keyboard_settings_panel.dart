// ============================================
// keyboard_settings_panel.dart - Visual Customization
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/velocity_curve.dart';
import 'enhanced_piano_keyboard.dart';

class KeyboardSettingsPanel extends StatefulWidget {
  final KeyboardSettings settings;
  final Function(KeyboardSettings) onSettingsChanged;
  final ValueListenable<double>? lastMidiVelocity;

  const KeyboardSettingsPanel({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    this.lastMidiVelocity,
  });

  @override
  State<KeyboardSettingsPanel> createState() => _KeyboardSettingsPanelState();
}

class _KeyboardSettingsPanelState extends State<KeyboardSettingsPanel> {
  late KeyboardSettings _settings;
  double? _calibrationSoft;
  double? _calibrationHard;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  void _updateSettings(KeyboardSettings newSettings) {
    setState(() => _settings = newSettings);
    widget.onSettingsChanged(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Keyboard Appearance'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              'Size',
              CupertinoIcons.resize,
              _buildSizeSettings(),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Theme',
              CupertinoIcons.paintbrush,
              _buildThemeSettings(),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Animation',
              CupertinoIcons.sparkles,
              _buildAnimationSettings(),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Display',
              CupertinoIcons.eye,
              _buildDisplaySettings(),
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Advanced',
              CupertinoIcons.slider_horizontal_3,
              _buildAdvancedSettings(),
            ),
            const SizedBox(height: 32),
            _buildResetButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: CupertinoColors.activeBlue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Height'),
            Text(
              '${_settings.height.round()}px',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CupertinoSlider(
          value: _settings.height,
          min: 120,
          max: 400,
          divisions: 28,
          onChanged: (value) {
            _updateSettings(_settings..height = value);
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildQuickSizeButton('Compact', 150),
            _buildQuickSizeButton('Standard', 200),
            _buildQuickSizeButton('Large', 280),
            _buildQuickSizeButton('XL', 350),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Key Width'),
            Text(
              '${(_settings.keyWidthScale * 100).round()}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CupertinoSlider(
          value: _settings.keyWidthScale,
          min: 0.8,
          max: 1.6,
          divisions: 16,
          onChanged: (value) {
            _updateSettings(_settings..keyWidthScale = value);
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Black Key Width'),
            Text(
              '${(_settings.blackKeyWidthFactor * 100).round()}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CupertinoSlider(
          value: _settings.blackKeyWidthFactor,
          min: 0.45,
          max: 0.75,
          divisions: 15,
          onChanged: (value) {
            _updateSettings(_settings..blackKeyWidthFactor = value);
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Black Key Height'),
            Text(
              '${(_settings.blackKeyHeightFactor * 100).round()}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CupertinoSlider(
          value: _settings.blackKeyHeightFactor,
          min: 0.45,
          max: 0.75,
          divisions: 15,
          onChanged: (value) {
            _updateSettings(_settings..blackKeyHeightFactor = value);
          },
        ),
      ],
    );
  }

  Widget _buildQuickSizeButton(String label, double height) {
    final isSelected = (_settings.height - height).abs() < 5;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color:
          isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey5,
      onPressed: () {
        _updateSettings(_settings..height = height);
      },
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : CupertinoColors.label,
        ),
      ),
    );
  }

  Widget _buildThemeSettings() {
    return Column(
      children: KeyboardTheme.values.map((theme) {
        final isSelected = _settings.theme == theme;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () {
              _updateSettings(_settings..theme = theme);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? CupertinoColors.activeBlue.withOpacity(0.1)
                    : CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? CupertinoColors.activeBlue
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  _buildThemePreview(theme),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getThemeName(theme),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getThemeDescription(theme),
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      color: CupertinoColors.activeBlue,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildThemePreview(KeyboardTheme theme) {
    final colors = _getThemeColors(theme);

    return Container(
      width: 60,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors['white'],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                border: Border.all(color: Colors.black12),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors['black'],
                border: Border.all(color: Colors.black12),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors['pressed'],
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                border: Border.all(color: Colors.black12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getThemeColors(KeyboardTheme theme) {
    switch (theme) {
      case KeyboardTheme.classic:
        return {
          'white': Colors.white,
          'black': const Color(0xFF1A1A1A),
          'pressed': const Color(0xFF64B5F6),
        };
      case KeyboardTheme.modern:
        return {
          'white': const Color(0xFFF5F5F5),
          'black': const Color(0xFF2D2D2D),
          'pressed': const Color(0xFF00B8D4),
        };
      case KeyboardTheme.neon:
        return {
          'white': const Color(0xFF1A1A1A),
          'black': const Color(0xFF0A0A0A),
          'pressed': const Color(0xFF00FFFF),
        };
      case KeyboardTheme.gradient:
        return {
          'white': const Color(0xFFFFF8F0),
          'black': const Color(0xFF2A2A2A),
          'pressed': const Color(0xFFC06C84),
        };
      case KeyboardTheme.glassmorphic:
        return {
          'white': Colors.white.withOpacity(0.7),
          'black': const Color(0xFF424242).withOpacity(0.8),
          'pressed': const Color(0xFF81D4FA),
        };
      case KeyboardTheme.wooden:
        return {
          'white': const Color(0xFFEFEBE9),
          'black': const Color(0xFF3E2723),
          'pressed': const Color(0xFFBCAAA4),
        };
    }
  }

  String _getThemeName(KeyboardTheme theme) {
    switch (theme) {
      case KeyboardTheme.classic:
        return 'Classic Piano';
      case KeyboardTheme.modern:
        return 'Modern Minimal';
      case KeyboardTheme.neon:
        return 'Neon Nights';
      case KeyboardTheme.gradient:
        return 'Gradient Sunset';
      case KeyboardTheme.glassmorphic:
        return 'Glassmorphic';
      case KeyboardTheme.wooden:
        return 'Wooden Classic';
    }
  }

  String _getThemeDescription(KeyboardTheme theme) {
    switch (theme) {
      case KeyboardTheme.classic:
        return 'Traditional black & white piano look';
      case KeyboardTheme.modern:
        return 'Clean, contemporary design';
      case KeyboardTheme.neon:
        return 'Vibrant cyberpunk aesthetics';
      case KeyboardTheme.gradient:
        return 'Colorful gradient effects';
      case KeyboardTheme.glassmorphic:
        return 'Translucent frosted glass look';
      case KeyboardTheme.wooden:
        return 'Warm wooden piano finish';
    }
  }

  Widget _buildAnimationSettings() {
    return Column(
      children: [
        _buildAnimationOption(
          PressAnimation.scale,
          'Scale',
          'Keys shrink slightly when pressed',
          CupertinoIcons.arrow_down_right_arrow_up_left,
        ),
        _buildAnimationOption(
          PressAnimation.glow,
          'Glow',
          'Glowing effect on key press',
          CupertinoIcons.sun_max,
        ),
        _buildAnimationOption(
          PressAnimation.ripple,
          'Ripple',
          'Water ripple animation',
          CupertinoIcons.circle_grid_3x3,
        ),
        _buildAnimationOption(
          PressAnimation.wave,
          'Wave',
          'Wave motion effect',
          CupertinoIcons.waveform,
        ),
        _buildAnimationOption(
          PressAnimation.particles,
          'Particles',
          'Particle burst on press',
          CupertinoIcons.sparkles,
        ),
      ],
    );
  }

  Widget _buildAnimationOption(
    PressAnimation animation,
    String name,
    String description,
    IconData icon,
  ) {
    final isSelected = _settings.animation == animation;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          _updateSettings(_settings..animation = animation);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? CupertinoColors.activeBlue.withOpacity(0.1)
                : CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  isSelected ? CupertinoColors.activeBlue : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: CupertinoColors.activeBlue,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisplaySettings() {
    return Column(
      children: [
        _buildToggle(
          'Show Note Names',
          _settings.showNoteNames,
          (value) {
            _updateSettings(_settings..showNoteNames = value);
          },
        ),
        _buildToggle(
          'Show Octave Numbers',
          _settings.showOctaveNumbers,
          (value) {
            _updateSettings(_settings..showOctaveNumbers = value);
          },
        ),
        _buildToggle(
          'Velocity Colors',
          _settings.enableVelocityColors,
          (value) {
            _updateSettings(_settings..enableVelocityColors = value);
          },
          subtitle: 'Color intensity based on key press strength',
        ),
        _buildToggle(
          'Shadows & Effects',
          _settings.enableShadows,
          (value) {
            _updateSettings(_settings..enableShadows = value);
          },
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVelocityCurveSettings(),
        const SizedBox(height: 16),
        _buildToggle(
          'Pedal Installed',
          _settings.pedalInstalled,
          (value) {
            _updateSettings(_settings..pedalInstalled = value);
          },
          subtitle: 'Enable sustain pedal behavior (CC 64)',
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Key Spacing'),
            Text(
              '${_settings.keySpacing.toStringAsFixed(1)}px',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ],
        ),
        CupertinoSlider(
          value: _settings.keySpacing,
          min: 0,
          max: 4,
          divisions: 8,
          onChanged: (value) {
            _updateSettings(_settings..keySpacing = value);
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Corner Radius'),
            Text(
              '${_settings.cornerRadius.toStringAsFixed(1)}px',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ],
        ),
        CupertinoSlider(
          value: _settings.cornerRadius,
          min: 0,
          max: 12,
          divisions: 12,
          onChanged: (value) {
            _updateSettings(_settings..cornerRadius = value);
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: const [
            Icon(
              CupertinoIcons.speedometer,
              size: 16,
              color: CupertinoColors.systemGrey,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Performance mode is always on for lowest latency.',
                style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVelocityCurveSettings() {
    final currentPreset = _settings.velocityCurvePreset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Touch Response',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPresetButton('Linear', VelocityCurvePreset.linear),
            _buildPresetButton('Soft', VelocityCurvePreset.soft),
            _buildPresetButton('Medium', VelocityCurvePreset.medium),
            _buildPresetButton('Hard', VelocityCurvePreset.hard),
            _buildPresetButton('Custom', VelocityCurvePreset.custom),
          ],
        ),
        if (currentPreset == VelocityCurvePreset.custom) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Custom Curve'),
              Text(
                _settings.velocityCurveExponent.toStringAsFixed(2),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.activeBlue,
                ),
              ),
            ],
          ),
          CupertinoSlider(
            value: _settings.velocityCurveExponent,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            onChanged: (value) {
              _updateSettings(_settings..velocityCurveExponent = value);
            },
          ),
          const SizedBox(height: 8),
          _buildCalibrationSection(),
        ],
      ],
    );
  }

  Widget _buildPresetButton(String label, VelocityCurvePreset preset) {
    final isSelected = _settings.velocityCurvePreset == preset;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color:
          isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey5,
      onPressed: () {
        _updateSettings(_settings..velocityCurvePreset = preset);
      },
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : CupertinoColors.label,
        ),
      ),
    );
  }

  Widget _buildCalibrationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calibration',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        if (widget.lastMidiVelocity != null)
          ValueListenableBuilder<double>(
            valueListenable: widget.lastMidiVelocity!,
            builder: (context, value, child) {
              return Text(
                'Live velocity: ${(value * 100).round()}%',
                style: const TextStyle(fontSize: 12),
              );
            },
          )
        else
          const Text(
            'Live velocity unavailable',
            style: TextStyle(fontSize: 12),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildCaptureButton(
                'Capture Soft',
                () => _captureCalibration(true),
                _calibrationSoft,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCaptureButton(
                'Capture Hard',
                () => _captureCalibration(false),
                _calibrationHard,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: CupertinoColors.activeBlue,
          onPressed: (_calibrationSoft != null && _calibrationHard != null)
              ? _applyCalibration
              : null,
          child: const Text(
            'Apply Calibration',
            style: TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptureButton(
      String label, VoidCallback onPressed, double? value) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: CupertinoColors.systemGrey5,
      onPressed: onPressed,
      child: Text(
        value == null ? label : '$label (${(value * 100).round()}%)',
        style: const TextStyle(fontSize: 12, color: CupertinoColors.label),
      ),
    );
  }

  void _captureCalibration(bool isSoft) {
    final source = widget.lastMidiVelocity;
    if (source == null) return;

    final value = source.value.clamp(0.0, 1.0);
    setState(() {
      if (isSoft) {
        _calibrationSoft = value;
      } else {
        _calibrationHard = value;
      }
    });
  }

  void _applyCalibration() {
    final soft = _calibrationSoft;
    final hard = _calibrationHard;
    if (soft == null || hard == null) return;

    final exponent = computeExponentFromCalibration(soft, hard);
    _updateSettings(
      _settings
        ..velocityCurvePreset = VelocityCurvePreset.custom
        ..velocityCurveExponent = exponent,
    );
  }

  Widget _buildToggle(
    String label,
    bool value,
    Function(bool) onChanged, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return CupertinoButton(
      color: CupertinoColors.destructiveRed,
      onPressed: () {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Reset to Defaults'),
            content: const Text(
                'Are you sure you want to reset all keyboard settings to default values?'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  _updateSettings(KeyboardSettings());
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        );
      },
      child: const Text('Reset to Defaults'),
    );
  }
}
