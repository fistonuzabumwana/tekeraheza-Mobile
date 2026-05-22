import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/di/service_locator.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key, required this.token, this.type});

  final String token;
  final String? type;

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  final _code = TextEditingController();
  bool _loading = false;
  bool _useBackup = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    try {
      final user = await sl<AuthService>().verifyTwoFactor(
        widget.token,
        _code.text.trim(),
        useBackupCode: _useBackup,
      );
      if (!mounted) return;
      context.read<AuthProvider>().setUser(user);
      context.go('/dashboard');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Two-Factor Authentication')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.type == 'EMAIL_OTP'
                  ? 'Enter the code sent to your email'
                  : 'Enter your authenticator code',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _code,
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                prefixIcon: Icon(Icons.security),
              ),
            ),
            CheckboxListTile(
              value: _useBackup,
              onChanged: (v) => setState(() => _useBackup = v ?? false),
              title: const Text('Use backup code'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _verify,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
