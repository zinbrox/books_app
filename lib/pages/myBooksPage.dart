import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class myPage extends StatefulWidget {
  @override
  _myPageState createState() => _myPageState();
}

class _myPageState extends State<myPage> {
  firebase_storage.Reference ref;
  PlatformFile filePath;

  Future<void> getData() async {
    print("In data");
    ref = firebase_storage.FirebaseStorage.instance
        .ref()
        .child('test')
        .child('booktest')
        .child('Health.jpg');

    firebase_storage.ListResult result  = await firebase_storage.FirebaseStorage.instance.ref().child('test').listAll();
    print(ref);

    result.items.forEach((firebase_storage.Reference ref) {
      print('Found file: $ref');
    });
    result.prefixes.forEach((firebase_storage.Reference ref) {
      print('Found directory: $ref');
    });


  }

  Future<void> fileUpload() async {
    //FilePickerResult result = await FilePicker.platform.pickFiles();
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
    /*
    if (result != null) {
      filePath = result.files.first;
      String name = filePath.name;
      File file = File(filePath.path);
      await firebase_storage.FirebaseStorage.instance
          .ref('books/$name')
          .putFile(file, metadata);
    }

     */
  }

  @override
  void initState() {
    super.initState();
    getData();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Page"),
      ),
      body: Column(
        children: [
          Text("Page"),
          ElevatedButton(onPressed: () {
            fileUpload();
          }, child: Text("Select File and upload"),),
        ],
      ),
    );
  }
}