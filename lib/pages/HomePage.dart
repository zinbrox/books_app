import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:epub_viewer/epub_viewer.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PlatformFile file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          ElevatedButton(
              child: Text("Pick File"),
              onPressed: () async {
                print("Pressed File Picker button");
                FilePickerResult result = await FilePicker.platform.pickFiles();
                if (result != null) {
                  file = result.files.first;

                  print(file.name);
                  print(file.bytes);
                  print(file.size);
                  print(file.extension);
                  print(file.path);
                } else {
                  // User canceled the picker
                  print("Error");
                }
              }),
          ElevatedButton(
              onPressed: () {
                EpubViewer.setConfig(
                  themeColor: Theme
                      .of(context)
                      .primaryColor,
                  identifier: "iosBook",
                  scrollDirection: EpubScrollDirection.VERTICAL,
                  allowSharing: true,
                  enableTts: true,
                );
                EpubViewer.open(
                  file.path,
                  /*
                  lastLocation: EpubLocator.fromJson({
                    "bookId": "2239",
                    "href": "/OEBPS/ch06.xhtml",
                    "created": 1539934158390,
                    "locations": {
                      "cfi": "epubcfi(/0!/4/4[simple_book]/2/2/6)"
                    }
                  }),// first page will open up if the value is null
                */
                );
              },
              child: Text("Open Book")
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
      ),
    );
  }
}
