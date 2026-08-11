import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

/// A Material linear progress indicator configured through LiveView attributes.
class LiveLinearProgressIndicator
    extends LiveStateWidget<LiveLinearProgressIndicator> {
  const LiveLinearProgressIndicator({super.key, required super.state});

  @override
  State<LiveLinearProgressIndicator> createState() =>
      _LiveLinearProgressIndicatorState();
}

class _LiveLinearProgressIndicatorState
    extends StateWidget<LiveLinearProgressIndicator> {
  static const attributes = [
    'value',
    'minHeight',
    'color',
    'backgroundColor',
    'borderRadius',
    'semanticsLabel',
    'semanticsValue',
  ];

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, attributes);
  }

  @override
  Widget render(BuildContext context) {
    final rawValue = doubleAttribute('value');
    final radius = doubleAttribute('borderRadius');

    return LinearProgressIndicator(
      value: rawValue?.clamp(0.0, 1.0).toDouble(),
      minHeight: doubleAttribute('minHeight'),
      color: colorAttribute(context, 'color'),
      backgroundColor: colorAttribute(context, 'backgroundColor'),
      borderRadius:
          radius == null ? BorderRadius.zero : BorderRadius.circular(radius),
      semanticsLabel: getAttribute('semanticsLabel'),
      semanticsValue: getAttribute('semanticsValue'),
    );
  }
}
