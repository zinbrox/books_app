import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:epub/epub.dart' as epub;
import 'package:epub_viewer/epub_viewer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class downloadedBooks {
  String name, title, author;
  List<String> authors;
  var coverImage;

  downloadedBooks(
      {this.name, this.title, this.author, this.authors, this.coverImage});
}

class bookLocation {
  String name, bookId, href, cfi;
  int created;

  bookLocation({this.name, this.bookId, this.href, this.created, this.cfi});

  factory bookLocation.fromJson(Map<String, dynamic> parsedJson) {
    return new bookLocation(
        name: parsedJson['name'] ?? "",
        bookId: parsedJson['bookId'] ?? "",
        href: parsedJson['href'] ?? "",
        created: parsedJson['created'] ?? "",
        cfi: parsedJson['cfi'] ?? "");
  }

  Map<String, dynamic> toJson() {
    return {
      "name": this.name,
      "bookId": this.bookId,
      "href": this.href,
      "created": this.created,
      "cfi": this.cfi,
    };
  }
}

class myPage extends StatefulWidget {
  @override
  _myPageState createState() => _myPageState();
}

class _myPageState extends State<myPage> {
  List<String> books;
  List<downloadedBooks> downloadedBooksList = [];
  int bookIndexSelected;
  bool _loading = true;
  String dropdownValue = 'Downloaded';
  final firestoreInstance = FirebaseFirestore.instance;
  var firebaseUser = FirebaseAuth.instance.currentUser;

  Future<void> getDownloadedBooks() async {
    downloadedBooksList = [];
    final prefs = await SharedPreferences.getInstance();
    books = prefs.getStringList('downloadedBooks') ?? [];

    for (var book in books) {
      //print(book);
      downloadedBooks items;
      var targetFile = new File(book);
      List<int> bytes = await targetFile.readAsBytes();
      epub.EpubBook epubBook = await epub.EpubReader.readBook(bytes);
      String title = epubBook.Title;
      List<String> authors = epubBook.AuthorList;
      //print(title);
      //print(authors);
      items = downloadedBooks(
        title: epubBook.Title,
        author: epubBook.Author,
        authors: epubBook.AuthorList,
        coverImage: epubBook.CoverImage,
        name: book,
      );
      downloadedBooksList.add(items);
      //print(epubBook.CoverImage);
    }
    //print(downloadedBooksList);
    setState(() {
    });
    setState(() {
      _loading = false;
    });
  }

  Future<void> openBook() async {
    print("In openBook()");
    bookLocation loc = new bookLocation();
    final prefs = await SharedPreferences.getInstance();
    //prefs.setStringList('bookLocations', []);
    // Get list of Book Last Locations from Shared Preferences
    final rawJson = prefs.getStringList('bookLocations') ?? [];
    print(rawJson.length);
    for (var book in rawJson) {
      print("In Printing Books");
      print(book);
      // Decode from String to bookLocation Object
      bookLocation temp = bookLocation.fromJson(json.decode(book));
      // If the book last location already exists, remove that String from the saved.
      if (temp.name == downloadedBooksList[bookIndexSelected].name) {
        loc = temp;
        print(loc.bookId);
        rawJson.remove(book);
        break;
      }
    }
    print(rawJson.length);
    EpubViewer.setConfig(
      themeColor: Theme
          .of(context)
          .primaryColor,
      identifier: "iosBook",
      scrollDirection: EpubScrollDirection.VERTICAL,
      allowSharing: true,
      enableTts: true,
    );
    //print(downloadedBooksList[bookIndexSelected].name);
    File file = File(downloadedBooksList[bookIndexSelected].name);
    EpubViewer.open(
      downloadedBooksList[bookIndexSelected].name,
      // Load the Last Location of book from the object loc (if first time opened, it will start from first page)
      lastLocation: EpubLocator.fromJson({
        "bookId": loc.bookId,
        "href": loc.href,
        "created": loc.created,
        "locations": {
          "cfi": loc.cfi
        }
      }), // first page will open up if the value is null

    );

    EpubViewer.locatorStream.listen((locator) {
      // convert locator from string to json and save to your database to be retrieved later
      var decodedLoc = jsonDecode(locator);
      // remove the String from the saved Shared Preferences (to avoid multiple locations saved when switching between chapters)
      rawJson.remove(json.encode(loc));
      // Assign the new location values to loc Object
      loc.name = downloadedBooksList[bookIndexSelected].name;
      loc.bookId = decodedLoc['bookId'];
      loc.href = decodedLoc['href'];
      loc.created = decodedLoc['created'];
      loc.cfi = decodedLoc['locations']['cfi'];
      print(loc.name);
      // Encode the loc object, add it to the original List<String> and save that to the Shared Preferences to fetch later
      String newBookLocation = json.encode(loc);
      rawJson.add(newBookLocation);
      prefs.setStringList('bookLocations', rawJson);
    });
  }

