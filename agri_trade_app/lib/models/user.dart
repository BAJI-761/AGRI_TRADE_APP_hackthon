class User {
  final String id;
  final String type; // 'farmer' or 'retailer'
  final String name;
  final String address;
  final Map<String, dynamic>? additionalInfo;

  User(
      {required this.id,
      required this.type,
      required this.name,
      required this.address,
      this.additionalInfo});
}
