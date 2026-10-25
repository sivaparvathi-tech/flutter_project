import 'package:flutter/material.dart';
import '../data/product_repository.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class SearchResultsPage extends StatelessWidget {
  final String searchQuery;

  const SearchResultsPage({
    super.key,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Search Results',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: FutureBuilder<List<Product>>(
        future: ProductRepository.instance.searchProducts(searchQuery),
        builder: (context, snapshot) {
          final results = snapshot.data ?? <Product>[];

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (searchQuery.trim().isNotEmpty)
                  Text(
                    'Results for "$searchQuery"',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  const Text(
                    'All Products',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                const SizedBox(height: 6),

                Text(
                  '${results.length} products found',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 18),

                Expanded(
                  child: snapshot.connectionState !=
                              ConnectionState.done &&
                          !snapshot.hasData
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : results.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 70,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 15),
                                  const Text(
                                    'No products found',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try searching for another product.',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              itemCount: results.length,
                              gridDelegate:
                                  productGridDelegate(context),
                              itemBuilder: (context, index) {
                                final product = results[index];
                                return ProductCard(product: product);
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}