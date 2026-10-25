/// A single message in a conversation.
///
/// Conversations are grouped by the product they relate to together with the
/// counterpart name, which keeps the data simple enough for local storage
/// while remaining ready for a future backend.
class MessageModel {
  final int? id;

  /// The message owner (the logged-in user).
  final int userId;

  /// Product this conversation is about.
  final int productId;
  final String productName;

  /// Display name of the other person in the conversation.
  final String counterpartName;

  /// Whether this message was sent by the logged-in user.
  final bool isMine;

  final String text;
  final String createdAt;

  const MessageModel({
    this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.counterpartName,
    this.isMine = false,
    required this.text,
    this.createdAt = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'counterpartName': counterpartName,
      'isMine': isMine ? 1 : 0,
      'text': text,
      'createdAt': createdAt,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      userId: map['userId'],
      productId: map['productId'],
      productName: map['productName'] ?? '',
      counterpartName: map['counterpartName'] ?? '',
      isMine: (map['isMine'] ?? 0) == 1,
      text: map['text'] ?? '',
      createdAt: map['createdAt'] ?? '',
    );
  }
}