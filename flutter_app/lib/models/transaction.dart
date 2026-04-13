/// Transaction model — mirrors TransactionResponse from the backend.
class Transaction {
  final int id;
  final int userId;
  final double amount;
  final String transactionType;   // "debit" | "credit"
  final String? merchant;
  final String? description;
  final String? rawText;
  final bool isSmsParsed;
  final String category;
  final String? referenceId;
  final String? bankName;
  final String? accountLast4;
  final double? balanceAfter;
  final DateTime transactedAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.transactionType,
    this.merchant,
    this.description,
    this.rawText,
    required this.isSmsParsed,
    required this.category,
    this.referenceId,
    this.bankName,
    this.accountLast4,
    this.balanceAfter,
    required this.transactedAt,
  });

  bool get isDebit => transactionType == 'debit';

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        amount: (json['amount'] as num).toDouble(),
        transactionType: json['transaction_type'] as String,
        merchant: json['merchant'] as String?,
        description: json['description'] as String?,
        rawText: json['raw_text'] as String?,
        isSmsParsed: json['is_sms_parsed'] as bool? ?? false,
        category: json['category'] as String,
        referenceId: json['reference_id'] as String?,
        bankName: json['bank_name'] as String?,
        accountLast4: json['account_last4'] as String?,
        balanceAfter: (json['balance_after'] as num?)?.toDouble(),
        transactedAt: DateTime.parse(json['transacted_at'] as String),
      );
}
