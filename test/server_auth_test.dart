import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:klos/server/server_auth.dart';

void main() {
  late DateTime now;
  late ServerAuth auth;

  setUp(() {
    now = DateTime(2026, 1, 1, 12);
    auth = ServerAuth(
      random: Random(7),
      clock: () => now,
      maxAttempts: 5,
      attemptWindow: const Duration(minutes: 5),
      maxFailures: 20,
    );
    auth.start();
  });

  group('PIN', () {
    test('has four digits and does not start with zero', () {
      for (var i = 0; i < 20; i++) {
        auth.start();
        expect(auth.pin, hasLength(ServerAuth.pinLength));
        expect(int.parse(auth.pin), inInclusiveRange(1000, 9999));
      }
    });

    test('is empty until the server starts', () {
      final fresh = ServerAuth(clock: () => now);
      expect(fresh.pin, isEmpty);
      expect(fresh.matchesPin('1234'), isFalse);
    });

    test('accepts only the exact code', () {
      expect(auth.matchesPin(auth.pin), isTrue);
      expect(auth.matchesPin(null), isFalse);
      expect(auth.matchesPin(''), isFalse);
      expect(auth.matchesPin('123'), isFalse);
      expect(auth.matchesPin('${auth.pin}0'), isFalse);
      final other = auth.pin == '0000' ? '1111' : '0000';
      expect(auth.matchesPin(other), isFalse);
    });

    test('is forgotten when the server stops', () {
      auth.stop();
      expect(auth.pin, isEmpty);
      expect(auth.isSessionValid(null), isFalse);
    });
  });

  group('sessions', () {
    test('are valid only after they are created', () {
      expect(auth.isSessionValid(null), isFalse);
      expect(auth.isSessionValid('guess'), isFalse);

      final token = auth.createSession();
      expect(token, isNotEmpty);
      expect(auth.isSessionValid(token), isTrue);
    });

    test('expire after the lifetime without activity', () {
      final token = auth.createSession();

      // Activity refreshes the session, so 11 h later it is still valid.
      now = now.add(const Duration(hours: 11));
      expect(auth.isSessionValid(token), isTrue);

      // Once the last activity is older than the lifetime it expires.
      now = now.add(const Duration(hours: 13));
      expect(auth.isSessionValid(token), isFalse);
    });

    test('are dropped when the PIN is replaced', () {
      final token = auth.createSession();
      final oldPin = auth.pin;
      auth.rotate();

      expect(auth.pin, isNot(oldPin));
      expect(auth.isSessionValid(token), isFalse);
    });

    test('are cleared on a new server start', () {
      final token = auth.createSession();
      auth.start();
      expect(auth.isSessionValid(token), isFalse);
    });
  });

  group('wrong attempts', () {
    test('block a device after the allowed number', () {
      for (var i = 0; i < 4; i++) {
        auth.noteFailure('192.168.1.50');
        expect(auth.isBlocked('192.168.1.50'), isFalse);
      }

      auth.noteFailure('192.168.1.50');
      expect(auth.isBlocked('192.168.1.50'), isTrue);
      expect(auth.retryAfter('192.168.1.50'), const Duration(minutes: 5));
    });

    test('do not block other devices', () {
      for (var i = 0; i < 5; i++) {
        auth.noteFailure('192.168.1.50');
      }
      expect(auth.isBlocked('192.168.1.50'), isTrue);
      expect(auth.isBlocked('192.168.1.51'), isFalse);
      expect(auth.retryAfter('192.168.1.51'), Duration.zero);
    });

    test('stop blocking after the window', () {
      for (var i = 0; i < 5; i++) {
        auth.noteFailure('192.168.1.50');
      }
      now = now.add(const Duration(minutes: 4, seconds: 59));
      expect(auth.isBlocked('192.168.1.50'), isTrue);

      now = now.add(const Duration(seconds: 1));
      expect(auth.isBlocked('192.168.1.50'), isFalse);
      expect(auth.retryAfter('192.168.1.50'), Duration.zero);
    });

    test('are cleared by a correct PIN', () {
      for (var i = 0; i < 3; i++) {
        auth.noteFailure('192.168.1.50');
      }
      auth.noteSuccess('192.168.1.50');
      for (var i = 0; i < 2; i++) {
        auth.noteFailure('192.168.1.50');
      }
      expect(auth.isBlocked('192.168.1.50'), isFalse);
    });

    test('replace the PIN when too many pile up', () {
      final short = ServerAuth(
        random: Random(11),
        clock: () => now,
        maxFailures: 3,
      )..start();
      final oldPin = short.pin;
      final token = short.createSession();

      expect(short.noteFailure('a'), isFalse);
      expect(short.noteFailure('b'), isFalse);
      expect(short.noteFailure('c'), isTrue);

      expect(short.pin, isNot(oldPin));
      expect(short.isSessionValid(token), isFalse);
      expect(short.failureCount, 0);
    });
  });
}
