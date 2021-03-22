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
  downloadedBooks({this.name, this.title, this.author, this.authors, this.coverImage});
}

class myPage extends StatefulWidget {
  @override
  _myPageState createState() => _myPageState();
}

class _myPageState extends State<myPage> {
  List<String> books;
  List<downloadedBooks> downloadedBooksList = [];
  int bookIndexSelected;
  bool _loading=true;

  Future<void> getDownloadedBooks() async {
    final prefs = await SharedPreferences.getInstance();
    books = prefs.getStringList('downloadedBooks') ?? [];

    for(var book in books) {
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
      _loading=false;
    });

  }

  void openBook() {
    print("In openBook()");
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
          itemBuilder: (BuildContext context, int index){
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
                    Image.network("https://image.freepik.com/free-photo/red-hardcover-book-front-cover_1101-833.jpg", width: 120,),
                    Expanded(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(downloadedBooksList[index].title),
                        downloadedBooksList[index].authors.length > 1 ?  Text('By ${downloadedBooksList[index].authors}') : Text('By ${downloadedBooksList[index].author}'),
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
