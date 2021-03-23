import 'package:books_app/styles/color_styles.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  PlatformFile file;

  @override
  void initState() {
    super.initState();
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
        ],
      ),),
    );
  }
}
