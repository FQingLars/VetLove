import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:uuid/uuid.dart';

import '../models/trade.dart';
import 'location_service.dart';

/// Бэкенд аккаунтов и трейдов на Firebase Auth + Firestore.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _trades => _db.collection('trades');
  CollectionReference<Map<String, dynamic>> get _listings =>
      _db.collection('listings');

  // ---------------- Аккаунты ----------------

  /// Регистрация по email + пароль.
  Future<UserCredential> signUpEmail(
      String email, String password, String nickname) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user?.updateDisplayName(nickname);
    await _ensureProfile(cred.user!, nickname);
    return cred;
  }

  Future<UserCredential> signInEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  /// Google Sign-In (Android/iOS).
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Вход отменён');
    final googleAuth = await googleUser.authentication;
    final cred = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(cred);
    await _ensureProfile(result.user!, result.user!.displayName ?? 'Игрок');
    return result;
  }

  /// Sign in with Apple (iOS).
  Future<UserCredential> signInWithApple() async {
    final operation = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final oauth = OAuthProvider('apple.com').credential(
      idToken: operation.identityToken,
      accessToken: operation.authorizationCode,
    );
    final result = await _auth.signInWithCredential(oauth);
    await _ensureProfile(result.user!, result.user!.displayName ?? 'Игрок');
    return result;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> _ensureProfile(User user, String nickname) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set(UserProfile(
        uid: user.uid,
        nickname: nickname,
        photoUrl: user.photoURL ?? '',
        createdAt: DateTime.now(),
      ).toMap());
    }
  }

  Future<UserProfile?> profile(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return UserProfile.fromMap(snap.data()!);
  }

  Future<void> updatePosition(String uid, double lat, double lon) =>
      _users.doc(uid).update({'lastLat': lat, 'lastLon': lon});

  // ---------------- Обменники поблизости ----------------

  /// Публичные обменники в радиусе [radiusM] вокруг точки игрока.
  Future<List<TradeListing>> nearbyListings(
      double lat, double lon, double radiusM) async {
    final snap = await _listings
        .where('createdAt',
            isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(const Duration(days: 7))))
        .limit(200)
        .get();
    final out = <TradeListing>[];
    for (final doc in snap.docs) {
      final l = TradeListing.fromMap(doc.data());
      if (LocationService.distanceMeters(lat, lon, l.lat, l.lon) <= radiusM) {
        out.add(l);
      }
    }
    out.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return out;
  }

  /// Создать публичное объявление обменника.
  Future<String> createListing(TradeListing listing) async {
    final id = const Uuid().v4();
    await _listings.doc(id).set({...listing.toMap(), 'listingId': id});
    return id;
  }

  Future<void> deleteListing(String listingId) =>
      _listings.doc(listingId).delete();

  // ---------------- Трейд между пользователями ----------------

  /// Отправить предложение трейда второму пользователю.
  Future<String> sendTradeOffer(TradeOffer offer) async {
    final id = const Uuid().v4();
    await _trades.doc(id).set({...offer.toMap(), 'tradeId': id});
    return id;
  }

  /// Входящие/исходящие сделки пользователя в реальном времени.
  Stream<List<TradeOffer>> myTrades(String uid) {
    return _trades
        .where(
          Filter.or(
            Filter.equal('fromUid', uid),
            Filter.equal('toUid', uid),
          ),
        )
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((qs) => qs.docs
            .map((d) => TradeOffer.fromMap(d.data()))
            .where((t) => !t.isExpired || t.state == TradeState.completed)
            .toList());
  }

  Future<void> acceptTrade(String tradeId) =>
      _trades.doc(tradeId).update({'state': TradeState.accepted.name});

  Future<void> completeTrade(String tradeId) =>
      _trades.doc(tradeId).update({'state': TradeState.completed.name});

  Future<void> cancelTrade(String tradeId) =>
      _trades.doc(tradeId).update({'state': TradeState.cancelled.name});
}
