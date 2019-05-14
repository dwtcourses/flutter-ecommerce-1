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
  return (Store<AppState> store) {
    final List<Product> cartProducts = store.state.cartProducts;
    final int index = cartProducts.indexWhere((product) => product.id == cartProduct.id);
    List<Product> updatedCartProducts = List.from(cartProducts);
    bool isInCart = index > -1 == true;
    if (isInCart) {
      updatedCartProducts.removeAt(index);
    } else {
      updatedCartProducts.add(cartProduct);
    }
    store.dispatch(ToggleCartProductAction(updatedCartProducts));
  };
}

class ToggleCartProductAction {
  final List<Product> _cartProducts;

  List<Product> get cartProducts => this._cartProducts;

  ToggleCartProductAction(this._cartProducts);

}