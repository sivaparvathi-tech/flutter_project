import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/cart_line.dart';
import '../models/order_item.dart';
import '../models/exchange_item.dart';
import '../models/exchange.dart';
import '../models/message.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // On web, getDatabasesPath() + join() is unreliable (can return null /
    // throw). sqflite_common_ffi_web keys the IndexedDB on the plain file
    // name, so open by bare name for a deterministic, portable path.
    // NOTE: IndexedDB is scoped to origin + PORT, so always run the web app
    // on the same port (e.g. flutter run -d chrome --web-port=5000).
    final path =
        kIsWeb ? 'reexchange.db' : join(await getDatabasesPath(), 'reexchange.db');
    debugPrint('DATABASE OPEN: $path');
    final db = await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await _createTables(db);
        await _seedProducts(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createTables(db);
        if (oldVersion < 4) {
          // Add the images column (JSON array of image sources) to products.
          try {
            final cols = await db.rawQuery(
              'PRAGMA table_info(products)',
            );
            final hasImages = cols.any(
              (column) => column['name'] == 'images',
            );
            if (!hasImages) {
              await db.execute(
                "ALTER TABLE products ADD COLUMN images TEXT NOT NULL DEFAULT ''",
              );
            }
          } catch (e) {
            debugPrint('DATABASE MIGRATION: images column -> $e');
          }
        }
        if (oldVersion < 5) {
          await _ensureReferenceProducts(db);
        }
      },
    );
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
    );
    debugPrint(
      'DATABASE READY: path=${db.path}, tables=${tables.map((row) => row['name']).toList()}',
    );
    return db;
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        category TEXT NOT NULL,
        condition TEXT NOT NULL,
        description TEXT NOT NULL,
        location TEXT NOT NULL,
        sold INTEGER NOT NULL DEFAULT 0,
        views INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL DEFAULT '',
        images TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cart(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        UNIQUE(userId, productId)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS favourites(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        UNIQUE(userId, productId)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        category TEXT NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS exchanges(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        offerType TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS exchange_proposals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        myProductId INTEGER NOT NULL,
        myProductName TEXT NOT NULL,
        targetProductId INTEGER NOT NULL,
        targetProductName TEXT NOT NULL,
        cashAmount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'Pending',
        createdAt TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        counterpartName TEXT NOT NULL,
        isMine INTEGER NOT NULL DEFAULT 0,
        text TEXT NOT NULL,
        createdAt TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS session(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        userId INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _seedProducts(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM products'),
    );
    if (count != null && count > 0) return;

    final samples = [
      _seed(0, 'Sony A6400 Mirrorless', 58000, 'Cameras', 'Excellent',
          'Sony Alpha A6400 mirrorless camera body with 16-50mm kit lens. '
          'Great sensor, no marks, box and accessories included.',
          'Brooklyn'),
      _seed(0, 'Beta Jacket', 1500, 'Fashion', 'Good',
          'Classic beta jacket, size M, warm lining in immaculate shape.',
          'Brooklyn'),
      _seed(0, 'Custom Mechanical Keyboard', 9000, 'Gaming', 'Excellent',
          'Custom built mechanical keyboard, hot-swappable switches, PBT keycaps.',
          'Manhattan'),
      _seed(0, '1970s Leather Chair', 18000, 'Furniture', 'Fair',
          'Genuine leather lounge chair from the 1970s, solid wood base, '
          'beautiful patina.',
          'Brooklyn'),
      _seed(0, 'Samsung Galaxy S22', 12000, 'Mobiles', 'Good',
          'A well-maintained Samsung Galaxy S22 with original box and charger.',
          'Srikakulam'),
      _seed(0, 'iPhone 13', 32000, 'Mobiles', 'Excellent',
          'iPhone 13, 128GB, battery health 92%. Includes case and cable.',
          'Vizianagaram'),
      _seed(0, 'HP Pavilion Laptop', 24000, 'Laptops', 'Good',
          'HP Pavilion with Core i5, 8GB RAM, 512GB SSD. Works perfectly.',
          'Visakhapatnam'),
      _seed(0, 'Hero Splendor Bike', 28000, 'Bikes', 'Good',
          'Hero Splendor Plus, single owner, all documents ready.',
          'Srikakulam'),
      _seed(0, 'Royal Enfield Classic 350', 85000, 'Bikes', 'Good',
          'Classic 350 in great shape, recently serviced.',
          'Visakhapatnam'),
      _seed(0, 'Office Chair', 1500, 'Furniture', 'Fair',
          'Ergonomic office chair, adjustable height, minor wear on armrest.',
          'Ravulapalem'),
      _seed(0, 'Wooden Study Table', 2500, 'Furniture', 'Good',
          'Solid wooden study table with drawer, sturdy and clean.',
          'Vizianagaram'),
      _seed(0, 'Sony 43 Inch Smart TV', 16000, 'Electronics', 'Excellent',
          'Sony Bravia 43 inch smart TV with remote and wall mount.',
          'Srikakulam'),
      _seed(0, 'Nintendo Switch Lite', 9000, 'Gaming', 'Excellent',
          'Nintendo Switch Lite with two games and a case. Barely used.',
          'Hyderabad'),
      _seed(0, 'Canon EOS 200D', 21000, 'Cameras', 'Good',
          'Canon EOS 200D DSLR with 18-55mm lens and bag.',
          'Vizianagaram'),
      _seed(0, 'Prestige Pressure Cooker', 1100, 'Electronics', 'Good',
          '5 litre pressure cooker, lightly used, non-stick base.',
          'Vizianagaram'),
      _seed(0, 'Study Books Set', 800, 'Books', 'Good',
          'Engineering reference books set, clean condition.',
          'Visakhapatnam'),
      _seed(0, 'Denim Jacket', 600, 'Fashion', 'Excellent',
          'Classic blue denim jacket, size M, barely worn.',
          'Srikakulam'),
      _seed(0, 'Sony Bluetooth Speaker', 1800, 'Electronics', 'Excellent',
          'Waterproof bluetooth speaker with good bass.',
          'Ravulapalem'),
    ];

    for (final p in samples) {
      await db.insert('products', p);
    }
  }

  /// Upgrades an existing install by adding the showcase reference products
  /// when the Cameras category is empty (i.e. older DB without them).
  Future<void> _ensureReferenceProducts(Database db) async {
    final cameraCount = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM products WHERE LOWER(category) = 'cameras'",
      ),
    );
    if (cameraCount != null && cameraCount > 0) return;

    final reference = [
      _seed(0, 'Sony A6400 Mirrorless', 58000, 'Cameras', 'Excellent',
          'Sony Alpha A6400 mirrorless camera body with 16-50mm kit lens. '
          'Great sensor, no marks, box and accessories included.',
          'Brooklyn'),
      _seed(0, 'Custom Mechanical Keyboard', 9000, 'Gaming', 'Excellent',
          'Custom built mechanical keyboard, hot-swappable switches, PBT keycaps.',
          'Manhattan'),
      _seed(0, '1970s Leather Chair', 18000, 'Furniture', 'Fair',
          'Genuine leather lounge chair from the 1970s, solid wood base, '
          'beautiful patina.',
          'Brooklyn'),
    ];
    for (final p in reference) {
      await db.insert('products', p);
    }
    debugPrint('DATABASE SEED: reference products inserted on upgrade');
  }

  Map<String, dynamic> _seed(
    int userId,
    String name,
    double price,
    String category,
    String condition,
    String description,
    String location,
  ) {
    return {
      'userId': userId,
      'name': name,
      'price': price,
      'category': category,
      'condition': condition,
      'description': description,
      'location': location,
      'sold': 0,
      'views': 0,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  // =========================
  // USERS
  // =========================

  Future<int> insertUser(User user) async {
    final db = await database;
    final userId = await db.insert('users', user.toMap());
    debugPrint('DATABASE INSERT users: id=$userId, email=${user.email}');
    return userId;
  }

  Future<User?> registerUser(User user) async {
    final email = user.email.trim().toLowerCase();
    final existing = await getUserByEmail(email);
    if (existing != null) {
      debugPrint('DATABASE REGISTER: duplicate email=$email');
      return null;
    }

    final id = await insertUser(user);
    final createdUser = await getUserById(id);
    if (createdUser == null) {
      debugPrint('DATABASE REGISTER ERROR: inserted user id=$id was not found');
      throw StateError('User insert could not be verified');
    }
    debugPrint('DATABASE REGISTER VERIFIED: id=$id, email=$email');
    return createdUser;
  }

  Future<User?> loginUser(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final user = await getUserByEmail(normalizedEmail);
    if (user == null) {
      debugPrint('DATABASE LOGIN: no user found for email=$normalizedEmail');
      return null;
    }
    if (user.password != password) {
      debugPrint('DATABASE LOGIN: password mismatch for email=$normalizedEmail');
      return null;
    }
    debugPrint('DATABASE LOGIN VERIFIED: id=${user.id}, email=$normalizedEmail');
    return user;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (result.isEmpty) {
      return null;
    }
    debugPrint('DATABASE USER FOUND: email=${email.trim().toLowerCase()}');
    return User.fromMap(result.first);
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) {
      return null;
    }
    return User.fromMap(result.first);
  }

  Future<User?> getUserByPhone(String phone) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [phone.trim()],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  /// Updates the profile fields of an existing user (id must be set).
  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update(
      'users',
      {
        'fullName': user.fullName,
        'email': user.email.trim().toLowerCase(),
        'phone': user.phone,
        'password': user.password,
        'role': user.role,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
    debugPrint('DATABASE UPDATE users: id=${user.id}');
  }

  Future<void> saveSession(int userId) async {
    final db = await database;
    await db.insert(
      'session',
      {'id': 1, 'userId': userId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int?> getSessionUserId() async {
    final db = await database;
    final result = await db.query('session', limit: 1);
    if (result.isEmpty) return null;
    return result.first['userId'] as int;
  }

  Future<void> clearSession() async {
    final db = await database;
    await db.delete('session');
  }

  // =========================
  // PRODUCTS
  // =========================

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return db.insert('products', product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementViews(int id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE products SET views = views + 1 WHERE id = ?',
      [id],
    );
  }

  Future<void> markSold(int id) async {
    final db = await database;
    await db.update(
      'products',
      {'sold': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final result = await db.query(
      'products',
      orderBy: 'id DESC',
    );
    return result.map(Product.fromMap).toList();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await database;
    if (category.trim().toLowerCase() == 'other') {
      // "Other" also surfaces older "Others"/"Electronics" listings.
      final result = await db.query(
        'products',
        where:
            "LOWER(category) = 'other' OR LOWER(category) = 'others' OR LOWER(category) = 'electronics'",
        orderBy: 'id DESC',
      );
      return result.map(Product.fromMap).toList();
    }
    final result = await db.query(
      'products',
      where: 'LOWER(category) = LOWER(?)',
      whereArgs: [category.trim()],
      orderBy: 'id DESC',
    );
    return result.map(Product.fromMap).toList();
  }

  Future<List<Product>> getUserProducts(int userId) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return result.map(Product.fromMap).toList();
  }

  Future<Product?> getProduct(int id) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) {
      return null;
    }
    return Product.fromMap(result.first);
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final term = '%${query.trim()}%';
    final result = await db.query(
      'products',
      where:
          'name LIKE ? OR category LIKE ? OR condition LIKE ? OR description LIKE ?',
      whereArgs: [term, term, term, term],
      orderBy: 'id DESC',
    );
    return result.map(Product.fromMap).toList();
  }

  // =========================
  // CART
  // =========================

  Future<void> addToCart(int userId, int productId) async {
    final db = await database;
    final existing = await db.query(
      'cart',
      where: 'userId = ? AND productId = ?',
      whereArgs: [userId, productId],
    );
    if (existing.isNotEmpty) {
      await db.rawUpdate(
        'UPDATE cart SET quantity = quantity + 1 '
        'WHERE userId = ? AND productId = ?',
        [userId, productId],
      );
    } else {
      await db.insert('cart', {
        'userId': userId,
        'productId': productId,
        'quantity': 1,
      });
    }
  }

  Future<List<CartLine>> getCartLines(int userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT c.*, p.userId AS pUserId, p.name AS pName,
             p.price AS pPrice, p.category AS pCategory,
             p.condition AS pCondition, p.description AS pDescription,
             p.location AS pLocation, p.sold AS pSold, p.views AS pViews,
             p.createdAt AS pCreatedAt
      FROM cart c
      INNER JOIN products p ON p.id = c.productId
      WHERE c.userId = ?
      ORDER BY c.id DESC
    ''', [userId]);

    return result.map((row) {
      final product = Product.fromMap({
        'id': row['productId'],
        'userId': row['pUserId'],
        'name': row['pName'],
        'price': row['pPrice'],
        'category': row['pCategory'],
        'condition': row['pCondition'],
        'description': row['pDescription'],
        'location': row['pLocation'],
        'sold': row['pSold'],
        'views': row['pViews'],
        'createdAt': row['pCreatedAt'],
      });
      return CartLine(
        id: row['id'] as int,
        product: product,
        quantity: row['quantity'] as int,
      );
    }).toList();
  }

  Future<void> updateCartQuantity(int id, int quantity) async {
    final db = await database;
    await db.update(
      'cart',
      {'quantity': quantity},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removeCartItem(int id) async {
    final db = await database;
    await db.delete('cart', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearCart(int userId) async {
    final db = await database;
    await db.delete('cart', where: 'userId = ?', whereArgs: [userId]);
  }

  // =========================
  // FAVOURITES
  // =========================

  Future<void> addFavourite(int userId, int productId) async {
    final db = await database;
    await db.insert('favourites', {
      'userId': userId,
      'productId': productId,
    });
  }

  Future<void> removeFavourite(int userId, int productId) async {
    final db = await database;
    await db.delete(
      'favourites',
      where: 'userId = ? AND productId = ?',
      whereArgs: [userId, productId],
    );
  }

  Future<bool> isFavourite(int userId, int productId) async {
    final db = await database;
    final result = await db.query(
      'favourites',
      where: 'userId = ? AND productId = ?',
      whereArgs: [userId, productId],
    );
    return result.isNotEmpty;
  }

  Future<List<Product>> getFavouriteProducts(int userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT p.* FROM favourites f
      INNER JOIN products p ON p.id = f.productId
      WHERE f.userId = ?
      ORDER BY f.id DESC
    ''', [userId]);
    return result.map(Product.fromMap).toList();
  }

  // =========================
  // ORDERS
  // =========================

  Future<int> insertOrder(OrderItem order) async {
    final db = await database;
    return db.insert('orders', order.toMap());
  }

  Future<List<OrderItem>> getUserOrders(int userId) async {
    final db = await database;
    final result = await db.query(
      'orders',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return result.map(OrderItem.fromMap).toList();
  }

  // =========================
  // EXCHANGES
  // =========================

  Future<int> insertExchange(ExchangeItem exchange) async {
    final db = await database;
    return db.insert('exchanges', exchange.toMap());
  }

  Future<List<ExchangeItem>> getUserExchanges(int userId) async {
    final db = await database;
    final result = await db.query(
      'exchanges',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return result.map(ExchangeItem.fromMap).toList();
  }

  // =========================
  // EXCHANGE PROPOSALS
  // =========================

  Future<int> insertProposal(ExchangeModel proposal) async {
    final db = await database;
    return db.insert('exchange_proposals', proposal.toMap());
  }

  Future<List<ExchangeModel>> getUserProposals(int userId) async {
    final db = await database;
    final result = await db.query(
      'exchange_proposals',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return result.map(ExchangeModel.fromMap).toList();
  }

  Future<void> updateProposalStatus(int id, String status) async {
    final db = await database;
    await db.update(
      'exchange_proposals',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> seedDemoProposalsIfEmpty(int userId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM exchange_proposals WHERE userId = ?',
        [userId],
      ),
    );
    if (count != null && count > 0) return;

    final demos = [
      _proposal(userId, 24, 'Custom Mechanical Keyboard',
          'Sony A6400 Mirrorless', 50, 'Accepted'),
      _proposal(userId, 3, 'HP Pavilion Laptop', '1970s Leather Chair',
          120, 'Pending'),
      _proposal(userId, 12, 'Sony 43 Inch Smart TV',
          'Custom Mechanical Keyboard', 0, 'Incoming'),
      _proposal(userId, 8, 'Office Chair', 'Beta Jacket', 0, 'Rejected'),
    ];
    for (final p in demos) {
      await db.insert('exchange_proposals', p);
    }
  }

  Map<String, dynamic> _proposal(
    int userId,
    int myProductId,
    String myProductName,
    String targetProductName,
    double cash,
    String status,
  ) {
    return {
      'userId': userId,
      'myProductId': myProductId,
      'myProductName': myProductName,
      'targetProductId': 1,
      'targetProductName': targetProductName,
      'cashAmount': cash,
      'status': status,
      'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    };
  }

  /// Seeds a few sample listings owned by the user so the "Propose Exchange"
  /// flow always has "My Products" to choose from (mock data only, used until
  /// the user adds real products).
  Future<void> seedDemoProductsIfNone(int userId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM products WHERE userId = ?',
        [userId],
      ),
    );
    if (count != null && count > 0) return;

    final demos = [
      _seed(userId, 'Custom Mechanical Keyboard', 180, 'Gaming', 'Excellent',
          'My hot-swappable keyboard with MX switches and PBT caps, '
          'barely used.', 'Brooklyn'),
      _seed(userId, 'Denim Jacket', 60, 'Fashion', 'Good',
          'Classic blue denim jacket, size M, in great shape.',
          'Brooklyn'),
      _seed(userId, 'Sony Bluetooth Speaker', 90, 'Electronics', 'Excellent',
          'Waterproof portable speaker with punchy bass.', 'Brooklyn'),
    ];
    for (final p in demos) {
      await db.insert('products', p);
    }
    debugPrint('DATABASE SEED: demo owner products inserted (userId=$userId)');
  }

  // =========================
  // MESSAGES
  // =========================

  Future<int> insertMessage(MessageModel message) async {
    final db = await database;
    return db.insert('messages', message.toMap());
  }

  Future<List<MessageModel>> getConversationMessages({
    required int userId,
    required int productId,
    required String counterpartName,
  }) async {
    final db = await database;
    final result = await db.query(
      'messages',
      where: 'userId = ? AND productId = ? AND counterpartName = ?',
      whereArgs: [userId, productId, counterpartName],
      orderBy: 'createdAt ASC',
    );
    return result.map(MessageModel.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> getConversations(int userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT productId, productName, counterpartName,
             MAX(createdAt) AS lastAt
      FROM messages
      WHERE userId = ?
      GROUP BY productId, counterpartName
      ORDER BY lastAt DESC
    ''', [userId]);
    final conversations = <Map<String, dynamic>>[];
    for (final row in result) {
      final messages = await getConversationMessages(
        userId: userId,
        productId: row['productId'] as int,
        counterpartName: row['counterpartName'] as String,
      );
      final last = messages.isNotEmpty ? messages.last : null;
      if (last == null) continue;
      conversations.add({
        'productId': row['productId'],
        'productName': row['productName'],
        'counterpartName': row['counterpartName'],
        'lastText': last.text,
        'isMine': last.isMine,
        'lastAt': row['lastAt'],
      });
    }
    return conversations;
  }

  Future<void> seedDemoMessagesIfEmpty(int userId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM messages WHERE userId = ?',
        [userId],
      ),
    );
    if (count != null && count > 0) return;

    final messages = [
      MessageModel(
        userId: userId,
        productId: 1,
        productName: 'Sony A6400 Mirrorless',
        counterpartName: 'Alex Morales',
        isMine: false,
        text: 'Hi! Are you still open to swapping for the keyboard?',
        createdAt: DateTime.now()
            .subtract(const Duration(hours: 5))
            .toIso8601String(),
      ),
      MessageModel(
        userId: userId,
        productId: 1,
        productName: 'Sony A6400 Mirrorless',
        counterpartName: 'Alex Morales',
        isMine: true,
        text: 'Yes! Would matching the trade value work for you?',
        createdAt: DateTime.now()
            .subtract(const Duration(hours: 4))
            .toIso8601String(),
      ),
      MessageModel(
        userId: userId,
        productId: 6,
        productName: '1970s Leather Chair',
        counterpartName: 'Sofia Reyes',
        isMine: false,
        text: 'Thanks for the offer. Could you share more photos?',
        createdAt: DateTime.now()
            .subtract(const Duration(hours: 20))
            .toIso8601String(),
      ),
      MessageModel(
        userId: userId,
        productId: 18,
        productName: 'Denim Jacket',
        counterpartName: 'Priya Sharma',
        isMine: true,
        text: 'I can exchange the jacket this weekend.',
        createdAt: DateTime.now()
            .subtract(const Duration(days: 2))
            .toIso8601String(),
      ),
    ];
    for (final m in messages) {
      await db.insert('messages', m.toMap());
    }
  }

  // =========================
  // SELLER STATS
  // =========================

  Future<Map<String, int>> getSellerStats(int userId) async {
    final db = await database;
    final productCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM products WHERE userId = ?',
        [userId],
      ),
    );
    final views = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COALESCE(SUM(views), 0) FROM products WHERE userId = ?',
        [userId],
      ),
    );
    final orderCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM orders WHERE userId = ?',
        [userId],
      ),
    );
    return {
      'products': productCount ?? 0,
      'views': views ?? 0,
      'orders': orderCount ?? 0,
    };
  }
}