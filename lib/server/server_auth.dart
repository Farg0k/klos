import 'dart:convert';
import 'dart:math';

/// PIN and session handling for the local HTTP server.
///
/// The Kindle shows a short numeric PIN once and receives a random session
/// cookie in return, so the PIN never appears in the address bar or in the
/// generated links. The PIN is compared in constant time, and repeated wrong
/// guesses from one device are temporarily blocked, so the four digits cannot
/// be brute-forced over Wi-Fi.
class ServerAuth {
  ServerAuth({
    Random? random,
    DateTime Function()? clock,
    this.maxAttempts = 5,
    this.attemptWindow = const Duration(minutes: 5),
    this.maxFailures = 20,
    this.sessionLifetime = const Duration(hours: 12),
  }) : _random = random ?? Random.secure(),
       _clock = clock ?? DateTime.now;

  /// Number of digits in the PIN.
  static const int pinLength = 4;

  final Random _random;
  final DateTime Function() _clock;

  /// Wrong PINs allowed from one device inside [attemptWindow].
  final int maxAttempts;

  /// How long wrong attempts are remembered.
  final Duration attemptWindow;

  /// Total wrong PINs after which the PIN is replaced automatically.
  final int maxFailures;

  /// How long a signed-in device stays signed in.
  final Duration sessionLifetime;

  String _pin = '';
  final Map<String, DateTime> _sessions = {};
  final Map<String, List<DateTime>> _failures = {};
  int _failureCount = 0;

  /// Current PIN, or an empty string while the server is stopped.
  String get pin => _pin;

  /// Wrong PINs since the last rotation.
  int get failureCount => _failureCount;

  /// Starts a protected run: a fresh PIN and no signed-in devices.
  ///
  /// Called on every server start, so a PIN seen yesterday no longer works.
  void start() {
    _pin = _newPin();
    _sessions.clear();
    _failures.clear();
    _failureCount = 0;
  }

  /// Replaces the PIN and signs every device out.
  void rotate() {
    _pin = _newPin();
    _sessions.clear();
    _failureCount = 0;
  }

  /// Forgets the PIN and every session when the server stops.
  void stop() {
    _pin = '';
    _sessions.clear();
    _failures.clear();
    _failureCount = 0;
  }

  /// Compares [input] with the PIN in constant time.
  ///
  /// The loop always touches every digit, so the response time does not
  /// reveal how many leading digits were correct.
  bool matchesPin(String? input) {
    final expected = _pin;
    if (expected.isEmpty || input == null || input.length != expected.length) {
      return false;
    }
    var difference = 0;
    for (var i = 0; i < expected.length; i++) {
      difference |= expected.codeUnitAt(i) ^ input.codeUnitAt(i);
    }
    return difference == 0;
  }

  /// Creates a session for a device that entered the PIN.
  String createSession() {
    final token = _newToken();
    _sessions[token] = _clock();
    return token;
  }

  /// Whether [token] belongs to a signed-in device that is still fresh.
  bool isSessionValid(String? token) {
    if (token == null || token.isEmpty) return false;
    final lastSeen = _sessions[token];
    if (lastSeen == null) return false;
    final now = _clock();
    if (now.difference(lastSeen) >= sessionLifetime) {
      _sessions.remove(token);
      return false;
    }
    _sessions[token] = now;
    return true;
  }

  /// Signs one device out (used when it sends a useless cookie).
  void dropSession(String token) {
    _sessions.remove(token);
  }

  /// Whether [client] used up its attempts and must wait.
  bool isBlocked(String client) =>
      _recentFailures(client).length >= maxAttempts;

  /// How long [client] has to wait before another attempt.
  Duration retryAfter(String client) {
    final recent = _recentFailures(client);
    if (recent.length < maxAttempts) return Duration.zero;
    final wait = recent.first.add(attemptWindow).difference(_clock());
    return wait.isNegative ? Duration.zero : wait;
  }

  /// Records a wrong PIN.
  ///
  /// Returns true when the PIN was replaced because too many attempts were
  /// made in total; the caller should refresh the code shown in the app.
  bool noteFailure(String client) {
    final now = _clock();
    final entries = _failures.putIfAbsent(client, () => <DateTime>[])..add(now);
    entries.removeWhere((time) => now.difference(time) >= attemptWindow);
    _failureCount++;
    if (_failureCount >= maxFailures) {
      rotate();
      return true;
    }
    return false;
  }

  /// Clears the wrong-attempt counter of a device that entered the PIN.
  void noteSuccess(String client) {
    _failures.remove(client);
  }

  List<DateTime> _recentFailures(String client) {
    final entries = _failures[client];
    if (entries == null) return const [];
    final now = _clock();
    entries.removeWhere((time) => now.difference(time) >= attemptWindow);
    return entries;
  }

  /// Four digits, never starting with a zero so the length is obvious.
  String _newPin() => (1000 + _random.nextInt(9000)).toString();

  /// Random URL-safe session token.
  String _newToken() {
    final bytes = List<int>.generate(24, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
