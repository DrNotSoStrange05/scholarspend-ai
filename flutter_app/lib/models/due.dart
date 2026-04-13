/// Due model — mirrors DueResponse from the backend.
class Due {
  final int id;
  final int userId;
  final double amount;
  final String? description;
  final String personName;
  final DateTime? dueDate;
  final bool isOwedToMe;
  final bool isPaid;
  final DateTime createdAt;

  const Due({
    required this.id,
    required this.userId,
    required this.amount,
    this.description,
    required this.personName,
    this.dueDate,
    required this.isOwedToMe,
    required this.isPaid,
    required this.createdAt,
  });

  factory Due.fromJson(Map<String, dynamic> json) => Due(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        amount: (json['amount'] as num).toDouble(),
        description: json['description'] as String?,
        personName: json['person_name'] as String,
        dueDate: json['due_date'] != null
            ? DateTime.parse(json['due_date'] as String)
            : null,
        isOwedToMe: json['is_owed_to_me'] as bool,
        isPaid: json['is_paid'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
