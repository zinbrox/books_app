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
  double size;
  DateTime timeCreated;

  Books({this.name, this.title, this.author, this.description, this.genre, this.size, this.timeCreated});
}


class mainHomePage extends StatefulWidget {
  @override
  _mainHomePageState createState() => _mainHomePageState();
}

class _mainHomePageState extends State<mainHomePage> {
  List<Books> booksList = [], searchBooksList=[];
  bool _loading = true;
  int bookIndexSelected;
  final firestoreInstance = FirebaseFirestore.instance;
  TextEditingController _searchController = TextEditingController();
  List<String> categories = [
    'Art',
    'Business',
    'Children'
    'Classics',
    'Crime',
    'Fantasy',
    'Fiction',
    'History',
    'Horror',
    'Humour & Comedy',
    'Memoir & Autobiography',
    'Mystery & Thriller',
    'Nonfiction',
    'Science Fiction',
    'Science & Technology',
    'Young Adult',
  ];
  List<String> selectedCategories=[];
  List<bool> selectedCheck=[];
  Map sortBy = {'Alphabetical': 0, 'Reverse Alphabetical': 1, 'Date Added': 2, 'Size (Low to High)': 3, 'Size (High to Low)' : 4};
  int _radioValue=2;


  Future<void> showFiles() async {
    print("In showFiles");
    Books book;
    firebase_storage.ListResult result =
        await firebase_storage.FirebaseStorage.instance.ref('books/').listAll();


    for(var i in categories) {
      selectedCheck.add(false);
    }


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
        size: double.parse(((metadata.size)/1000000).toStringAsFixed(2)),
        timeCreated: metadata.timeCreated,
      );
      booksList.add(book);
    }

    // Sort the books according to Time Created (time added to cloud server)
    booksList.sort((b,a) => a.timeCreated.compareTo(b.timeCreated));
    searchBooksList = booksList;

    setState(() {
      _loading = false;
    });
  }

  Future<void> downloadFile() async {
    print("In downloadFile()");
    Directory appDocDir = await getApplicationDocumentsDirectory();
    File downloadToFile =
        File('${appDocDir.path}/${searchBooksList[bookIndexSelected].name}');
    Directory downloadsDirectory =
        await DownloadsPathProvider.downloadsDirectory;
    //print(downloadsDirectory);
    print(appDocDir.path);
    await firebase_storage.FirebaseStorage.instance
        .ref('books/${searchBooksList[bookIndexSelected].name}')
        .writeToFile(downloadToFile);
    print("Downloaded File");

    List<String> books;
    final prefs = await SharedPreferences.getInstance();
    books = prefs.getStringList('downloadedBooks') ?? [];
    print(books);

    String newBookLoc =
        '${appDocDir.path}/${searchBooksList[bookIndexSelected].name}';
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
            if(element.data()['name'] == searchBooksList[bookIndexSelected].name)
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
        "name": searchBooksList[bookIndexSelected].name,
        "title": searchBooksList[bookIndexSelected].title,
        "author": searchBooksList[bookIndexSelected].author,
        "description": searchBooksList[bookIndexSelected].description,
        "genre": searchBooksList[bookIndexSelected].genre,
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

  onBookSearch(String value) {
    print("In onItemChanged");
    setState(() {
        searchBooksList = booksList.where((element) => element.title.toLowerCase().contains(value.toLowerCase())).toList();
    });
  }

  onFilterChanged() async {
    await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text('Select Categories'),
          content: Container(
            height: 300,
            width: 300,
            child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (BuildContext context, index) {
                  return CheckboxListTile(
                      title: Text(categories[index]),
                      value: selectedCheck[index],
                      onChanged: (bool value) {
                        print("Value: $value");
                        if (value)
                          selectedCategories.add(categories[index]);
                        else
                          selectedCategories.remove(categories[index]);
                        setState(() {
                          selectedCheck[index] = value;
                        });
                        print("SelectedCheck[index]: ${selectedCheck[index]}");
                        print(selectedCategories);
                      });
                }),
          ),
          actions: [
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    searchBooksList = booksList.where((element) =>
                        selectedCategories.contains(element.genre)).toList();
                    if(searchBooksList.isEmpty)
                      searchBooksList = booksList;
                  });
                },
                child: Text("Apply"))
          ],
        );
      }
      );
    }

      );
    setState(() {
    });

  }

  onSortChanged() async {
    await showModalBottomSheet(
    context: context,
        builder: (context){
      return StatefulBuilder(builder: (context, setState){
        return Container(
          child: Container(
            height: 300,
            decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10)),
            ),
            child: ListView.builder(
              itemCount: sortBy.length,
                itemBuilder: (BuildContext context, index){
                return ListTile(
                  title: Text(sortBy.keys.toList()[index]),
                  trailing: Radio(
                    value: sortBy.values.toList()[index],
                    groupValue: _radioValue,
                    onChanged: (value){
                      print("Changed");
                      setState(() {
                        _radioValue=value;
                      });
                    },
                  ),
                );

            })
        ),
        );
        }
      );

        });
    setState(() {
      switch(_radioValue) {
        case 0: searchBooksList.sort((a,b) => a.title.compareTo(b.title)); break;
        case 1: searchBooksList.sort((b,a) => a.title.compareTo(b.title)); break;
        case 2: searchBooksList.sort((b,a) => a.timeCreated.compareTo(b.timeCreated)); break;
        case 3: searchBooksList.sort((a,b) => a.size.compareTo(b.size)); break;
        case 4: searchBooksList.sort((b,a) => a.size.compareTo(b.size)); break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    showFiles();
  }

  @override
  void dispose() {
    super.dispose();
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
          : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search Books"
                  ),
                  onChanged: onBookSearch,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      onFilterChanged();
                    },
                      child: Text("Filter")),
                  ElevatedButton(
                    onPressed: (){
                      onSortChanged();
                    },
                      child: Text("Sort")),
                ],
              ),
              Expanded(
                child: ListView.builder(
                    itemCount: searchBooksList.length,
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
                                      Text(searchBooksList[index].title),
                                      Text('By ${searchBooksList[index].author}'),
                                      Expanded(
                                          child: Text(
                                        '\n${searchBooksList[index].description}',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 9,
                                      )),
                                      Text(searchBooksList[index].size.toString() + 'MB'),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Genre: ${searchBooksList[index].genre}'),
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
              ),
            ],
          ),
    );
  }
}
