import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

//TODO: Be able to send things


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Firestore databse connection'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final databaseReference = Firestore.instance;

  List<Widget> makeListWidget(AsyncSnapshot snapshot) {
    return snapshot.data.documents.map<Widget>((document) {
      return ListTile(
        title: Text(document["Message"]),
        subtitle: Text(document["NameUser"]),
      );
    }).toList();
  }

  Future<void> createRecord(String uid) async {
    await databaseReference
        .collection("Users")
        .document(uid)
        .updateData({'chattingWith': uid});
  }

  void _onSendMessage(String content, String uid) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('kk:mm:ss \n EEE d MMM').format(now);

    //payload
    Message msg = new Message(content, formattedDate, uid);

    var docref = Firestore.instance
        .collection('messg')
        .document('Message');
       // .collection(uid)
        //.document(DateTime.now().millisecondsSinceEpoch.toString());

    //Map<String,dynamic> mapz = new Map();
    Map <String, dynamic > mapz =  {
      'Message': msg.message,
      'NameUser': msg.NameUser,
      'TimeStamp': msg.TimeStamp,
    };


    docref.updateData(mapz);

    //Firestore.instance.collection('Users').document('$uid').collection(uid);

//    databaseReference.runTransaction((transaction) async {
//      await transaction.set(
//        docref,
//        {"Message": msg.message.toString()},
//      );
//    });
  }

  //final myController = TextEditingController();

  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat window'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              flex: 10,
              child: StreamBuilder(
                stream: Firestore.instance.collection('messg').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Text('Data is coming');

                  return ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: snapshot.data.documents.length,
                      itemBuilder: (_, int index) {
                        final DocumentSnapshot docs =
                        snapshot.data.documents[index];
                        String tim =  docs['TimeStamp'];
                        String User = docs['NameUser'];
                        String anotherOne = User+" Sent: " +tim;
                        return ListTile(
                          title: Text(docs['Message']),

                          subtitle: Text(anotherOne),
                        );
                      });
                },
              ),
            ),
            Expanded(
              flex: 2,
              child: TextField(
                controller: textController,
                decoration: InputDecoration(
                    hintText: "Skicka ett meddelande",
                    suffixIcon: IconButton(
                      onPressed: () {
                        _onSendMessage(textController.text, "MOSH");
                      },
                      icon:Icon(Icons.send, color: Colors.blue,),

                      //color: Colors.blue,
                    )),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class Message {
  String message;
  String TimeStamp;
  String NameUser;

  Message(this.message, this.TimeStamp, this.NameUser);
}
