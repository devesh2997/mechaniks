import 'package:flutter/material.dart';
import 'package:mechaniks/data/tickets_repository.dart';
import 'package:mechaniks/data/user_repository.dart';
import 'package:mechaniks/screens/tickets_page.dart';
import 'package:mechaniks/utils/index.dart';
import 'package:provider/provider.dart';
import 'package:mechaniks/providers/connectivity_provider.dart';
import 'package:oktoast/oktoast.dart';
import 'package:mechaniks/screens/landing.dart';
import 'package:mechaniks/screens/login_page.dart';
import 'package:mechaniks/screens/offline_page.dart';
import 'package:mechaniks/widgets/with_authentication.dart';

import 'data/mechanics_repository.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          builder: (context) => UserRepository.instance(),
        ),
        ChangeNotifierProvider(
          builder: (context) => MechanicsRepository.instance(),
        ),
        ChangeNotifierProvider(
          builder: (context) => TicketsRepository.instance(),
        )
      ],
      child: MyApp(),
    ),
  );
}

class Root extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    bool hasConnection =
        Provider.of<ConnectivityProvider>(context).hasConnection ?? true;
    return hasConnection ? MyApp() : OfflinePage();
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return OKToast(
      textStyle: TextStyle(color: getPrimaryColor()),
      radius: 5,
      textPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      position: ToastPosition(align: Alignment.topCenter, offset: 80),
      dismissOtherOnShow: true,
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: getPrimaryColor(),
          fontFamily: 'HindSiliguri',
          hintColor: Colors.black,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => WithAuthentication(
                child: Landing(),
              ),
          '/login': (context) => LoginPage(),
          '/landing': (context) => Landing(),
          '/offline': (context) => OfflinePage(),
          '/tickets': (context) => TicketsPage(),
        },
      ),
    );
  }
}
