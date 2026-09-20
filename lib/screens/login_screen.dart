import 'package:flutter/material.dart';

import '../data/demo_accounts.dart';
import '../services/auth_service.dart';
import '../services/energy_service.dart';
import '../services/entitlement_service.dart';
import '../services/progress_service.dart';
import 'path_screen.dart';

/// Email/password sign-in and sign-up, backed by Firebase Authentication.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.entitlements,
    required this.auth,
    required this.progress,
    required this.energy,
  });

  final EntitlementService entitlements;
  final AuthService auth;
  final ProgressService progress;
  final EnergyService energy;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isCreatingAccount = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _useDemoAccount(DemoAccount account) {
    _emailController.text = account.email;
    _passwordController.text = account.password;
    setState(() {
      _isCreatingAccount = false;
      _error = null;
    });
    _submit();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final error = _isCreatingAccount
        ? await widget.auth.signUp(email, password)
        : await widget.auth.signIn(email, password);

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isSubmitting = false;
        _error = error;
      });
      return;
    }

    final demo = widget.auth.activeDemoAccount;
    if (demo != null && widget.entitlements is DemoEntitlementService) {
      await (widget.entitlements as DemoEntitlementService).applyDemoPreset(
        subscriptionActive: demo.subscriptionActive,
      );
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PathScreen(
          entitlements: widget.entitlements,
          auth: widget.auth,
          progress: widget.progress,
          energy: widget.energy,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isCreatingAccount ? 'Create your account' : 'Welcome back',
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  _isCreatingAccount
                      ? 'Sign up to save your books and subscription.'
                      : 'Sign in to pick up right where you left off.',
                  style:
                      TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: TextStyle(color: scheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isCreatingAccount ? 'Create Account' : 'Sign In',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => setState(() {
                            _isCreatingAccount = !_isCreatingAccount;
                            _error = null;
                          }),
                  child: Text(
                    _isCreatingAccount
                        ? 'Already have an account? Sign in'
                        : 'New here? Create an account',
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(child: Divider(color: scheme.outlineVariant)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or try it instantly',
                          style: TextStyle(
                              fontSize: 13, color: scheme.onSurfaceVariant)),
                    ),
                    Expanded(child: Divider(color: scheme.outlineVariant)),
                  ],
                ),
                const SizedBox(height: 16),
                for (final account in demoAccounts) ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed:
                        _isSubmitting ? null : () => _useDemoAccount(account),
                    child: Text(
                      account.subscriptionActive
                          ? '👑  ${account.label}'
                          : '🙂  ${account.label}',
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
