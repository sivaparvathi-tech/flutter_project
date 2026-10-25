import 'package:flutter/material.dart';

IconData productIconForCategory(String category) {
  switch (category.toLowerCase()) {
    case 'mobiles':
      return Icons.smartphone_rounded;
    case 'cars':
      return Icons.directions_car_rounded;
    case 'bikes':
      return Icons.two_wheeler_rounded;
    case 'laptops':
      return Icons.laptop_mac_rounded;
    case 'cameras':
      return Icons.camera_alt_rounded;
    case 'gaming':
      return Icons.sports_esports_rounded;
    case 'electronics':
      return Icons.devices_other_rounded;
    case 'furniture':
      return Icons.chair_rounded;
    case 'fashion':
      return Icons.checkroom_rounded;
    case 'books':
      return Icons.menu_book_rounded;
    default:
      return Icons.category_rounded;
  }
}