  Future<void> deleteBook() async {
    print("In deleteBook()");
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getStringList('bookLocations') ?? [];
    for (var book in rawJson) {
      // Decode from String to bookLocation Object
      bookLocation temp = bookLocation.fromJson(json.decode(book));
      // If the book last location already exists, remove that String from the saved.
      if (temp.name == downloadedBooksList[bookIndexSelected].name) {
        rawJson.remove(book);
        break;
      }
    }
    File file = File(downloadedBooksList[bookIndexSelected].name);
    file.delete();
    print("Book Deleted");

    List<String> books = prefs.getStringList('downloadedBooks') ?? [];
    var x = downloadedBooksList[bookIndexSelected].name;
    books.remove(x);
    prefs.setStringList('downloadedBooks', books);
    downloadedBooksList.remove(x);

    setState(() {
      _loading=true;
    });
    getDownloadedBooks();
    setState(() {
      _loading=false;
    });

  }

  Future<void> onRefresh() async {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getDownloadedBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("My Page"),
              DropdownButton<String>(
                value: dropdownValue,
                onChanged: (String newValue) {
                  setState(() {
                    dropdownValue = newValue;
                  });
                },
                items: <String>['Downloaded', 'Want to Read']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        body: dropdownValue=='Downloaded' ? returnDownloadedList() : returnSavedList(),

    );
  }

  Widget returnDownloadedList() {
    return _loading ? Center(child: CircularProgressIndicator()) :
    RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
          itemCount: downloadedBooksList.length,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () {
                print("Book Selected");
                bookIndexSelected = index;
                openBook();
              },
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        Image.network(
                          "https://image.freepik.com/free-photo/red-hardcover-book-front-cover_1101-833.jpg",
                          width: 120,),
                        Expanded(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(downloadedBooksList[index].title),
                            downloadedBooksList[index].authors.length > 1
                                ? Text(
                                'By ${downloadedBooksList[index].authors}')
                                : Text(
                                'By ${downloadedBooksList[index].author}'),
                            //Image(image: downloadedBooksList[index].coverImage),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                        value: 1, child: Text("Delete")),
                                  ],
                                  onSelected: (value) {
                                    bookIndexSelected = index;
                                    deleteBook();
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

  Widget returnSavedList() {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: StreamBuilder(
        stream: firestoreInstance.collection("users").doc(firebaseUser.uid)
            .collection("saved")
            .snapshots(),
        builder: (context, snapshot) {
          return snapshot.hasData ?
          ListView.builder(
              itemCount: snapshot.data.docs.length,
              itemBuilder: (context, index){
                DocumentSnapshot orderData = snapshot.data.docs[index];
                return GestureDetector(
                  onTap: () {
                    print("Tapped");
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: SizedBox(
                        height: 200,
                        child: Row(
                          children: [
                            Image.network(
                              "https://image.freepik.com/free-photo/red-hardcover-book-front-cover_1101-833.jpg",
                              width: 120,),
                            Expanded(child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(orderData.data()['title']),
                                Text(orderData.data()['author']),
                                Expanded(
                                    child: Text(
                                      '\n${orderData.data()['description']}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 9,
                                    )),
                                //Image(image: downloadedBooksList[index].coverImage),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Genre: ${orderData.data()['genre']}'),
                                    PopupMenuButton(
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                            value: 1, child: Text("Download")),
                                        PopupMenuItem(
                                            value: 2,
                                            child: Text("Remove from Want to Read")),
                                      ],
                                      onSelected: (value) {
                                        if (value == 1) {
                                          print("Download Selected");
                                          //bookIndexSelected = index;
                                          //downloadFile();
                                        } else if (value == 2) {
                                          print("Remove from Want to Read Selected");
                                          //bookIndexSelected = index;
                                          //saveBook();
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
              })
              : Center(child: CircularProgressIndicator(),);
        },
      ),
    );
  }
}
