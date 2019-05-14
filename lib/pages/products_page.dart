import 'package:flutter/material.dart';
import 'package:flutter_ecommerce/models/app_state.dart';
import 'package:flutter_ecommerce/redux/actions.dart';
import 'package:flutter_ecommerce/widgets/product_item.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:badges/badges.dart';

final gradientBackground = BoxDecoration(
    gradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        stops: [
      0.1,
      0.3,
      0.5,
      0.7,
      0.9
    ],
        colors: [
      Colors.deepOrange[300],
      Colors.deepOrange[400],
      Colors.deepOrange[500],
      Colors.deepOrange[600],
      Colors.deepOrange[700]
    ]));

class ProductsPage extends StatefulWidget {
  // () after Function type means
  // it will be immideatly executes this function
  // when that widget loads
  final void Function() onInit;
  ProductsPage({this.onInit});

  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
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
              : FlatButton(
                  child: Text('Register Here', 
                    style: Theme.of(context).textTheme.body1),
                    onPressed: () => Navigator.pushNamed(context, '/register'), 
                    // with pushNamed we will be taken back from Register/Login page
                    ),
          ),
          leading: state.user != null 
            ? BadgeIconButton(
                itemCount: state.cartProducts.length,
                badgeColor: Colors.lime,
                badgeTextColor: Colors.black,
                hideZeroCount: false,
                icon: Icon(Icons.store), 
                onPressed: () => Navigator.pushNamed(context, '/cart'),) 
            : Text(''),
          actions: <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: StoreConnector<AppState, VoidCallback>(
                converter: (store) {
                  return () => store.dispatch(logoutUserAction);
                },
                builder: (_, callback) {
                  return state.user != null
                    ? IconButton(
                      icon: Icon(Icons.exit_to_app),
                      onPressed: callback)
                    : Text('');
                },
              ),
            )
          ],
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Scaffold(
      appBar: _appBar,
      body: Container(
        decoration: gradientBackground,
        child: StoreConnector<AppState, AppState>(
          converter: (store) => store.state,
          builder: (_, state) {
            return Column(
              children: [
                Expanded( // prevent overflow image 
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: GridView.builder(
                      itemCount: state.products.length, // itemBuilder takes state.products from here
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: orientation == Orientation.portrait ? 2 : 3,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0,
                        childAspectRatio: orientation == Orientation.portrait ? 1 : 1.3,
                      ),
                      itemBuilder: (context, i) => ProductItem(item: state.products[i]),
                    ),
                  ),
                )
              ]
            );
          },),
      ),
    );
  }
}
