import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/cart_line.dart';
import 'database_helper.dart';

class AppState {
  AppState._();

  static final AppState instance = AppState._();

  User? currentUser;
  bool isGuest = false;

  bool get isLoggedIn => currentUser != null && !isGuest;

  final ValueNotifier<List<CartLine>> cart =
      ValueNotifier<List<CartLine>>([]);
  final ValueNotifier<List<Product>> favourites =
      ValueNotifier<List<Product>>([]);

  /// Market area shown in the Home location selector.
  final ValueNotifier<String> currentCity =
      ValueNotifier<String>('Brooklyn');

  Future<void> enterGuestMode() async {
    isGuest = true;
    currentUser = null;
    cart.value = [];
    favourites.value = [];
  }

  Future<void> setUser(User? user) async {
    currentUser = user;
    isGuest = false;
    if (user?.id != null) {
      await DatabaseHelper.instance.saveSession(user!.id!);
    } else {
      await DatabaseHelper.instance.clearSession();
    }
    await loadUserData();
  }

  /// Replaces the in-memory current user (e.g. after editing the profile).
  Future<void> setCurrentUser(User user) async {
    currentUser = user;
    isGuest = false;
    await loadUserData();
  }

  Future<void> restoreUser() async {
    final userId = await DatabaseHelper.instance.getSessionUserId();
    if (userId == null) return;

    currentUser = await DatabaseHelper.instance.getUserById(userId);
    if (currentUser == null) {
      await DatabaseHelper.instance.clearSession();
      return;
    }
    isGuest = false;
    await loadUserData();
  }

  Future<void> loadUserData() async {
    final user = currentUser;
    if (user == null) {
      cart.value = [];
      favourites.value = [];
      return;
    }
    cart.value = await DatabaseHelper.instance.getCartLines(user.id!);
    favourites.value =
        await DatabaseHelper.instance.getFavouriteProducts(user.id!);
  }

  Future<void> refreshCart() async {
    final user = currentUser;
    if (user == null) return;
    cart.value = await DatabaseHelper.instance.getCartLines(user.id!);
  }

  Future<void> refreshFavourites() async {
    final user = currentUser;
    if (user == null) return;
    favourites.value =
        await DatabaseHelper.instance.getFavouriteProducts(user.id!);
  }

  Future<void> addToCart(Product product) async {
    final user = currentUser;
    if (user == null) return;
    await DatabaseHelper.instance.addToCart(user.id!, product.id!);
    await refreshCart();
  }

  Future<void> updateCartQuantity(CartLine line, int quantity) async {
    final user = currentUser;
    if (user == null) return;
    await DatabaseHelper.instance
        .updateCartQuantity(line.id, quantity);
    await refreshCart();
  }

  Future<void> removeFromCart(CartLine line) async {
    final user = currentUser;
    if (user == null) return;
    await DatabaseHelper.instance.removeCartItem(line.id);
    await refreshCart();
  }

  Future<void> clearCart() async {
    final user = currentUser;
    if (user == null) return;
    await DatabaseHelper.instance.clearCart(user.id!);
    await refreshCart();
  }

  Future<void> toggleFavourite(Product product) async {
    final user = currentUser;
    if (user == null) return;
    final db = DatabaseHelper.instance;
    if (await db.isFavourite(user.id!, product.id!)) {
      await db.removeFavourite(user.id!, product.id!);
    } else {
      await db.addFavourite(user.id!, product.id!);
    }
    await refreshFavourites();
  }

  Future<bool> isFavourite(Product product) async {
    final user = currentUser;
    if (user == null) return false;
    return DatabaseHelper.instance
        .isFavourite(user.id!, product.id!);
  }

  Future<void> clear() async {
    currentUser = null;
    isGuest = false;
    cart.value = [];
    favourites.value = [];
    await DatabaseHelper.instance.clearSession();
  }
}