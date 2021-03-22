import 'package:books_app/pages/LoginPage.dart';
import 'package:books_app/pages/myBooksPage.dart';
import 'package:books_app/styles/color_styles.dart';
import 'package:flutter/material.dart';
import 'package:books_app/pages/home.dart';
import 'package:books_app/pages/adminPage.dart';
import 'package:books_app/pages/mainHomePage.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  DarkThemeProvider themeChangeProvider =  new DarkThemeProvider();

  void initState(){
    super.initState();
    getCurrentAppTheme();
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme = await themeChangeProvider.darkThemePreference.getTheme();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => themeChangeProvider,
      child: Consumer<DarkThemeProvider>(
        builder: (BuildContext context, value, Widget child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: Styles.themeData(themeChangeProvider.darkTheme, context),
            initialRoute: '/login',
            routes: {
              '/login': (context) => LoginPage(),
              '/home': (context) => Home(),
              '/myPage': (context) => myPage(),
              '/adminPage': (context) => AdminPage(),
              '/mainHomePage': (context) => mainHomePage(),
            },
          );
        },
      ),
    );
  }
}
