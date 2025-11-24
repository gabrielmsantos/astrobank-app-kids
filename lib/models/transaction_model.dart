class Transaction {
  final String id;
  final String type;
  final String nature;
  final String title;
  final String description;
  final DateTime date;
  final String value;
  final String? bankerAlias;
  final String? customerAlias;

  Transaction({
    required this.id,
    required this.type,
    required this.nature,
    required this.title,
    required this.description,
    required this.date,
    required this.value,
    this.bankerAlias,
    this.customerAlias,
  });

  bool get isPositive {
    try {
      return double.parse(value) > 0;
    } catch (e) {
      return false;
    }
  }

  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      nature: json['nature']?.toString() ?? 'debit',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      value: json['value']?.toString() ?? '0.00',
      bankerAlias: json['banker_alias']?.toString(),
      customerAlias: json['customer_alias']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'nature': nature,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'value': value,
      'banker_alias': bankerAlias,
      'customer_alias': customerAlias,
    };
  }
}
