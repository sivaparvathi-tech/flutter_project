import '../models/product.dart';
import 'database_helper.dart';

/// Single data source for products.
///
/// Today it talks to the local SQLite database (DatabaseHelper). The app is
/// designed so that this class can later be swapped for a real HTTP backend
/// without touching any screen:
///
///   getProducts()          -> GET    /products
///   getProductById(id)     -> GET    /products/:id
///   addProduct(product)    -> POST   /products            (returns id)
///   uploadProductImages()  -> POST   /products/:id/images (or multipart)
///   updateProduct(product) -> PUT    /products/:id
///   deleteProduct(id)      -> DELETE /products/:id
///   getProductsByCategory  -> GET    /products?category=...
///   searchProducts(query)  -> GET    /products?q=...
///
/// When images come from a backend they will be http(s) URLs inside
/// [Product.images]; [ProductImage] already renders them.
class ProductRepository {
  ProductRepository._();

  static final ProductRepository instance = ProductRepository._();

  Future<List<Product>> getProducts() {
    return DatabaseHelper.instance.getAllProducts();
  }

  Future<Product?> getProductById(int id) {
    return DatabaseHelper.instance.getProduct(id);
  }

  Future<int> addProduct(Product product) {
    return DatabaseHelper.instance.insertProduct(product);
  }

  Future<void> updateProduct(Product product) {
    return DatabaseHelper.instance.updateProduct(product);
  }

  Future<void> deleteProduct(int id) {
    return DatabaseHelper.instance.deleteProduct(id);
  }

  Future<List<Product>> getProductsByCategory(String category) {
    return DatabaseHelper.instance.getProductsByCategory(category);
  }

  Future<List<Product>> searchProducts(String query) {
    return DatabaseHelper.instance.searchProducts(query);
  }
}