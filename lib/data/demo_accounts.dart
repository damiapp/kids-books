/// Built-in accounts that work without a real Firebase project — handy for
/// trying the app, demos, or App Store review before you've wired up
/// production sign-in (see README §1c). Signing in with one of these never
/// touches Firebase; it just sets local entitlements to match.
class DemoAccount {
  const DemoAccount({
    required this.email,
    required this.password,
    required this.label,
    required this.subscriptionActive,
  });

  final String email;
  final String password;

  /// Shown on the login screen's quick-fill buttons.
  final String label;

  final bool subscriptionActive;
}

const List<DemoAccount> demoAccounts = [
  DemoAccount(
    email: 'subscriber@demo.peekado.app',
    password: 'demo1234',
    label: 'All Access subscriber (unlimited energy)',
    subscriptionActive: true,
  ),
  DemoAccount(
    email: 'newuser@demo.peekado.app',
    password: 'demo1234',
    label: 'Brand-new user (limited energy)',
    subscriptionActive: false,
  ),
];

DemoAccount? demoAccountByEmail(String email) {
  for (final account in demoAccounts) {
    if (account.email.toLowerCase() == email.trim().toLowerCase()) {
      return account;
    }
  }
  return null;
}

DemoAccount? matchDemoAccount(String email, String password) {
  final account = demoAccountByEmail(email);
  return (account != null && account.password == password) ? account : null;
}
