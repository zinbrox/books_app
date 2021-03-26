import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:epub/epub.dart' as epub;
import 'package:epub_viewer/epub_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as image;

class downloadedBooks {
  String name, title, author, coverLoc;
  List<String> authors;
  var coverImage;

  downloadedBooks(
      {this.name,
      this.title,
      this.author,
      this.authors,
      this.coverImage,
      this.coverLoc});
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
  bool expanded2 = false;

  ScrollController controller;
  bool fabIsVisible = true;

  Future<void> getDownloadedBooks() async {
    print("In getDownloadedBooks()");
    downloadedBooksList = [];
    bool coverError = false;
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

      Directory appDocDir = await getApplicationDocumentsDirectory();
      if (await File('${appDocDir.path}/${epubBook.Title}.png').exists()) {
        print("File exists");
      } else {
        try {
          File('${appDocDir.path}/${epubBook.Title}.png')
              .writeAsBytesSync(image.encodePng(epubBook.CoverImage));
        } catch (e) {
          print("Error Saving Cover Image");
          print(e);
          coverError = true;
        }
      }

      items = downloadedBooks(
        title: epubBook.Title,
        author: epubBook.Author,
        authors: epubBook.AuthorList,
        coverImage: epubBook.CoverImage,
        name: book,
        coverLoc: coverError ? null : '${appDocDir.path}/${epubBook.Title}.png',
      );
      downloadedBooksList.add(items);
      //print(epubBook.CoverImage);
    }
    Fluttertoast.showToast(
        msg: "Welcome Back, " + firebaseUser.displayName,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        fontSize: 16.0);

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

