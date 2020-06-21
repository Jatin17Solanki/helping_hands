//buy, sell ,request, lost and found etc
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expandable/expandable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:yozznett/pages/choose_institution_dropdown_page.dart';
import 'add_items.dart';
import 'done_tag.dart';
import 'colors.dart';

class MyP2pPage extends StatefulWidget {
  // final ScrollController scrollController;
  MyP2pPage({Key key}) : super(key: key);
  @override
  _MyP2pPageState createState() => _MyP2pPageState();
}

class _MyP2pPageState extends State<MyP2pPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  scrollToTop() {
    _scrollController.animateTo(_scrollController.position.minScrollExtent,
        duration: Duration(milliseconds: 1000), curve: Curves.easeIn);
    setState(() {});
  }

  CollectionReference userProfileCollection =
      Firestore.instance.collection('userProfile');

  StreamSubscription<DocumentSnapshot> profileColSubscription;

  var userInstituteLocation;

  loadProfileData(FirebaseUser user) async {
    profileColSubscription = userProfileCollection
        .document('${user.uid}')
        .snapshots()
        .listen((profileDataSnap) {
      if (profileDataSnap.exists) {
        print('profile data exists');
        setState(() {
          this.userInstituteLocation =
              profileDataSnap.data['userInstituteLocation'];
          print('userInsLoc from profile $userInstituteLocation');

//          getP2pData();
        });

//        if(mounted){
//          print('mounted $mounted');
//          getP2pData();
////          loadP2PList();
//        }

        getP2pData();
      } else {
        print('profile data does not exist');
      }
    });

    //  await     getP2pData();
  }

  bool userProfileExists = false;
  checkProfile() {
    FirebaseAuth.instance.currentUser().then((user) {
      if (user != null) {
        debugPrint('user is not null, user is ${user.uid}');

//check if user profile already exists
        Firestore.instance
            .collection('userProfile')
            .document(user.uid)
            .get()
            .then((doc) {
          if (doc.exists) {
            debugPrint('profile exists while logging');
            setState(() {
              userProfileExists = true;
            });
          } else {
            debugPrint('profile doesnt exist while logging');

            Navigator.pop(context);
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //       builder: (context) => ChooseInstitutionDdPage(user)),
            // );
          }
        }).catchError((e) {
          print(e.toString());
        });
      } else {
        debugPrint('user is null');
        Navigator.pop(context);
      }
    }).catchError((e) {
      print(e.toString());
    });
  }

  // Firestore firestore = Firestore.instance;
  CollectionReference p2pNetworkColRef =
      Firestore.instance.collection('p2pNetwork');
  String giaTypeSelected = 'All';
  int giaItemCount = 0;

  bool hideCard = false;

  //paginatin starts
  Firestore firestore = Firestore.instance;

  List<DocumentSnapshot> products = []; // stores fetched products

  bool isLoading = false; // track if products fetching

  bool hasMore = true; // flag for more products available or not

  int documentLimit = 5; // documents to be fetched per request

  DocumentSnapshot
      lastDocument; // flag for last document from where next 10 records to be fetched

  ScrollController _scrollController =
      ScrollController(); // listener for listview scrolling
  //pagination ends
  //pagination...
  getP2pData() async {
    print('get product called');
    if (!hasMore) {
      print('has more = $hasMore');
      return;
    }
    if (isLoading) {
      print('isLoading = $isLoading');

      return;
    }
//    if (!mounted) return;

    setState(() {
      isLoading = true;
      print('isLoadinggg= $isLoading');
      print('inside get products. GiaTypeSeleceted = ${this.giaTypeSelected}');
    });

    print('inside get products. GiaTypeSeleceted = ${this.giaTypeSelected}');
    Query query;
    if (giaTypeSelected == 'All') {
      query = p2pNetworkColRef.orderBy('serverTimeStamp', descending: true);
    } else if (giaTypeSelected == 'searchQuery') {
      print('inside get products. GiaTypeSeleceted = ${this.giaTypeSelected}');
//      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
      // query = searchQuery();
      return;
    } else {
      print('inside get products. GiaTypeSeleceted = ${this.giaTypeSelected}');

      query = queryGiaItemsByCategory();
    }

    QuerySnapshot querySnapshot;
    if (lastDocument == null) {
      querySnapshot = await query.limit(10).getDocuments();
    } else {
      querySnapshot = await query
          .startAfterDocument(lastDocument)
          .limit(documentLimit)
          .getDocuments();

      print(1);
    }
    if (querySnapshot.documents.length < documentLimit) {
      hasMore = false;
    }
    if (querySnapshot.documents.length - 1 < 0) {
      lastDocument = null;
    } else {
//      if (!mounted) return;
      lastDocument =
          querySnapshot.documents[querySnapshot.documents.length - 1];
    }
    products.addAll(querySnapshot.documents);
    if (this.mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  //pagination ends
  @override
  void initState() {
    super.initState();
    print('in 2nd init state');

    userInstituteLocation = '';
    try {
      FirebaseAuth.instance.currentUser().then((onlineUser) {
        setState(() {
          print('user is ${onlineUser.uid}');
        });

        checkProfile();
        loadProfileData(onlineUser);
      }).catchError((e) {
        print(e.toString());
      });
    } catch (e) {
      print(e.toString());
    }

    _scrollController.addListener(() {
      double maxScroll = _scrollController.position.maxScrollExtent;
      double currentScroll = _scrollController.position.pixels;
      double delta = MediaQuery.of(context).size.height * 0.25;
      if (maxScroll - currentScroll <= delta) {
//        if(mounted){
//          print('mounted $mounted');
//          getP2pData();
//        }

        getP2pData();
      }
      // }
    });
  }

  @override
  void dispose() {
    profileColSubscription?.cancel();
    searchItemController?.dispose();
    _scrollController?.dispose();
    super.dispose();
  }

  DoneTag doneTag = new DoneTag();
  int maxLine = 1;

  //parthiv gia template
  bool isClicked = false;
  bool isShowDescriptionClicked = false;

  Widget buildP2pTemplate(DocumentSnapshot doc) {
    return Padding(
      padding: EdgeInsets.only(top: 15, left: 10, right: 10),
      child: AnimatedContainer(
        duration: Duration(seconds: 2),
        curve: Curves.easeOutSine,
        // height: isClicked ? null : 262,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.white,
          // Colors.teal[50],
          borderRadius: BorderRadius.circular(10),
          // border: Border.all(
          //     color: Colors.black12, style: BorderStyle.solid, width: 0.75),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.12),
              offset: Offset(0, 10),
              blurRadius: 8,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AnimatedContainer(
                //image
                duration: Duration(seconds: 2),
                curve: Curves.easeOutSine,
                // child: Image(
                //   image: AssetImage(imgpath),
                //   height: isClicked? 300 : 125,
                //   width: MediaQuery.of(context).size.width,
                //   fit: BoxFit.cover,
                // )
                child: ClipRRect(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10)),
                    child: getImage(doc))),
            SizedBox(
              height: 5,
            ),
            doneTag.getDoneTag(doc),
//            getItemDetails(doc),
//          getItemDetails3(doc),
            getItemDetails2(doc),
          ],
        ),
      ),
    );
  }

  getItemDetails2(DocumentSnapshot doc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
              top: 8.0, left: 8.0, right: 6.0, bottom: 0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          doc['itemName'] == null ? '' : '${doc['itemName']}',
                          // '${doc.data['item']} ',
                          style: TextStyle(
                            color: Colors.black,
                            // fontWeight: FontWeight.w800,
                            fontSize: 18.0,
                            // color: Colors.grey[300],`
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        showReportDialog(doc.documentID);
                      },
                      child: Icon(
                        Icons.more_vert,
                        color: Colors.grey,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        ExpandablePanel(
          // tapBodyToCollapse: true,
//          iconPlacement: ExpandablePanelIconPlacement.left,
          hasIcon: false,
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              doc.data['itemPrice'] == null || doc.data['itemPrice'] == ''
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        // doc['itemType'] == null
                        //     ? ''
                        //     : doc['itemType'] == 'Item Or Contribution Request'
                        // ?
                        doc['itemType'] == 'Item Or Contribution Request' ||
                                doc['itemType'] == 'Other Requests'
                            ? 'Request'
                            : doc.data['itemType']
                        // :
                        //  '${doc['itemType']}',
                        // '${doc.data['price']}',
                        ,
                        style: TextStyle(fontSize: 12.0, color: Colors.grey),
                      ),
                    )
                  : Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 0.0, right: 0.0, left: 12.0),
                          child: Container(
                            height: 12.0,
                            width: 20.0,
                            child:
//                        Container(),
//                         Image.asset('assets/rupee.png')

                                Image.network(
                                    // 'https://cdn3.iconfinder.com/data/icons/indian-rupee-symbol/800/Indian_Rupee_symbol.png',
                                    'https://tse4.mm.bing.net/th?id=OIP.9oYa51bAuZmZyJ2CDiHfVgHaHa&pid=Api&P=0&w=300&h=300',
                                    // 'https://maxcdn.icons8.com/Share/icon/ultraviolet/Finance/rupee1600.png',
                                    fit: BoxFit.contain),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 0.0),
                          child: Text(
                              doc['itemPrice'] == null
                                  ? ''
                                  : '${doc['itemPrice']}',
                              // '${doc.data['price']}',
                              style: TextStyle(fontSize: 14.0)),
                        ),
                      ],
                    ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
