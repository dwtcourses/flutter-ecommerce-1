import 'dart:convert';

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

class GetUserAction {
  final User _user;

  User get user => this._user;

  GetUserAction(this._user);
}
 