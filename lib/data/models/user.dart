class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? avatarUrl;

  /// Nobody. The signed-out profile — used instead of falling back to the demo
  /// user, which is how mock details leaked onto real accounts.
  static const AppUser empty =
      AppUser(id: '', fullName: '', email: '', phone: '');

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
