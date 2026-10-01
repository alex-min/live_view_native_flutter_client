import 'package:example/billing/revenuecat_purchase_flow.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeStore implements RevenueCatStore {
  @override
  bool supported = true;
  List<PurchasePlan> available = const [
    PurchasePlan(title: 'Monthly', price: '€4.99', nativePackage: 'monthly'),
  ];
  bool active = true;
  String? observedUser;
  String? observedEntitlement;
  int purchases = 0;

  @override
  Future<List<PurchasePlan>> plans(String apiKey, String appUserId) async {
    observedUser = appUserId;
    return available;
  }

  @override
  Future<bool> purchase(PurchasePlan plan, String entitlementId) async {
    purchases++;
    observedEntitlement = entitlementId;
    return active;
  }

  @override
  Future<bool> restore(
    String apiKey,
    String appUserId,
    String entitlementId,
  ) async {
    observedUser = appUserId;
    observedEntitlement = entitlementId;
    return active;
  }
}

void main() {
  test('platform keys stay separate across stores', () {
    expect(
      keyForPlatform(
        apple: 'apple',
        google: 'google',
        web: 'web',
        platform: TargetPlatform.android,
        isWeb: false,
      ),
      'google',
    );
    expect(
      keyForPlatform(
        apple: 'apple',
        google: 'google',
        web: 'web',
        platform: TargetPlatform.iOS,
        isWeb: false,
      ),
      'apple',
    );
    expect(
      keyForPlatform(
        apple: 'apple',
        google: 'google',
        web: 'web',
        isWeb: true,
      ),
      'web',
    );
  });

  test('purchase uses the signed-in customer and selected entitlement',
      () async {
    final store = FakeStore();
    final outcome = await RevenueCatPurchaseFlow(store).purchase(
      apiKey: 'public-key',
      appUserId: 'opaque-user-id',
      entitlementId: 'pro',
      select: (plans) async => plans.single,
    );

    expect(outcome, PurchaseOutcome.active);
    expect(store.observedUser, 'opaque-user-id');
    expect(store.observedEntitlement, 'pro');
    expect(store.purchases, 1);
  });

  test('missing config and missing offerings never start a purchase', () async {
    final store = FakeStore();
    final flow = RevenueCatPurchaseFlow(store);

    expect(
      await flow.purchase(
        apiKey: null,
        appUserId: 'user',
        entitlementId: 'pro',
        select: (_) async => null,
      ),
      PurchaseOutcome.unavailable,
    );

    store.available = [];
    expect(
      await flow.purchase(
        apiKey: 'key',
        appUserId: 'user',
        entitlementId: 'pro',
        select: (_) async => null,
      ),
      PurchaseOutcome.noPlans,
    );
    expect(store.purchases, 0);
  });

  test('restore reports inactive without granting membership locally',
      () async {
    final store = FakeStore()..active = false;
    final outcome = await RevenueCatPurchaseFlow(store).restore(
      apiKey: 'key',
      appUserId: 'user',
      entitlementId: 'pro',
    );

    expect(outcome, PurchaseOutcome.inactive);
    expect(store.observedUser, 'user');
    expect(store.observedEntitlement, 'pro');
  });
}
