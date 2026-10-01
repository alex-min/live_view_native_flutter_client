import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/exec/exec_live_event.dart';
import 'package:liveview_flutter/exec/live_view_exec_registry.dart';
import 'package:liveview_flutter/live_view/plugin.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/live_view/ui/live_view_ui_registry.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import 'revenuecat_purchase_flow.dart';
import 'revenuecat_store.dart';

class RevenueCatPlugin extends Plugin {
  RevenueCatPlugin({RevenueCatStore? store})
      : flow = RevenueCatPurchaseFlow(store ?? SdkRevenueCatStore());

  final RevenueCatPurchaseFlow flow;

  @override
  String get name => 'revenuecat';

  @override
  void registerWidgets(LiveViewUiRegistry registry) {}

  @override
  void registerExecs(LiveViewExecRegistry registry) {
    registry.add(
      ['phx-revenuecat'],
      (value, attributes) => _RevenueCatExec(
        action: value?['name'] as String? ?? '',
        attributes: attributes ?? {},
        flow: flow,
      ),
      triggers: [LiveViewExecTrigger.onTap],
    );
  }
}

class _RevenueCatExec extends Exec {
  _RevenueCatExec({
    required this.action,
    required this.attributes,
    required this.flow,
  });

  final String action;
  final Map<String, dynamic> attributes;
  final RevenueCatPurchaseFlow flow;

  @override
  void handler(BuildContext context, StateWidget widget) {
    unawaited(_run(context, widget));
  }

  Future<void> _run(BuildContext context, StateWidget widget) async {
    final appUserId = attributes['phx-value-app-user-id'] as String?;
    if (appUserId == null || appUserId.isEmpty) return;

    final key = keyForPlatform(
      apple: attributes['phx-value-apple-key'] as String?,
      google: attributes['phx-value-google-key'] as String?,
      web: attributes['phx-value-web-key'] as String?,
    );
    final entitlementId =
        attributes['phx-value-entitlement-id'] as String? ?? 'pro';

    try {
      final outcome = action == 'purchase'
          ? await flow.purchase(
              apiKey: key,
              appUserId: appUserId,
              entitlementId: entitlementId,
              select: (plans) async {
                if (!context.mounted) return null;
                return showDialog<PurchasePlan>(
                  context: context,
                  builder: (dialogContext) => SimpleDialog(
                    title: Text(
                      attributes['phx-value-choose-label'] as String? ?? '',
                    ),
                    children: [
                      for (final plan in plans)
                        SimpleDialogOption(
                          onPressed: () => Navigator.pop(dialogContext, plan),
                          child: Text('${plan.title} — ${plan.price}'),
                        ),
                    ],
                  ),
                );
              },
            )
          : await flow.restore(
              apiKey: key,
              appUserId: appUserId,
              entitlementId: entitlementId,
            );

      if (!context.mounted) return;
      if (outcome == PurchaseOutcome.active ||
          outcome == PurchaseOutcome.inactive) {
        widget.liveView.dispatchEvent(
          ExecLiveEvent(
            type: 'phx-click',
            name: 'refresh_entitlement',
            value: const <String, dynamic>{},
          ),
        );
      } else if (outcome == PurchaseOutcome.unavailable ||
          outcome == PurchaseOutcome.noPlans) {
        _showMessage(context, attributes['phx-value-unavailable-label']);
      }
    } on PlatformException catch (error) {
      if (rc.PurchasesErrorHelper.getErrorCode(error) !=
          rc.PurchasesErrorCode.purchaseCancelledError) {
        if (context.mounted) {
          _showMessage(context, attributes['phx-value-error-label']);
        }
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, attributes['phx-value-error-label']);
      }
    }
  }

  void _showMessage(BuildContext context, Object? message) {
    if (message is String && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
