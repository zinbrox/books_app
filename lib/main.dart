import 'package:books_app/pages/LoginPage.dart';
import 'package:books_app/pages/myBooksPage.dart';
import 'package:flutter/material.dart';
import 'package:books_app/pages/home.dart';
import 'package:books_app/pages/adminPage.dart';
import 'package:books_app/pages/mainHomePage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/login',
      routes: {
        '/login':(context) => LoginPage(),
        '/home': (context) => Home(),
        '/myPage': (context) => myPage(),
        '/adminPage':(context) => AdminPage(),
        '/mainHomePage':(context) => mainHomePage(),
      },
    );
  }
}
