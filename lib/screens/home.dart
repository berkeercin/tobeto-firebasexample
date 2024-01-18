import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebasexample/screens/auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  File? _selectedImage;
  bool isAlreadyUpdated = false;
  String? avatarProfilePhoto = "";
  final fcm = FirebaseMessaging.instance;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _requestNotificationPermission();
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

  Future<String> _getUserImage() async {
    User? loggedInUser = firebaseAuthInstance.currentUser;
    final document =
        firebaseFireStore.collection("users").doc(loggedInUser!.uid);
    final documentSnapshot = await document.get();

    try {
      final imageUrl = await documentSnapshot.get("imageUrl");
      return imageUrl;
    } catch (e) {
      print(e);
      final imageUrl = "";
      return imageUrl;
    }
  }

  void _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _uploadImage() async {
    if (_selectedImage != null) {
      User? loggedInUser = firebaseAuthInstance.currentUser;
      final storageRef = firebaseStorageInstance
          .ref()
          .child("images")
          .child("${loggedInUser!.uid}.jpg");
      await storageRef.putFile(_selectedImage!);

      final url = await storageRef.getDownloadURL();
      await firebaseFireStore
          .collection("users")
          .doc(loggedInUser.uid)
          .update({"imageUrl": url});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Firebase HomeScreen"),
        actions: [
          IconButton(
              onPressed: () {
                firebaseAuthInstance.signOut();
              },
              icon: Icon(Icons.logout))
        ],
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_selectedImage == null)
            FutureBuilder(
                future: _getUserImage(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    return CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 40,
                        foregroundImage: NetworkImage(snapshot.data!));
                  }
                  if (snapshot.hasError) {
                    return const Text("Avatar yüklenirken bir hata oluştu..");
                  }
                  return const CircularProgressIndicator();
                }),
          TextButton(
              onPressed: () {
                _pickImage();
              },
              child: Text("Resim Seç")),
          if (_selectedImage != null)
            ElevatedButton(
                onPressed: () {
                  _uploadImage();
                },
                child: Text("Resim Yükle"))
        ],
      )),
    );
  }
}
