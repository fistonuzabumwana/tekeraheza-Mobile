enum UserRole {
  admin('ADMIN'),
  manager('MANAGER'),
  staff('STAFF'),
  deliveryPersonnel('DELIVERY_PERSONNEL'),
  customer('CUSTOMER');

  const UserRole(this.value);
  final String value;

  static UserRole? fromString(String? raw) {
    if (raw == null) return null;
    for (final role in UserRole.values) {
      if (role.value == raw) return role;
    }
    return null;
  }
}
