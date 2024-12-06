class RoleManager {
  static const Map<String, List<String>> _permissions = {
    'admin': [
      'property.create',
      'property.update',
      'property.delete',
      'tenant.create',
      'tenant.update',
      'tenant.delete',
      'payment.create',
      'payment.view',
      'user.create',
      'user.update',
      'user.delete',
      'reports.view',
    ],
    'manager': [
      'property.view',
      'tenant.create',
      'tenant.update',
      'payment.create',
      'payment.view',
      'reports.view_assigned',
    ],
  };

  static bool hasPermission(String role, String permission) {
    return _permissions[role]?.contains(permission) ?? false;
  }
}
