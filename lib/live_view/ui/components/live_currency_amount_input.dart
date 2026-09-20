import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
import 'package:liveview_flutter/live_view/mapping/input_decoration.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';
import 'package:uuid/uuid.dart';

extension NumberTruncation on double {
  String truncatePrecision(int precision) {
    var res = toString();
    var decimal = res.indexOf('.');
    if (decimal == -1) {
      return res;
    }
    var decimalPosition = decimal + precision + 1;
    if (decimalPosition >= res.length) {
      return res + ('0' * (decimalPosition - res.length));
    }
    return res.substring(0, decimalPosition);
  }
}

/// A locale-aware currency amount mask, ported from mavio's
/// money_input_formatter, minus the arithmetic expressions.
///
/// Only the decimal separator is locale-aware (`","` for French, `"."`
/// otherwise); the thousands separator is always a plain space. Keyboard
/// input accepts both `,` and `.` as the decimal separator regardless of
/// the locale; the typed separator is normalized to the locale one.
/// Typing re-masks the value on every keystroke, keeps a user-typed trailing
/// separator ("1 000,") or separator + zero ("1 000,0"), rejects a second
/// decimal separator, deletes the adjacent digit when a thousands space is
/// deleted, and preserves the cursor by counting non-space characters.
class CurrencyAmountFormatter extends TextInputFormatter {
  static const int precision = 2;
  static const String thousandSeparator = ' ';

  final String decimalSeparator;

  CurrencyAmountFormatter({this.decimalSeparator = '.'}) {
    if (decimalSeparator == thousandSeparator) {
      throw Exception(
        'decimalSeparator cannot be the same as thousandSeparator',
      );
    }
  }

  String applyMask(double value) {
    var fixedPrecision = value.toStringAsFixed(precision + 1);

    // we convert numbers like 0.213 into 0.23
    // this is due to the fact that there's a two digit limit
    // so if the user touches another digit, we expect to replace the last one
    if (fixedPrecision[fixedPrecision.length - 1] != '0') {
      var newVal = value.truncatePrecision(precision);
      value = double.parse(
        newVal.substring(0, newVal.length - 1) +
            fixedPrecision[fixedPrecision.length - 1],
      );
    }

    List<String> textRepresentation =
        value
            .toStringAsFixed(precision)
            .replaceAll('.', '')
            .split('')
            .reversed
            .toList();

    textRepresentation.insert(precision, decimalSeparator);

    for (var i = precision + 4; true; i = i + 4) {
      if (textRepresentation.length > i) {
        textRepresentation.insert(i, thousandSeparator);
      } else {
        break;
      }
    }

    var txt = textRepresentation.reversed.join('');
    return txt.replaceFirst('${decimalSeparator}00', '');
  }

  /// Strips the thousands spaces and parses with a dot, accepting either
  /// separator: a dot works in comma locales and vice versa.
  double numberValue(String val) {
    if (val == '') {
      return 0;
    }
    var cleaned = val
        .replaceAll(thousandSeparator, '')
        .replaceFirst(decimalSeparator, '.')
        .replaceFirst(',', '.');
    return double.tryParse(cleaned) ?? 0;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Accept both ',' and '.' as the decimal separator on keyboard input,
    // whatever the current language: the foreign separator is swapped for
    // ours before masking, and a value mixing both separators is rejected.
    var foreignSeparator = decimalSeparator == '.' ? ',' : '.';
    if (newValue.text.contains(foreignSeparator)) {
      var separatorCount =
          decimalSeparator.allMatches(newValue.text).length +
          foreignSeparator.allMatches(newValue.text).length;
      if (separatorCount > 1) {
        return oldValue;
      }
      newValue = TextEditingValue(
        text: newValue.text.replaceFirst(foreignSeparator, decimalSeparator),
        selection: newValue.selection,
        composing: newValue.composing,
      );
    }

    if (newValue.text == '') {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
        composing: TextRange.empty,
      );
    }
    if (newValue.text == '0') {
      return const TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
        composing: TextRange.empty,
      );
    }

    // too many separators
    if (decimalSeparator.allMatches(newValue.text).length > 1) {
      return oldValue;
    }

    // we deleted a space
    if (oldValue.text != newValue.text &&
        oldValue.text.replaceAll(' ', '') ==
            newValue.text.replaceAll(' ', '')) {
      var newVal =
          oldValue.text.substring(0, oldValue.selection.baseOffset - 2) +
          oldValue.text.substring(oldValue.selection.baseOffset - 1);
      var formattedVal = applyMask(numberValue(newVal));
      return TextEditingValue(
        text: formattedVal,
        selection: TextSelection.collapsed(
          offset: oldValue.selection.baseOffset - 2,
        ),
      );
    }

    String masked = applyMask(numberValue(newValue.text));

    // no changes
    if (masked == newValue.text) {
      return newValue;
    }

    var spacesBeforeCursor = 0;
    var oldCursor = oldValue.selection.baseOffset;
    for (var i = 0; i < oldCursor; i++) {
      if (oldValue.text[i] == thousandSeparator) {
        spacesBeforeCursor++;
      }
    }
    oldCursor -= spacesBeforeCursor;
    spacesBeforeCursor = 0;

    var newCursor = newValue.selection.baseOffset;
    for (var i = 0; i < newCursor; i++) {
      if (newValue.text[i] == ' ') {
        spacesBeforeCursor++;
      }
    }
    newCursor -= spacesBeforeCursor;

    var spacesToAdd = 0;
    var charCount = 0;
    for (var i = 0; i < masked.length; i++) {
      if (masked[i] == ' ') {
        spacesToAdd++;
      } else {
        charCount++;
        if (charCount == newCursor) {
          break;
        }
      }
    }

    var offset = newCursor + spacesToAdd;

    if (newValue.text.endsWith(decimalSeparator)) {
      masked += decimalSeparator;
    } else if (newValue.text.endsWith('${decimalSeparator}0') &&
        newCursor - oldCursor >= 0) {
      masked += '${decimalSeparator}0';
    }

    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(
        offset: offset > masked.length ? masked.length : offset,
      ),
    );
  }
}

