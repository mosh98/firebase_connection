import 'dart:async';
import 'dart:io' show Platform;


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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




List<Widget> makeListWidget(AsyncSnapshot snapshot){

  return snapshot.data.documents.map<Widget>((document){

    return ListTile(
      title: Text(document["Message"]),
      subtitle: Text(document["NameUser"]),
    );
  }).toList();

}

Future<void> createRecord(String uid) async {
  await databaseReference.collection("Users")
      .document(uid)
      .updateData({'chattingWith': uid});


}

void onSendMessage(String content, String uid ){

  DateTime now = DateTime.now();
  String formattedDate = DateFormat('kk:mm:ss \n EEE d MMM').format(now);

  //payload
  Message msg = new Message(content,  formattedDate , uid);

  var docref = Firestore.instance
      .collection('Users')
      .document(uid)
      .collection(uid)
      .document(DateTime.now().millisecondsSinceEpoch.toString());

  //Firestore.instance.collection('Users').document('$uid').collection(uid);

//  databaseReference.runTransaction((transaction) =>
//     transaction.set(docref,set{
//
//     })

  databaseReference.runTransaction((transaction) async {
    await transaction.set(
      docref,
      {
        "Message": msg
      },
    );
  });

}
  final myController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Text(widget.title),
      ),

      body: Row(
        children: [

          StreamBuilder(

            stream: Firestore.instance.collection('messg').snapshots(),
            builder: (context,snapshot){

              if(! snapshot.hasData ) return Text('Data is coming');

              return ListView.builder(

                  itemCount: snapshot.data.documents.length,

                  itemBuilder: (_, int index){
                    final DocumentSnapshot docs = snapshot.data.documents[index];
                    Message msgz = new Message(docs['Message'], docs['TimeStamp'], docs['NameUser']);

                    return ListTile(
                      title: Text(msgz.toString()),
                      //subtitle: Text( "\n "+username.toString() +"  "+ timeStamp.toString( ) ),
                    );
                  }) ;
            },
          ),

          new TextField(
            controller: myController,
            decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter a search term'
            ),
          )
        ],
      ),


    );
  }

}

class Message{
  String message;
  String TimeStamp;
  String NameUser;

  Message(this.message, this.TimeStamp, this.NameUser);
}
