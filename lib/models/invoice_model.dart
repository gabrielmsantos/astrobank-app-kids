class Invoice {
  final String id;
  final String closingDate;
  final String? dueDate;
  final String totalAmount;
  final String paidAmount;
  final String? fees;
  final String? interest;
  final String status;

  Invoice({
    required this.id,
    required this.closingDate,
    this.dueDate,
    required this.totalAmount,
    required this.paidAmount,
    this.fees,
    this.interest,
    required this.status,
  });

  String get unpaidAmount {
    try {
      final total = double.parse(totalAmount);
      final paid = double.parse(paidAmount);
      final unpaid = total - paid;
      return unpaid.toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  bool get isFullyPaid {
    try {
      final total = double.parse(totalAmount);
      final paid = double.parse(paidAmount);
      return paid >= total;
    } catch (e) {
      return false;
    }
  }

  String get monthAbbreviation {
    try {
      final date = DateTime.parse(closingDate);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return months[date.month - 1];
    } catch (e) {
      return '';
    }
  }

  String get formattedClosingDate {
    try {
      final date = DateTime.parse(closingDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return closingDate;
    }
  }

  String get formattedDueDate {
    if (dueDate == null) return 'N/A';
    try {
      final date = DateTime.parse(dueDate!);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dueDate!;
    }
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['invoice_id']?.toString() ?? json['id']?.toString() ?? '',
      closingDate: json['closing_date']?.toString() ?? '',
      dueDate: json['due_date']?.toString(),
      totalAmount: json['total_amount']?.toString() ?? '0.00',
      paidAmount: json['paid_amount']?.toString() ?? '0.00',
      fees: json['fees']?.toString(),
      interest: json['interest']?.toString(),
      status: json['status']?.toString() ?? 'open',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'closing_date': closingDate,
      'due_date': dueDate,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'status': status,
    };
  }
}
