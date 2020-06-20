import 'package:flutter/material.dart';

class MyInfoBtmSheet {
  void showInfoBtmShet(context, string1, string2, string3) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: new Wrap(
              children: <Widget>[
                // new ListTile(
                //     leading: new Icon(Icons.update),
                //     title: new Text('Update'),
                //     onTap: () => {}),
                new ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        height: 20,
                      ),
                      Text(
string1,                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      Text(string2),
                      Text(
                       string3,
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),)
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }
}