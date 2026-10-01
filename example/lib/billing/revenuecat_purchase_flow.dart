import 'package:flutter/foundation.dart';

enum PurchaseOutcome { unavailable, noPlans, cancelled, inactive, active }

class PurchasePlan {
  const PurchasePlan({
    required this.title,
    required this.price,
    required this.nativePackage,
  });

  final String title;
  final String price;
  final Object nativePackage;
}

abstract class RevenueCatStore {
  bool get supported;

  Future<List<PurchasePlan>> plans(String apiKey, String appUserId);

  Future<bool> purchase(PurchasePlan plan, String entitlementId);

  Future<bool> restore(
    String apiKey,
    String appUserId,
    String entitlementId,
  );
}

class RevenueCatPurchaseFlow {
  const RevenueCatPurchaseFlow(this.store);

  final RevenueCatStore store;

  Future<PurchaseOutcome> purchase({
    required String? apiKey,
    required String appUserId,
    required String entitlementId,
    required Future<PurchasePlan?> Function(List<PurchasePlan>) select,
  }) async {
    if (!store.supported || apiKey == null || apiKey.isEmpty) {
      return PurchaseOutcome.unavailable;
    }

    final available = await store.plans(apiKey, appUserId);
    if (available.isEmpty) return PurchaseOutcome.noPlans;

    final selected = await select(available);
    if (selected == null) return PurchaseOutcome.cancelled;

    return await store.purchase(selected, entitlementId)
        ? PurchaseOutcome.active
        : PurchaseOutcome.inactive;
  }

  Future<PurchaseOutcome> restore({
    required String? apiKey,
    required String appUserId,
    required String entitlementId,
  }) async {
    if (!store.supported || apiKey == null || apiKey.isEmpty) {
      return PurchaseOutcome.unavailable;
    }

    return await store.restore(apiKey, appUserId, entitlementId)
        ? PurchaseOutcome.active
        : PurchaseOutcome.inactive;
  }
}

String? keyForPlatform({
  required String? apple,
  required String? google,
  required String? web,
  TargetPlatform? platform,
  bool? isWeb,
}) {
  if (isWeb ?? kIsWeb) return web;
  switch (platform ?? defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return apple;
    case TargetPlatform.android:
      return google;
    default:
      return null;
  }
}
