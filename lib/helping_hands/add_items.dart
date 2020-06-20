//add items here.
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'info_btm_sheet.dart';

class MyAddP2PItemPage extends StatefulWidget {
  final String itemType;
  MyAddP2PItemPage(this.itemType, {Key key}) : super(key: key);

  @override
  _MyAddP2PItemPageState createState() => _MyAddP2PItemPageState();
}

class _MyAddP2PItemPageState extends State<MyAddP2PItemPage> {
//image picker

  MyInfoBtmSheet myInfoBtmSheet = new MyInfoBtmSheet();

  File _imageFile;
  File compressedImage;

  var userNameController = TextEditingController();

  var isPosting = false;

  var phoneController = TextEditingController();

  Future pickImage(ImageSource imageSource) async {
    var image = await ImagePicker.pickImage(
      source: imageSource,
      imageQuality: 20,
    );

    setState(() {
      _imageFile = image;

      print('image before compress: ${image?.lengthSync()}');

      print('compressedimagesize: ${_imageFile?.lengthSync()}');

      print(_imageFile?.lengthSync());
    });
  }
//image picker ends

//image compressor

  Future<File> getCompressedImage(File image, String targetPath) async {
    var compressedImage = await FlutterImageCompress.compressAndGetFile(
      image.path, image.path,
      quality: 20,
      // rotate: 180,
    );

    print('image before compress: ${image.lengthSync()}');
    print('image after compress: ${compressedImage.lengthSync()}');
    return compressedImage;
  }

  var _formKey = GlobalKey<FormState>();
  bool isUploading = false;
  TextEditingController _giaItemNameController = TextEditingController();

  TextEditingController _itemDescriptionController = TextEditingController();

  TextEditingController _itemPriceController = TextEditingController();

  //drop down
  var giaItemTypeList = [
    "Books",
    "Stationary",
    "Others",
    "Item Or Contribution Request"
  ];
  String currentGiaTypeSelected = "";
  //drop down ends

  String userPhoneNo = '';
  String userContactNo = '';
  String userName = '';
  String fetchedUserName = '';
  String userInstituteLocation = '';

  FirebaseUser user;

  CollectionReference userProfileCollection =
      Firestore.instance.collection('userProfile');

  StreamSubscription<DocumentSnapshot> profileColSubscription;

  loadProfileData(FirebaseUser user) async {
    profileColSubscription = userProfileCollection
        .document('${user.uid}')
        .snapshots()
        .listen((profileDataSnap) {
      if (profileDataSnap.exists) {
        print('profile data exists');
        setState(() {
          userNameController.text = this.userName =
              profileDataSnap.data['userName'] == null
                  ? ''
                  : profileDataSnap['userName'];
          this.fetchedUserName = userName;
          debugPrint('Inside Gia Add Item Page -- name: $userName');
          this.userInstituteLocation =
              profileDataSnap.data['userInstituteLocation'];
          phoneController.text =
              this.userPhoneNo = profileDataSnap.data['userPhoneNo'];

          this.userContactNo = this.userPhoneNo;

          // nameController.text = this.name;
        });
      } else {
        print('profile data does not exist');
      }
    });
  }

  void updateProfileData() {
    userProfileCollection
        .document('${user.uid}')
        .updateData({'userName': userNameController.text}).then((_) {
      print('profile data saved');
      final snackBar = SnackBar(content: Text('Your data has been saved.'));
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }).catchError((e) {
      print(e.toString());
    });
  }

