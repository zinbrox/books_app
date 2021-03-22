import 'package:books_app/pages/HomePage.dart';
import 'package:books_app/pages/myBooksPage.dart';
import 'package:books_app/pages/settingsPage.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  final tabs=[
    HomePage(),
    myPage(),
    SettingsPage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: bottomNavigationBarFunction(),
      body: IndexedStack(
        children: <Widget>[
          HomePage(),
          myPage(),
          SettingsPage()
        ],
        index: _currentIndex,
      ),
    ); //tabs[_currentIndex],

  }
  Widget bottomNavigationBarFunction() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          title: Text('Home'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          title: Text('My Books'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          title: Text("Settings"),
        ),
      ],
      onTap: (index){
        setState(() {
          _currentIndex=index;
        });
      },
    );
  }
}