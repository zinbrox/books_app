import 'dart:io';
import 'package:books_app/styles/color_styles.dart';
import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Books {
  String name, title, author, description, genre;
  double size;
  DateTime timeCreated;
  //expanded- Whether the Animated Container is expanded or now, downloadExists - to check whether the shown book is already downloaded or not
  bool expanded, downloadExists;

  Books({this.name, this.title, this.author, this.description, this.genre, this.size, this.timeCreated, this.expanded, this.downloadExists});
}

class mainHomePage extends StatefulWidget {
  @override
  _mainHomePageState createState() => _mainHomePageState();
}

class _mainHomePageState extends State<mainHomePage> with TickerProviderStateMixin{
  // booksList is origianl list, searchBooksList is the list after filtering and/or sorting
  List<Books> booksList = [], searchBooksList=[];
  bool _loading = true, _BookLoading=true;
  int bookIndexSelected; // Book index Selected for download
  final firestoreInstance = FirebaseFirestore.instance;

  TextEditingController _searchController = TextEditingController();
  bool _searchVisible=false;

  // For Filtering
  List<String> categories = [
    'Art',
    'Business',
    'Children',
    'Classics',
    'Crime',
    'Fantasy',
    'Fiction',
    'History',
    'Horror',
    'Humour',
    'Memoir',
    'Mystery',
    'Nonfiction',
    'Poetry',
    'Psychology',
    'Science',
    'Science Fiction',
    'Technology',
    'Thriller',
    'Travel',
    'Young Adult',
  ];
  List<String> selectedCategories=[];
  List<bool> selectedCheck=[];

  // For Sorting
  Map sortBy = {'Alphabetical': 0, 'Reverse Alphabetical': 1, 'Date Added': 2, 'Size (Low to High)': 3, 'Size (High to Low)' : 4};
  int _radioValue=2; //Default Value of Sort is Date Added

  DateTime now = DateTime.now();

  Future<void> showFiles() async {
    print("In showFiles");
    Books book;
    firebase_storage.ListResult result =
        await firebase_storage.FirebaseStorage.instance.ref('books/').listAll();
    now = DateTime.now();
    print(now);


    for(var i in categories) {
      selectedCheck.add(false);
    }

    //Get the metadata of each file (in reverse order so that latest uploaded is first to load)
    for (var item in result.items.reversed) {
      firebase_storage.FullMetadata metadata = await item.getMetadata();

      bool downloadExists=false;
      Directory appDocDir = await getApplicationDocumentsDirectory();
      if(await File('${appDocDir.path}/${item.name}').exists()) {
        downloadExists=true;
      }

        book = new Books(
        name: item.name,
        title: metadata.customMetadata['title'],
        author: metadata.customMetadata['author'],
        description: metadata.customMetadata['description'],
        genre: metadata.customMetadata['genre'],
        size: double.parse(((metadata.size)/1000000).toStringAsFixed(2)),
        timeCreated: metadata.timeCreated,
        expanded: false,
          downloadExists: downloadExists,
      );
      booksList.add(book);
      // Sort the books according to Time Created (time added to cloud server)
      booksList.sort((b,a) => a.timeCreated.compareTo(b.timeCreated));
      searchBooksList = booksList;
      setState(() {
        _loading=false;
      });

      //now=DateTime.now();
      //print(now);
    }
    //print("Done");
    //now=DateTime.now();
    //print(now);


    setState(() {
      _BookLoading = false;
    });
  }

  Future<bool> checkIfFileExists(String filePath) async {
    if(await File(filePath).exists())
      return true;
    else
      return false;
  }