//       Padding(
//         padding: const EdgeInsets.only(left:8.0),
//         child: Icon(Icons.expand_more, color: Colors.grey),
//       ),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, right: 16, bottom: .0, top: 16.0),
                    child: Text(
                      doc['userName'] == null ? '' : 'by ${doc['userName']}',
                      style: TextStyle(
                        color: Colors.grey,
//                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 16),
                    child: Icon(Icons.expand_more, color: Colors.grey),
                  ),
                ],
              )
            ],
          ),
          collapsed: doc.data['itemDescription'] == null ||
                  doc.data['itemDescription'] == ''
              ? Container(height: 16)
              :
//    doc.data['itemDescription'],

              Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, right: 32.0, bottom: 16.0, top: 8.0),
                  child: Text(
                    doc.data['itemDescription'] == null
                        ? 'item description'
                        : doc.data['itemDescription'],
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey,
                    ),
                  ),
                ),
          expanded: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(
                    left: 16.0, right: 32.0, bottom: 22.0, top: 8.0),
                child: Text(
                  doc.data['itemDescription'] == null
                      ? 'item description'
                      : doc.data['itemDescription'],
                  // overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 14.0,
                  ),
                ),
              ),
              // SizedBox(height: 10),
//              Padding(
//                padding:
//                const EdgeInsets.only(left: 16.0, right: 16, bottom: 16.0, top: 8.8),
//                child: Text(
//                  doc['userName'] == null ? '' : '- ${doc['userName']}',
//                  style: TextStyle(
//                    // color: Colors.grey,
//                    // fontWeight: FontWeight.w700,
//                  ),
//                ),
//              ),
              Padding(
                padding:
                    const EdgeInsets.only(left: 14.0, right: 14, bottom: 8.0),
                child: Container(
                  color: Colors.teal,
                  width: double.infinity,
                  child: IconButton(
                    icon: Icon(Icons.call, color: Colors.white),
                    onPressed: () {
                      String userContactNo = doc.data['userContactNo'];
                      if (userContactNo == '') {
                        final snackBar = SnackBar(
                            content: Text('No contact number provided.'));

// Find the Scaffold in the widget tree and use it to show a SnackBar.
                        _scaffoldKey.currentState.showSnackBar(snackBar);
//Scaffold.of(context).showSnackBar(snackBar);
                      } else {
                        launch("tel:$userContactNo");
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );

    // tapHeaderToExpand: true,
    // hasIcon: true,

    // SizedBox(height: 10),
  }

  bool searchOn = false;
  loadSearchList() {
    // reloadP2PList();
    return StreamBuilder<QuerySnapshot>(
      stream: p2pNetworkColRef
          //.where('userInstituteLocation', isEqualTo: this.userInstituteLocation)
          .where('itemSearchQuery',
              arrayContains: enteredSearchQuery.toLowerCase())
          // .orderBy('itemSearchQuery')
          .orderBy('serverTimeStamp', descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          // : do something with the data
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // : do something with the error
          return Text(snapshot.error.toString());
        }
        // : the data is not ready, show a loading indicator
        return Padding(
          padding: const EdgeInsets.all(0.0),
          child: Container(
            // width: 200.0,
            // height: 400.0,
            child: ListView.builder(
              physics: ClampingScrollPhysics(),
              //  controller: _scrollController,
              itemCount: snapshot.data.documents.length + 2,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                if (index == 0) {
                  this.giaItemCount =
                      // snapshot.length;
                      snapshot.data.documents.length;
                  // snapshot.data.documents.length;

                  return totalGiaCount(context, giaItemCount);
                }
                if (index == giaItemCount + 1) {
                  return Container(height: 100);
                } else {
                  DocumentSnapshot docSnap =
                      // snapshot[index-1];
                      snapshot.data.documents[index - 1];
                  print('Snap length $giaItemCount');
                  return buildP2pTemplate(docSnap);
                }

                // return ListTile(
                //   contentPadding: EdgeInsets.all(5),
                //   title: Text(products[index].data['itemName']),
                //   subtitle: Text(
                //       '${products[index].data['userName']} ${products.length}'),
                // );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var children2 = <Widget>[
      // SizedBox(height: 10.0),
      Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Material(
              elevation: 2.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  //     .blue, //use here Colors.white, and in the scaffold-> backgroundColor: Colors.blueGrey[50],
                  // borderRadius: BorderRadius.circular(8),
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: Colors.black.withOpacity(.12),
                  //     offset: Offset(0, 10),
                  //     blurRadius: 8,
                  //   )
                  // ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: 10.0),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text('Institute Location'),
                    ),
                    Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 10.0),
                          child: Icon(
                            Icons.location_on,
                            size: 16.0,
                            color: Colors.black,
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width - 80,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Text(
                              userInstituteLocation,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style:
                                  TextStyle(fontSize: 17.0, color: textColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // SizedBox(height: 8.0),
      hideCard == true
          ? Padding(
              padding: const EdgeInsets.only(right: 12.0, top: 4.0),
              child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        hideCard = hideCard ? false : true;
                      });
                    },
                    child: Text(
                      'Show p2p card',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  )),
            )
          : Padding(
              padding: const EdgeInsets.only(right: 12.0, top: 4.0),
              child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        hideCard = hideCard ? false : true;
                      });
                    },
                    child: Text(
                      'Hide p2p card',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  )),
            ),
      hideCard == true ? Container() : _getAddIteamArea(),

      SizedBox(height: 10.0),

      getSearchBar(),
      SizedBox(height: 10.0),

      buildGiaCategory(),
      SizedBox(
        height: 5.0,
      ),

      // _loadGiaItems(),
      // searchOn

      giaTypeSelected == 'searchQuery' ? loadSearchList() : loadP2PList(),
      SizedBox(height: 10)
    ];
    return Scaffold(
      key: _scaffoldKey,
      // backgroundColor: Colors.teal[50].withOpacity(.2),
      body: Container(
        // color:
        //  Colors.white,
        // Colors.green[100].withOpacity(.4),
        // Colors.blueGrey[100].withOpacity(0.2),
        child: ListView(
          controller: _scrollController
          // widget.scrollController

          ,
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          children: children2,
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () {
          setState(() {
            // fabBtnClicked = true;
            //   print('fab clicked = $fabBtnClicked');
            scrollToTop();
          });
        },
        // scrollToTop,
        child: Icon(Icons.arrow_upward),
      ),
      // _buildStaggeredGiaTemplate();
    );
  }

  Widget loadP2PList() {
    return Padding(
      padding: const EdgeInsets.all(.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20.0)),
        ),
        child: Container(
          // width: 200.0,
          // height: 400.0,
          child: ListView.builder(
            physics: ClampingScrollPhysics(),
            //  controller: _scrollController,
            itemCount: products.length + 2,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              if (index == 0) {
                this.giaItemCount =
                    // snapshot.length;
                    products.length;

                return totalGiaCount(context, giaItemCount);
              }
              if (index == giaItemCount + 1) {
                return Container(height: 100);
              } else {
                DocumentSnapshot docSnap =
                    // snapshot[index-1];
                    products[index - 1];
                print('Snap length ${products.length}');
                return buildP2pTemplate(docSnap);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _getAddIteamArea() {
    return ClipRRect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0.0,

          // color:
          // Colors.white,
          // Colors.green.withOpacity(0.15),
          child: Container(
            padding: EdgeInsets.all(10.0),
            // color: giaCardColor,

            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            'Peer to Peer Network',
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.0,
                                  letterSpacing: .5),
                            ),
                          ),
                          Text(
                            "Just a single post to...",
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              textStyle: TextStyle(
                                  // color: Colors.blue,
                                  letterSpacing: .5),
                            ),
                          ),
                          SizedBox(
                            height: 8.0,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              '•buy/sell/donate items to your peers. ',
                              style: GoogleFonts.lato(
                                color: Colors.white,
                                textStyle: TextStyle(
                                    fontSize: 16.0,
                                    // fontWeight: FontWeight.bold,
                                    // color: Colors.blue,
                                    letterSpacing: .5),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              "(E.g. previous semester books, notes, calculator etc.)",
                              style: GoogleFonts.lato(
                                color: Colors.white,
                                textStyle: TextStyle(
                                    // color: Colors.blue,
                                    letterSpacing: .5),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 8.0,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              "•request item or contribution from your peers.",
                              style: GoogleFonts.lato(
                                color: Colors.white,
                                textStyle: TextStyle(
                                    fontSize: 16.0,
                                    // fontWeight: FontWeight.bold,
                                    // color: Colors.blue,
                                    letterSpacing: .5),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              '(E.g. cab share request, lost item request etc.)',
                              style: GoogleFonts.lato(
                                color: Colors.white,
                                textStyle: TextStyle(
                                    // color: Colors.blue,
                                    letterSpacing: .5),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 8.0,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: InkWell(
                              onTap: () {
                                showDetailsBottomSheet();
                              },
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Text('🔽Explain more',
                                    //textAlign: TextAlign.center,
                                    style: GoogleFonts.lato(
                                      color: Colors.black,
                                      textStyle: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.blueAccent,
                                        letterSpacing: .5,
                                      ),
                                    )),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 4.0,
                    ),
                    //     )),
                  ],
                ),
                SizedBox(height: 15.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      // width: 128,
                      decoration: BoxDecoration(
                        color:
                            // Colors.green,
                            Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        // boxShadow: [BoxShadow(
                        //   color: Colors.grey,
                        //   blurRadius: 3,
                        //   offset: Offset(0,3)
                        // )]
                      ),
                      child: InkWell(
                        // elevation: 3,
                        // color: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Add an Item',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        onTap: () => openAddGiaPage('Item'),
                      ),
                    ),
                    SizedBox(
                      width: 7,
                    ),
                    Container(
                      // width: 128,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        // boxShadow: [BoxShadow(
                        //   color: Colors.grey,
                        //   blurRadius: 3,
                        //   offset: Offset(0,3)
                        // )]
                      ),
                      child: InkWell(
                        // color: Colors.white,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'Make a Request',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        onTap: () => openAddGiaPage('Request'),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 5,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget totalGiaCount(BuildContext context, int length) {
    var giaTypee;
    if (giaTypeSelected == 'All' || giaTypeSelected == 'Others') {
      giaTypee = length <= 1 ? 'Item' : 'Items';
    } else if (giaTypeSelected == 'Item Or Contribution Request') {
      giaTypee = length <= 1 ? 'Request' : 'Requests';
    } else if (giaTypeSelected == 'searchQuery') {
      giaTypee = length <= 1 ? 'Item' : 'Items';
    } else {
      giaTypee = giaTypeSelected;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              searchItemController.text.length >= 0 &&
                      giaTypeSelected == 'searchQuery'
                  ? Text('Search Result: ')
                  : Container(),
              Text(
                length > 9 && length < 11 ? '+9' : '+$length',
                // '${Firestore.instance.collection('lostAndFoundPage').snapshots().length}',
                style: TextStyle(
                  fontSize: 18.0,
                  color: giaCountColor,
                  // fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 7.0),
              Text(
                '$giaTypee',
                // '${Firestore.instance.collection('lostAndFoundPage').snapshots().length}',
                style: TextStyle(
                  fontSize: 18.0,
                  color: giaCountColor,

                  // fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () async {
                await reloadP2PList();

                Fluttertoast.showToast(
                  msg: "Reloaded",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
              })
        ],
      ),
    );
  }

  Widget buildGiaCategory() {
    return Container(
      // color: Colors.black,
      // padding: EdgeInsets.all(4.0),
      height: 50.0,
      width: MediaQuery.of(context).size.width,
      child: ListView(
        padding: EdgeInsets.all(10.0),
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          getGiaChip('All'),
          SizedBox(
            width: 6.0,
          ),
          InkWell(
              onTap: () {
                setState(() {
                  this.giaTypeSelected = "Item Or Contribution Request";
                  this.searchItemController.text = '';
                });
                reloadP2PList();
              },
              child: Chip(
                label: Text(
                  "Requests",
                  style: TextStyle(
                      color: giaTypeSelected == "Item Or Contribution Request"
                          ? Colors.white
                          : Colors.black),
                ),
                backgroundColor:
                    giaTypeSelected == "Item Or Contribution Request"
                        ? Colors.teal.withOpacity(.8)
                        : Colors.grey[300],
                // Colors.blueGrey[50],
              )),
          // getGiaChip('Requests'),
          SizedBox(
            width: 6.0,
          ),
          getGiaChip('Lost & Found Items'),
          SizedBox(
            width: 6.0,
          ),
          getGiaChip('Books'),
          SizedBox(
            width: 6.0,
          ),
          getGiaChip('Stationary'),
          SizedBox(
            width: 6.0,
          ),
          getGiaChip('Electronics'),
          SizedBox(
            width: 6.0,
          ),
          getGiaChip('Others'),
          SizedBox(
            width: 6.0,
          ),
        ],
      ),
    );
  }

  void openAddGiaPage(String itemType) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (context) => MyAddP2PItemPage(itemType)));
  }

  queryGiaItemsByCategory() {
    print('giaType clicked: $giaTypeSelected');

    return p2pNetworkColRef
        //.where('userInstituteLocation', isEqualTo: userInstituteLocation)
        .where(
          'itemType',
          isEqualTo: giaTypeSelected,
        )
        // .orderBy('itemType', descending: false)

        // .orderBy('userInstituteLocation', descending: false)
        .orderBy('serverTimeStamp', descending: true);

    // .listen((onData){

    // }).onError((handleError){
    //   print(handleError.toString());
    // });

    // return

    // p2pColRef
    //     .where('itemType', isEqualTo: giaTypeSelected)
    //     .where('userInstituteLocation', isEqualTo: widget.userInstituteLocation)
    //     // .orderBy('itemType')
    //     .orderBy('serverTimeStamp', descending: true)
    //     .snapshots();

    //   .listen((query){
    // print('query on $giaType done. ${query.documents.length} $giaType');
    //   });
    //   .then((QuerySnapshot querySnapshot) {
    // print('query on $giaType done. ${querySnapshot.documents.length} $giaType');
  }

  getGiaChip(String clickedGiaType) {
    return InkWell(
      onTap: () {
        setState(() {
          if (clickedGiaType == 'Requests') {
            this.giaTypeSelected = "Item Or Contribution Request";
            clickedGiaType = "Item Or Contribution Request";
            this.giaTypeSelected = clickedGiaType;

            this.searchItemController.text = '';
          } else
            this.giaTypeSelected = clickedGiaType;
          this.searchItemController.text = '';
        });

        reloadP2PList();
      },
      child: Chip(
        label: Text(
          clickedGiaType,
          style: TextStyle(
              color: giaTypeSelected == clickedGiaType
                  ? Colors.white
                  : Colors.black),
        ),
        backgroundColor: giaTypeSelected == clickedGiaType
            ? Colors.teal.withOpacity(.8)
            : Colors.grey[300],
        // Colors.blueGrey[50],
      ),
    );
  }

  //parthiv get image
  bool isImageExpanded = false;
  var imageContainerHeight = 200.0;
  var tappedImage;
  var imagefit = BoxFit.cover;

  getImage(doc) {
    return InkWell(
      onTap: () {
        setState(() {
          this.imageContainerHeight = 400.0;
          this.imagefit = BoxFit.contain;

          this.tappedImage = doc['itemImage'];

          if (tappedImage != doc['itemImage']) {
            this.isImageExpanded = false;
          }

          isImageExpanded = isImageExpanded ? false : true;
          // if (isImageExpanded == false) {
          //   this.isImageExpanded = true;
          // } else {
          //   this.isImageExpanded = false;
          // }
        });
      },
      child: AnimatedContainer(
        // color: Colors.blue,
        duration: Duration(milliseconds: 1000),
        curve:

            // Curves.easeIn,
            Curves.fastOutSlowIn,
        width: double.infinity,

        height: doc['itemImage'] == '' || doc['itemImage'] == 'itemImage'
            ? 0.0
            :
            // isImageExpanded
            //     ? tappedImage == doc['eventImage'] ? imageContainerHeight : 100.0
            //     : 100.0,

            tappedImage == doc['itemImage']
                ? isImageExpanded ? imageContainerHeight : 200.0
                : 200.0,
        // color: Colors.cyan,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 0.0),
          child: SizedBox(
            child: doc['itemImage'] == ''
                ? Container()
                : Stack(
                    children: <Widget>[
                      Center(child: CircularProgressIndicator()),
                      SizedBox.expand(
                        child: FadeInImage.memoryNetwork(
                          placeholder:
                              //  Image.network('http://entechdesigns.com/new_site/wp-content/themes/en-tech/images/not_available_icon.jpg'),

                              kTransparentImage,
                          image: "${doc['itemImage']}",
                          fit: tappedImage == doc['itemImage']
                              ? isImageExpanded ? imagefit : BoxFit.cover
                              : BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  //parthiv get image

  // getImage(doc) {
  //   try {
  //     return FadeInImage.memoryNetwork(
  //       //height: 250,
  //       // width: 580,
  //       placeholder:
  //           //  Image.network('http://entechdesigns.com/new_site/wp-content/themes/en-tech/images/not_available_icon.jpg'),

  //           kTransparentImage,
  //       image: doc.data['itemImage'],
  //       fit: BoxFit.contain,
  //     );
  //   } catch (e) {
  //     print(e.toString);
  //   }
  // }

  void showDetailsBottomSheet() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return ListView(
            children: [
              SizedBox(
                height: 20,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  // height: 350,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          width: 0.5,
                          style: BorderStyle.solid,
                          color: Colors.white),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.blue.withOpacity(0.5), blurRadius: 10)
                      ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: 20),
                      Text(
                        "Peer to Peer (p2p) Network.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.teal,
                            fontSize: 20,
                            fontWeight: FontWeight.w700),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                            Colors.white,
                            Colors.teal[100],
                            Colors.teal[100],
                            Colors.white
                          ])),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      detailsTemplate(
                        'Buy/Sell/Donate An Item',
                        "- Sell your previous semester books to your juniours."
                            "\n\n- No longer need your workshop dress?"
                            "\n\n- Have an extra calculator?"
                            "\n\n- In mood for some charity? Give away your previous notes to some needy soul :)"
                            "\n\n- Have a big heart? Well, don't sell it... Share it! (alongwith this app :)\n\n",
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      requestDetailsTemplate(),
                      SizedBox(
                        height: 8,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
            ],
          );
        });
  }

  detailsTemplate(String heading, String desc) {
    return ExpansionTile(
      title: Text(
        heading,
        style: TextStyle(color: Colors.black, fontSize: 15),
      ),
      children: <Widget>[
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 10), child: Text(desc)),
      ],
    );
  }

  requestDetailsTemplate() {
    return ExpansionTile(
      title: Text(
        'Request an Item or Contribution',
        style: TextStyle(color: Colors.black, fontSize: 15),
      ),
      children: <Widget>[
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: <Widget>[
                RichText(
                  text: TextSpan(
                    text: "- In need for ",
                    style: TextStyle(
                      fontSize: 15.0,
                      color: Colors.black,
                      // fontWeight: FontWeight.bold
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: "cab share? ",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            "Make a request to all your college peers with a single post to see who is available! ",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: "\n\n- Lost something?",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            " (E.g. your wallet) With just one post let your entire college know. (Then wait with your finger crossed.) ",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: '\n\n- Need a ',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.normal),
                      ),
                      TextSpan(
                        text: 'book (semester book, novels etc.)? ',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: "Check if your peers got it!",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: '\n\n- Participating in some ',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      TextSpan(
                        text: "hackathon ",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: "or ",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: "competition ",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: "but lack team members? ",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.normal),
                      ),
                      TextSpan(
                        text: "Make a ",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.normal),
                      ),
                      TextSpan(
                        text: "Team Search request!",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: '\n\n- Flatmate search request',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.normal),
                      ),
                      TextSpan(
                          text: '\n\n- Senior help request\n\n'
                              '- Blood donation request\n\n'),
                      TextSpan(
                        text: " \n\n- Need someone to do your ",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.normal),
                      ),
                      TextSpan(
                        text: "assignment? ",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: "(just kidding) ",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //   children: <Widget>[
                //     SizedBox(
                //       width: 20.0,
                //     ),
                //     Expanded(
                //       child: Text(
                //         desc,
                //         style: TextStyle(color: Colors.black, fontSize: 15),
                //       ),
                //     ),
                //   ],
                // ),
              ],
            )),
      ],
    );
  }

  var searchItemController = TextEditingController();
  var enteredSearchQuery = '';
  getSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 7.0, left: 4.0, right: 4.0),
      child: Card(
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            30.0,
          ),
        ),
        child: Container(
          height: 50.0,
          // color: Colors.white,
          decoration: BoxDecoration(
            color:
                // Colors.white,
                // Colors.green,
                Colors.blueGrey[50],
            // Colors.green[50],
            // Colors.grey[200],
            //use here Colors.white, and in the scaffold-> backgroundColor: Colors.blueGrey[50],
            borderRadius: BorderRadius.circular(30),

            // border: Border.all(
            //     color: Colors.black12, style: BorderStyle.solid, width: 0.75),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.15),
                offset: Offset(0, 10),
                blurRadius: 8,
              )
            ],
          ),

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: searchItemController,
              onChanged: (String enteredSearchQuery) {
                setState(() {
                  this.giaTypeSelected =
                      // searchItemController.text.length == 0
                      // ? this.giaTypeSelected = 'All'
                      // :
                      'searchQuery';
                  this.enteredSearchQuery = enteredSearchQuery;
                  // this.searchOn = true;
                  // reloadP2PList();
                });
              },
              // controller: lnfSearchController,
              // keyboardType: TextInputType.number,
              decoration: InputDecoration(
                focusColor: Colors.indigo[50],
                // Colors.green,
                // labelText: "Search...",
                // labelStyle: TextStyle(color: Colors.white),
                hintText: "Search Items, Requests, lost Items...",
                // hintStyle: Colors.white,
                border: InputBorder.none,
                fillColor: Colors.white,
                // border: OutlineInputBorder(
                //     borderRadius: BorderRadius.circular(4.0)),
              ),
            ),
          ),

          // decoration: BoxDecoration(
          //     color: Colors
          //         .white, //use here Colors.white, and in the scaffold-> backgroundColor: Colors.blueGrey[50],
          //     borderRadius: BorderRadius.circular(8),
          //     boxShadow: [
          //       BoxShadow(
          //         color: Colors.black.withOpacity(.12),
          //         offset: Offset(0, 10),
          //         blurRadius: 30,
          //       )
          //     ]),
        ),
      ),
    );
  }

  void showReportDialog(String docId) {
    var alertDialog = AlertDialog(
      title: Text("Report this?"),
      content: Text(
          "If this post contains some inappropriate content, kindly report this to us.\n\nLet's keep Yozznet clean :)"),
      actions: <Widget>[
        FlatButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel')),
        FlatButton(
            onPressed: () {
              reportTheDoc(docId);
            },
            child: Text('Report')),
      ],
    );
    showDialog(
        context: context,
        //builder: (BuildContext context){ // builder returns a widget
        //return alertDialog;
        //}

        builder: (BuildContext context) => alertDialog);
  }

  void reportTheDoc(String docId) {
    p2pNetworkColRef.document(docId).updateData({
      'reported': true,
    }).then((_) {
      Navigator.pop(context);
      Fluttertoast.showToast(
        msg: "Thank you for reporting. We'll look into this.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }).catchError((e) {
      print(e.toString());
      Fluttertoast.showToast(
        msg: "Coundn't report. Check connection.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    });
  }

  getItemDetails(doc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
              top: 6.0, left: 8.0, right: 14.0, bottom: 0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          doc['itemName'] == null ? '' : '${doc['itemName']}',
                          // '${doc.data['item']} ',
                          style: TextStyle(
                            color: Colors.black,
                            // fontWeight: FontWeight.w800,
                            fontSize: 18.0,
                            // color: Colors.grey[300],`
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  showReportDialog(doc.documentID);
                },
                child: Icon(
                  Icons.more_vert,
                  color: Colors.grey,
                ),
              )
            ],
          ),
        ),
        doc.data['itemPrice'] != null || doc.data['itemPrice'] != ''
            ? Row(
                children: <Widget>[
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 0.0, right: 0.0, left: 12.0),
                    child: Container(
                      height: 12.0,
                      width: 20.0,
                      child:
//                        Container(),
//                         Image.asset('assets/rupee.png')

                          Image.network(
                              'https://cdn3.iconfinder.com/data/icons/indian-rupee-symbol/800/Indian_Rupee_symbol.png',
//                             'https://tse4.mm.bing.net/th?id=OIP.9oYa51bAuZmZyJ2CDiHfVgHaHa&pid=Api&P=0&w=300&h=300',
                              // 'https://maxcdn.icons8.com/Share/icon/ultraviolet/Finance/rupee1600.png',
                              fit: BoxFit.contain),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 0.0),
                    child: Text(
                        doc['itemPrice'] == null ? '' : '${doc['itemPrice']}',
                        // '${doc.data['price']}',
                        style: TextStyle(fontSize: 14.0)),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  // doc['itemType'] == null
                  //     ? ''
                  //     : doc['itemType'] == 'Item Or Contribution Request'
                  // ?
                  doc['itemType'] == 'Item Or Contribution Request' ||
                          doc['itemType'] == 'Other Requests'
                      ? 'Request'
                      : doc.data['itemType']
                  // :
                  //  '${doc['itemType']}',
                  // '${doc.data['price']}',
                  ,
                  style: TextStyle(fontSize: 12.0, color: Colors.grey),
                ),
              )

