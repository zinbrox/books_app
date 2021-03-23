import 'dart:convert';
import 'dart:io';
import 'package:epub/epub.dart' as epub;
import 'package:epub_viewer/epub_viewer.dart';
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

  Future<void> getDownloadedBooks() async {
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
      _loading = false;
    });
  }

  Future<void> openBook() async {
    print("In openBook()");
    bookLocation loc = new bookLocation();
    final prefs = await SharedPreferences.getInstance();
    //prefs.setStringList('bookLocations', []);
    final rawJson = prefs.getStringList('bookLocations') ?? [];
    print(rawJson.length);
    for (var book in rawJson) {
      print("In Printing Books");
      print(book);
      bookLocation temp = bookLocation.fromJson(json.decode(book));
      //print(temp.name);
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
      lastLocation: EpubLocator.fromJson({
        "bookId": loc.bookId,
        "href": loc.href,
        "created": loc.created,
        "locations": {
          "cfi": loc.cfi
        }
      }), // first page will open up if the value is null

    );


    int maxLoc = 0;
    List<String> bookId = [],
        href = [],
        cfi = [];
    List<int> created = [];
    EpubViewer.locatorStream.listen((locator) {
      //print('LOCATOR: ${EpubLocator.fromJson(jsonDecode(locator))}');
      //print(jsonDecode(locator)['locations']['cfi']);
      var decodedLoc = jsonDecode(locator);
      //print(decodedLoc['locations']['cfi']);
      // convert locator from string to json and save to your database to be retrieved later
      rawJson.remove(json.encode(loc));
      loc.name = downloadedBooksList[bookIndexSelected].name;
      loc.bookId = decodedLoc['bookId'];
      loc.href = decodedLoc['href'];
      loc.created = decodedLoc['created'];
      loc.cfi = decodedLoc['locations']['cfi'];
      print(loc.name);
      String newBookLocation = json.encode(loc);
      rawJson.add(newBookLocation);
      prefs.setStringList('bookLocations', rawJson);

    });
    print("Hellllloooo");
    print(bookId);
    /*
    loc.name = downloadedBooksList[bookIndexSelected].name;
    loc.bookId = bookId[maxLoc-1];
    loc.href = href[maxLoc-1];
    loc.created = created[maxLoc-1];
    loc.cfi = cfi[maxLoc-1];
    print(loc.name);
    String newBookLocation = json.encode(loc);
    rawJson.add(newBookLocation);
    prefs.setStringList('bookLocations', rawJson);

     */


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
        title: Text("My Page"),
      ),
      body: _loading ? Center(child: CircularProgressIndicator()) :
      ListView.builder(
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
