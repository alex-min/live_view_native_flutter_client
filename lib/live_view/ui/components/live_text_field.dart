import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/mapping/input_decoration.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';
import 'package:uuid/uuid.dart';

class LiveTextField extends LiveStateWidget<LiveTextField> {
  const LiveTextField({super.key, required super.state});

  @override
  State<LiveTextField> createState() => _LiveTextFieldState();
}

class _LiveTextFieldState extends StateWidget<LiveTextField> {
  List<String> attributes = [
    'name',
    'initialValue',
    'decoration',
    'label',
    'hintText',
    'obscureText',
    'errors',
    'keyboardType',
    'maxLines',
    'minLines',
    'maxLength',
    'expands',
    'readOnly',
    'autocorrect',
    'enableSuggestions',
    'showCursor',
    'obscuringCharacter',
    'icon',
    'textAlign',
    'enabled',
    'cursorWidth',
    'cursorHeight',
    'cursorColor',
    'cursorOpacityAnimates',
    'scrollPadding',
    'enableInteractiveSelection',
    'scribbleEnabled',
    'enableIMEPersonalizedLearning',
    'canRequestFocus',
    'selectionHeightStyle',
    'submitOnEnter',
  ];
  @override
  handleClickState() => HandleClickState.manual;
  final key = GlobalKey<FormFieldState>();
  var unamedInput = const Uuid().v4();
  List<FormError> errors = [];
  TextEditingController? _controller;
  StreamSubscription? _clearComposerSubscription;

