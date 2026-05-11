import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/Innovator/widget/Custom_refresh_Indicator.dart';
import 'package:innovator/ecommerce/provider/notificationProvider.dart';
import 'package:innovator/ecommerce/screens/Shop/cart_screen.dart';
import 'package:innovator/ecommerce/screens/Shop/Product_detail_Page.dart';
import 'package:innovator/ecommerce/screens/notifications_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:innovator/ecommerce/model/product_model.dart';
import 'package:innovator/ecommerce/provider/product_provider.dart';

class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String sortBy = 'name';
  bool ascending = true;
  String? _selectedCategory;

  static final _skeletonProducts = List.generate(
    6,
    (i) => ProductModel(
      id: '$i',
      name: 'Product Name Here',
      price: '999',
      stock: 10,
      image: null,
    ),
  );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    ref.refresh(productListProvider);
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.toLowerCase());
  }

  List<String> _extractCategories(List<ProductModel> products) {
    final categories =
        products
            .where((p) => p.categoryDetails?.name != null)
            .map((p) => p.categoryDetails!.name!)
            .toSet()
            .toList()
          ..sort();
    return categories;
  }

  List<ProductModel> _getFilteredAndSorted(List<ProductModel> products) {
    var filtered = List<ProductModel>.from(products);

    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where((p) => p.name.toLowerCase().contains(_searchQuery))
              .toList();
    }

    if (_selectedCategory != null) {
      filtered =
          filtered
              .where((p) => p.categoryDetails?.name == _selectedCategory)
              .toList();
    }

    filtered.sort((a, b) {
      int comparison = 0;
      if (sortBy == 'name') {
        comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      } else if (sortBy == 'price') {
        final priceA = double.tryParse(a.price) ?? 0;
        final priceB = double.tryParse(b.price) ?? 0;
        comparison = priceA.compareTo(priceB);
      }
      return ascending ? comparison : -comparison;
    });

    return filtered;
  }

  Future<void> _addToCart(ProductModel product) async {
    try {
      await ref.read(productServiceProvider).addCartItem(product: product.id);
      ref.refresh(cartListProvider);
      if (!mounted) return;
      _showSnackBar(
        message: '${product.name} added to cart!',
        icon: Icons.check_circle,
        color: Colors.green.shade600,
      );
    } catch (e) {
      if (!mounted) return;
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

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Sort Products',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildSortTile(
                  title: 'Name (A → Z)',
                  isSelected: sortBy == 'name' && ascending,
                  onTap: () {
                    setState(() {
                      sortBy = 'name';
                      ascending = true;
                    });
                    Navigator.pop(context);
                  },
                ),
                _buildSortTile(
                  title: 'Name (Z → A)',
                  isSelected: sortBy == 'name' && !ascending,
                  onTap: () {
                    setState(() {
                      sortBy = 'name';
                      ascending = false;
                    });
                    Navigator.pop(context);
                  },
                ),
                _buildSortTile(
                  title: 'Price (Low → High)',
                  isSelected: sortBy == 'price' && ascending,
                  onTap: () {
                    setState(() {
                      sortBy = 'price';
                      ascending = true;
                    });
                    Navigator.pop(context);
                  },
                ),
                _buildSortTile(
                  title: 'Price (High → Low)',
                  isSelected: sortBy == 'price' && !ascending,
                  onTap: () {
                    setState(() {
                      sortBy = 'price';
                      ascending = false;
                    });
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildSortTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? Colors.blue : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue : Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildCategoryTabs(List<String> categories) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final label = isAll ? 'All' : categories[index - 1];
          final isSelected =
              isAll ? _selectedCategory == null : _selectedCategory == label;

          return GestureDetector(
            onTap:
                () => setState(() => _selectedCategory = isAll ? null : label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? const Color.fromRGBO(244, 135, 6, 1)
                        : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected
                          ? const Color.fromRGBO(244, 135, 6, 1)
                          : Colors.grey.shade300,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productListProvider);

    const double topAreaHeight = 130.0 + 36.0 + 10.0;

    return Scaffold(
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: const Color.fromRGBO(244, 135, 6, 1),
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
      ),
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: topAreaHeight),
              Expanded(
                child: productAsync.when(
                  loading:
                      () => Skeletonizer(
                        enabled: true,
                        effect: ShimmerEffect(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                        ),
                        child: _buildGrid(_skeletonProducts),
                      ),
                  error:
                      (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load products',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => ref.refresh(productListProvider),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                  data: (products) {
                    final filtered = _getFilteredAndSorted(products);
                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No products found'
                                  : _selectedCategory != null
                                  ? 'No products in "$_selectedCategory"'
                                  : 'No products available',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return CustomRefreshIndicator(
                      onRefresh: () async {
                        ref.refresh(productListProvider);
                        await ref.read(productListProvider.future);
                      },
                      child: _buildGrid(filtered),
                    );
                  },
                ),
              ),
            ],
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            suffixIcon:
                                _searchQuery.isNotEmpty
                                    ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                    : Icon(
                                      Icons.search,
                                      color: Colors.grey[600],
                                    ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _showSortBottomSheet,
                      icon: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.settings_input_component,
                              size: 18,
                              color: Colors.black,
                            ),
                          ),
                          if (sortBy != 'name' || !ascending)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => const EcommerceNotificationScreen(),
                            ),
                          ),
                      child: Consumer(
                        builder: (context, ref, _) {
                          final count = ref.watch(ecommerceUnreadCountProvider);
                          return count > 0
                              ? Badge.count(
                                count: count,
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  size: 25,
                                ),
                              )
                              : const Icon(
                                Icons.notifications_outlined,
                                size: 25,
                              );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                productAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (products) {
                    final categories = _extractCategories(products);
                    if (categories.isEmpty) return const SizedBox.shrink();
                    return _buildCategoryTabs(categories);
                  },
                ),
                // InkWell(
                //   onTap:
                //       () => Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (_) => const EcommerceNotificationScreen(),
                //         ),
                //       ),
                //   child: Consumer(
                //     builder: (context, ref, _) {
                //       final unreadAsync = ref.watch(
                //         ecommerceUnreadCountProvider,
                //       );
                //       final count = unreadAsync;
                //       return count > 0
                //           ? Badge.count(
                //             count: count,
                //             child: const Icon(
                //               Icons.notifications_outlined,
                //               size: 25,
                //             ),
                //           )
                //           : const Icon(Icons.notifications_outlined, size: 25);
                //     },
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<ProductModel> products) {
    return GridView.builder(
      padding: const EdgeInsets.only(right: 5, left: 5, bottom: 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisSpacing: 10,
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        childAspectRatio: 0.6,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductCard(products[index]),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final price = double.tryParse(product.price) ?? 0.0;
    final hasImage = product.image != null;

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(productId: product.id),
            ),
          ),
      child: Card(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                width: double.infinity,
                color: Colors.grey[200],
                child:
                    hasImage
                        ? Image.network(
                          product.image!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                        : const Center(
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 52,
                            color: Colors.grey,
                          ),
                        ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product.categoryDetails != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.categoryDetails?.name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Rs ${price.toInt()}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Stock: ${product.stock}',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  product.stock > 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 34,
                        child: ElevatedButton.icon(
                          onPressed:
                              product.stock > 0
                                  ? () => _addToCart(product)
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(
                              244,
                              135,
                              6,
                              1,
                            ),
                            disabledBackgroundColor: Colors.grey[300],
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            product.stock > 0 ? 'Add to Cart' : 'Out of Stock',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
