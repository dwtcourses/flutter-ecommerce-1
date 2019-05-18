import 'dart:convert';
import 'package:flutter_ecommerce/models/product.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_ecommerce/models/app_state.dart';
import 'package:flutter_ecommerce/models/user.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:shared_preferences/shared_preferences.dart';

/* User Actions */
ThunkAction<AppState> getUserAction = (Store<AppState> store) async {
  // thunk action is never going to interact with a reducer
  // it's just going get data and pass that data to the action
  // and that action is going to be picked up by appropriate reducer
  final prefs = await SharedPreferences.getInstance();
  final String storedUser = prefs.getString('user');
  final user = 
    storedUser != null 
      ? User.fromJson(json.decode(storedUser)) 
      : null;
  store.dispatch(GetUserAction(user));
};

ThunkAction<AppState> logoutUserAction = (Store<AppState> store) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('user');
  User user; // declare but not initialize
  store.dispatch(LogoutUserAction(user));
};

class GetUserAction {
  final User _user;

  User get user => this._user;

  GetUserAction(this._user);
}

class LogoutUserAction {
  final User _user;

  User get user => this._user;

  LogoutUserAction(this._user);
}

 
/* Products Actions */
ThunkAction<AppState> getProductsAction = (Store<AppState> store) async {
  http.Response response = await http.get('http://10.0.2.2:1337/products');
  final List<dynamic> responseDats = json.decode(response.body);
  List<Product> products = [];
  responseDats.forEach((productData) {
    final Product product = Product.fromJson(productData);
    products.add(product);
  });
  store.dispatch(GetProductsAction(products));
};

class GetProductsAction {
  final List<Product> _products;

  List<Product> get products => this._products;

  GetProductsAction(this._products);
}


/* Cart Producrts Action */
// this thunk action is different then getProductsAction due to it takes an argument, so that it return another function
ThunkAction<AppState> toggleCartProductAction(Product cartProduct) {
  return (Store<AppState> store) async {
    final List<Product> cartProducts = store.state.cartProducts;
    final User user = store.state.user;
    final int index = cartProducts.indexWhere((product) => product.id == cartProduct.id);
    List<Product> updatedCartProducts = List.from(cartProducts);
    bool isInCart = index > -1 == true;
    if (isInCart) {
      updatedCartProducts.removeAt(index);
    } else {
      updatedCartProducts.add(cartProduct);
    }
    final List<String> cartProductIds = updatedCartProducts.map((product) => product.id).toList();
    await http.put('http://10.0.2.2:1337/carts/${user.cartId}', body: {
      "products": json.encode(cartProductIds)
    }, headers: {
      "Authorization": "Bearer ${user.jwt}"
    });
    store.dispatch(ToggleCartProductAction(updatedCartProducts));
  };
}

ThunkAction<AppState> getCartProductsAction = (Store<AppState> store) async {
  final prefs = await SharedPreferences.getInstance();
  final String storedUser = prefs.getString('user');
  if (storedUser == null) {
    return;
  }
  final User user = User.fromJson(json.decode(storedUser));
  http.Response response = await http.get('http://10.0.2.2:1337/carts/${user.cartId}', headers: {
    'Authorization': 'Bearer ${user.jwt}'
  });
  final responseData = json.decode(response.body)['products'];
  List<Product> cartProducts = [];
  responseData.forEach((productData) {
    final Product product = Product.fromJson(productData);
    cartProducts.add(product);
  });
  store.dispatch(GetCartProductsAction(cartProducts));
};

class ToggleCartProductAction {
  final List<Product> _cartProducts;

  List<Product> get cartProducts => this._cartProducts;

  ToggleCartProductAction(this._cartProducts);
}

class GetCartProductsAction {
  final List<Product> _cartProducts;

  List<Product> get cartProducts => this._cartProducts;

  GetCartProductsAction(this._cartProducts);
}

/* Cards Actions */
ThunkAction<AppState> getCardsAction = (Store<AppState> store) async {
  final String customerId = store.state.user.customerId;
  http.Response response = await http.get('http://10.0.2.2:1337/card?${customerId}');
  final responseData = json.decode(response.body);
  //print('Card Data: $responseData');
  store.dispatch(GetCardsAction(responseData));
};

class GetCardsAction {
  final List<dynamic> _cards;

  List<dynamic> get cards => this._cards;

  GetCardsAction(this._cards);
}


class AddCardAction {
  final dynamic _card;

  dynamic get card => this._card;

  AddCardAction(this._card);
}

/* Card Token Actions */
ThunkAction<AppState> getCardTokenAction = (Store<AppState> store) async {
  final String jwt = store.state.user.jwt;
  http.Response response = await http.get('http://10.0.2.2:1337/users/me', headers: {
    'Authorization': 'Bearer $jwt'
  });
  final responseData = json.decode(response.body);
  final cardToken = responseData['card_token'];
  store.dispatch(GetCardTokenAction(cardToken));
};

class UpdateCardAction {
  final String _cardToken;

  String get cardToken => this._cardToken;

  UpdateCardAction(this._cardToken);
}

class GetCardTokenAction {
  final String _cardToken;

  String get cardToken => this._cardToken;

  GetCardTokenAction(this._cardToken);
}