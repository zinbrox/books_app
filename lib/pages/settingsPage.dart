import 'package:books_app/styles/color_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  PlatformFile file;
  String lightMode;
  final TextEditingController _password = new TextEditingController();
  String passText;
  int i=0;
  final firestoreInstance = FirebaseFirestore.instance;
  final databaseRef = FirebaseDatabase.instance.reference(); //database reference object
  var databaseData;

  Future<void> getScrollDirection() async {
    final prefs = await SharedPreferences.getInstance();
    String light = prefs.getString('readerMode') ?? null;
    if(light!=null)
      lightMode=light;
    else
      lightMode="Light";
    setState(() {
    });
  }

  Future<void> changeLightMode(String newValue) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('readerMode', newValue);
  }

  @override
  void initState() {
    super.initState();
    getScrollDirection();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _themeChanger = Provider.of<DarkThemeProvider>(context);
    bool isSwitched = _themeChanger.darkTheme;
    String dropdownValue;
    isSwitched ? dropdownValue = 'Dark' : dropdownValue = 'Light';


    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Settings"),
      ),
      body: Center(child: Column(
        children: <Widget>[
          ListTile(
            title: Text("App Theme", style: TextStyle(fontSize: 18),),
            trailing: DropdownButton<String>(
              value: dropdownValue,
              onChanged: (String newValue){
                setState((){
                  dropdownValue = newValue;
                  newValue=='Dark' ? _themeChanger.darkTheme=true : _themeChanger.darkTheme=false;
                });
              },
              items: <String>['Light','Dark'].map<DropdownMenuItem<String>>((String value){
                return DropdownMenuItem<String>(value: value, child: Text(value),);
              }).toList(),
            ),
          ),
          Divider(thickness: 3,),
          ListTile(
            title: Text("Reader Theme", style: TextStyle(fontSize: 18),),
            trailing:  DropdownButton<String>(
              value: lightMode,
              onChanged: (String newValue){
                if(this.mounted) {
                  setState((){
                    lightMode=newValue;
                    changeLightMode(newValue);
                  });
                }
              },
              items: <String>['Light', 'Dark'].map<DropdownMenuItem<String>>((String value){
                return DropdownMenuItem<String>(value: value, child: Text(value),);
              }).toList(),
            ),
          ),
          Divider(thickness: 3,),
          ListTile(
            title: Text("Request Books", style: TextStyle(fontSize: 18),),
            trailing: Icon(Icons.navigate_next),
            onTap: () => Navigator.pushNamed(context, '/requestsPage'),
          ),
          Divider(thickness: 3,),
          ListTile(
            title: Text("Feedback & Complaints", style: TextStyle(fontSize: 18),),
            trailing: Icon(Icons.navigate_next),
            onTap: () => Navigator.pushNamed(context, '/feedbackPage'),
          ),
          Divider(thickness: 3,),
          ListTile(
            title: Text("Test Databse", style: TextStyle(fontSize: 18),),
            trailing: Icon(Icons.navigate_next),
            onTap: () async {
              DatabaseReference db = FirebaseDatabase.instance.reference().child("results");
              db.once().then((DataSnapshot snapshot){
                //Map<dynamic, dynamic> values = snapshot.value;
                print(snapshot.value);
              });
            }
          ),
          Divider(thickness: 3,),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: (){
                  i++;
                  if(i==10) {
                    i=0;
                    showDialog(
                        context: context,
                        builder: (BuildContext context){
                          return AlertDialog(
                            title: Text("Enter Admin Password"),
                            content: TextFormField(
                              controller: _password,
                              maxLines: 1,
                              onChanged: (value) {
                                passText = _password.text;
                              },
                            ),
                            actions: [
                              ElevatedButton(
                                  onPressed: (){
                                    Navigator.of(context).pop();
                                  },
                                  child: Text("Cancel")),
                              ElevatedButton(
                                  onPressed: () {
                                    var firebaseUser = FirebaseAuth.instance.currentUser;
                                    print(firebaseUser.uid);
                                    firestoreInstance.collection("adminControl").get().then((querySnapshot){
                                      querySnapshot.docs.forEach((element) {
                                        if (element.data()['${firebaseUser.uid}'] == true) {
                                          print("Valid");
                                          Navigator.pushNamed(context, '/adminPage');
                                        }
                                        else {
                                          print("Invalid");
                                          Fluttertoast.showToast(
                                              msg: "You're not an admin",
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.BOTTOM,
                                              timeInSecForIosWeb: 1,
                                              fontSize: 16.0);
                                        }
                                      });
                                    });
                                },
                                  child: Text("Enter")),
                            ],
                          );
                        });
                  }
                },
                  child: Text("zinbrox", style: TextStyle(fontSize: 20, decoration: TextDecoration.overline),)),
            ],
          )
        ],
      ),),
    );
  }
}
