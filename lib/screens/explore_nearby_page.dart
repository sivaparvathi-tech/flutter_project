import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../data/product_repository.dart';
import '../models/product.dart';
import '../utils/location_service.dart';
import '../widgets/product_card.dart';

class ExploreNearbyPage extends StatefulWidget {
  const ExploreNearbyPage({super.key});

  @override
  State<ExploreNearbyPage> createState() => _ExploreNearbyPageState();
}

class _ExploreNearbyPageState extends State<ExploreNearbyPage> {
  bool _loading = true;
  bool _permissionDenied = false;
  Position? _position;
  String? _error;
  List<Product> _products = [];
  bool _productsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    final products = await ProductRepository.instance.getProducts();
    if (!mounted) return;
    setState(() {
      _products = products;
      _productsLoading = false;
    });
    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _loading = true;
      _permissionDenied = false;
      _error = null;
    });

    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _loading = false;
          _error =
              'Location services are disabled. Please enable them in settings.';
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _loading = false;
            _permissionDenied = true;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _loading = false;
          _permissionDenied = true;
          _error = 'Location permission is denied forever. '
              'Please allow it from app settings.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      LocationService.instance.lastPosition = position;
      setState(() {
        _position = position;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Unable to get your location. Please try again.';
      });
    }
  }

  List<Product> get _sortedProducts {
    final sorted = [..._products];
    sorted.sort((a, b) {
      final da = LocationService.instance.distanceToCity(a.location);
      final db = LocationService.instance.distanceToCity(b.location);
      if (da == null && db == null) return b.id!.compareTo(a.id!);
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
        title: const Text(
          'Explore Nearby',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _getCurrentLocation,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationStatusCard(),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Products Near You',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Saved filters will come soon'),
                        ),
                      );
                    },
                    child: Text(
                      'Filters',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (_productsLoading || _loading)
                const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_products.isEmpty)
                const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text('No products available'),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: productGridDelegate(context),
                  itemCount: _sortedProducts.length,
                  itemBuilder: (context, index) {
                    return ProductCard(
                      product: _sortedProducts[index],
                    );
                  },
                ),

              const SizedBox(height: 25),

              // E-waste + shipping savings banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.teal.shade700,
                      Colors.green.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.eco_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'You are helping the planet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'By exchanging nearby instead of buying new, '
                      'you reduced shipping cost and kept e-waste '
                      'out of landfills.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceAround,
                      children: [
                        _StatChip(
                          icon: Icons.local_shipping_outlined,
                          value: '0 km',
                          label: 'Shipping',
                          color: Colors.white,
                          textColor: Colors.teal.shade700,
                        ),
                        _StatChip(
                          icon: Icons.delete_outline,
                          value: '1.2 kg',
                          label: 'E-waste saved',
                          color: Colors.white,
                          textColor: Colors.teal.shade700,
                        ),
                        _StatChip(
                          icon: Icons.recycling,
                          value: '3 items',
                          label: 'Reused',
                          color: Colors.white,
                          textColor: Colors.teal.shade700,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_loading) ...[
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Getting your location...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (_position != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: Colors.green.shade700,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '📍 You are near ${_position!.latitude.toStringAsFixed(2)}, '
              '${_position!.longitude.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Showing products within 5 km of your location',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 15),
            TextButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh location'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Distance measured reduces shipping cost. '
              'Best nearby products first.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ] else if (_permissionDenied) ...[
            Icon(
              Icons.location_off_rounded,
              size: 45,
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 12),
            const Text(
              'Location permission needed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Please allow location access to see '
                  'products near you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ] else ...[
            Icon(
              Icons.error_outline_rounded,
              size: 45,
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not get location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color textColor;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: textColor, size: 22),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}