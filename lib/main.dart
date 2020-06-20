import 'dart:async';
import 'dart:convert';

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:device_info/device_info.dart';

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

 // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();





  Future<String> getThisDeviceInfo() async {

    String identifier;
    final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        var build = await deviceInfoPlugin.androidInfo;
        identifier = build.id.toString();
        print(identifier);
      } else if (Platform.isIOS) {
        var data = await deviceInfoPlugin.iosInfo;
        identifier = data.identifierForVendor;//UUID for iOS
      }
      return identifier;
    } catch (e) {
      print('Failed to get platform version');
    }


  }


  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  void getTokenForThisDevice() async {
    _firebaseMessaging.getToken().then((value) => print(value));
  }

//dSlNvWn9-FQ:APA91bHU3vCNpLz6tHMW8GSFJzqGDl_2B2j7uoDYeMSjMg_ac9lmdtDCKIFiElTUZDezNUvBCHm0wOA4nf-23ADkbTUvmJJvN02eRBCMMec9DMqhXH8K9qrJJff609c9Rnu6GNOP3XMe
  @override
  Future<void> initState()  {


    //_firebaseMessaging.subscribeToTopic(topic);

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
      },
    );

  }

  Future<void> createRecord(String uid) async {
    await databaseReference
        .collection("Users")
        .document(uid)
        .updateData({'chattingWith': uid});
  }





    Future<Map<String, dynamic>> sendAndRetrieveMessage(String body, String title) async {
      await _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true, provisional: false),
      );

      String teken = 'dSlNvWn9-FQ:APA91bHU3vCNpLz6tHMW8GSFJzqGDl_2B2j7uoDYeMSjMg_ac9lmdtDCKIFiElTUZDezNUvBCHm0wOA4nf-23ADkbTUvmJJvN02eRBCMMec9DMqhXH8K9qrJJff609c9Rnu6GNOP3XMe';

      await http.post(
        'https://fcm.googleapis.com/fcm/send',
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=AAAApxhRlHQ:APA91bHl1eBjWN0jTAwguFZKAWPES8DnTa5A7Akw-DSrQiG4mE2lDo-12kzWLke1Kj1rAZ00yguG9FOsLZCODNHLq1-wZOLa_Ny1hKBz-7pRt3mgc8F4FgYk5nykcX7yBstZIQ4-8uuk',
        },

        body: jsonEncode(
          <String, dynamic>{
            'notification': <String, dynamic>{
              'body': '$body',
              'title': '$title'
            },
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done'
            },
            'to': teken,
          },
        ),
      );

      final Completer<Map<String, dynamic>> completer =
      Completer<Map<String, dynamic>>();

      _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) async {
          completer.complete(message);
        },
      );

      return completer.future;
    }


  String peerUid;

  void _onSendMessage(String content, String uid) {
    //DateTime now = DateTime.now();
    //String formattedDate = DateFormat('kk:mm:ss').format(now);
    Firestore.instance.collection('messages').document().setData({
      'from': uid,
    'text': content,
    'timestamp': DateTime.now().toIso8601String().toString()});

    //getTokenForThisDevice();
    _firebaseMessaging.getToken().then((value) => print(value));
    getThisDeviceInfo();
//    Future<String> s =  getThisDeviceInfo();
//    print( s.toString());
    sendAndRetrieveMessage(content, uid);

  }


  final textController = TextEditingController();
  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                    .collection('messages').orderBy('timestamp')
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
                        _onSendMessage(textController.text, "MOSH");
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
    );
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

//
//class MessagingWidget extends StatefulWidget{
//
//  @override
//  State<StatefulWidget> createState() {
//    // TODO: implement createState
//    throw MessagingWidgetState();
//  }
//
//}

//
//class MessagingWidgetState extends State<MessagingWidget> {
//
//  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
//
//
//
//
//  @override
//  void initState() {
//
//    _firebaseMessaging.configure(
//
//      onMessage: (Map<String, dynamic> message) async {
//        print("onMessage: $message");
//
//      },
//
//      onLaunch: (Map<String, dynamic> message) async {
//        print("onLaunch: $message");
//
//      },
//      onResume: (Map<String, dynamic> message) async {
//        print("onResume: $message");
//
//      },
//    );
//
//    _firebaseMessaging.requestNotificationPermissions(
//      const IosNotificationSettings(sound: true, badge:true, alert: true)
//
//    );
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return Container(
//
//    );
//  }


//}