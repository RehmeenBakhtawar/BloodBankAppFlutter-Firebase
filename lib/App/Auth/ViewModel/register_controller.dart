import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var isObscured = true.obs;

  void togglePasswordVisibility() => isObscured.value = !isObscured.value;

  void register() async {
    if (!formKey.currentState!.validate()) return;

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // ✅ Save additional user data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'email': emailController.text.trim(),
        'uid': credential.user!.uid,
        'createdAt': Timestamp.now(),
      });

      Get.snackbar('Success', 'Account created successfully');
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
}
