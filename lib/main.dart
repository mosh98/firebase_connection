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
    String formattedDate = DateFormat('kk:mm:ss').format(now);

    //payload
    Message msg = new Message(content, formattedDate, uid);

    var docref = Firestore.instance.collection('Users').document('UserMsg');

    Map<String, dynamic> mapz = {
      'Message': msg.message,
      'NameUser': msg.NameUser,
      'created_At': msg.TimeStamp,
    };


//    Firestore.instance
//        .collection('messg')
//        .document('Message')
//        .updateData({'array':FieldValue.arrayUnion([mapz])});

    docref.updateData( {'array':FieldValue.arrayUnion([mapz])} );

//    Firestore.instance.runTransaction((transaction) async {
//      await transaction.update(docref, mapz);
//    });

  }



  //final myController = TextEditingController();

  final textController = TextEditingController( );

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
                stream: Firestore.instance
                    .collection('Users')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Text('Data is coming');

                  return ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: snapshot.data.documents.length,
                    itemBuilder: (_, index) {

                      List<dynamic> document = snapshot.data.documents[index]['array'];
                      print(document.toString());

                      //TODO: The idea is to append the things in things in List<dynamic> document to listTile, otherwise it's good.
                      return ListTile(

                        // Access the fields as defined in FireStore
                        title: Text("MESSAGE"),
                        // subtitle: Text(msg.data['NameUser'].toString()),
                      );
                    },
                  );
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
                      icon: Icon(
                        Icons.send,
                        color: Colors.blue,
                      ),

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