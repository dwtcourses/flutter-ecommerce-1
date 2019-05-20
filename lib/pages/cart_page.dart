
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/models/app_state.dart';
import 'package:flutter_ecommerce/models/order.dart';
import 'package:flutter_ecommerce/models/user.dart';
import 'package:flutter_ecommerce/redux/actions.dart';
import 'package:flutter_ecommerce/widgets/product_item.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:stripe_payment/stripe_payment.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class CartPage extends StatefulWidget {
  final void Function() onInit; //the function which will be immediatly called
  CartPage({ this.onInit });

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
final _scaffoldKey = GlobalKey<ScaffoldState>();
bool _isSubmitting = false;

  void initState() {
    super.initState();
    widget.onInit();
    StripeSource.setPublishableKey("pk_test_J830ZCDNslUBtl2yeUipf6mi");
  }

  Widget _cartTab(state) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Column(
      children: [
        Expanded( // prevent overflow image 
          child: SafeArea(
            top: false,
            bottom: false,
            child: GridView.builder(
              itemCount: state.cartProducts.length, // itemBuilder takes state.products from here
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: orientation == Orientation.portrait ? 2 : 3,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
                childAspectRatio: orientation == Orientation.portrait ? 1 : 1.3,
              ),
              itemBuilder: (context, i) => ProductItem(item: state.cartProducts[i]),
            ),
          ),
        )
      ]
    );
  }

  Widget _cardsTab(state) {
    _addCard(cardToken) async {
      final User user = state.user;
      // update user's data to include cardToken (PUT /user/:id)
      await http.put('http://10.0.2.2:1337/users/${user.id}', body: {
        "card_token": cardToken
      }, headers: {
        'Authorization': 'Bearer ${user.jwt}'
      });
      // associate cardToken (added card) with Stripe customer (POST /card/add)
      http.Response response = await http.post('http://10.0.2.2:1337/card/add', body: {
        "source": cardToken, "customer": user.customerId
      });
      final responseData = json.decode(response.body);
      return responseData;
    }
    return Column(children: <Widget>[
      Padding(padding: EdgeInsets.only(top: 10.0)),
      RaisedButton(
        elevation: 8.0,
        child: Text('Add Card'),
        onPressed: () async {
          final String cardToken = await StripeSource.addSource();
          final card = await _addCard(cardToken);
          // Action to AddCard
          StoreProvider.of<AppState>(context).dispatch(AddCardAction(card));
          // Action to Update Card Token
          StoreProvider.of<AppState>(context).dispatch(UpdateCardAction(card['id']));
          // Show snackBar
          final snackbar = SnackBar(
            content: Text('Card Added!', style: TextStyle(color: Colors.green)),
          );
          _scaffoldKey.currentState.showSnackBar(snackbar);
        },
      ),
      Expanded(child: ListView(
        children: state.cards.map<Widget>((c) => (ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.deepOrange,
            child: Icon(
              Icons.credit_card,
              color: Colors.white
            ),
          ),
          title: Text("${c['card']['exp_month']}/${c['card']['exp_year']}, ${c['card']['last4']}"),
          subtitle: Text(c['card']['brand']),
          trailing: state.cardToken == c['id'] ?
          Chip(
            avatar: CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.check_circle, color: Colors.white,),
            ),
            label: Text('Primary Card'),
          ) : FlatButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0))
            ),
            child: Text('Set as Primary', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
            onPressed: () {
              // Action to Update Card Token
              StoreProvider.of<AppState>(context).dispatch(UpdateCardAction(c['id']));
            },
          ),
        ))).toList(),
        ),)
    ],);
  }

  Widget _ordersTab(state) {
    return ListView(children: state.orders.length > 0 ? state.orders.map<Widget>((order) => (ListTile(
        title: Text('\$${order.amount}'),
        subtitle: Text(DateFormat('MMM dd, yyyy - kk:mm').format(order.createdAt)),
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.attach_money, color: Colors.white,),),
      ))
      ).toList() : [
        Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.close, size: 60.0),
              Text('No orders yet', style: Theme.of(context).textTheme.title)
            ],
          ), 
        )
      ]
      );
  }

  String calculateTotalPrice(cartProducts) {
    double totalPrice = 0.0;
    cartProducts.forEach((cartProduct) {
      totalPrice += cartProduct.price;
    });
    return totalPrice.toStringAsFixed(2);
  } 

  Future _showCheckoutDialog(state) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        if (state.cards.length == 0) {
          return AlertDialog(
            title: Row(children: <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 10.0),
                child: Text('Add Card'),
              ),
              Icon(Icons.credit_card, size: 60.0)
            ]),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Provide a credit card before checking out', style: Theme.of(context).textTheme.body1)
                ],
              ),
            ),
          );
        }

        String cartSummary = '';
        state.cartProducts.forEach((cartProduct) {
          cartSummary += "· ${cartProduct.name}, \$${cartProduct.price}\n";
        });
        final primaryCard = state.cards.singleWhere((card) => card['id'] == state.cardToken)['card'];
        return AlertDialog(
          title: Text('Checkout'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('CART ITEMS (${state.cartProducts.length})\n', style: Theme.of(context).textTheme.body1),
                Text('$cartSummary', style: Theme.of(context).textTheme.body1),
                Text('CARD DETAILS\n', style: Theme.of(context).textTheme.body1),
                Text('Brand ${primaryCard['brand']}\n', style: Theme.of(context).textTheme.body1),
                Text('Card Number ${primaryCard['last4']}\n', style: Theme.of(context).textTheme.body1),
                Text('Expires On: ${primaryCard['exp_month']}/${primaryCard['exp_year']}\n', style: Theme.of(context).textTheme.body1),
                Text('ORDER TOTAL \$${calculateTotalPrice(state.cartProducts)}', style: Theme.of(context).textTheme.body1),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              // function _showCheckoutDialog has type Future, 
              // Navigator.pop() pass palse to `then` statement of _showCheckoutDialog function
              onPressed: () => Navigator.pop(context, false), 
              color: Colors.red,
              child: Text('Close', style: TextStyle(color: Colors.white))
            ),
            RaisedButton(
              onPressed: () => Navigator.pop(context, true), 
              color: Colors.green,
              child: Text('Checkout', style: TextStyle(color: Colors.white))
            )
          ],
        );
      }
    ).then((value) async {
      _checkoutCartProducts() async {
        // create new order in Strapi
        http.Response response = await http.post('http://10.0.2.2:1337/orders', body: { 
          "amount": calculateTotalPrice(state.cartProducts),
          "products": json.encode(state.cartProducts),
          "source": state.cardToken,
          "customer": state.user.customerId
        }, headers: {
          'Authorization': 'Bearer ${state.user.jwt}'
        });
        final responseData = json.decode(response.body);
        return responseData;
      }
      // if value == false dialog is going to close
      if (value == true) {
        // show loading spinner
        setState(() { _isSubmitting = true; });
        // checkout cart products (create new orders in Strapi / charge Card with Stripe)
        final newOrderData = await _checkoutCartProducts();
        // create order instance
        Order newOrder = Order.fromJson(newOrderData);
        // pass order instance to a new action (AddOrderAction)
        StoreProvider.of<AppState>(context).dispatch(AddOrderAction(newOrder));
        // clear out cart products by using thunk action
        StoreProvider.of<AppState>(context).dispatch(clearCartProductsAction);
        // hide loading spinners
        setState(() { _isSubmitting = false; });
        // show success dialog
        _showSuccessDialog();
      }
    });
  }

  Future _showSuccessDialog() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('Success!'),
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('Order successful!\n\nCheck your email for a receipt of your purchase!\n\nOrder summary will apper in your orders tab', style: Theme.of(context).textTheme.body1,),
              )
          ],
        );
      }
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      converter: (store) => store.state,
      builder: (_, state) {
        return ModalProgressHUD(child: DefaultTabController(
          length: 3,
          initialIndex: 0,
          child: Scaffold(
            key: _scaffoldKey,
            floatingActionButton: state.cartProducts.length > 0 
              ? FloatingActionButton(
                  child: Icon(Icons.local_atm, size: 30.0,),
                  onPressed: () => _showCheckoutDialog(state),
                )
              : Text(''),
            appBar: AppBar(
              title: Text('Summary: ${state.cartProducts.length} Items · \$${calculateTotalPrice(state.cartProducts)}'),
              bottom: TabBar(
                labelColor: Colors.deepOrange[600],
                unselectedLabelColor: Colors.deepOrange[900],
                tabs: <Widget>[
                  Tab(icon: Icon(Icons.shopping_cart)),
                  Tab(icon: Icon(Icons.credit_card)),
                  Tab(icon: Icon(Icons.receipt)),
                ],
              )
            ),
            body: TabBarView(
              children: <Widget>[
                _cartTab(state),
                _cardsTab(state),
                _ordersTab(state),
              ],
            ),
          )
        ), 
        inAsyncCall: _isSubmitting,);
      }
    );
  }
}