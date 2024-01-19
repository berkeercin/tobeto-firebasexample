import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebasexample/screens/auth.dart';
import 'package:firebasexample/screens/settings.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

var uuid = Uuid();

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAlreadyUpdated = false;
  String? avatarProfilePhoto = "";
  TextEditingController messageController = TextEditingController();
  List newMessageList = [];
  final fcm = FirebaseMessaging.instance;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _requestNotificationPermission();
    getMessageList();
  }

  User? loggedInUser = firebaseAuthInstance.currentUser;
  Future getMessageList() async {
    try {
      QuerySnapshot<Map<String, dynamic>> messageList =
          await firebaseFireStore.collection('messages').get();
      newMessageList.clear();
      // Access the documents and their data
      for (QueryDocumentSnapshot<Map<String, dynamic>> messageDoc
          in messageList.docs) {
        Map<String, dynamic> data = messageDoc.data();
        // Do something with the data...
        data.forEach(
          (key, value) {
            setState(() {
              newMessageList.add(value);
            });
          },
        );
        // print(newMessageList);
      }
    } catch (e) {}
  }

  void _requestNotificationPermission() async {
    _updateTokenInDb();
    fcm.onTokenRefresh.listen((token) {
      _updateTokenInDb();
    });
  }

  void _updateTokenInDb() async {
    NotificationSettings settings = await fcm.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await fcm.getToken();
      User? loggedInUser = firebaseAuthInstance.currentUser;
      await firebaseFireStore
          .collection('users')
          .doc(loggedInUser!.uid)
          .update({"fcm": token});

      await fcm.subscribeToTopic("flutter-1b");
    }
  }

  Widget chatBubble(message, user) {
    var author = message!['author'];
    var authorId = message!['authorId'];
    var content = message!['content'];
    var avatar = message!['avatar'];
    print("$message + $author + $content + $avatar");
    if (user == authorId) {
      return Align(
        alignment: Alignment.topRight,
        child: Container(
          width: 200,
          decoration: BoxDecoration(
              color: Colors.purple[600],
              borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Text(
                content.toString(),
                style: TextStyle(color: Colors.white),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 20,
                    foregroundImage: NetworkImage(avatar),
                  ),
                  Text(
                    author.toString(),
                    style: TextStyle(color: Colors.white),
                  )
                ],
              )
            ],
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            width: 200,
            decoration: BoxDecoration(
              color: Colors.purple[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(content.toString()),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      foregroundImage: NetworkImage(avatar),
                    ),
                    Text(author.toString())
                  ],
                )
              ],
            ),
          ),
        ),
      );
    }
  }

  Future sendMessage() async {
    User? loggedInUser = firebaseAuthInstance.currentUser;
    final document =
        firebaseFireStore.collection('users').doc(loggedInUser!.uid);
    final documentSnapshot = await document.get();
    final avatarUrl = await documentSnapshot.get("imageUrl");
    await firebaseFireStore.collection('messages').doc(uuid.v8()).set({
      "message": {
        "author": loggedInUser.displayName,
        "authorId": loggedInUser.uid,
        "avatar": avatarUrl,
        "content": messageController.text
      }
    });
    getMessageList();
  }

  Widget chatUI() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          height: 350,
          child: ListView.builder(
            itemCount: newMessageList.length,
            itemBuilder: (context, index) {
              return chatBubble(newMessageList[index], loggedInUser!.uid);
            },
          ),
        ),
        Container(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  textInputAction: TextInputAction.send,
                  style: TextStyle(),
                  decoration: InputDecoration(
                    hintText: "Lütfen göndermek istediğiniz mesajı yazınız.",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  sendMessage();
                },
                child: Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  var fakeData = [
    {
      'message': {
        'author': 'Test1',
        'content': "Test123123",
        'avatar': 'https://i.pravatar.cc/300'
      }
    },
    {
      'message': {
        'author': 'Test2',
        'content': "Second test",
        'avatar': 'https://i.pravatar.cc/300'
      }
    },
    {
      'message': {
        'author': 'Test3',
        'content': "Third test",
        'avatar': 'https://i.pravatar.cc/300'
      }
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Firebase HomeScreen"),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()));
              },
              icon: const Icon(Icons.settings),
            ),
            IconButton(
                onPressed: () {
                  firebaseAuthInstance.signOut();
                },
                icon: Icon(Icons.logout))
          ],
        ),
        body: chatUI());
  }
}
