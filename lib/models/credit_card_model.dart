class CreditCard {
  final String cardId;
  final String cardNumber;
  final String cardType;
  final String expirationDate;
  final String limitAmount;
  final String availableLimit;
  final String status;
  final bool virtual;

  CreditCard({
    required this.cardId,
    required this.cardNumber,
    required this.cardType,
    required this.expirationDate,
    required this.limitAmount,
    required this.availableLimit,
    required this.status,
    required this.virtual,
  });

  String get maskedCardNumber {
    if (cardNumber.length >= 4) {
      final lastFour = cardNumber.substring(cardNumber.length - 4);
      return '**** **** **** $lastFour';
    }
    return cardNumber;
  }

  String get expiryMonth {
    try {
      // Handle ISO date format (YYYY-MM-DD) or MM/YY format
      if (expirationDate.contains('-')) {
        final date = DateTime.parse(expirationDate);
        return date.month.toString().padLeft(2, '0');
      } else {
        final parts = expirationDate.split('/');
        return parts.isNotEmpty ? parts[0].padLeft(2, '0') : '00';
      }
    } catch (e) {
      return '00';
    }
  }

  String get expiryYear {
    try {
      // Handle ISO date format (YYYY-MM-DD) or MM/YY format
      if (expirationDate.contains('-')) {
        final date = DateTime.parse(expirationDate);
        return date.year.toString().substring(2); // Get last 2 digits
      } else {
        final parts = expirationDate.split('/');
        return parts.length > 1 ? parts[1] : '00';
      }
    } catch (e) {
      return '00';
    }
  }

  String get typeDisplay {
    return cardType.split(' ').first.toUpperCase();
  }

  bool get isActive {
    return status.toLowerCase() == 'active';
  }

  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard(
      cardId: (json['credit_card_id'] ?? json['card_id'])?.toString() ?? '',
      cardNumber: json['card_number']?.toString() ?? '',
      cardType: json['card_type']?.toString() ?? '',
      expirationDate: json['expiration_date']?.toString() ?? '',
      limitAmount: json['limit_amount']?.toString() ?? '0.00',
      availableLimit: json['available_limit']?.toString() ?? '0.00',
      status: json['status']?.toString() ?? 'inactive',
      virtual: json['virtual'] == true || json['virtual'] == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_id': cardId,
      'card_number': cardNumber,
      'card_type': cardType,
      'expiration_date': expirationDate,
      'limit_amount': limitAmount,
      'available_limit': availableLimit,
      'status': status,
      'virtual': virtual,
    };
  }
}
