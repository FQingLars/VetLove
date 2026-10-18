import 'package:flutter/foundation.dart';

import '../models/collection_card.dart';
import '../models/trade.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

/// Состояние трейдов: ближайшие обменники, мои сделки, конструктор оффера.
class TradeProvider extends ChangeNotifier {
  TradeProvider(this._auth);

  final AuthService _auth;

  List<TradeListing> nearby = [];
  List<TradeOffer> myOffers = [];
  bool busy = false;
  String? error;

  /// Карточки, выбранные текущим пользователем как «отдаю».
  final Set<String> givingCardIds = {};

  /// Вид/редкость, которую пользователь ищет в трейде.
  CardRef? wantedRef;

  double _lastLat = 0, _lastLon = 0;

  Stream<List<TradeOffer>> tradesStream(String uid) => _auth.myTrades(uid);

  void startListeningTrades(String uid) {
    _auth.myTrades(uid).listen((list) {
      myOffers = list;
      notifyListeners();
    });
  }

  Future<void> refreshNearby(double radiusMeters) async {
    busy = true;
    error = null;
    try {
      final pos = await LocationService().getCurrent();
      if (pos == null) {
        error = 'Нет доступа к геолокации';
      } else {
        _lastLat = pos.latitude;
        _lastLon = pos.longitude;
        final me = _auth.currentUser?.uid;
        nearby = (await _auth.nearbyListings(_lastLat, _lastLon, radiusMeters))
            .where((l) => l.ownerUid != me)
            .toList();
      }
    } catch (e) {
      error = e.toString();
    }
    busy = false;
    notifyListeners();
  }

  void toggleGiveCard(CollectionCard card) {
    if (!card.canTrade) return;
    if (givingCardIds.contains(card.cardId)) {
      givingCardIds.remove(card.cardId);
    } else {
      givingCardIds.add(card.cardId);
    }
    notifyListeners();
  }

  void setWanted(CardRef? ref) {
    wantedRef = ref;
    notifyListeners();
  }

  void clearDraft() {
    givingCardIds.clear();
    wantedRef = null;
    notifyListeners();
  }

  /// Выставить публичный обменник.
  Future<bool> publishListing(
      List<CollectionCard> offered, CardRef wanted) async {
    final me = _auth.currentUser;
    if (me == null || offered.isEmpty) return false;
    busy = true;
    try {
      await _auth.createListing(TradeListing(
        listingId: '',
        ownerUid: me.uid,
        ownerName: me.displayName ?? me.email ?? 'Игрок',
        offeredCards: offered.map(CardRef.fromCard).toList(),
        wantedCards: [wanted],
        createdAt: DateTime.now(),
        lat: _lastLat,
        lon: _lastLon,
      ));
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Отправить персональный трейд-оффер владельцу объявлении или другу.
  Future<bool> sendOffer({
    required String toUid,
    required String toName,
    required List<CollectionCard> give,
    required CardRef receive,
  }) async {
    final me = _auth.currentUser;
    if (me == null || give.isEmpty) return false;
    busy = true;
    try {
      await _auth.sendTradeOffer(TradeOffer(
        tradeId: '',
        fromUid: me.uid,
        fromName: me.displayName ?? me.email ?? 'Я',
        toUid: toUid,
        toName: toName,
        give: give.map(CardRef.fromCard).toList(),
        receive: [receive],
        state: TradeState.proposed,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        type: give.length == 1 && receive.rarityStars >= 0
            ? TradeType.simple
            : TradeType.multi,
      ));
      clearDraft();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> accept(String tradeId) => _act(() => _auth.acceptTrade(tradeId));
  Future<void> complete(String tradeId) => _act(() => _auth.completeTrade(tradeId));
  Future<void> cancel(String tradeId) => _act(() => _auth.cancelTrade(tradeId));

  Future<void> _act(Future<void> Function() f) async {
    busy = true;
    try {
      await f();
    } catch (e) {
      error = e.toString();
    }
    busy = false;
    notifyListeners();
  }
}
