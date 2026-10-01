import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import 'revenuecat_purchase_flow.dart';

class SdkRevenueCatStore implements RevenueCatStore {
  String? _currentAppUserId;

  @override
  bool get supported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.macOS;

  Future<void> _identify(String apiKey, String appUserId) async {
    if (!await rc.Purchases.isConfigured) {
      await rc.Purchases.configure(
        rc.PurchasesConfiguration(apiKey)..appUserID = appUserId,
      );
    } else if (_currentAppUserId != appUserId) {
      await rc.Purchases.logIn(appUserId);
    }
    _currentAppUserId = appUserId;
  }

  @override
  Future<List<PurchasePlan>> plans(String apiKey, String appUserId) async {
    await _identify(apiKey, appUserId);
    final offerings = await rc.Purchases.getOfferings();
    return [
      for (final package
          in offerings.current?.availablePackages ?? <rc.Package>[])
        PurchasePlan(
          title: package.storeProduct.title,
          price: package.storeProduct.priceString,
          nativePackage: package,
        ),
    ];
  }

  @override
  Future<bool> purchase(PurchasePlan plan, String entitlementId) async {
    final result = await rc.Purchases.purchase(
      rc.PurchaseParams.package(plan.nativePackage as rc.Package),
    );
    return result.customerInfo.entitlements.active.containsKey(entitlementId);
  }

  @override
  Future<bool> restore(
    String apiKey,
    String appUserId,
    String entitlementId,
  ) async {
    await _identify(apiKey, appUserId);
    final info = kIsWeb
        ? await rc.Purchases.getCustomerInfo()
        : await rc.Purchases.restorePurchases();
    return info.entitlements.active.containsKey(entitlementId);
  }
}
