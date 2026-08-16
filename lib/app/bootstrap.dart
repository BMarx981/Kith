import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kith/data/repositories/firestore_household_repository.dart';
import 'package:kith/data/services/firebase_auth_service.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/household/application/household_providers.dart';

/// Provider overrides that bind the graph to live Firebase services.
///
/// The entry point and its test share this list, so the wiring under test is
/// the wiring that ships. Firebase itself must already be initialised.
List<Override> firebaseOverrides({
  required FirebaseAuth auth,
  required FirebaseFirestore firestore,
}) => [
  authServiceProvider.overrideWithValue(FirebaseAuthService(auth)),
  householdRepositoryProvider.overrideWithValue(
    FirestoreHouseholdRepository(firestore, Random.secure()),
  ),
];
