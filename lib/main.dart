import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/app/app.dart';
import 'package:kith/app/bootstrap.dart';
import 'package:kith/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ProviderScope(
      overrides: firebaseOverrides(auth: FirebaseAuth.instance),
      child: const KithApp(),
    ),
  );
}