  String itemTypeSelected = '';
  @override
  void initState() {
    super.initState();
    // itemTypeSelected =
    //     widget.itemType == 'Item' ? '' : 'Item Or Contribution Request';

    currentGiaTypeSelected = giaItemTypeList[0];

    //get user
    try {
      FirebaseAuth.instance.currentUser().then((user) {
        if (user != null) {
          setState(() {
            print('user is ${user.uid}');
            this.user = user;
            this.userPhoneNo = user.phoneNumber;
          });
          loadProfileData(user);
        } else {
          print('user is $user');
        }
      }).catchError((e) {
        print(e.toString());
      });
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  void dispose() {
    profileColSubscription?.cancel();
    phoneController?.dispose();
    userNameController?.dispose();
    _giaItemNameController?.dispose();
    _itemDescriptionController?.dispose();
    _itemPriceController?.dispose();
    super.dispose();
  }

  Widget _addPhoto() {
    return Center(
      child: _imageFile == null
          ? Container(
              height: 200.0,
              child: Center(
                  child: Text(widget.itemType == 'Item'
                      ? 'No image selected.\n  (Image required)'
                      : 'No image selected.\n       (Optional)')))
          :
          // height: 400.0,
          // width: MediaQuery.of(context).size.width,
          Container(
              height: 400.0,
              child: Image.file(
                _imageFile,
                fit: BoxFit.contain,
              ),
            ),
    );
  }

  Widget _textFormFieldTemplate(
      String labelText, String hintText, TextEditingController controller) {
    // if (currentGiaTypeSelected == giaItemTypeList[3]) {
    //   if (controller == _giaItemNameController) {
    //     hintText = 'Eg. Cab share';
    //   }
    //   if (controller == _itemPriceController) {
    //     hintText = '';
    //   }
    //   if (controller == _itemDescriptionController) {
    //     hintText = 'Eg. At airport, time 5 pm';
    //   }
    // }

    return Container(
      child: TextFormField(
          validator: (String value) {
            // if (controller != _whatsAppController) {
            if (value.isEmpty) {
              return "required";
            } else
              return null;
            // }
          },
          controller: controller,

          // textInputAction: TextInputAction.newline,
          // keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            // if(currentGiaTypeSelected== giaItemTypeList[3]){
            //   if(ccontroller == _giaItemController? ){
            //     hintText='Eg. Cab share'
            //   }
            // }
            // currentGiaTypeSelected== giaItemTypeList[3]
            // ?controller == _giaItemController?  hintText='Eg. Cab share': hintText: hintText,
            errorStyle: TextStyle(color: Colors.red, fontSize: 14.0),
//            border: InputBorder.none,
//                OutlineInputBorder(borderRadius: BorderRadius.circular(4.0)),
          )),
    );
  }

  setSearchParam(String searchQuery) {
    List<String> searchQueryList = List();
    String temp = "";
    int shortLength = searchQuery.length > 17 ? 17 : searchQuery.length;
    for (int i = 0; i < shortLength; i++) {
      temp = temp + searchQuery[i];
      searchQueryList.add(temp);
    }
    return searchQueryList;
  }

  void _postItem(String uploadedItemImageUrl) {
    setState(() {
      isUploading = true;
    });

    Firestore.instance.collection("p2pNetwork").add({
      'itemName': _giaItemNameController.text,
      'itemDescription': _itemDescriptionController.text,
      'itemPrice': _itemPriceController.text,
      'itemImage': uploadedItemImageUrl,
      'itemType': itemTypeSelected,

      'itemSearchQuery':
          setSearchParam(_giaItemNameController.text.toLowerCase()),

      //user's contact
      //'userId': user.uid,
      'userName': this.userName,
      'userPhoneNo': this.userPhoneNo,
      'userContactNo': this.userContactNo == '' ? '' : this.userContactNo,
      //'userInstituteLocation': this.userInstituteLocation,
      //user's contact

      'serverTimeStamp': FieldValue.serverTimestamp()
    }).then((_) {
      //if (fetchedUserName == '' || fetchedUserName == null) updateProfileData();

      Future.delayed(Duration(seconds: 2)).then((_) {
        setState(() {
          uploaded = true;
          // isUploading = false;
        });
        // isPosting = false;
        resetPage();
      }).catchError((e) {
        print(e.toString());
      });
    }).catchError((e) => print(e));
  }

  void resetPage() {
    _itemPriceController.text = '';
    _itemDescriptionController.text = '';
    _giaItemNameController.text = '';
    currentGiaTypeSelected = giaItemTypeList[0];

    _imageFile = null;
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool uploaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.teal,
          title:
              Text(widget.itemType == 'Item' ? 'Add Item' : 'Make A Request'),
        ),
        body: isUploading ? showProgressScreen() : bodyContent());
  }

  Widget bodyContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: <Widget>[
            SizedBox(
              height: 5.0,
            ),

            Center(
                child: Text(
              widget.itemType == 'Item'
                  ? 'Add item to sell/donate to your peers'
                  : ' ',
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
            _addPhoto(),

            Container(
                child: Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        SizedBox(
                          width: 8.0,
                        ),
                        Container(
                            // color: Colors.blue,
                            child: Text(
                          (widget.itemType == 'Item'
                              ? 'Add Image'
                              : 'Add Image (optional)'),
                          style: TextStyle(fontSize: 16.0),
                          textAlign: TextAlign.start,
                        )),
                        IconButton(
                          icon: Icon(Icons.add_a_photo),
                          onPressed: () {
                            pickImage(ImageSource.camera);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.photo_library),
                          onPressed: () {
                            pickImage(ImageSource.gallery);
                          },
                        ),
                        Spacer()
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Align(
                          alignment: Alignment.topLeft,
                          child: widget.itemType == 'Item'
                              ? Text(
                                  'Choose Item Type',
                                  style: TextStyle(fontSize: 16.0),
                                )
                              : Row(
                                  children: <Widget>[
                                    Text(
                                      'Choose Request Type',
                                      style: TextStyle(fontSize: 16.0),
                                    ),
                                    SizedBox(
                                      width: 8.0,
                                    ),
                                    FlatButton(
                                      onPressed: () {
                                        showDetailsBottomSheet();
                                      },
                                      child: Icon(Icons.help),

                                      //  Text(
                                      //     'what\'s this?🔽',
                                      //     style: TextStyle(
                                      //         fontSize: 14.0, color: Colors.blue),
                                      //   ),
                                    ),
                                  ],
                                )),
                    ),
                    Row(
                      children: <Widget>[
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: widget.itemType == 'Item'
                                ? getGiaCategory()
                                : getRequestsCategory()
                            //  _addDropdown(),
                            ),
                      ],
                    ),
                    SizedBox(
                      height: 7.0,
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 2,
                          child: Container(
                            width: 100.0,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: _textFormFieldTemplate(
                                  widget.itemType == 'Item'
                                      ? "Item Name"
                                      : "Add Request",
                                  widget.itemType == 'Item'
                                      ? "E.g. xyz Book"
                                      : "E.g. Cab share",
                                  _giaItemNameController),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FlatButton(
                              child: Text(
                                'Tip',
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontStyle: FontStyle.italic),
                              ),
                              onPressed: () {
                                myInfoBtmSheet.showInfoBtmShet(
                                  context,
                                  'Keep the item/request name short and precise.',
                                  '\nThe \"first word\" will be used by others to search for your item/request.',
                                  '\nThink what a person would search in the search bar while '
                                      'looking for your item/request.',
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 7.0,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 7.0,
                    ),

                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Row(
                        children: <Widget>[
                          Container(
                            height: 25.0,
                            width: 25.0,
                            child: widget.itemType == 'Item'
                                ? Image.network(
                                    'https://cdn3.iconfinder.com/data/icons/indian-rupee-symbol/800/Indian_Rupee_symbol.png',
                                    // 'https://maxcdn.icons8.com/Share/icon/ultraviolet/Finance/rupee1600.png',
                                    fit: BoxFit.contain)
                                : Container(),
                          ),
                          SizedBox(
                            width: 4.0,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: Container(
                                // width: 100.0,
                                child: widget.itemType == 'Item'
                                    ? _textFormFieldTemplate(
                                        "Price",
                                        "E.g. Free, or 100",
                                        _itemPriceController)
                                    : Container(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 7.0,
                    ),

                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Container(
                        child: TextFormField(
                            controller: _itemDescriptionController,

                            // textInputAction: TextInputAction.newline,
                            // keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              labelText: "Description (optional)",
                              hintText: widget.itemType == 'Item'
                                  ? "E.g. It's in good condition. Never used ;) "
                                  : '',
                              // if(currentGiaTypeSelected== giaItemTypeList[3]){
                              //   if(ccontroller == _giaItemController? ){
                              //     hintText='Eg. Cab share'
                              //   }
                              // }
                              // currentGiaTypeSelected== giaItemTypeList[3]
                              // ?controller == _giaItemController?  hintText='Eg. Cab share': hintText: hintText,
                              errorStyle:
                                  TextStyle(color: Colors.red, fontSize: 14.0),
//                            border: OutlineInputBorder(
//                                borderRadius: BorderRadius.circular(4.0)),
                            )),
                      ),
                    ),
                    // _textFormFieldTemplate(
                    //     "Add Description (optional)",
                    //     "Eg. It's in good condition. Never used ;) ",
                    //     _descriptionController),
                  ],
                ),
              ),
            )),
            SizedBox(
              height: 16.0,
            ),

            Container(
              child: Card(
                elevation: 2.0,
                // color: Colors.blue[50],
                // . withOpacity(.2),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('Your Contact',
                            style: TextStyle(fontSize: 24.0)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Name:',
                              ),
                            ),
                            this.userName != ''
                                ? Expanded(flex: 2, child: Text(userName))
                                : Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      // clubName,
                                      validator: (value) {
                                        setState(() {
                                          this.userName = value;
                                        });
                                        if (value.isEmpty)
                                          return 'Required';
                                        else
                                          return null;
                                      },
                                      controller: userNameController,

                                      decoration: InputDecoration(
                                          hintText: 'Write your name'),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Text('Contact No:'),
                                  InkWell(
                                      onTap: () {
                                        myInfoBtmSheet.showInfoBtmShet(
                                            context,
                                            'Uncomfortable sharing your phone no?',
                                            "\nWe understand.\nWe are working on the chat feature!\n"
                                                "\nFor now provide some form of contact like your email in the description.\n"
                                                "\nJust kidding.",
                                            "\nProvide your friend's contact(upon agreement) or "
                                                "your Fb Messenger id, "
                                                "Instagram id, etc.");
                                      },
                                      child: Icon(Icons.help)),
                                ],
                              ),
                            ),
                            Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: phoneController,
                                  onChanged: (enteredPhoneNo) {
                                    setState(() {
                                      this.userContactNo = enteredPhoneNo;
                                    });
                                  },
                                )
                                //  Text(phoneNo),
                                ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Institute Location:',
                              ),
                            ),
                            Expanded(
                              child: Text(userInstituteLocation),
                              flex: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Padding(

            isUploading
                ? Center(child: CircularProgressIndicator())
                : RaisedButton(
                    color: Colors.teal,
                    child: Text(
                        widget.itemType == 'Item'
                            ? 'Post Item'
                            : 'Post Request',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      if (_imageFile == null) {
                        if (widget.itemType == 'Item') {
                          final snackBar = SnackBar(
                              content: Text('Please choose an Item Image'));

                          // Find the Scaffold in the widget tree and use it to show a SnackBar.
                          _scaffoldKey.currentState.showSnackBar(snackBar);
                          //Scaffold.of(context).showSnackBar(snackBar);
                          return;
                        } else if (itemTypeSelected == '') {
                          final snackBar = SnackBar(
                              content: Text('Please choose a Request Type'));

                          // Find the Scaffold in the widget tree and use it to show a SnackBar.
                          _scaffoldKey.currentState.showSnackBar(snackBar);
                          //Scaffold.of(context).showSnackBar(snackBar);

                        } else {
                          // setState(() {
                          if (_formKey.currentState.validate()) {
                            // showProgressDialog(context);

                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                // return object of type Dialog
                                return AlertDialog(
                                  title: new Text("Disclaimer",
                                      style: TextStyle(color: Colors.black87)),
                                  content: new Text(
                                      "Do you accept responsibility that the given details "
                                      "are true to the best of your knowledge "
                                      "& don't contain any inappropriate content?",
                                      style: TextStyle(color: Colors.black54)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(18.0)),
                                  actions: <Widget>[
                                    // usually buttons at the bottom of the dialog
                                    new FlatButton(
                                      child: new Text(
                                        "No, edit post",
                                        style:
                                            TextStyle(color: Colors.redAccent),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    new FlatButton(
                                      child: new Text("Yes"),
                                      onPressed: () {
                                        setState(() {
                                          isUploading = true;

                                          _postItem('');
                                        });
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                          // });
                        }
                      } else if (itemTypeSelected == '') {
                        final snackBar = SnackBar(
                            content: Text('Please choose an Item Type'));

                        // Find the Scaffold in the widget tree and use it to show a SnackBar.
                        _scaffoldKey.currentState.showSnackBar(snackBar);
                        //Scaffold.of(context).showSnackBar(snackBar);

                      } else {
                        // setState(() {
                        if (_formKey.currentState.validate()) {
                          // showProgressDialog(context);

                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              // return object of type Dialog
                              return AlertDialog(
                                title: new Text("Disclaimer",
                                    style: TextStyle(color: Colors.black87)),
                                content: new Text(
                                    "Do you accept responsibility that the given details "
                                    "are true to the best of your knowledge "
                                    "& don't contain any inappropriate content?",
                                    style: TextStyle(color: Colors.black54)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0)),
                                actions: <Widget>[
                                  // usually buttons at the bottom of the dialog
                                  new FlatButton(
                                    child: new Text(
                                      "No, edit post",
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  new FlatButton(
                                    child: new Text("Yes"),
                                    onPressed: () {
                                      setState(() {
                                        _startUpload(_imageFile);
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        }
                        // });
                      }
                    },
                  ),

            // isUploading
            //     ? CircularProgressIndicator()
            //     : RaisedButton(
            //         color: Colors.blue,
            //         child: Text('Post Your Gia Item',
            //             style: TextStyle(color: Colors.white)),
            //         onPressed: () {

            //           if (_imageFile == null) {
            //             final snackBar =
            //                 SnackBar(content: Text('please select an image'));

            //             // Find the Scaffold in the widget tree and use it to show a SnackBar.
            //             _scaffoldKey.currentState.showSnackBar(snackBar);
            //             //Scaffold.of(context).showSnackBar(snackBar);
            //           } else {
            //             setState(() {
            //               if (_formKey.currentState.validate()) {
            //                 _startUpload(_imageFile);
            //               }
            //             });
            //           }
            //           // _postGiaItem();
            //         },
            //       ),
            SizedBox(
              height: 40.0,
            )
          ],
        ),
      ),
    );
  }

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
                        "Make A Request to your peers.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.lightBlue,
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
                            Colors.lightBlue[100],
                            Colors.lightBlue[100],
                            Colors.white
                          ])),
                        ),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('ITEM REQUEST:'
                                '\n\n- Eg Books, stationary items, workshop dress, calculator etc.\n\n'),
                            Text('CONTRIBUTION REQUEST:'
                                '\n\n- Eg Cab Share request,\n- Flatmate search request(if living in apartment)'
                                '\n- Participating in some hackathon or competition but lack team members?'
                                'Make a Team Search request!\n'
                                '- Senior help request\n'
                                '- Blood donation request\n'
                                '- Need someone to do your assignment? (Just Kidding)'
                                '- etc\n\n'),
                            Text('LOST AND FOUND REQUEST:'
                                '\n\n- E.g. if lost or found an item eg someone\'s wallet, id card, watch etc')
                          ],
                        ),
                      ),
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
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                SizedBox(
                  width: 20.0,
                ),
                Expanded(
                  child: Text(
                    desc,
                    style: TextStyle(color: Colors.black, fontSize: 15),
                  ),
                ),
              ],
            )),
      ],
    );
  }

  // String itemTypeSelected = widget.itemType == 'Item'? 'Books' : 'Item Request';

  Widget getGiaCategory() {
    return Container(
      // color: Colors.black,
      // padding: EdgeInsets.all(4.0),
      height: 40.0,
      width: MediaQuery.of(context).size.width - 56,
      child: ListView(
        padding: EdgeInsets.all(.0),
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          // getGiaChip('Requests'),

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

  String requestSubType = '';
  getRequestChip(String requestTypeSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          this.itemTypeSelected = "Item Or Contribution Request";

//              requestTypeSelected;
//          "Item Or Contribution Request";
          // this.itemTypeSelected = 'Lost & Found Request';
          this.requestSubType = requestTypeSelected;
          print('requesttypeselected $requestTypeSelected');
          print('item type seleced $itemTypeSelected');
        });
      },
      child: Chip(
          label: Text(
            requestTypeSelected,
            style: TextStyle(
              color: requestSubType == requestTypeSelected
                  // itemTypeSelected == requestTypeSelected
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          backgroundColor:
              // requestSubType == requestTypeSelected
              requestSubType == requestTypeSelected
                  ? Colors.teal.withOpacity(.8)
                  : Colors.grey[300]),
    );
  }

  Widget getRequestsCategory() {
    return Container(
      // color: Colors.black,
      // padding: EdgeInsets.all(4.0),
      // height: 40.0,
      width: MediaQuery.of(context).size.width - 56,
      child: Wrap(
        // spacing: 8.0, // gap between adjacent chips
        // runSpacing: 4.0, // ga
        // padding: EdgeInsets.all(4.0),
        // shrinkWrap: true,
        // physics: ClampingScrollPhysics(),
        // scrollDirection: Axis.horizontal,
        children: <Widget>[
          getRequestChip('Item Request'),
          SizedBox(
            width: 6.0,
          ),
          getRequestChip('Contribution Request'),
          SizedBox(
            width: 6.0,
          ),
          InkWell(
            onTap: () {
              setState(() {
                this.itemTypeSelected = "Lost & Found Items";
                this.requestSubType = "Lost & Found Request";
              });
            },
            child: Chip(
                label: Text(
                  "Lost & Found Request",
                  style: TextStyle(
                    color: requestSubType == "Lost & Found Request"
                        // itemTypeSelected == "Lost & Found Items"
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                backgroundColor:
                    // itemTypeSelected == 'Lost & Found Items'
                    requestSubType == 'Lost & Found Request'
                        ? Colors.teal.withOpacity(.8)
                        : Colors.grey[300]),
          ),
          // getRequestChip('Lost & Found Request'),
          SizedBox(
            width: 6.0,
          ),
          getRequestChip('Other Requests'),
          SizedBox(
            width: 6.0,
          ),
        ],
      ),
    );
  }

  getGiaChip(String clickedItemType) {
    return InkWell(
      onTap: () {
        setState(() {
          if (clickedItemType == 'Requests') {
            this.itemTypeSelected = "Item Or Contribution Request";
            clickedItemType = "Item Or Contribution Request";
            this.itemTypeSelected = clickedItemType;
          } else
            this.itemTypeSelected = clickedItemType;
        });
      },
      child: Chip(
          label: Text(
            clickedItemType,
            style: TextStyle(
                color: itemTypeSelected == clickedItemType
                    ? Colors.white
                    : Colors.black),
          ),
          backgroundColor: itemTypeSelected == clickedItemType
              ? Colors.teal.withOpacity(.8)
              : Colors.grey[300]),
    );
  }

  StorageUploadTask _uploadTask;

  _startUpload(File imageToUpload) async {
    debugPrint('inside _startUpload');
    // final FirebaseStorage _storage =
    //     FirebaseStorage(storageBucket: 'gs://bay-max-5311c.appspot.com');

    // StorageUploadTask _uploadTask;
    String _uploadedfileurl = "";
    // FirebaseAuth _auth = FirebaseAuth.instance;
    // FirebaseUser user;

    String filePath = 'images/${DateTime.now()}.png';

    StorageReference _storageReference =
        FirebaseStorage.instance.ref().child(filePath);

    setState(() {
      isUploading = true;
      //_uploadTask = _storage.ref().child(filePath).putFile(widget.file);
      _uploadTask = _storageReference.putFile(imageToUpload);
    });
    await _uploadTask.onComplete.whenComplete(() {
      print('File Uploaded');
      //getting download link of image uploaded.
      _storageReference.getDownloadURL().then((fileurl) {
        setState(() {
          _uploadedfileurl = fileurl;
          debugPrint(_uploadedfileurl);
        });

        _postItem(_uploadedfileurl);

        // _getuserId();
      });
    }).catchError((e) {
      print(e.toString());
    });
    // print('File Uploaded');
  }

  void showRegisterDialog(BuildContext context) {
    var alertDialog = AlertDialog(
      title: Text("Event registered successfully"),
      content: Text("have a nice day"),
    );
    showDialog(
        context: context,
        //builder: (BuildContext context){ // builder returns a widget
        //return alertDialog;
        //}

        builder: (BuildContext context) => alertDialog);
  }

  getRequestCategory() {
    return Container(child: Text('Request'));
  }

  showProgressScreen() {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        !uploaded
            ? CircularProgressIndicator()
            : Text(
                '🎉🎉🎉',
                style: TextStyle(fontSize: 20.0),
              ),
        Text(
          !uploaded
              ? 'Uploading. Please wait...'
              : widget.itemType == 'Item'
                  ? 'Your Item Post is now Live!'
                  : 'Your Request Post is now Live!',
          style: TextStyle(fontSize: 20.0),
        ),
      ],
    ));
  }
}