    Fluttertoast.showToast(
        msg: "Opening Book...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        fontSize: 16.0);

    print(rawJson.length);

    String lightMode = prefs.getString('readerMode') ?? "Light";
    bool light;
    lightMode=="Light" ? light = false : light = true;

    EpubViewer.setConfig(
      themeColor: Theme.of(context).primaryColor,
      identifier: "iosBook",
      scrollDirection: EpubScrollDirection.ALLDIRECTIONS,
      allowSharing: true,
      enableTts: true,
      nightMode: light,
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
        "locations": {"cfi": loc.cfi}
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
    try {
      file.delete();
    } catch (e) {
      print("File couldn't be deleted: ");
      print(e);
    }

    Directory appDocDir = await getApplicationDocumentsDirectory();
    if(await File('${appDocDir.path}/${downloadedBooksList[bookIndexSelected]
        .title}.png').exists()) {
      file = File(
          '${appDocDir.path}/${downloadedBooksList[bookIndexSelected]
              .title}.png');
      try {
        file.delete();
      } catch (e) {
        print("Cover Image couldn't be deleted: ");
        print(e);
      }
    }
    else {
      print("Cover Image File doesn't exist");
    }

    print("Book Deleted");

    List<String> books = prefs.getStringList('downloadedBooks') ?? [];
    var x = downloadedBooksList[bookIndexSelected].name;
    books.remove(x);
    prefs.setStringList('downloadedBooks', books);
    downloadedBooksList.remove(x);

    setState(() {
      _loading = true;
    });
    getDownloadedBooks();
    setState(() {
      _loading = false;
    });
  }

  Future<void> onRefresh1() async {
    setState(() {
      _loading=true;
    });
    getDownloadedBooks();
    setState(() {
      _loading=false;
    });
  }

  Future<void> onRefresh2() async {
    setState(() {
    });
  }

  Future<void> downloadFile(String name) async {
    print("In downloadFile");

    Directory appDocDir = await getApplicationDocumentsDirectory();
    File downloadToFile =
    File('${appDocDir.path}/$name');

    print(appDocDir.path);
    await firebase_storage.FirebaseStorage.instance
        .ref('books/$name')
        .writeToFile(downloadToFile);
    print("Downloaded File");

    List<String> books;
    final prefs = await SharedPreferences.getInstance();
    books = prefs.getStringList('downloadedBooks') ?? [];
    print(books);

    String newBookLoc =
        '${appDocDir.path}/$name';
    if (!books.contains(newBookLoc)) {
      books.add(newBookLoc);
      prefs.setStringList('downloadedBooks', books);
    }

    Fluttertoast.showToast(
        msg: "Downloaded Book!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        fontSize: 16.0);



  }

  void removeBook(String name) {
    print("In removeBook()");
  }



  @override
  void initState() {
    super.initState();
    getDownloadedBooks();
    controller = ScrollController();
    controller.addListener(() {
      setState(() {
        fabIsVisible =
            controller.position.userScrollDirection == ScrollDirection.forward;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
      body: dropdownValue == 'Downloaded'
          ? returnDownloadedList()
          : returnSavedList(),
      floatingActionButton: AnimatedOpacity(
        opacity: fabIsVisible ? 1 : 0,
        duration: Duration(milliseconds: 200),
        child: FloatingActionButton(
            onPressed: () async {
              Fluttertoast.showToast(
                  msg: "Choose an epub file to open",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                  fontSize: 16.0);

              FilePickerResult result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['epub'],
              );
              if(result != null) {
                PlatformFile file = result.files.first;
                print(file.name);

                EpubViewer.setConfig(
                  themeColor: Theme.of(context).primaryColor,
                  identifier: "iosBook",
                  scrollDirection: EpubScrollDirection.ALLDIRECTIONS,
                  allowSharing: true,
                  enableTts: true,
                  nightMode: false,
                );

                Fluttertoast.showToast(
                    msg: "Opening Book",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    fontSize: 16.0);

                EpubViewer.open(
                  file.path,
                  // Load the Last Location of book from the object loc (if first time opened, it will start from first page)
                  lastLocation: EpubLocator.fromJson({
                    "bookId": "2239",
                    "href": "/OEBPS/ch06.xhtml",
                    "created": 1539934158390,
                    "locations": {"cfi": "epubcfi(/0!/4/4[simple_book]/2/2/6)"}
                  }), // first page will open up if the value is null
                );

              } else {
                // User canceled the picker
                Fluttertoast.showToast(
                    msg: "Cancelled",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    fontSize: 16.0);
              }
            },
          child: Icon(Icons.folder_open),
        ),
      ),
    );
  }

  Widget returnDownloadedList() {
    return _loading
        ? Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Image(image: AssetImage("assets/DogDiggingGif.gif"),)),
        Padding(padding: EdgeInsets.symmetric(vertical: 5.0)),
        Text("Fetching Downloads..."),
        Padding(padding: EdgeInsets.symmetric(vertical: 5.0)),
        CircularProgressIndicator(),
      ],
    ))
        : RefreshIndicator(
            onRefresh: onRefresh1,
            child: ListView.builder(
              controller: controller,
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
                              Padding(padding: EdgeInsets.only(left: 5)),
                              downloadedBooksList[index].coverLoc == null
                                  ? Image(
                                      image: AssetImage("assets/BookCover.png"),
                                      width: 120,
                                    )
                                  : Image.file(File(
                                      downloadedBooksList[index].coverLoc)),
                              Padding(padding: EdgeInsets.only(left: 15)),
                              Expanded(
                                  child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Spacer(),
                                  Text(downloadedBooksList[index].title),
                                  downloadedBooksList[index].authors.length > 1
                                      ? Text(
                                          'By ${downloadedBooksList[index].authors}')
                                      : Text(
                                          'By ${downloadedBooksList[index].author}'),
                                  //Image(image: downloadedBooksList[index].coverImage),
                                  Spacer(),
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
      onRefresh: onRefresh2,
      child: StreamBuilder(
        stream: firestoreInstance
            .collection("users")
            .doc(firebaseUser.uid)
            .collection("saved")
            .snapshots(),
        builder: (context, snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot orderData = snapshot.data.docs[index];
                    bool expanded=false;
                    double len;
                    if(orderData.data()['description'].length < 500)
                      len=0.4;
                    else if(orderData.data()['description'].length > 500 && orderData.data()['description'].length<1000)
                      len=0.65;
                    else if(orderData.data()['description'].length > 1000 && orderData.data()['description'].length<1500)
                      len=1.0;
                    else if(orderData.data()['description'].length>1500)
                      len=1.2;
                    double containerHeight = expanded2 ? MediaQuery.of(context).size.height * len
                        : MediaQuery.of(context).size.height * 0.30;


                    return GestureDetector(
                      onTap: () {
                        print("Tapped");
                        setState(() {
                          expanded2=!expanded2;
                        });
                        print(expanded2);
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: AnimatedContainer(
                            curve: Curves.easeOut,
                            duration: Duration(milliseconds: 400),
                            height: containerHeight,
                            child: Row(
                              children: [
                                Padding(padding: EdgeInsets.only(left: 5)),
                                Image(
                                  image: AssetImage("assets/BookCover.png"),
                                  width: 120,
                                ),
                                Padding(padding: EdgeInsets.only(left: 15)),
                                Expanded(
                                    child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(orderData.data()['title']),
                                    Text('By ' + orderData.data()['author']),
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
                                        Text(
                                            'Genre: ${orderData.data()['genre']}'),
                                        PopupMenuButton(
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                                value: 1,
                                                child: Text("Download")),
                                            PopupMenuItem(
                                                value: 2,
                                                child: Text(
                                                    "Remove from Want to Read")),
                                          ],
                                          onSelected: (value) {
                                            if (value == 1) {
                                              print("Download Selected");
                                              //bookIndexSelected = index;
                                              downloadFile(orderData.data()['name']);
                                            } else if (value == 2) {
                                              print(
                                                  "Remove from Want to Read Selected");
                                              //bookIndexSelected = index;
                                              removeBook(orderData.data()['name']);
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
              : Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Image(image: AssetImage("assets/DogDiggingGif.gif"),)),
              Padding(padding: EdgeInsets.symmetric(vertical: 5.0)),
              Text("Fetching Saved..."),
              Padding(padding: EdgeInsets.symmetric(vertical: 5.0)),
              CircularProgressIndicator(),
            ],
          ));
        },
      ),
    );
  }
}
