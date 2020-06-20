import 'package:flutter/material.dart';

class DoneTag {
  getDoneTag(doc) {
    return doc['markAsDone'] != 'true'
        ? Container()
        : Padding(
            padding: const EdgeInsets.only(left: 14.0, top: 8.0),
            child: Container(
                decoration: BoxDecoration(
                    color:
                        //  doc['markAsDone'] == "true"
                        // ?
                        Colors.red.withOpacity(0.9),
                    // :
                    // Colors.transparent,
                    borderRadius: BorderRadius.circular(5)),
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    "Marked as done!",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                )),
          );
  }
}
