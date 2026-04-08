import 'package:flutter/cupertino.dart';
import '../services/aws_auth_service.dart';
import '../utils/theme_service.dart' as theme_service;

class AuthScreen extends StatefulWidget {
  final VoidCallback onSignedIn;
  final VoidCallback onContinueAsGuest;

  const AuthScreen({
    super.key,
    required this.onSignedIn,
    required this.onContinueAsGuest,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isSigningUp = false;
  bool _isConfirming = false;
  bool _busy = false;
  String _status = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _status = '';
    });
    final ok = await AwsAuthService.instance.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );
    setState(() {
      _busy = false;
      _status = ok ? 'Signed in' : 'Sign in failed';
    });
    if (ok) widget.onSignedIn();
  }

  Future<void> _signUp() async {
    setState(() {
      _busy = true;
      _status = '';
    });
    final ok = await AwsAuthService.instance.signUp(
      _emailController.text.trim(),
      _passwordController.text,
    );
    setState(() {
      _busy = false;
      _isConfirming = ok;
      _status = ok ? 'Check your email for a code' : 'Sign up failed';
    });
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _status = '';
    });
    final ok = await AwsAuthService.instance.confirmSignUp(
      _emailController.text.trim(),
      _codeController.text.trim(),
    );
    setState(() {
      _busy = false;
      _isConfirming = false;
      _status = ok ? 'Confirmed. You can sign in.' : 'Confirm failed';
      _isSigningUp = !ok ? _isSigningUp : false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = theme_service.ThemeService.theme;

    return CupertinoPageScaffold(
      backgroundColor: theme.backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                'GrandPiano',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to sync and use AI features',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              _buildField('Email', _emailController, false),
              const SizedBox(height: 12),
              _buildField('Password', _passwordController, true),
              if (_isConfirming) ...[
                const SizedBox(height: 12),
                _buildField('Confirmation code', _codeController, false),
              ],
              const SizedBox(height: 16),
              if (_status.isNotEmpty)
                Text(
                  _status,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textColor.withOpacity(0.7),
                  ),
                ),
              const Spacer(),
              if (_isConfirming)
                _primaryButton('Confirm email', _confirm, theme),
              if (!_isConfirming && !_isSigningUp)
                _primaryButton('Sign in', _signIn, theme),
              if (!_isConfirming && _isSigningUp)
                _primaryButton('Create account', _signUp, theme),
              const SizedBox(height: 10),
              if (!_isConfirming)
                CupertinoButton(
                  onPressed: _busy ? null : widget.onContinueAsGuest,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  color: theme.surfaceColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  child: Text(
                    'Continue as Guest',
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              if (!_isConfirming)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _busy
                      ? null
                      : () => setState(() => _isSigningUp = !_isSigningUp),
                  child: Text(
                    _isSigningUp
                        ? 'Already have an account? Sign in'
                        : 'New here? Create an account',
                    style: TextStyle(color: theme.primaryColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      String placeholder, TextEditingController controller, bool obscure) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      obscureText: obscure,
      padding: const EdgeInsets.all(14),
      keyboardType:
          obscure ? TextInputType.text : TextInputType.emailAddress,
    );
  }

  Widget _primaryButton(
      String label, VoidCallback action, theme_service.ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton.filled(
        onPressed: _busy ? null : action,
        child: Text(label),
      ),
    );
  }
}
