import 'package:flutter_ecommerce/models/order.dart';
import 'package:flutter_ecommerce/models/product.dart';
import 'package:flutter_ecommerce/models/user.dart';
import 'package:meta/meta.dart';

@immutable
class AppState {
  final User user;
  final List<Product> products;
  final List<Product> cartProducts;
  final List<dynamic> cards;
  final List<Order> orders;
  final String cardToken;

  AppState({ @required this.user, @required this.products, @required this.cartProducts, @required this.orders, @required this.cards, @required this.cardToken });

  factory AppState.initial() {
    return AppState(
      user: null,
      products: [],
      orders: [],
      cartProducts: [],
      cards: [],
      cardToken: ''
    );
  }
}