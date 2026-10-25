class ExchangeItem {
  final int? id;
  final int userId;
  final int productId;
  final String name;
  final String category;
  final String offerType;
  final String description;
  final String status;
  final String createdAt;

  const ExchangeItem({
    this.id,
    required this.userId,
    required this.productId,
    required this.name,
    required this.category,
    required this.offerType,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'name': name,
      'category': category,
      'offerType': offerType,
      'description': description,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory ExchangeItem.fromMap(Map<String, dynamic> map) {
    return ExchangeItem(
      id: map['id'],
      userId: map['userId'],
      productId: map['productId'],
      name: map['name'],
      category: map['category'],
      offerType: map['offerType'],
      description: map['description'],
      status: map['status'],
      createdAt: map['createdAt'],
    );
  }
}