/// A currency form input for native amounts, usable like any other field
/// inside a `<Form>`:
///
/// ```xml
/// <CurrencyAmountInput name="account[initial_balance]" initialValue="1 000,50"
///                      label="Initial balance" decimalSeparator="," />
/// ```
///
/// The displayed value is masked by [CurrencyAmountFormatter]; the masked
/// text is dispatched on change like a TextField and normalized server-side
/// before the Decimal cast.
class LiveCurrencyAmountInput extends LiveStateWidget<LiveCurrencyAmountInput> {
  const LiveCurrencyAmountInput({super.key, required super.state});

  @override
  State<LiveCurrencyAmountInput> createState() =>
      _LiveCurrencyAmountInputState();
}

class _LiveCurrencyAmountInputState
    extends StateWidget<LiveCurrencyAmountInput> {
  final attributes = [
    'name',
    'initialValue',
    'label',
    'hintText',
    'decoration',
    'decimalSeparator',
    'errors',
    'appearance',
    'prefixText',
    'prefixStyle',
    'barColor',
    'barActiveColor',
  ];

  @override
  handleClickState() => HandleClickState.manual;

  final key = GlobalKey<FormFieldState>();
  var unamedInput = const Uuid().v4();

  List<FormError> errors = [];

  String get fieldName =>
      getAttribute('name') ?? 'unamed-amount-input-$unamedInput';

  bool get isHero => getAttribute('appearance') == 'hero';

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      parseErrors();
      key.currentState?.validate();
      sendInitialState();
    });
    super.initState();
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
    key.currentState?.validate();
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
      data: getAttribute('initialValue') ?? '',
      type: FormFieldEventType.initField,
    ).dispatch(context);
  }

  @override
  Widget render(BuildContext context) {
    final field = TextFormField(
      key: key,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      autovalidateMode: AutovalidateMode.disabled,
      validator: (_) {
        var message = errors.map((e) => interpolateError(e)).join('\n');
        return message == '' ? null : message;
      },
      decoration: _decoration(context),
      inputFormatters: [
        CurrencyAmountFormatter(
          decimalSeparator: getAttribute('decimalSeparator') ?? '.',
        ),
      ],
      initialValue: getAttribute('initialValue'),
      style:
          isHero
              ? const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)
              : null,
      cursorColor: isHero ? Theme.of(context).colorScheme.primary : null,
      onTapOutside: (_) => executeOnTapOutsideEventsManually(),
      onTap: () => executeTapEventsManually(),
      onChanged: (value) {
        FormFieldEvent(
          name: fieldName,
          data: value,
          type: FormFieldEventType.change,
        ).dispatch(context);
      },
    );

    if (!isHero) return field;

    // Hero appearance (the web's `:hero` amount card): the field sits on a
    // rounded card with the currency symbol on the left, a large bold font,
    // and a progress-like bar under the input.
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            field,
            const SizedBox(height: 8),
            _AmountBar(
              trackColor:
                  getColor(context, getAttribute('barColor')) ??
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              activeColor:
                  getColor(context, getAttribute('barActiveColor')) ??
                  Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(BuildContext context) {
    if (!isHero) {
      return getInputDecoration(
        context,
        getAttribute('decoration'),
        labelText: getAttribute('label'),
        hintText: getAttribute('hintText'),
      );
    }

    final prefixText = getAttribute('prefixText');
    return InputDecoration(
      labelText: getAttribute('label'),
      hintText: getAttribute('hintText'),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      prefixText:
          prefixText == null || prefixText.isEmpty ? null : '$prefixText ',
      prefixStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _AmountBar extends StatelessWidget {
  final Color trackColor;
  final Color activeColor;

  const _AmountBar({required this.trackColor, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 2,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: trackColor)),
            FractionallySizedBox(
              widthFactor: 0.25,
              heightFactor: 1,
              child: ColoredBox(color: activeColor),
            ),
          ],
        ),
      ),
    );
  }
}
