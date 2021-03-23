import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class savedPaged extends StatefulWidget {
  @override
  _savedPagedState createState() => _savedPagedState();
}

class _savedPagedState extends State<savedPaged> {
  final firestoreInstance = FirebaseFirestore.instance;
  var firebaseUser = FirebaseAuth.instance.currentUser;

  Future<void> onRefresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: savedCardReturn(),
      ),
    );
  }

  Widget savedCardReturn() {
    print("In savedCardReturn");

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: StreamBuilder(
        stream: firestoreInstance.collection("users").doc(firebaseUser.uid)
            .collection("saved").orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          return snapshot.hasData ?
          ListView.builder(
              itemCount: snapshot.data.docs.length,
              itemBuilder: (context, index){
                DocumentSnapshot orderData = snapshot.data.docs[index];
                return GestureDetector(
                  onTap: () {

                  },
                  child: Card(
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
                  ),
                );
              })
              : Center(child: CircularProgressIndicator(),);
        },
      ),
    );
  }
}
