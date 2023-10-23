import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:liveview_flutter/live_view/mapping/inputDecoration.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:uuid/uuid.dart';

class LiveTextField extends LiveStateWidget<LiveTextField> {
  const LiveTextField({super.key, required super.state});

  @override
  State<LiveTextField> createState() => _LiveTextFieldState();
}

class _LiveTextFieldState extends StateWidget<LiveTextField> {
  final key = GlobalKey<FormBuilderFieldState>();

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, ['name', 'value', 'decoration']);
    key.currentState?.didChange(getAttribute('value'));
  }

  @override
  Widget render(BuildContext context) {
    var children = multipleChildren();
    var icon = StateChild.extractChild<LiveIconAttribute>(children);

    return FormBuilderTextField(
        key: key,
        decoration: getInputDecoration(
          context,
          getAttribute('decoration'),
          icon: icon,
        ),
        name: getAttribute('name') ?? const Uuid().v4(),
        initialValue: getAttribute('value'));
  }
}
