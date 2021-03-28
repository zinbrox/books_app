import 'package:books_app/pages/home.dart';
import 'package:books_app/pages/sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: Image(image: AssetImage("assets/BookLogo.png"), height: 300,),
          ),
          Spacer(),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("assets/GoogleLogo.png", height: 40.0,),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        "Sign In With Google",
                        style: GoogleFonts.getFont("Open Sans",
                            color: Colors.black,
                            fontSize: 20.0
                        ),
                      ),
                    ),
                  ],
                ),
              style: ElevatedButton.styleFrom(
                primary: Colors.white,
                padding: const EdgeInsets.all(8.0),
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.symmetric(vertical: 50))
        ],
      ),),
    );
  }
}
