import 'package:flutter/material.dart';

import '../config.dart';
import '../services/auth_service.dart';
import '../services/energy_service.dart';
import '../services/entitlement_service.dart';
import '../services/narration_service.dart';
import '../services/progress_service.dart';
import 'landing_screen.dart';
import 'paywall_screen.dart';

/// Everything in the app that a child shouldn't reach by tapping around,
/// in one place a parent can find: the account, the subscription, and how
/// the voice sounds.
///
/// Opened only through [ParentalGate] (see PathScreen), so nothing here
/// asks again. Before this existed, Sign out sat in the side menu where
/// a child could tap it and land on a password screen they can't pass.
class GrownUpsScreen extends StatefulWidget {
  const GrownUpsScreen({
    super.key,
    required this.progress,
    required this.energy,
    required this.entitlements,
    this.auth,
  });

  final ProgressService progress;
  final EnergyService energy;
  final EntitlementService entitlements;
  final AuthService? auth;

  @override
  State<GrownUpsScreen> createState() => _GrownUpsScreenState();
}

class _GrownUpsScreenState extends State<GrownUpsScreen> {
  final _narration = NarrationService();

  @override
  void dispose() {
    _narration.dispose();
    super.dispose();
  }

  Future<void> _setSpeed(SpeechSpeed speed) async {
    await NarrationService.setSpeed(speed);
    // A sample of what the child will hear, so the choice isn't blind.
    _narration.speak('Can you find... apple?');
  }

  /// Back to the landing page with the whole stack cleared — signing in
  /// replaced the root route, so there's nothing underneath to pop to.
  void _toLanding(AuthService auth) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LandingScreen(
          entitlements: widget.entitlements,
          auth: auth,
          progress: widget.progress,
          energy: widget.energy,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _signOut(AuthService auth) async {
    await auth.signOut();
    if (mounted) _toLanding(auth);
  }

  Future<void> _deleteAccount(AuthService auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this account?'),
        content: const Text(
          'This permanently deletes the account, and everything Peekadoo '
          'has saved on this phone about the child using it: lessons '
          'finished, streaks, and the words they found hard. It can\'t be '
          'undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    var result = await auth.deleteAccount();
    if (result == AuthService.needsPassword && mounted) {
      final password = await showDialog<String>(
        context: context,
        builder: (_) => const _PasswordDialog(),
      );
      if (password == null || !mounted) return;
      result = await auth.deleteAccount(password: password);
    }
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result == AuthService.needsPassword
            ? 'Please sign out, sign back in, and try again.'
            : result),
      ));
      return;
    }

    await widget.progress.resetAll();
    if (mounted) _toLanding(auth);
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    final email = auth?.currentEmail;
    final subscribed = widget.entitlements.subscriptionActive;

    return Scaffold(
      appBar: AppBar(title: const Text('For grown-ups')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _Heading('Voice'),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              'How fast Peekadoo talks. Slower suits the youngest '
              'listeners; you\'ll hear a sample when you choose.',
            ),
          ),
          ValueListenableBuilder<SpeechSpeed>(
            valueListenable: NarrationService.speed,
            builder: (context, speed, _) => SegmentedButton<SpeechSpeed>(
              segments: [
                for (final s in SpeechSpeed.values)
                  ButtonSegment(value: s, label: Text(s.label)),
              ],
              selected: {speed},
              showSelectedIcon: false,
              onSelectionChanged: (picked) => _setSpeed(picked.single),
            ),
          ),
          if (kPaymentsLive) ...[
            const _Heading('Subscription'),
            Card(
              child: ListTile(
                leading: Icon(subscribed
                    ? Icons.verified_rounded
                    : Icons.workspace_premium_rounded),
                title: Text(subscribed ? 'All Access' : 'Free plan'),
                subtitle: Text(subscribed
                    ? 'Unlimited energy'
                    : 'Upgrade for unlimited energy'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      PaywallScreen(entitlements: widget.entitlements),
                )),
              ),
            ),
          ],
          if (auth != null) ...[
            const _Heading('Account'),
            Card(
              child: Column(
                children: [
                  if (email != null)
                    ListTile(
                      leading: const Icon(Icons.mail_outline_rounded),
                      title: const Text('Signed in as'),
                      subtitle: Text(email),
                    ),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: const Text('Sign out'),
                    onTap: () => _signOut(auth),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Quiet on purpose, and last: findable by a parent who looks
            // for it, never the obvious thing to tap.
            Center(
              child: TextButton(
                onPressed: () => _deleteAccount(auth),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete account'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Firebase asks for the password again before it will delete an account
/// that signed in a while ago. Its own widget so the text controller is
/// created and disposed with the dialog.
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _controller.text;
    if (password.isNotEmpty) Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm your password'),
      content: TextField(
        controller: _controller,
        obscureText: true,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Password'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Delete')),
      ],
    );
  }
}
