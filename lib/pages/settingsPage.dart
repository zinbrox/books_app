import 'package:books_app/styles/color_styles.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  PlatformFile file;
  String lightMode;

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
        title: Text("Settings"),
        centerTitle: true,
      ),
      body: Center(child: Column(
        children: <Widget>[
          Text("Hello"),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Theme"),
              Text(_themeChanger.darkTheme.toString()),
              DropdownButton<String>(
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
            ],
          ),


          ElevatedButton(onPressed: () {
            Navigator.pushNamed(context, '/myPage');
          }, child: Text("Go to my Page")
          ),
          ElevatedButton(onPressed: () {
            Navigator.pushNamed(context, '/mainHomePage');
          }, child: Text("Main Home Page")),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/adminPage');
            },
            child: Text("Admin Page"),
          ),
          ListTile(
            title: Text("Request Books"),
            onTap: () => Navigator.pushNamed(context, '/requestsPage'),
          ),
          ListTile(
            title: Text("Feedback"),
            onTap: () => Navigator.pushNamed(context, '/feedbackPage'),
          ),
          Row(
            children: <Widget>[
              Padding(padding: EdgeInsets.only(left: 15)),
              Text("Reader Scroll Direction"),
              Spacer(),
              DropdownButton<String>(
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
              )
            ],
          ),
        ],
      ),),
    );
  }
}
