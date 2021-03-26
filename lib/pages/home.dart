import 'package:books_app/pages/HomePage.dart';
import 'package:books_app/pages/mainHomePage.dart';
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
    myPage(),
    mainHomePage(),
    SettingsPage(),
  ];
  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        bottomNavigationBar: bottomNavigationBarFunction(),
        body: Stack(
          children: [
            Offstage(
              offstage: _currentIndex!=0,
              child: tabs[0],
            ),
            Offstage(
              offstage: _currentIndex!=1,
              child: tabs[1],
            ),
            Offstage(
              offstage: _currentIndex!=2,
              child: tabs[2],
            ),
          ],
        ),
            /*
        IndexedStack(
          children: <Widget>[
            myPage(),
            mainHomePage(),
            SettingsPage()
          ],
          index: _currentIndex,
        ),

             */
      ),
    ); //tabs[_currentIndex],

  }
  Widget bottomNavigationBarFunction() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          title: Text('My Books'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          title: Text('Explore'),
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