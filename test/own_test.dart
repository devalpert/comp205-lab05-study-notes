// Part 7: my own tests. They test real code (Note, AuthRepository, NotesRepository).
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab05_study_notes/data/auth_repository.dart';
import 'package:lab05_study_notes/data/notes_repository.dart';
import 'package:lab05_study_notes/models/note.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

void main() {
  // Create one fake first: it makes FieldValue.serverTimestamp() work in tests.
  setUpAll(FakeFirebaseFirestore.new);

  test('example: messageFor maps weak-password', () {
    expect(AuthRepository.messageFor('weak-password'), contains('6 characters'));
  });

  test('messageFor maps network-request-failed, wrong-password and user-not-found', () {
    expect(AuthRepository.messageFor('network-request-failed'), 'No connection. Check your network.');
    expect(AuthRepository.messageFor('wrong-password'), 'Wrong email or password.');
    expect(AuthRepository.messageFor('user-not-found'), 'Wrong email or password.');
  });

  test('signUp failure (email-already-in-use) becomes an AuthFailure', () async {
    final auth = MockFirebaseAuth();
    whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
        .on(auth)
        .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
    final repo = AuthRepository(auth);
    await expectLater(
      repo.signUp('ada@agu.edu.tr', 'secret123'),
      throwsA(isA<AuthFailure>()
          .having((f) => f.message, 'message', 'An account already exists for this email.')),
    );
    expect(repo.currentUser, isNull, reason: 'a failed sign-up must not sign anyone in');
  });

  test('addNote accepts a title of exactly 100 characters (boundary)', () async {
    final repo = NotesRepository(FakeFirebaseFirestore());
    await repo.addNote('u1', 'a' * 100, '');
    final notes = await repo.watchNotes('u1').first;
    expect(notes.single.title, hasLength(100));
  });

  test('addNote trims the title before checking its length', () async {
    final repo = NotesRepository(FakeFirebaseFirestore());
    // 100 real characters plus spaces around them: still valid after trim.
    await repo.addNote('u1', '   ${'b' * 100}   ', '  body  ');
    final note = (await repo.watchNotes('u1').first).single;
    expect(note.title, 'b' * 100);
    expect(note.body, 'body');
  });

  test('fromFirestore: a non-String body is a FormatException', () {
    expect(() => Note.fromFirestore('n1', {'title': 'T', 'body': 42}), throwsFormatException);
  });
}
