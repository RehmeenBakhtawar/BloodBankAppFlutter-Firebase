import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'App/Auth/View/auth_view.dart';
import 'App/Form/View/form_view.dart';
import 'App/Home/View/feed_view.dart';
import 'Utils/constants.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
       webProvider: ReCaptchaEnterpriseProvider('12345'),
    );
  } catch (e, stack) {
    print('FirebaseAppCheck activation error: $e');
  }

  await GetStorage.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final box = GetStorage();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Blood Bank App',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        builder: EasyLoading.init(),

        initialRoute: box.read('uid') == null ? '/login' : '/feed',
        getPages: [
          GetPage(name: '/login', page: () => LoginScreen()),
          GetPage(name: '/feed', page: () => FeedScreen()),
          GetPage(name: '/form', page: () => FormScreen()),
          GetPage(name: '/register', page: () => RegisterScreen()),
        ],
      ),
    );
  }
}
