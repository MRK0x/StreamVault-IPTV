/// A device registered on the account — `GET /api/devices/`.
class UserDevice {
  const UserDevice({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.isActive,
    this.createdAt,
    this.lastSeen,
  });

  /// Numeric ID — used in `DELETE /api/devices/{id}/`.
  final int id;

  /// Device ID — matched against ours to mark "this is your device".
  final String deviceId;
  final String name;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastSeen;

  static UserDevice fromJson(Map<String, dynamic> j) => UserDevice(
        id: int.tryParse('${j['id']}') ?? 0,
        deviceId: '${j['device_id'] ?? ''}',
        // Empty when there's no name — the UI shows a localized default.
        name: '${j['name'] ?? ''}',
        isActive: j['is_active'] != false,
        createdAt: DateTime.tryParse('${j['created_at']}')?.toLocal(),
        lastSeen: DateTime.tryParse('${j['last_seen']}')?.toLocal(),
      );
}

/// Subscription — from `subscription` in `/api/me/`.
class Subscription {
  const Subscription({
    required this.active,
    required this.plan,
    required this.maxDevices,
    this.expiryDate,
  });

  final bool active;
  final String plan;
  final int maxDevices;
  final DateTime? expiryDate;

  /// Days remaining (0 if expired/unknown).
  int get daysLeft {
    final e = expiryDate;
    if (e == null) return 0;
    final d = e.difference(DateTime.now()).inMinutes / 1440.0;
    return d <= 0 ? 0 : d.ceil();
  }

  bool get expired => !active || (expiryDate != null && daysLeft == 0);

  /// Never subscribed — a new account after registration (no plan, no expiry).
  /// Not the same as "expired": this one shows "activate with a code", not
  /// "expired on —".
  bool get never => !active && expiryDate == null;

  static Subscription fromJson(Map<String, dynamic> j) => Subscription(
        active: j['active'] == true,
        plan: '${j['plan'] ?? '—'}',
        maxDevices: int.tryParse('${j['max_devices']}') ?? 1,
        expiryDate: DateTime.tryParse('${j['expiry_date']}')?.toLocal(),
      );
}

/// Account profile — `GET /api/me/`.
class Account {
  const Account({
    required this.username,
    this.email,
    required this.subscription,
    this.device,
  });

  final String username;
  final String? email;
  final Subscription subscription;

  /// The current device as the server sees it.
  final UserDevice? device;

  static Account fromJson(Map<String, dynamic> j) {
    final u = (j['user'] is Map)
        ? (j['user'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final s = (j['subscription'] is Map)
        ? (j['subscription'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final d = (j['device'] is Map)
        ? (j['device'] as Map).cast<String, dynamic>()
        : null;
    return Account(
      username: '${u['username'] ?? ''}',
      email: '${u['email'] ?? ''}'.isEmpty ? null : '${u['email']}',
      subscription: Subscription.fromJson(s),
      device: d == null ? null : UserDevice.fromJson(d),
    );
  }
}
