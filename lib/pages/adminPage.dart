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
  FilePickerResult result;
  final TextEditingController _title = new TextEditingController();
  final TextEditingController _author = new TextEditingController();
  final TextEditingController _description = new TextEditingController();
  final TextEditingController _genre = new TextEditingController();
  String titleText, authorText, descriptionText, genreText;

  Future<void> pickFile() async {
    result = await FilePicker.platform.pickFiles(allowMultiple: true);
  }

  Future<void> fileUpload() async {

    firebase_storage.SettableMetadata metadata =
    firebase_storage.SettableMetadata(
      cacheControl: 'max-age=60',
      customMetadata: <String, String>{
        'title': '$titleText',
        'author': '$authorText',
        'description': '$descriptionText',
        'genre': '$genreText',
      },
    );
    //FilePickerResult result = await FilePicker.platform.pickFiles(allowMultiple: true);

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
      body: ListView(
        children: <Widget>[
          Text("Whaddup Admin"),
          ElevatedButton(onPressed: () {pickFile();}, child: Text("Pick File"),),
          TextFormField(controller: _title, maxLines: 3, onChanged: (value){titleText=_title.text;}, decoration: InputDecoration(hintText: "Title"),),
          TextFormField(controller: _author, maxLines: 3, onChanged: (value){authorText=_author.text;}, decoration: InputDecoration(hintText: "Author"),),
          TextFormField(controller: _description, maxLines: 10, onChanged: (value){descriptionText=_description.text;}, decoration: InputDecoration(hintText: "Description"),),
          TextFormField(controller: _genre, maxLines: 2, onChanged: (value){genreText=_genre.text;}, decoration: InputDecoration(hintText: "Genre"),),
          ElevatedButton(onPressed: () {fileUpload();}, child: Text("Upload File")),
          ElevatedButton(onPressed: () {showFiles();}, child: Text("Show Files")),
        ],
      ),
    );
  }
}
