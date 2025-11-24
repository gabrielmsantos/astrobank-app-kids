class Customer {
  final String customerId;
  final String alias;
  final String name;
  final String email;
  final String balance;
  final String? birthdate;
  final String? gender;
  final String? avatarUrl;

  Customer({
    required this.customerId,
    required this.alias,
    required this.name,
    required this.email,
    required this.balance,
    this.birthdate,
    this.gender,
    this.avatarUrl,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerId: json['customer_id']?.toString() ?? '',
      alias: json['alias']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      balance: json['balance']?.toString() ?? '0.00',
      birthdate: json['birthdate']?.toString(),
      gender: json['gender']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'alias': alias,
      'name': name,
      'email': email,
      'balance': balance,
      'birthdate': birthdate,
      'gender': gender,
      'avatar_url': avatarUrl,
    };
  }
}
