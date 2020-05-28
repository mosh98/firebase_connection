import 'dart:async';

import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
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
  final String recipient = "norp@florp.com";
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseUser user;

  _MyHomePageState() {
    signInUser("florp@norp.com", "tester");
}


  Future signInUser(String email, String password) async {
    try{
      AuthResult result = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = result.user;
    } catch(e){
      return null;
    }


  }



  void _onSendMessage(String content, String uid, String peerUid) {
    Firestore.instance.collection('users').document(user.email).collection('chats').document(recipient).collection('messages').document().setData({
      'from': recipient,
    'text': content,
    'timestamp': DateTime.now().toIso8601String().toString()});
    Firestore.instance.collection('users').document(recipient).collection('chats').document(user.email).collection('messages').document().setData({
      'from': user.email,
      'text': content,
      'timestamp': DateTime.now().toIso8601String().toString()});
  }


  final textController = TextEditingController();
  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Scaffold(
      //resizeToAvoidBottomInset: true,
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
                    .collection('users').document(user.email).collection('chats').document(recipient).collection('messages').orderBy('timestamp')
                    .snapshots(),

                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Text('Data is coming');

                  List<DocumentSnapshot> docs = snapshot.data.documents;
                  List<Widget> messages = docs.map((doc) =>
                      Message(
                        message: doc.data['text'],
                        timeStamp: doc.data['timestamp'],
                        nameUser: doc.data['from'],
                      )).toList();

                  return ListView(

                    controller: scrollController,
                    children: <Widget>[
                      ...messages,
                    ],
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
                        _onSendMessage(textController.text, "b2YxBTdWCTTbxSb6lSvJyskuyN22","ZPdRVUxgUzeMozR6Z6WAhqV13ZZ2");
                        textController.clear();
                        scrollController.animateTo(scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
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
    ));
  }
}

class Message extends StatelessWidget {
  final String message;
  final String timeStamp;
  final String nameUser;
  final bool self = true;

  const Message({Key key, this.message, this.timeStamp, this.nameUser})
      : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
      child: Column(
        crossAxisAlignment: self ? CrossAxisAlignment.end : CrossAxisAlignment
            .start,


        children: <Widget>[
          Text(nameUser),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(timeStamp),
              SizedBox(height: 8.0,),
              Text(message)
            ],
          )
        ],
      ),
    );
  }

}