import 'dart:async';

import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/repositories/contact_repository.dart';
import 'package:kith/features/contacts/domain/contact_draft.dart';

/// An in-memory [ContactRepository] for widget and controller tests.
///
/// Holds contacts in a map and re-emits the whole list on every change, the
/// way a Firestore query does. Widget tests never build the real repository.
class FakeContactRepository implements ContactRepository {
  /// Contacts by id, in insertion order.
  final contacts = <String, Contact>{};

  /// Drafts passed to [createContact], oldest first.
  final createCalls = <({String householdId, ContactDraft draft})>[];

  /// Drafts passed to [updateContact], oldest first.
  final updateCalls =
      <({String householdId, String contactId, ContactDraft draft})>[];

  /// Arguments of every [setArchived] call, oldest first.
  final archiveCalls =
      <({String householdId, String contactId, bool isArchived})>[];

  /// Failure to return from the next write, instead of succeeding. Cleared
  /// once consumed.
  Failure? nextFailure;

  /// Completes before the next write returns, when set. Lets a test observe
  /// the form mid-request.
  Completer<void>? gate;

  /// Error the contact stream emits instead of data, when set.
  Failure? streamFailure;

  /// When the contact stream emits, in UTC.
  DateTime now = DateTime.utc(2026, 8, 18);

  final _changes = StreamController<void>.broadcast();
  var _nextId = 0;

  @override
  Stream<List<Contact>> watchContacts(String householdId) =>
      streamFailure != null
      ? Stream.error(streamFailure!)
      : _onChange().map((_) => contacts.values.toList());

  @override
  Future<Result<Contact>> createContact({
    required String householdId,
    required ContactDraft draft,
  }) async {
    createCalls.add((householdId: householdId, draft: draft));
    await gate?.future;
    final failure = _takeFailure();
    if (failure != null) return Err(failure);

    final contact = draft.normalised().toContact(
      id: 'cid-${++_nextId}',
      createdAt: now,
      updatedAt: now,
    );
    _put(contact);
    return Ok(contact);
  }

  @override
  Future<Result<void>> updateContact({
    required String householdId,
    required String contactId,
    required ContactDraft draft,
  }) async {
    updateCalls.add((
      householdId: householdId,
      contactId: contactId,
      draft: draft,
    ));
    await gate?.future;
    final failure = _takeFailure();
    if (failure != null) return Err(failure);

    final existing = contacts[contactId];
    if (existing == null) {
      return const Err(NotFoundFailure('No such contact.'));
    }
    _put(
      draft.normalised().toContact(
        id: contactId,
        createdAt: existing.createdAt,
        updatedAt: now,
        isArchived: existing.isArchived,
      ),
    );
    return const Ok(null);
  }

  @override
  Future<Result<void>> setArchived({
    required String householdId,
    required String contactId,
    required bool isArchived,
  }) async {
    archiveCalls.add((
      householdId: householdId,
      contactId: contactId,
      isArchived: isArchived,
    ));
    await gate?.future;
    final failure = _takeFailure();
    if (failure != null) return Err(failure);

    final existing = contacts[contactId];
    if (existing == null) {
      return const Err(NotFoundFailure('No such contact.'));
    }
    _put(existing.copyWith(isArchived: isArchived, updatedAt: now));
    return const Ok(null);
  }

  /// Puts [contact] in the list without going through a write, for seeding.
  void seed(Contact contact) => _put(contact);

  /// Releases the change stream. Register with `addTearDown`.
  Future<void> dispose() => _changes.close();

  void _put(Contact contact) {
    contacts[contact.id] = contact;
    if (_changes.hasListener) _changes.add(null);
  }

  Stream<void> _onChange() async* {
    yield null;
    yield* _changes.stream;
  }

  Failure? _takeFailure() {
    final failure = nextFailure;
    nextFailure = null;
    return failure;
  }
}
