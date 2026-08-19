import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:kith/app/app.dart';
import 'package:kith/app/bootstrap.dart';
import 'package:kith/data/services/plugin_google_sign_in_service.dart';
import 'package:kith/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ProviderScope(
      overrides: firebaseOverrides(
        auth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
        // The one place the real Google plugin and a real socket are named.
        // Sign-in asks for no scope here: the calendar scopes are granted when
        // a household links a calendar, not at the door.
        googleSignIn: PluginGoogleSignInService(),
        httpClient: http.Client(),
      ),
      child: const KithApp(),
    ),
  );
}
