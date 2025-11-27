class Customer {
  final String customerId;
  final String alias;
  final String name;
  final String email;
  final String balance;
  final String? key; // Can be null for customers
  final String? birthdate;
  final String? gender;
  final String? avatarUrl;
  final String? type;

  Customer({
    required this.customerId,
    required this.alias,
    required this.name,
    required this.email,
    required this.balance,
    this.key,
    this.birthdate,
    this.gender,
    this.avatarUrl,
    this.type,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      // Handle both 'customer_id' (from details API) and 'id' (from login API)
      customerId: json['customer_id']?.toString() ?? json['id']?.toString() ?? '',
      // Handle both 'alias' (from details API) and 'username' (from login API)
      alias: json['alias']?.toString() ?? json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      balance: json['balance']?.toString() ?? '0.00',
      key: json['key']?.toString(), // Can be null
      birthdate: json['birthdate']?.toString(),
      gender: json['gender']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      type: json['type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'alias': alias,
      'name': name,
      'email': email,
      'balance': balance,
      'key': key,
      'birthdate': birthdate,
      'gender': gender,
      'avatar_url': avatarUrl,
      'type': type,
    };
  }
}
