import 'dart:developer';

import 'package:innovator/ecommerce/core/constants/api_constants.dart';
import 'package:innovator/ecommerce/core/constants/network/base_api_service.dart';
import 'package:innovator/ecommerce/core/constants/network/dio_client.dart';
import 'package:innovator/ecommerce/model/cart_model.dart';
import 'package:innovator/ecommerce/model/product_details_model.dart';
import 'package:innovator/ecommerce/model/product_model.dart';

class ProductListService extends EcommerBaseApiService {
  ProductListService() : super(dio: DioClient.instance);

  Future<List<ProductModel>> getProductList() async {
    final data = await get<List<dynamic>>(EcommerceApi.productList);
    final products = ProductModel.fromJsonList(data);
    log('Products: $products');
    return products;
  }

  Future<ProductDetailModel> getProductDetails(String id) async {
    final data = await get<Map<String, dynamic>>(
      '${EcommerceApi.productDetails}$id/',
    );
    final detail = ProductDetailModel.fromJson(data);
    log('Product detail: ${detail.name}');
    return detail;
  }

  Future<Map<String, dynamic>> addCartItem({required String product}) async {
    return await post(EcommerceApi.cartItems, data: {'product': product});
  }

  Future<List<CartItemModel>> getCartList() async {
    final data = await get<List<dynamic>>(EcommerceApi.cartItems);
    final items = CartItemModel.fromJsonList(data);
    log('Cart items: $items');
    return items;
  }

  Future<void> deleteCartItem({required String cartItemId}) async {
    await delete(EcommerceApi.itemUpdate(cartItemId));
  }

  Future<void> updateCartItemQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    await patch(
      EcommerceApi.itemUpdate(cartItemId),
      data: {'quantity': quantity},
    );
  }
}