//         giaTypeSelected == 'All' ||
//                 giaTypeSelected == 'searchQuery' ||
//                 giaTypeSelected == 'Requests'
//             ? doc['itemType'] == 'Item Or Contribution Request' ||
//                     doc.data['itemType'] == 'Lost & Found Items' ||
//                     doc['itemType'] == 'Item Request' ||
//                     doc.data['itemType'] == 'Contribution Request' ||
//                     doc['itemType'] == 'Item Request' ||
//                     doc.data['itemType'] == 'Other Request'
//                 ? Padding(
//                     padding: const EdgeInsets.only(left: 16.0),
//                     child: Text(
//                       // doc['itemType'] == null
//                       //     ? ''
//                       //     : doc['itemType'] == 'Item Or Contribution Request'
//                       // ?
//                       doc['itemType'] == 'Item Or Contribution Request' ||
//                               doc['itemType'] == 'Other Requests'
//                           ? 'Request'
//                           : doc.data['itemType']
//                       // :
//                       //  '${doc['itemType']}',
//                       // '${doc.data['price']}',
//                       ,
//                       style: TextStyle(fontSize: 12.0, color: Colors.grey),
//                     ),
//                   )
//                 // : Container()
//                 // ,
//                 // doc.data['itemType'] == 'Item Or Contribution Request' ||
//                 //         doc.data['itemType'] == 'Lost & Found Items'
//                 //     ? Container()
//                 : Row(
//                     children: <Widget>[
//                       Padding(
//                         padding: const EdgeInsets.only(
//                             top: 0.0, right: 0.0, left: 12.0),
//                         child: Container(
//                           height: 12.0,
//                           width: 20.0,
//                           child:
// //                        Container(),
// //                         Image.asset('assets/rupee.png')

