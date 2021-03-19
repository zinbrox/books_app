import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class Books {
  String title, description;
  Books({this.title, this.description});
}

class mainHomePage extends StatefulWidget {
  @override
  _mainHomePageState createState() => _mainHomePageState();
}

class _mainHomePageState extends State<mainHomePage> {
  List<Books> booksList = [];
  bool _loading = true;

  Future<void> showFiles() async {
    print("In showFiles");
    Books book;
    firebase_storage.ListResult result = await firebase_storage.FirebaseStorage
        .instance.ref('books/').listAll();

    result.items.forEach((firebase_storage.Reference ref) {
      print('Found file: ${ref.fullPath}');
    });
    for (var i in result.items) {
      firebase_storage.FullMetadata metadata = await firebase_storage
          .FirebaseStorage.instance
          .ref('${i.fullPath}')
          .getMetadata();
      print(metadata.customMetadata['title']);
      book = new Books(
        title: metadata.customMetadata['title'],
        description: metadata.customMetadata['description'],
      );
      booksList.add(book);
    }
    for(var i in booksList)
      print(i.description);
    setState(() {
      _loading=false;
    });
  }

  @override
  void initState() {
    super.initState();
    showFiles();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Main Home Page"),
        centerTitle: true,
      ),
      body: _loading ? Center(child: CircularProgressIndicator()) :
      ListView.builder(
          itemCount: booksList.length,
          itemBuilder: (BuildContext context, int index){
        return GestureDetector(
          onTap: () {},
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)
            ),
            elevation: 5.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(booksList[index].title),
                Text(booksList[index].description),
              ],
            ),
          ),
        );
      }),
    );
  }
}
