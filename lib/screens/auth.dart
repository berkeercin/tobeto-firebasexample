// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseAuthInstance = FirebaseAuth.instance;
final firebaseStorageInstance = FirebaseStorage.instance;
final firebaseFireStore = FirebaseFirestore.instance;

class Auth extends StatefulWidget {
  const Auth({Key? key}) : super(key: key);

  @override
  _AuthState createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  var _isLogin = true;
  final _formKey = GlobalKey<FormState>();

  void _submit() async {
    _formKey.currentState!.save();

    if (_isLogin) {
      try {
        var userCredentials = await firebaseAuthInstance
            .signInWithEmailAndPassword(email: email, password: password);
      } catch (e) {
        if (e is FirebaseAuthException) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message ?? "Giriş Hatalı")));
        }
      }

      // Giriş Yap
    } else {
      // Kayıt Ol
      try {
        final userCredentials = await firebaseAuthInstance
            .createUserWithEmailAndPassword(email: email, password: password);

        await firebaseFireStore
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({"email": email});

        await firebaseFireStore
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({"passwod": password});
        // print(userCredentials);
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "Kayıt Hatalı"),
          ),
        );
      }
    }
  }

  var email = "";
  var password = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: "E-posta"),
                        autocorrect: false,
                        keyboardType: TextInputType.emailAddress,
                        onSaved: (newValue) {
                          email = newValue!;
                        },
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: "Şifre"),
                        autocorrect: false,
                        obscureText: true,
                        onSaved: (newValue) {
                          password = newValue!;
                        },
                      ),
                      ElevatedButton(
                          onPressed: () {
                            _submit();
                          },
                          child: Text(_isLogin ? "Giriş Yap" : "Kayıt Ol")),
                      TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                          child: Text(_isLogin
                              ? "Kayıt sayfasına git"
                              : "Giriş Sayfasına Git"))
                    ],
                  )),
            ),
          ),
        ),
      ),
    );
  }
}
