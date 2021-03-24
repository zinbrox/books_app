import 'dart:io';
import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Books {
  String name, title, author, description, genre;

  Books({this.name, this.title, this.author, this.description, this.genre});
}

class mainHomePage extends StatefulWidget {
  @override
  _mainHomePageState createState() => _mainHomePageState();
}

class _mainHomePageState extends State<mainHomePage> {
  List<Books> booksList = [];
  bool _loading = true;
  int bookIndexSelected;
  final firestoreInstance = FirebaseFirestore.instance;

  Future<void> showFiles() async {
    print("In showFiles");
    Books book;
    firebase_storage.ListResult result =
        await firebase_storage.FirebaseStorage.instance.ref('books/').listAll();

    result.items.forEach((firebase_storage.Reference ref) {
      //print('Found file: ${ref.name}');
    });
    for (var item in result.items) {
      firebase_storage.FullMetadata metadata = await firebase_storage
          .FirebaseStorage.instance
          .ref('${item.fullPath}')
          .getMetadata();
      //print(metadata.customMetadata['title']);
      book = new Books(
        name: item.name,
        title: metadata.customMetadata['title'],
        author: metadata.customMetadata['author'],
        description: metadata.customMetadata['description'],
        genre: metadata.customMetadata['genre'],
      );
      booksList.add(book);
    }
    //for (var i in booksList) print(i.description);
    setState(() {
      _loading = false;
    });
  }

  Future<void> downloadFile() async {
    print("In downloadFile()");
    Directory appDocDir = await getApplicationDocumentsDirectory();
    File downloadToFile =
        File('${appDocDir.path}/${booksList[bookIndexSelected].name}');
    Directory downloadsDirectory =
        await DownloadsPathProvider.downloadsDirectory;
    //print(downloadsDirectory);
    print(appDocDir.path);
    await firebase_storage.FirebaseStorage.instance
        .ref('books/${booksList[bookIndexSelected].name}')
        .writeToFile(downloadToFile);
    print("Downloaded File");

    List<String> books;
    final prefs = await SharedPreferences.getInstance();
    books = prefs.getStringList('downloadedBooks') ?? [];
    print(books);

    String newBookLoc =
        '${appDocDir.path}/${booksList[bookIndexSelected].name}';
    if (!books.contains(newBookLoc)) {
      books.add(newBookLoc);
      prefs.setStringList('downloadedBooks', books);
    }

    books = prefs.getStringList('downloadedBooks') ?? [];
    print(books);

    Fluttertoast.showToast(
        msg: "Downloaded Book!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        fontSize: 16.0);
  }

  Future<void> saveBook() async {
    print("In saveBook()");
    bool existingCheck=false;
    var firebaseUser = FirebaseAuth.instance.currentUser;
    firestoreInstance.collection("users").get().then((querySnapshot){
      querySnapshot.docs.forEach((element) {
        firestoreInstance.collection("users").doc(firebaseUser.uid).collection("saved").get().then((querySnapshot){
          querySnapshot.docs.forEach((element) {
            if(element.data()['name'] == booksList[bookIndexSelected].name)
              existingCheck=true;
          });
        });
      });
    });
    if(existingCheck) {
      firestoreInstance
          .collection("users")
          .doc(firebaseUser.uid)
          .collection("saved")
          .add({
        "name": booksList[bookIndexSelected].name,
        "title": booksList[bookIndexSelected].title,
        "author": booksList[bookIndexSelected].author,
        "description": booksList[bookIndexSelected].description,
        "genre": booksList[bookIndexSelected].genre,
      }).then((_) {
        final snackBar = SnackBar(content: Text('Added to Want to Read!'));
        Scaffold.of(context).showSnackBar(snackBar);
        print("success!");
      });
    }
    else {
      final snackBar = SnackBar(content: Text("Book already exists in Want to Read"));
      Scaffold.of(context).showSnackBar(snackBar);
    }
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
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: booksList.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onTap: () {},
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: SizedBox(
                        height: 250,
                        child: Row(
                          children: [
                            Image.network(
                              "https://image.freepik.com/free-photo/red-hardcover-book-front-cover_1101-833.jpg",
                              width: 120,
                            ),
                            Expanded(
                                child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(booksList[index].title),
                                Text('By ${booksList[index].author}'),
                                Expanded(
                                    child: Text(
                                  '\n${booksList[index].description}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 9,
                                )),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Genre: ${booksList[index].genre}'),
                                    PopupMenuButton(
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                            value: 1, child: Text("Download")),
                                        PopupMenuItem(
                                            value: 2,
                                            child: Text("Want to Read")),
                                      ],
                                      onSelected: (value) {
                                        if (value == 1) {
                                          print("Download Selected");
                                          bookIndexSelected = index;
                                          downloadFile();
                                        } else if (value == 2) {
                                          print("Want to Read Selected");
                                          bookIndexSelected = index;
                                          saveBook();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ))
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
    );
  }
}
