
class Account {
  final String servicePassword;
  final String upToken;
  final String username;

  Account({
    required this.servicePassword,
    required this.upToken,
    required this.username,
  });

  factory Account.fromMap(Map<dynamic, dynamic> map) {
    return Account(
      servicePassword: map['service_password'] as String? ?? '',
      upToken: map['up_token'] as String? ?? '',
      username: map['username'] as String? ?? '',
    );
  }

  @override
  String toString() {
    // IMPORTANT: Avoid logging raw passwords or sensitive tokens in production.
    return 'Account(username: $username, upToken: ${upToken.isNotEmpty ? "[PRESENT]" : "[EMPTY]"}, servicePassword: ${servicePassword.isNotEmpty ? "[PRESENT]" : "[EMPTY]"})';
  }
}