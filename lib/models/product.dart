import 'dart:convert';

class Product {
  final int? id;
  final int userId;
  final String name;
  final double price;
  final String category;
  final String condition;
  final String description;
  final String location;
  final int sold;
  final int views;
  final String createdAt;

  /// Images for this product. Each entry can be:
  ///  - a base64 data URI  (data:image/jpeg;base64,...)
  ///  - an http(s) URL      (used when a real backend is connected)
  ///  - a local file path   (native only)
  /// The first image is the cover image shown on cards.
  final List<String> images;

  const Product({
    this.id,
    required this.userId,
    required this.name,
    required this.price,
    required this.category,
    required this.condition,
    required this.description,
    required this.location,
    this.sold = 0,
    this.views = 0,
    this.createdAt = '',
    this.images = const [],
  });

  String get priceLabel => '₹${price.toStringAsFixed(0)}';

  /// Exchange value shown across the ReLoop marketplace.
  /// Priced in Indian Rupees (INR).
  String get exchangeValueLabel =>
      '$currencySymbol${price.toStringAsFixed(0)}';

  static const String currencySymbol = '₹';

  /// Rounded to zero decimals for display.
  double get displayPrice => price.roundToDouble();

  /// Deterministic trade-mode label used by the marketplace filter chips.
  /// "Direct Trade" vs "Open to Offers" (mock classification ready to be
  /// replaced by a real backend field later).
  String get tradeType {
    final key = id ?? name.hashCode;
    return key.isEven ? 'Direct Trade' : 'Open to Offers';
  }

  bool get isDirectTrade => tradeType == 'Direct Trade';

  String get coverImage => images.isNotEmpty ? images.first : '';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'price': price,
      'category': category,
      'condition': condition,
      'description': description,
      'location': location,
      'sold': sold,
      'views': views,
      'createdAt': createdAt,
      'images': jsonEncode(images),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      category: map['category'],
      condition: map['condition'],
      description: map['description'],
      location: map['location'],
      sold: map['sold'] ?? 0,
      views: map['views'] ?? 0,
      createdAt: map['createdAt'] ?? '',
      images: _parseImages(map['images']),
    );
  }

  static List<String> _parseImages(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(value as String);
      if (decoded is! List) return const [];
      return decoded.whereType<String>().toList();
    } catch (_) {
      return const [];
    }
  }
}