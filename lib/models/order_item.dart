class OrderItem {
  final int? id;
  final int userId;
  final int productId;
  final String name;
  final double price;
  final String category;
  final String status;
  final String createdAt;

  const OrderItem({
    this.id,
    required this.userId,
    required this.productId,
    required this.name,
    required this.price,
    required this.category,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'name': name,
      'price': price,
      'category': category,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      userId: map['userId'],
      productId: map['productId'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      category: map['category'],
      status: map['status'],
      createdAt: map['createdAt'],
    );
  }
}