import 'dart:io';

import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'package:epub_viewer/epub_viewer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path_provider/path_provider.dart';

class Books {
  String name, title, author, description, genre;
  Books({this.name, this.title, this.author, this.description, this.genre});
}

class CustomListItem extends StatelessWidget {
  CustomListItem({this.title, this.author, this.description, this.genre});
  String title, author, description, genre;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: SizedBox(
        height: 200,
        child: Row(
          children: [
            Image.network("https://image.freepik.com/free-photo/red-hardcover-book-front-cover_1101-833.jpg"),
            Expanded(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text('By $author'),
                Expanded(child: Text('\n$description', overflow: TextOverflow.ellipsis, maxLines: 9,)),
                Text('Genre: $genre'),
              ],
            ))
          ],
        ),
      ),
    );
  }
}

class mainHomePage extends StatefulWidget {
  @override
  _mainHomePageState createState() => _mainHomePageState();
}

class _mainHomePageState extends State<mainHomePage> {
  List<Books> booksList = [];
  bool _loading = true;
  int bookIndexSelected;

  Future<void> showFiles() async {
    print("In showFiles");
    Books book;
    firebase_storage.ListResult result = await firebase_storage.FirebaseStorage
        .instance.ref('books/').listAll();

    result.items.forEach((firebase_storage.Reference ref) {
      //print('Found file: ${ref.name}');
    });
    for (var item in result.items) {
      firebase_storage.FullMetadata metadata = await firebase_storage
          .FirebaseStorage.instance
          .ref('${item.fullPath}')
          .getMetadata();
      print(metadata.customMetadata['title']);
      book = new Books(
        name: item.name,
        title: metadata.customMetadata['title'],
        author: metadata.customMetadata['author'],
        description: metadata.customMetadata['description'],
        genre: metadata.customMetadata['genre'],
      );
      booksList.add(book);
    }
    for(var i in booksList)
      print(i.description);
    setState(() {
      _loading=false;
    });
  }

  Future<void> downloadFile() async {
    print("In downloadFile()");

    Directory appDocDir = await getApplicationDocumentsDirectory();
    File downloadToFile = File('${appDocDir.path}/${booksList[bookIndexSelected].name}');
    Directory downloadsDirectory = await DownloadsPathProvider.downloadsDirectory;
    //print(downloadsDirectory);
    print(appDocDir.path);
    await firebase_storage.FirebaseStorage.instance
        .ref('books/${booksList[bookIndexSelected].name}')
        .writeToFile(downloadToFile);
    print("Downloaded File");

    File file = File('${appDocDir.path}/${booksList[bookIndexSelected].name}');
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
          child: CustomListItem(
            title: booksList[index].title,
            author: booksList[index].author,
            description: booksList[index].description,
            genre: booksList[index].genre,
          ),
              /*
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)
            ),
            elevation: 5.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(booksList[index].title),
                Text(booksList[index].author),
                Text(booksList[index].description),
                Text(booksList[index].genre),
                PopupMenuButton(itemBuilder: (context) =>
                    [
                      PopupMenuItem(
                          value: 1,
                          child: Text("Download")
                      ),
                    ],
                    onSelected: (value){
                      print("Download Selected");
                      bookIndexSelected = index;
                      downloadFile();
                    },
                ),
              ],
            ),
          ),
          */
        );
      }),
    );
  }
}
