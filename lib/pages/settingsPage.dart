import 'package:books_app/styles/color_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';


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

  // For Easteregg
  VideoPlayerController _videoController;
  Future<void> _initializeVideoPlayerFuture;

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
    _videoController = VideoPlayerController.asset("assets/YodaCaughtYou.mp4");
    _initializeVideoPlayerFuture = _videoController.initialize();
  }

  @override
  void dispose() {
    super.dispose();
    _videoController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _themeChanger = Provider.of<DarkThemeProvider>(context);
    bool isSwitched = _themeChanger.darkTheme;
    String dropdownValue;
    isSwitched ? dropdownValue = 'Dark' : dropdownValue = 'Light';

    double height = MediaQuery.of(context).size.height * 0.8;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Settings", style: TextStyle(fontSize: 25),),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          height: height,
          child: Column(
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
              //MediaQuery.of(context).orientation == Orientation.portrait ? Spacer() : Container(),
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
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Stack(alignment: Alignment.center,
                                        children: [
                                          FutureBuilder(
                                              future: _initializeVideoPlayerFuture,
                                              builder: (context, snapshot){
                                                if (snapshot.connectionState == ConnectionState.done) {
                                                  if(_videoController.value.position==_videoController.value.duration){
                                                    _videoController.initialize();
                                                  }
                                                  return Container(
                                                    height: 300,
                                                    child: AspectRatio(
                                                      aspectRatio: 1,//_videoController.value.aspectRatio,
                                                      child: VideoPlayer(_videoController),
                                                    ),
                                                  );
                                                } else {
                                                  return Center(child: CircularProgressIndicator());
                                                }
                                              }),
                                          IconButton(
                                              icon: Icon(Icons.play_arrow),
                                              iconSize: 50,
                                              onPressed: (){
                                            setState(() {
                                              if(_videoController.value.position==_videoController.value.duration){
                                                _videoController.initialize();
                                              }
                                                _videoController.play();
                                            });
                                          })
                                        ],
                                      ),
                                      TextFormField(
                                        controller: _password,
                                        maxLines: 1,
                                        onChanged: (value) {
                                          passText = _password.text;
                                        },
                                      ),
                                    ],
                                  ),
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
          ),
        ),
      ),
    );
  }
}
