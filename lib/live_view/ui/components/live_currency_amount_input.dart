import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liveview_flutter/live_view/mapping/input_decoration.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
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
/// otherwise); the thousands separator is always a plain space. Typing
/// re-masks the value on every keystroke, keeps a user-typed trailing
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
  ];

  @override
  handleClickState() => HandleClickState.manual;

  final key = GlobalKey<FormFieldState>();
  var unamedInput = const Uuid().v4();

  String get fieldName =>
      getAttribute('name') ?? 'unamed-amount-input-$unamedInput';

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      sendInitialState();
    });
    super.initState();
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, attributes);
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
    return TextFormField(
      key: key,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      autovalidateMode: AutovalidateMode.disabled,
      decoration: getInputDecoration(
        context,
        getAttribute('decoration'),
        labelText: getAttribute('label'),
        hintText: getAttribute('hintText'),
      ),
      inputFormatters: [
        CurrencyAmountFormatter(
          decimalSeparator: getAttribute('decimalSeparator') ?? '.',
        ),
      ],
      initialValue: getAttribute('initialValue'),
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
  }
}
