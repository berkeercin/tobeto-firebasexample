import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebasexample/screens/auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  File? _selectedImage;
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

  Widget settingsPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Firebase settings"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (_selectedImage == null)
            Center(
              child: FutureBuilder(
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
            ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return settingsPage();
  }
}
