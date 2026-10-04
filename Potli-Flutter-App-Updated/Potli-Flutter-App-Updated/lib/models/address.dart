class Address {
  const Address({
    required this.id,
    required this.name,
    required this.mobile,
    required this.address,
    required this.landmark,
    required this.city,
    required this.pincode,
    required this.type,
    required this.isDefault,
  });

  final String id;
  final String name;
  final String mobile;
  final String address;
  final String landmark;
  final String city;
  final String pincode;
  final String type;
  final bool isDefault;

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      mobile: '${json['mobile'] ?? ''}',
      address: '${json['address'] ?? ''}',
      landmark: '${json['landmark'] ?? ''}',
      city: '${json['city'] ?? ''}',
      pincode: '${json['pincode'] ?? ''}',
      type: '${json['type'] ?? ''}',
      isDefault: '${json['is_default'] ?? '0'}' == '1',
    );
  }
}