  Future<void> downloadFile() async {
    print("In downloadFile()");
    Fluttertoast.showToast(
        msg: "Downloading Book...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        fontSize: 16.0);
    Directory appDocDir = await getApplicationDocumentsDirectory();
    File downloadToFile =
        File('${appDocDir.path}/${searchBooksList[bookIndexSelected].name}');
    Directory downloadsDirectory =
        await DownloadsPathProvider.downloadsDirectory;

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

    setState(() {
      searchBooksList[bookIndexSelected].downloadExists=true;
    });

    Fluttertoast.showToast(
        msg: "Downloaded Book!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        fontSize: 16.0);
  }

  // Check if File is already saved in Want to Read
  Future<void> checkIfAlreadySaved() async {
    int i=0;
    var firebaseUser = FirebaseAuth.instance.currentUser;
    await firestoreInstance.collection("users").get().then((querySnapshot){
      querySnapshot.docs.forEach((element) {
        firestoreInstance.collection("users").doc(firebaseUser.uid).collection("saved").get().then((querySnapshot){
          querySnapshot.docs.forEach((element1) {
            print(element1.data()['name']);
            print(searchBooksList[bookIndexSelected].name);
            if(element1.data()['name'] == searchBooksList[bookIndexSelected].name)
              {
                print("Found");
                if(i>0) {
                    element1.reference.delete();
                }
                i++;
              }
          });
        });
      });
    });
  }

  // Save Book to Want to Read if it isn't already there
  Future<void> saveBook() async {
    print("In saveBook()");
    var firebaseUser = FirebaseAuth.instance.currentUser;
    checkIfAlreadySaved();
      print("Saving");
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
        Fluttertoast.showToast(
            msg: "Added to Want to Read",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            fontSize: 16.0);
      });

  }

  // Search books based on the input. searchBooksList only contains those books which have searched keyword in it
  onBookSearch(String value) {
    print("In onItemChanged");
    setState(() {
        searchBooksList = booksList.where((element) => element.title.toLowerCase().contains(value.toLowerCase())).toList();
    });
  }

