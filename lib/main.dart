import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rawat_jalan/pages/admin/admin_page.dart';
import 'package:rawat_jalan/pages/auth_page.dart';
import 'package:rawat_jalan/pages/pasien_page.dart';
import 'package:rawat_jalan/pages/user_data_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final userRef = FirebaseFirestore.instance.collection('users');

  Future<Map<String, dynamic>?> user(String userUID) async {
    final snap = await userRef.doc(userUID).get();

    return snap.data();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Pasein Rawat Jalan Kec. Jeumpa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Bisa tampilkan loading
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            User currentUser = snapshot.data!;
            Future<Map<String, dynamic>?> userFuture = user(currentUser.uid);

            return FutureBuilder(
              future: userFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Bisa tampilkan loading
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final userData = snapshot.data;

                if (userData == null) {
                  return UserDataPage(
                    user: currentUser,
                    onFinished: () {
                      setState(() {
                        userFuture = user(currentUser.uid);
                      });
                    },
                  );
                }

                if (userData['role'] == 'admin') {
                  return AdminPage();
                } else {
                  return PasienPage();
                }
              },
            );
          } else {
            return const AuthPage();
          }
        },
      ),
    );
  }
}
