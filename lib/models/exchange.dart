/// A full exchange proposal created through the "Propose Exchange" flow.
///
/// Represents one user offering one of their own products (plus an optional
/// cash sweetener) in exchange for a target product listed by another user.
class ExchangeModel {
  final int? id;

  /// Id of the user who created the proposal (the offerer).
  final int userId;

  /// The proposer's own product being offered as the swap item.
  final int myProductId;
  final String myProductName;

  /// The product the proposer wants in return.
  final int targetProductId;
  final String targetProductName;

  /// Optional cash added on top of the product to balance the trade.
  final double cashAmount;

  /// pending | accepted | rejected
  final String status;

  final String createdAt;

  const ExchangeModel({
    this.id,
    required this.userId,
    required this.myProductId,
    required this.myProductName,
    required this.targetProductId,
    required this.targetProductName,
    this.cashAmount = 0,
    this.status = 'Pending',
    this.createdAt = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'myProductId': myProductId,
      'myProductName': myProductName,
      'targetProductId': targetProductId,
      'targetProductName': targetProductName,
      'cashAmount': cashAmount,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory ExchangeModel.fromMap(Map<String, dynamic> map) {
    return ExchangeModel(
      id: map['id'],
      userId: map['userId'],
      myProductId: map['myProductId'],
      myProductName: map['myProductName'] ?? '',
      targetProductId: map['targetProductId'],
      targetProductName: map['targetProductName'] ?? '',
      cashAmount: (map['cashAmount'] as num?)?.toDouble() ?? 0,
      status: map['status'] ?? 'Pending',
      createdAt: map['createdAt'] ?? '',
    );
  }
}