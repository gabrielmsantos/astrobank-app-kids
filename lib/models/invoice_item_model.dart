class InvoiceItem {
  final String id;
  final String postingDate;
  final String title;
  final String? description;
  final String category;
  final String type;
  final String amount;

  InvoiceItem({
    required this.id,
    required this.postingDate,
    required this.title,
    this.description,
    required this.category,
    required this.type,
    required this.amount,
  });

  bool get isPositive {
    try {
      return double.parse(amount) > 0;
    } catch (e) {
      return false;
    }
  }

  String get formattedPostingDate {
    try {
      final date = DateTime.parse(postingDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return postingDate;
    }
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id']?.toString() ?? '',
      postingDate: json['posting_date']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category']?.toString() ?? 'Other',
      type: json['type']?.toString() ?? 'charge',
      amount: json['amount']?.toString() ?? '0.00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'posting_date': postingDate,
      'title': title,
      'description': description,
      'category': category,
      'type': type,
      'amount': amount,
    };
  }
}
