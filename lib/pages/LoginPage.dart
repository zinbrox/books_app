import 'package:books_app/pages/home.dart';
import 'package:books_app/pages/sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _buttonVisible=false;

  Future<void> googleCall() async {
    Future.delayed(const Duration(seconds: 3),() async {
      await Firebase.initializeApp();

      User user = FirebaseAuth.instance.currentUser;
      if(user!=null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return Home();
            },
          ),
        );
      }
      else {
        setState(() {
          _buttonVisible=true;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    googleCall();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Column(
        children: [
          Image(image: AssetImage("assets/CatReadingGif.gif"),),
          AnimatedOpacity(
            opacity: _buttonVisible ? 1 : 0,
            duration: Duration(milliseconds: 400),
            child: ElevatedButton(
                onPressed: (){
                  signInWithGoogle().then((result) {
                    if (result != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return Home();
                          },
                        ),
                      );
                    }
                  });
                },
                child: Text("Sign In With Google")),
          )
        ],
      ),),
    );
  }
}
