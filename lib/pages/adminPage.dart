import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/services.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {

  Future<void> fileUpload() async {

    firebase_storage.SettableMetadata metadata =
    firebase_storage.SettableMetadata(
      cacheControl: 'max-age=60',
      customMetadata: <String, String>{
        'description': 'Pluto is a dwarf planet in the Kuiper belt, a ring of bodies beyond the orbit of Neptune. It was the first and the largest Kuiper belt object to be discovered. After Pluto was discovered in 1930, it was declared to be the ninth planet from the Sun',
        'title': 'Pluto',
      },
    );
    FilePickerResult result = await FilePicker.platform.pickFiles(allowMultiple: true);

    if(result != null) {
      List<File> files = result.paths.map((path) => File(path)).toList();
      for(var file in result.files) {
        String name = file.name;
        await firebase_storage.FirebaseStorage.instance
            .ref('books/$name')
            .putFile(File(file.path), metadata);
      }
    } else {
      // User canceled the picker
      print("Error Picking Files");
    }
  }

  Future<void> showFiles() async {
  firebase_storage.ListResult result  = await firebase_storage.FirebaseStorage.instance.ref('books/').listAll();

  result.items.forEach((firebase_storage.Reference ref) {
    print('Found file: ${ref.fullPath}');
  });
  for(var i in result.items) {
    firebase_storage.FullMetadata metadata = await firebase_storage
        .FirebaseStorage.instance
        .ref('${i.fullPath}')
        .getMetadata();
    print(metadata.customMetadata['title']);
  }


  //print(metadata.customMetadata['title']);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Page"),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Text("Whaddup Admin"),
          ElevatedButton(onPressed: () {fileUpload();}, child: Text("Pick Books and Upload")),
          ElevatedButton(onPressed: () {showFiles();}, child: Text("Show Files")),
        ],
      ),
    );
  }
}
