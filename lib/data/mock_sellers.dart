/// Seller profile displayed on product details until a real backend serves
/// owner profiles. Values (rating, completed swaps, response time) are mock
/// user-facing data only.
class SellerInfo {
  final String name;
  final double rating;
  final int completedSwaps;
  final String responseTime;
  final String location;

  const SellerInfo({
    required this.name,
    required this.rating,
    this.completedSwaps = 0,
    this.responseTime = '~2 hrs',
    this.location = 'Nearby',
  });
}

const List<SellerInfo> _sellers = [
  SellerInfo(
    name: 'Alex Morales',
    rating: 4.9,
    completedSwaps: 27,
    responseTime: '~1 hr',
    location: 'Next City',
  ),
  SellerInfo(
    name: 'Priya Sharma',
    rating: 4.8,
    completedSwaps: 41,
    responseTime: '~2 hrs',
    location: 'Downtown',
  ),
  SellerInfo(
    name: 'Marcus Lee',
    rating: 5.0,
    completedSwaps: 63,
    responseTime: '~30 min',
    location: 'Midtown',
  ),
  SellerInfo(
    name: 'Sofia Reyes',
    rating: 4.7,
    completedSwaps: 15,
    responseTime: '~3 hrs',
    location: 'North Side',
  ),
  SellerInfo(
    name: 'James Wu',
    rating: 4.9,
    completedSwaps: 22,
    responseTime: '~1 hr',
    location: 'Old Town',
  ),
];

/// Returns a stable mock seller for a product (deterministic per product id).
SellerInfo mockSellerForProduct(int productId) {
  if (productId <= 0) return _sellers.first;
  return _sellers[productId % _sellers.length];
}