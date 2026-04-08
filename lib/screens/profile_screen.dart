import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/complete_songs_library.dart';
import '../services/enhanced_ai_tutor_service.dart';
import '../services/audio_player_service.dart';
import '../services/aws_service.dart';
import '../services/aws_auth_service.dart';
import '../widgets/falling_notes_widget.dart';
import '../widgets/ai_chat_widget.dart';
import '../utils/build_info.dart';

// ============================================
// profile_screen.dart - User Profile
// ============================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AwsService _cloudService = AwsService.instance;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _getUserProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading profile: $e');
    }
  }

  // Then update the _getUserProfile method:
  Future<Map<String, dynamic>?> _getUserProfile() async {
    if (!_cloudService.isInitialized) return null;

    try {
      return await _cloudService.getProfile();
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

// Update the _signOut method:
  Future<void> _signOut() async {
    await AwsAuthService.instance.signOut();
    setState(() {
      _profile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Profile'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _profile == null
                ? _buildSignInPrompt()
                : _buildProfile(),
      ),
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.person_circle,
            size: 80,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Sign In',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in to sync your progress',
            style: TextStyle(color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton.filled(
                onPressed: _showLoginDialog,
                child: const Text('Sign In'),
              ),
              const SizedBox(width: 12),
              CupertinoButton(
                onPressed: _showSignUpDialog,
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLoginDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sign In'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: emailController,
              placeholder: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: passwordController,
              placeholder: 'Password',
              obscureText: true,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Sign In'),
            onPressed: () async {
              final email = emailController.text.trim();
              final password = passwordController.text;
              Navigator.pop(context);
              final ok = await AwsAuthService.instance.signIn(email, password);
              if (ok) {
                _loadProfile();
              } else {
                _showAuthError('Sign in failed');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSignUpDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final codeController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Create Account'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: emailController,
              placeholder: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: passwordController,
              placeholder: 'Password',
              obscureText: true,
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: codeController,
              placeholder: 'Confirmation Code (optional)',
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text('Create'),
            onPressed: () async {
              final email = emailController.text.trim();
              final password = passwordController.text;
              final code = codeController.text.trim();
              Navigator.pop(context);

              final ok = await AwsAuthService.instance.signUp(email, password);
              if (!ok) {
                _showAuthError('Sign up failed');
                return;
              }
              if (code.isNotEmpty) {
                final confirmed =
                    await AwsAuthService.instance.confirmSignUp(email, code);
                if (!confirmed) {
                  _showAuthError('Confirmation failed');
                  return;
                }
              }
              _showAuthError(
                  'Account created. Check email for confirmation code.');
            },
          ),
        ],
      ),
    );
  }

  void _showAuthError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Auth Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final displayName = _profile!['display_name'] ?? 'User';
    final email = _profile!['email'] ?? '';
    final skillLevel = _profile!['skill_level'] ?? 'beginner';
    final practiceHours = (_profile!['total_practice_hours'] ?? 0.0).toDouble();

    return ListView(
      children: [
        _buildHeader(displayName, email),
        _buildStatsSection(practiceHours, skillLevel),
        _buildSettingsSection(),
      ],
    );
  }

  Widget _buildHeader(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: CupertinoColors.activeBlue,
            child: Icon(
              CupertinoIcons.person_fill,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            email,
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(double hours, String skillLevel) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('${hours.toStringAsFixed(1)}h', 'Practice Time'),
          _buildStat(skillLevel.toUpperCase(), 'Skill Level'),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return CupertinoListSection(
      children: [
        CupertinoListTile(
          leading: const Icon(CupertinoIcons.music_albums),
          title: const Text('My Progress'),
          trailing: const CupertinoListTileChevron(),
          onTap: () {
            _showProgressDetails();
          },
        ),
        CupertinoListTile(
          leading: const Icon(CupertinoIcons.chart_bar),
          title: const Text('Statistics'),
          trailing: const CupertinoListTileChevron(),
          onTap: () {
            _showStatistics();
          },
        ),
        CupertinoListTile(
          leading: const Icon(CupertinoIcons.settings),
          title: const Text('Settings'),
          trailing: const CupertinoListTileChevron(),
          onTap: () {
            _showSettings();
          },
        ),
        CupertinoListTile(
          leading: const Icon(CupertinoIcons.heart),
          title: const Text('Support'),
          trailing: const CupertinoListTileChevron(),
          onTap: () {
            _showSupport();
          },
        ),
        CupertinoListTile(
          leading: Icon(
            CupertinoIcons.square_arrow_right,
            color: CupertinoColors.systemRed,
          ),
          title: Text(
            'Sign Out',
            style: TextStyle(color: CupertinoColors.systemRed),
          ),
          onTap: () => _showSignOutConfirmation(),
        ),
      ],
    );
  }

  Widget _buildSettingsInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showProgressDetails() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('My Progress'),
        content: const Text(
            'View your detailed practice progress and achievements.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showStatistics() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Statistics'),
        content: const Text('View your practice statistics and insights.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Adjust app settings and preferences.'),
            const SizedBox(height: 10),
            _buildSettingsInfoRow('Build', BuildInfo.display),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSupport() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Support'),
        content: const Text('Get help and support for the app.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSignOutConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: const Text(
              'Sign Out',
              style: TextStyle(color: CupertinoColors.systemRed),
            ),
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
          ),
        ],
      ),
    );
  }
}