  // Return only certain selected categories of books
  onFilterChanged() async {
    await showModalBottomSheet(
        context: context,
        builder: (context){
          return StatefulBuilder(builder: (context, setState){
            return Container(
              height: 300,
              child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (BuildContext context, index) {
                    return CheckboxListTile(
                        title: Text(categories[index]),
                        value: selectedCheck[index],
                        onChanged: (bool value) {
                          if (value)
                            selectedCategories.add(categories[index]);
                          else
                            selectedCategories.remove(categories[index]);
                          setState(() {
                            selectedCheck[index] = value;
                          });
                        });
                  }),
            );
          }
          );

        });
    setState(() {
        searchBooksList = booksList.where((element) =>
            selectedCategories.contains(element.genre)).toList();
        if(searchBooksList.isEmpty) {
          searchBooksList = booksList;
        }
        if(selectedCategories.isNotEmpty && searchBooksList==booksList) {
          Fluttertoast.showToast(
              msg: "Couldn't find any books with those parameters",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              fontSize: 16.0);
        }
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
    print(now);
    showFiles();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final _theme = Provider.of<DarkThemeProvider>(context);

    return Scaffold(
      body: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              title: Text("Bibliotium", style: TextStyle(fontSize: 25)),
              automaticallyImplyLeading: false,
              pinned: true,
              snap: false,
              floating: true,
              expandedHeight: _searchVisible ? 180.0 : 120.0,
              actions: [
                Visibility(
                  visible: _BookLoading,
                    child: Center(child: CircularProgressIndicator())),
                IconButton(
                    icon: Icon(Icons.search),
                    onPressed: (){
                      setState(() {
                        _searchVisible=!_searchVisible;
                      });

                    }),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
                  children: [
                    SizedBox(height: 90.0),
                    Visibility(
                      visible: _searchVisible,
                      maintainSize: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: TextFormField(
                          controller: _searchController,
                          decoration: InputDecoration(
                              hintText: "Search Books"
                          ),
                          onChanged: onBookSearch,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              onFilterChanged();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.filter_list, color: Colors.white),
                                  Padding(padding: EdgeInsets.symmetric(horizontal: 5)),
                                  Text("Filter", style: TextStyle(fontSize: 20, color: Colors.white),),
                                ],
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.pinkAccent.shade400,
                              //backgroundColor: _theme.darkTheme ? Colors.grey[800] : Colors.grey[50],
                              //side: BorderSide(color: _theme.darkTheme ? Colors.white : Colors.black, width: 1),
                              elevation: 5

                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: (){
                              onSortChanged();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.sort, color: Colors.white),
                                  Padding(padding: EdgeInsets.symmetric(horizontal: 5)),
                                  Text("Sort", style: TextStyle(fontSize: 20, color: Colors.white),),
                                ],
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.pinkAccent.shade400,
                              //backgroundColor: _theme.darkTheme ? Colors.grey[800] : Colors.grey[50],
                              //side: BorderSide(color: _theme.darkTheme ? Colors.white : Colors.black, width: 1),
                              elevation: 5,

                            ),
                          ), ),
                      ],
                    ),
                  ],
                ),
      ),
            ),
           SliverList(
               delegate: SliverChildBuilderDelegate((context, index){
                 double len;
                 if(searchBooksList[index].description.length <= 500)
                   len=0.35;
                 else if (searchBooksList[index].description.length > 500 && searchBooksList[index].description.length<=750)
                   len = 0.6;
                 else if(searchBooksList[index].description.length > 750 && searchBooksList[index].description.length<=1000)
                   len=0.66;
                 else if(searchBooksList[index].description.length > 1000 && searchBooksList[index].description.length<=1500)
                   len=1.0;
                 else if(searchBooksList[index].description.length>=1500)
                   len=1.2;

                 double containerHeight = searchBooksList[index].expanded ? 1000 * len : 1000 * 0.25;
                 //double containerHeight = Theme.of(context).textTheme.headline1.fontSize * 2.1;
                 return GestureDetector(
                   onTap: () {
                     setState(() {
                       searchBooksList[index].expanded = !searchBooksList[index].expanded;

                     });
                   },
                   child: Card(
                     elevation: 10,
                     child: Padding(
                       padding: const EdgeInsets.symmetric(vertical: 10.0),
                       child: AnimatedContainer(
                         height: containerHeight,
                         curve: Curves.easeOut,
                         duration: Duration(milliseconds: 400),
                         child: Row(
                           children: [
                             Padding(padding: EdgeInsets.only(left: 5)),
                             Stack(
                               children: [
                                 Align(
                                   alignment: Alignment.center,
                                   child: Image(
                                     image: AssetImage("assets/BookCover.png"),
                                     width: 100,
                                   )
                                 ),
                                 Align(
                                   alignment: Alignment.center,
                                     child: Text("  Couldn't Load\n  Cover Image", textAlign: TextAlign.center, style: TextStyle(color: Colors.white),)),
                               ],
                             ),
                             Padding(padding: EdgeInsets.only(left: 15)),
                             Expanded(
                                 child: Column(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text(searchBooksList[index].title),
                                     Text('By ${searchBooksList[index].author}'),
                                     //Text(searchBooksList[index].description.length.toString()),
                                     Expanded(
                                         child: Text(
                                           '\n${searchBooksList[index].description}',
                                           overflow: TextOverflow.ellipsis,
                                           maxLines: searchBooksList[index].expanded ? 50 : 7,
                                         )
                                     ),
                                     Row(
                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                       children: [
                                         Text('Size: ' + searchBooksList[index].size.toString() + 'MB'),
                                         searchBooksList[index].downloadExists ?
                                         Row(
                                           children: [
                                             Text("Downloaded"),
                                             Icon(Icons.check_circle),
                                           ],
                                         ) : Spacer(),
                                       ],
                                     ),
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
               },
                 childCount: searchBooksList.length,
               )),
          ],

      ),
    );
  }
}
