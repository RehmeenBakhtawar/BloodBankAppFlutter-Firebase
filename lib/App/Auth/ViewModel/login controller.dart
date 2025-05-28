import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var isObscured = true.obs;

  void togglePasswordVisibility() => isObscured.value = !isObscured.value;

  void login() async {
    if (!formKey.currentState!.validate()) return;

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // ✅ Optionally fetch user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (userDoc.exists) {
        Get.snackbar('Success', 'Login successful');
        Get.offAllNamed('/feed'); // Change route as needed
      } else {
        Get.snackbar('Error', 'User data not found in Firestore');
      }
    } catch (e) {
      Get.snackbar('Login Failed', e.toString());
    }
  }
}
