import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/models/app_state.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductPage extends StatefulWidget {
  // () after Function type means 
  // it will be immideatly executes this function 
  // when that widget loads
  final void Function() onInit;
  ProductPage({ this.onInit });

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {

  @override
  void initState() {
    super.initState();
    widget.onInit();
  }
  //with StoreConnector we can read from a store or dispatch an action
  final _appBar = PreferredSize(
    preferredSize: Size.fromHeight(60.0),
    child: StoreConnector<AppState, AppState>(
      converter: (store) => store.state,
      builder: (context, state /* state = returned val from converter */) {
        return AppBar(
          centerTitle: true,
          title: SizedBox(
            child: state.user != null 
              ? Text(state.user.username) 
              : Text(''),
              ),
          leading: Icon(Icons.store),
          actions: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: state.user != null 
                ? IconButton(
                    icon: Icon(Icons.exit_to_app),
                    onPressed: () => print('pressed'),
                    )
                : Text(''),
            )
          ],
        );
      },
      ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar,
      body: Container(
        child: Text('Products Page'),
      ),
    );
  }
}