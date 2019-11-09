import 'package:flutter/material.dart';
import 'package:mechaniks/data/user_repository.dart';
import 'package:mechaniks/screens/login_page.dart';
import 'package:provider/provider.dart';

class WithAuthentication extends StatelessWidget {
  final Widget child;
  WithAuthentication({this.child});
  @override
  Widget build(BuildContext context) {
    return Consumer<UserRepository>(builder: (context, UserRepository user, _) {
      switch (user.status) {
        case Status.Authenticating:
        case Status.Unauthenticated:
          return LoginPage();
        case Status.Authenticated:
          return child;
        case Status.Uninitialized:
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        default:
          return LoginPage();
      }
    });
  }
}
