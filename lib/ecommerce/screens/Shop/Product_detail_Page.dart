import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/ecommerce/model/product_details_model.dart';
import 'package:innovator/ecommerce/provider/product_provider.dart';
import 'package:innovator/ecommerce/screens/Shop/cart_screen.dart';

// ─ Constants ─
const _kOrange = Color.fromRGBO(244, 135, 6, 1);

class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailPage({Key? key, required this.productId})
    : super(key: key);

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ─ Cart helpers (mirrors ShopPage logic) ─
  final Set<String> _cartProductIds = {};

  Future<void> _addToCart(ProductDetailModel product) async {
    if (_cartProductIds.contains(product.id)) {
      _showSnackBar(
        message: 'Already in cart!',
        icon: Icons.info_outline,
        color: Colors.orange.shade700,
      );
      return;
    }

    try {
      await ref.read(productServiceProvider).addCartItem(product: product.id);
      setState(() => _cartProductIds.add(product.id));
      ref.refresh(cartListProvider);
      if (!mounted) return;
      _showSnackBar(
        message: '${product.name} added to cart!',
        icon: Icons.check_circle,
        color: Colors.green.shade600,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data?.toString() ?? '';
      final isHtml500 =
          statusCode == 500 &&
          responseData.contains('<h1>Server Error (500)</h1>');

      if (isHtml500) {
        setState(() => _cartProductIds.add(product.id));
        _showSnackBar(
          message: '${product.name} is already in your cart.',
          icon: Icons.info_outline,
          color: Colors.orange.shade700,
        );
      } else if (statusCode == 401 || statusCode == 403) {
        _showSnackBar(
          message: 'Session expired. Please log in again. 2',
          icon: Icons.lock_outline,
          color: Colors.red.shade600,
        );
      } else {
        _showSnackBar(
          message: 'Something went wrong. Try again later.',
          icon: Icons.error_outline,
          color: Colors.red.shade600,
        );
      }
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(
        message: 'Unexpected error. Please try again.',
        icon: Icons.error_outline,
        color: Colors.red.shade600,
      );
    }
  }

  void _showSnackBar({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: _cartFab(),
      body: detailAsync.when(
        loading:
            () =>
                const Center(child: CircularProgressIndicator(color: _kOrange)),
        error: (e, _) => _errorView(),
        data: (product) => _buildContent(product),
      ),
    );
  }

  Widget _cartFab() {
    return Container(
      decoration: BoxDecoration(
        color: _kOrange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
        child: Consumer(
          builder: (context, ref, _) {
            final count = ref.watch(cartCountProvider);
            return Badge.count(
              count: count,
              isLabelVisible: count > 0,
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Failed to load product',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed:
                () => ref.refresh(productDetailProvider(widget.productId)),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: _kOrange),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ProductDetailModel product) {
    final imageUrls = product.allImageUrls;
    final price = double.tryParse(product.price) ?? 0.0;
    final inCart = _cartProductIds.contains(product.id);
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          ),
          expandedHeight: 340,
          pinned: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(background: _imageGallery(imageUrls)),
        ),

        //  Product info
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Stock badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _stockBadge(product.stock),
                  ],
                ),
                const SizedBox(height: 10),

                // Price
                Text(
                  'Rs ${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _kOrange,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Description
                if (product.description != null &&
                    product.description!.isNotEmpty) ...[
                  _sectionLabel('Description:'),
                  const SizedBox(height: 6),
                  Text(
                    product.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Category row
                if (product.category != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Category:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              product.categoryDetails != null
                                  ? Border.all(color: Colors.blue)
                                  : null,
                        ),
                        child: Text(
                          product.categoryDetails!.name,
                          style: TextStyle(fontSize: 13, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Stock detail row
                _infoRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Stock',
                  value: '${product.stock} items available',
                  valueColor:
                      product.stock > 0
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                ),
                const SizedBox(height: 32),

                // Add to Cart button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed:
                        product.stock > 0 && !inCart
                            ? () => _addToCart(product)
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: inCart ? Colors.grey[300] : _kOrange,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(
                      inCart
                          ? Icons.check
                          : product.stock > 0
                          ? Icons.add_shopping_cart
                          : Icons.remove_shopping_cart,
                      color: Colors.white,
                    ),
                    label: Text(
                      inCart
                          ? 'Added to Cart'
                          : product.stock > 0
                          ? 'Add to Cart'
                          : 'Out of Stock',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80), // space for FAB
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─ Image gallery with PageView + pinch-to-zoom ─
  Widget _imageGallery(List<String> urls) {
    if (urls.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: urls.length,
          onPageChanged: (i) => setState(() => _currentImageIndex = i),
          itemBuilder: (context, i) => _zoomableImage(urls[i]),
        ),
        // Page indicator dots
        if (urls.length > 1)
          Positioned(
            bottom: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                urls.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == i ? _kOrange : Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _zoomableImage(String url) {
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 5.0,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder:
            (_, __, ___) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
              ),
            ),
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                color: _kOrange,
                strokeWidth: 2,
              ),
            ),
          );
        },
      ),
    );
  }

  // ─ Small helpers
  Widget _stockBadge(int stock) {
    final inStock = stock > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: inStock ? Colors.green.withAlpha(26) : Colors.red.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        inStock ? 'In Stock' : 'Out of Stock',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: inStock ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.grey[500],
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