//                               Image.network(
//                                   // 'https://cdn3.iconfinder.com/data/icons/indian-rupee-symbol/800/Indian_Rupee_symbol.png',
//                                   'https://tse4.mm.bing.net/th?id=OIP.9oYa51bAuZmZyJ2CDiHfVgHaHa&pid=Api&P=0&w=300&h=300',
//                                   // 'https://maxcdn.icons8.com/Share/icon/ultraviolet/Finance/rupee1600.png',
//                                   fit: BoxFit.contain),
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.only(top: 0.0),
//                         child: Text(
//                             doc['itemPrice'] == null
//                                 ? ''
//                                 : '${doc['itemPrice']}',
//                             // '${doc.data['price']}',
//                             style: TextStyle(fontSize: 14.0)),
//                       ),
//                     ],
//                   )
//             : Container(),

        // SizedBox(height: 10),
        ,
        ExpansionTile(
          title: InkWell(
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                // color: Colors.green,

                child: Text(
                  doc['userName'] == null ? '' : '${doc['userName']}',
                  style: TextStyle(
                    color: Colors.grey,
                    // fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          children: <Widget>[
            doc.data['itemDescription'] == null ||
                    doc.data['itemDescription'] == ''
                ? Container()
                : Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, right: 8.0, bottom: 4.0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(doc.data['itemDescription'] == null
                            ? 'item description'
                            : doc.data['itemDescription'])),
                  ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                color: Colors.teal,
                width: double.infinity,
                child: IconButton(
                  icon: Icon(Icons.call, color: Colors.white),
                  onPressed: () {
                    String userContactNo = doc.data['userContactNo'];
                    launch("tel:$userContactNo");
                  },
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Future reloadP2PList() async {
    setState(() {
      // isLoading = true;
      // if (giaTypeSelected != 'searchQuery') {
      hasMore = true;
      products.clear();
      lastDocument = null;

//      if(mounted){
//        print('mounted $mounted');
//        getP2pData();
//        loadP2PList();
//      }
      getP2pData();
      loadP2PList();

      // }
    });
  }
}
