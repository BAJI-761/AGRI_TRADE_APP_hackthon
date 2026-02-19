enum OrderStatus {
  pending,
  accepted,
  rejected;

  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => OrderStatus.pending,
    );
  }

  String toShortString() => name;
}

enum TradeState {
  pending,
  accepted,
  paymentPending,
  paymentHeld,
  shipped,
  delivered,
  completed,
  disputed;

  static TradeState fromString(String state) {
    return TradeState.values.firstWhere(
      (e) => e.name == state,
      orElse: () => TradeState.pending,
    );
  }

  String toShortString() => name;
}
