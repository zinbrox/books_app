import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class requestPage extends StatefulWidget {
  @override
  _requestPageState createState() => _requestPageState();
}

class _requestPageState extends State<requestPage> {
  final TextEditingController _title = new TextEditingController();
  final TextEditingController _author = new TextEditingController();
  String titleText, authorText;
  final firestoreInstance = FirebaseFirestore.instance;
  var firebaseUser =  FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Request Books"),
        ),
        body: Center(
            child: ListView(
          children: <Widget>[
            Center(child: Text("Looking for a book in particular? Send a request for the book and we'll try to add it!")),
            SizedBox(height: 50,),
            TextFormField(
              controller: _title,
              maxLines: 3,
              onChanged: (value) {
                titleText = _title.text;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Title of the book is required';
                }
                return null;
              },
              decoration: InputDecoration(hintText: "Title"),
            ),
            TextFormField(
              controller: _author,
              maxLines: 3,
              onChanged: (value) {
                authorText = _author.text;
              },
              decoration: InputDecoration(hintText: "Author"),
            ),
            ElevatedButton(onPressed: () {
              FocusScope.of(context).unfocus();
              if (_formKey.currentState.validate()) {
                if(authorText == null)
                  authorText = "noAuthor";
                firestoreInstance
                    .collection("bookRequests")
                    .doc('requestsDoc')
                    .update({
                  'requests': FieldValue.arrayUnion([titleText + " , " + authorText + " - " + firebaseUser.displayName])
                });
                Fluttertoast.showToast(
                    msg: "Book Request Sent!",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    fontSize: 16.0);
              }
            }, child: Text("Request Book")),
          ],
        )),
      ),
    );
  }
}

class feedbackPage extends StatefulWidget {
  @override
  _feedbackPageState createState() => _feedbackPageState();
}

class _feedbackPageState extends State<feedbackPage> {
  final TextEditingController _text = new TextEditingController();
  final firestoreInstance = FirebaseFirestore.instance;
  var firebaseUser =  FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Feedback Page"),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 30,
            ),
            TextFormField(
              controller: _text,
              maxLines: 12,
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey)),
                //border: OutlineInputBorder(borderSide: new BorderSide(color: Colors.white, width: 20.0)),
                hintText: "Enter Feedback",
              ),
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              child: Text("Send Feedback"),
              onPressed: () {
                final snackBar =
                    SnackBar(content: Text('Thank you for your Feedback!'));
                Scaffold.of(context).showSnackBar(snackBar);
                FocusScope.of(context).unfocus();
                firestoreInstance
                    .collection("feedbackCollection")
                    .doc('feedback')
                    .update({
                  'feedbackArray': FieldValue.arrayUnion(
                      [firebaseUser.displayName + " : " + _text.text])
                });
                print("Feedback Sent");
              },
            ),
          ],
        ),
      ),
    );
  }
}
