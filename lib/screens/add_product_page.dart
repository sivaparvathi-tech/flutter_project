import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/app_state.dart';
import '../data/database_helper.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

/// Maximum number of photos a product can have.
const int _maxProductImages = 8;

/// A picked image kept in memory before the product is submitted.
class _PickedImage {
  final Uint8List bytes;
  final String mime;

  const _PickedImage({required this.bytes, required this.mime});

  String get dataUri =>
      'data:${mime.isEmpty ? 'image/jpeg' : mime};base64,${base64Encode(bytes)}';
}

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<_PickedImage> _pickedImages = [];

  String? _category;
  String? _condition;
  bool _submitting = false;
  bool _picking = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // =====================================================
  // IMAGE PICKING
  // =====================================================

  Future<void> _pickImages() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final files = await _picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1280,
        maxHeight: 1280,
        limit: _maxProductImages,
      );
      if (files.isEmpty) {
        if (!mounted) return;
        setState(() => _picking = false);
        return;
      }

      final remaining = _maxProductImages - _pickedImages.length;
      final toAdd = files.length > remaining ? files.sublist(0, remaining) : files;

      final newImages = <_PickedImage>[];
      for (final file in toAdd) {
        final bytes = await file.readAsBytes();
        final mime = file.mimeType ?? 'image/jpeg';
        newImages.add(_PickedImage(bytes: bytes, mime: mime));
      }

      if (!mounted) return;
      setState(() {
        _pickedImages.addAll(newImages);
        _picking = false;
      });
      if (files.length > remaining) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can add up to 8 photos per product'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _picking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not pick images: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() => _pickedImages.removeAt(index));
  }

  void _setAsCover(int index) {
    if (index <= 0) return;
    setState(() {
      final item = _pickedImages.removeAt(index);
      _pickedImages.insert(0, item);
    });
  }

  // =====================================================
  // SUBMIT
  // =====================================================

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _category == null ||
        _condition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
        ),
      );
      return;
    }

    if (_pickedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product photo'),
        ),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid price'),
        ),
      );
      return;
    }

    final user = AppState.instance.currentUser;
    if (user == null || user.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to list a product'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final product = Product(
        userId: user.id!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category!,
        condition: _condition!,
        price: price,
        location: _locationController.text.trim().isEmpty
            ? 'Your Location'
            : _locationController.text.trim(),
        images: _pickedImages.map((p) => p.dataUri).toList(),
      );
      final productId = await DatabaseHelper.instance.insertProduct(product);
      debugPrint('ADD PRODUCT SUCCESS: id=$productId images=${product.images.length}');
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Product listed successfully!'),
          backgroundColor: AppColors.accent,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to list product: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotoSection(),

            const SizedBox(height: 24),

            const Text(
              'Product Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              hint: 'e.g. Dell Inspiron Laptop',
              icon: Icons.badge_outlined,
              controller: _nameController,
            ),

            const SizedBox(height: 18),

            const Text(
              'Price',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              hint: 'e.g. 15000',
              icon: Icons.currency_rupee_rounded,
              keyboardType: TextInputType.number,
              controller: _priceController,
            ),

            const SizedBox(height: 18),

            const Text(
              'Location',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              hint: 'e.g. Visakhapatnam',
              icon: Icons.location_on_outlined,
              controller: _locationController,
            ),

            const SizedBox(height: 18),

            const Text(
              'Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              hint: const Text('Select category'),
              decoration: _dropdownDecoration(),
              items: const [
                DropdownMenuItem(value: 'Mobiles', child: Text('Mobiles')),
                DropdownMenuItem(value: 'Laptops', child: Text('Laptops')),
                DropdownMenuItem(value: 'Cameras', child: Text('Cameras')),
                DropdownMenuItem(value: 'Cars', child: Text('Cars')),
                DropdownMenuItem(value: 'Bikes', child: Text('Bikes')),
                DropdownMenuItem(value: 'Gaming', child: Text('Gaming')),
                DropdownMenuItem(value: 'Fashion', child: Text('Fashion')),
                DropdownMenuItem(value: 'Furniture', child: Text('Furniture')),
                DropdownMenuItem(value: 'Books', child: Text('Books')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                setState(() => _category = value);
              },
            ),

            const SizedBox(height: 18),

            const Text(
              'Condition',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _condition,
              hint: const Text('Select condition'),
              decoration: _dropdownDecoration(),
              items: const [
                DropdownMenuItem(value: 'Excellent', child: Text('Excellent')),
                DropdownMenuItem(value: 'Good', child: Text('Good')),
                DropdownMenuItem(value: 'Fair', child: Text('Fair')),
                DropdownMenuItem(
                  value: 'Needs Repair',
                  child: Text('Needs Repair'),
                ),
              ],
              onChanged: (value) {
                setState(() => _condition = value);
              },
            ),

            const SizedBox(height: 18),

            const Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe condition, age, features...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.grey.shade200,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'List Product',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // PHOTO SECTION
  // =====================================================

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Product Photos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_pickedImages.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '${_pickedImages.length}/$_maxProductImages',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (_pickedImages.isEmpty)
          _buildAddTile()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _pickedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _pickedImages.length) {
                return _buildAddTile();
              }
              return _buildPreview(index);
            },
          ),
        const SizedBox(height: 6),
        Text(
          'First photo is used as the cover on product cards.',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildAddTile() {
    return InkWell(
      onTap: _picking ? null : _pickImages,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accent,
                  width: 1.5,
                ),
              ),
        child: _picking
            ? const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 40,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _pickedImages.isEmpty
                        ? 'Add Product Photos'
                        : 'Add More',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Tap to upload images',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPreview(int index) {
    final image = _pickedImages[index];
    final isCover = index == 0;

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            image.bytes,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
        if (isCover)
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              margin: const EdgeInsets.all(5),
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'COVER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.topRight,
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => _removeImage(index),
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (!isCover)
          Align(
            alignment: Alignment.bottomRight,
            child: Tooltip(
              message: 'Set as cover image',
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => _setAsCover(index),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.star_border_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // =====================================================
  // HELPERS
  // =====================================================

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
    );
  }
}