/// Built-in accounts that work without a real Firebase project — handy for
/// trying the app, demos, or App Store review before you've wired up
/// production sign-in (see README §1c). Signing in with one of these never
/// touches Firebase; it just sets local demo entitlements to match.
class DemoAccount {
  const DemoAccount({
    required this.email,
    required this.password,
    required this.label,
    required this.subscriptionActive,
    required this.ownedBookIds,
  });

  final String email;
  final String password;

  /// Shown on the login screen's quick-fill buttons.
  final String label;

  final bool subscriptionActive;
  final Set<String> ownedBookIds;
}

const List<DemoAccount> demoAccounts = [
  DemoAccount(
    email: 'subscriber@demo.storyshelf.app',
    password: 'demo1234',
    label: 'All Access subscriber',
    subscriptionActive: true,
    ownedBookIds: {},
  ),
  DemoAccount(
    email: 'newuser@demo.storyshelf.app',
    password: 'demo1234',
    label: 'Brand-new user',
    subscriptionActive: false,
    ownedBookIds: {},
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