  /// The controller backing the field. Owning it (instead of letting
  /// TextFormField create one from initialValue) lets the client clear the
  /// text when the server pushes a `clear-composer` event.
  TextEditingController get _effectiveController =>
      _controller ??= TextEditingController(
        text: storedValue ?? getAttribute('initialValue'),
      );

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      parseErrors();
      validateInput();
      sendInitialState();
    });
    super.initState();
    _clearComposerSubscription = liveView.eventHub.on('clear-composer', (data) {
      var field = data is Map ? data['field'] : null;
      if (field == fieldName && mounted && widget.state.isOnTheCurrentPage) {
        _effectiveController.clear();
        FormFieldEvent(
          name: fieldName,
          data: '',
          type: FormFieldEventType.clear,
        ).dispatch(context);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _clearComposerSubscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void onWipeState() {
    errors = [];
    super.onWipeState();
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, attributes);
    parseErrors();
    validateInput();
  }

  void validateInput() => key.currentState?.validate();

  String interpolateError(FormError error) {
    var message = error.message;
    error.options?.forEach((key, value) {
      message = message.replaceAll('%{$key}', value.toString());
    });
    return message;
  }

  void sendInitialState() {
    reloadAttributes(node, attributes);
    FormFieldEvent(
      name: fieldName,
      data: storedValue ?? getAttribute('initialValue') ?? '',
      type: FormFieldEventType.initField,
    ).dispatch(context);
  }

  String get fieldName =>
      getAttribute('name') ?? "unamed-text-field-$unamedInput";

  /// The value the user typed before a server diff rebuilt this field, if
  /// any. Server-rendered initial values are stale after validate round
  /// trips, so the remembered value wins.
  String? get storedValue {
    final value = liveView.formValuesFor(widget.state.urlPath)?[fieldName];
    return value == null ? null : value.toString();
  }

  void parseErrors() {
    reloadAttributes(node, attributes);
    List<dynamic>? serverErrors = tryJsonDecode(getAttribute('errors'));
    if (serverErrors == null) {
      return;
    }
    errors =
        serverErrors
            .map((e) => FormError(message: e['message'], options: e['options']))
            .toList();
  }

  /// Dispatches the enclosing form's submit event, the same path as tapping
  /// a submit button.
  void _dispatchSubmit() {
    FormFieldEvent(
      name: fieldName,
      data: _effectiveController.text,
      type: FormFieldEventType.submit,
    ).dispatch(context);
  }

  /// Multiline fields never call onFieldSubmitted (Enter inserts a newline
  /// through the text input channel), so submitOnEnter also intercepts plain
  /// Enter key events before they reach the editable and consumes them.
  KeyEventResult _onSubmitKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        (event.logicalKey != LogicalKeyboardKey.enter &&
            event.logicalKey != LogicalKeyboardKey.numpadEnter)) {
      return KeyEventResult.ignored;
    }
    var pressed = HardwareKeyboard.instance.logicalKeysPressed;
    var hasModifier = pressed.any(
      (key) =>
          key == LogicalKeyboardKey.shiftLeft ||
          key == LogicalKeyboardKey.shiftRight ||
          key == LogicalKeyboardKey.controlLeft ||
          key == LogicalKeyboardKey.controlRight ||
          key == LogicalKeyboardKey.metaLeft ||
          key == LogicalKeyboardKey.metaRight ||
          key == LogicalKeyboardKey.altLeft ||
          key == LogicalKeyboardKey.altRight,
    );
    if (hasModifier) {
      return KeyEventResult.ignored;
    }
    _dispatchSubmit();
    return KeyEventResult.handled;
  }

  @override
  Widget render(BuildContext context) {
    var children = multipleChildren();
    Widget? icon = StateChild.extractChild<LiveIconAttribute>(children);
    icon ??= StateChild.extractChild<LiveIcon>(children);
    icon ??= iconWidgetFromAttribute('icon');

    Widget field = TextFormField(
      selectionHeightStyle:
          boxHeightStyleAttribute('selectionHeightStyle') ??
          BoxHeightStyle.tight,
      obscuringCharacter: getAttribute('obscuringCharacter') ?? '•',
      showCursor: booleanAttribute('showCursor'),
      enableSuggestions: booleanAttribute('enableSuggestions') ?? true,
      autocorrect: booleanAttribute('autocorrect') ?? false,
      expands: booleanAttribute('expands') ?? false,
      readOnly:
          widget.state.viewType == ViewType.cached ||
          (booleanAttribute('readOnly') ?? false),
      keyboardType: textInputTypeAttribute('keyboardType'),
      maxLength: intAttribute('maxLength'),
      minLines: intAttribute('minLines'),
      maxLines:
          getAttribute('maxLines') == 'unlimited'
              ? null
              : intAttribute('maxLines') ?? 1,
      autovalidateMode: AutovalidateMode.disabled,
      validator: (_) {
        var message = errors.map((e) => interpolateError(e)).join('\n');
        return message == '' ? null : message;
      },
      key: key,
      obscureText: booleanAttribute('obscureText') ?? false,
      decoration: getInputDecoration(
        context,
        getAttribute('decoration'),
        icon: icon,
        labelText: getAttribute('label'),
        hintText: getAttribute('hintText'),
      ),
      onTapOutside: (_) => executeOnTapOutsideEventsManually(),
      onTap: () => executeTapEventsManually(),
      onFieldSubmitted:
          booleanAttribute('submitOnEnter') == true
              ? (_) => _dispatchSubmit()
              : null,
      controller: _effectiveController,
      onChanged: (value) {
        FormFieldEvent(
          name: fieldName,
          data: value,
          type: FormFieldEventType.change,
        ).dispatch(context);
      },
      textAlign: textAlignAttribute('textAlign') ?? TextAlign.start,
      enabled: booleanAttribute('enabled'),
      cursorWidth: doubleAttribute('cursorWidth') ?? 2.0,
      cursorHeight: doubleAttribute('cursorHeight'),
      cursorRadius: null, // TODO: Radius
      cursorColor: colorAttribute(context, 'cursorColor'),
      cursorOpacityAnimates: booleanAttribute('cursorOpacityAnimates'),
      scrollPadding:
          marginOrPaddingAttribute('scrollPadding') ??
          const EdgeInsets.all(20.0),
      enableInteractiveSelection: booleanAttribute(
        'enableInteractiveSelection',
      ),
      scribbleEnabled: booleanAttribute('scribbleEnabled') ?? true,
      enableIMEPersonalizedLearning:
          booleanAttribute('enableIMEPersonalizedLearning') ?? true,
      canRequestFocus: booleanAttribute('canRequestFocus') ?? true,
    );

    if (booleanAttribute('submitOnEnter') == true) {
      field = Focus(onKeyEvent: _onSubmitKeyEvent, child: field);
    }
    return field;
  }
}
