import 'json.dart';

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final List<String> roles;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.roles,
  });

  String get firstName {
    final n = fullName.trim();
    return n.isEmpty ? email : n.split(RegExp(r'\s+')).first;
  }

  String get initials {
    final src = fullName.trim().isNotEmpty ? fullName.trim() : email;
    final parts = src.split(RegExp(r'[\s@.]+')).where((s) => s.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0]).join().toUpperCase();
    return letters.isEmpty ? '?' : letters;
  }

  bool get isAdmin => roles.any((r) => r.toLowerCase().contains('admin'));

  /// A human label for the account — the first meaningful realm role, or
  /// "Staff". Keycloak's built-in meta roles are not shown.
  static const _metaRoles = {
    'offline_access',
    'uma_authorization',
    'default-roles-onshoretech',
  };

  String get roleLabel {
    for (final r in roles) {
      if (_metaRoles.contains(r) || r.startsWith('default-roles-')) continue;
      final words = r.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
      if (words.isEmpty) continue;
      return words[0].toUpperCase() + words.substring(1);
    }
    return 'Staff';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: asString(json['sub'], asString(json['id'])),
        email: asString(json['email'], asString(json['preferred_username'])),
        fullName: asString(json['name'], asString(json['preferred_username'])),
        // Keycloak sends `roles` as a list; the Vendors portal's Sanctum
        // response sends a single `role` string. Reading only `roles` here
        // left every user role-less without erroring, so fall back.
        roles: json['roles'] != null
            ? asStringList(json['roles'])
            : (json['role'] == null
                ? const <String>[]
                : <String>[asString(json['role'])]),
      );
}
