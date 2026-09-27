/// Identifiers for the 6 Executive Workstations on the Owner portal.
enum WorkstationId {
  members,
  workout,
  storeOrders,
  proShop,
  payments,
  tools;

  String get key => name;

  static const List<WorkstationId> defaultOrder = [
    WorkstationId.members,
    WorkstationId.workout,
    WorkstationId.storeOrders,
    WorkstationId.proShop,
    WorkstationId.payments,
    WorkstationId.tools,
  ];

  static WorkstationId? tryParse(String key) {
    for (final id in WorkstationId.values) {
      if (id.name.toLowerCase() == key.toLowerCase()) return id;
    }
    // Handle snake_case variants from JSON
    switch (key.toLowerCase()) {
      case 'store_orders':
      case 'storeorders':
        return WorkstationId.storeOrders;
      case 'pro_shop':
      case 'proshop':
        return WorkstationId.proShop;
    }
    return null;
  }
}
