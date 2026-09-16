import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/live_form.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:uuid/uuid.dart';

/// A form field that submits an ISO date while presenting Flutter's native,
/// locale-aware date picker and a localized value to the user.
class LiveDateInput extends LiveStateWidget<LiveDateInput> {
  const LiveDateInput({super.key, required super.state});

  @override
  State<LiveDateInput> createState() => _LiveDateInputState();
}

class _LiveDateInputState extends StateWidget<LiveDateInput> {
  final attributes = ['name', 'initialValue', 'displayValue', 'label'];
  final unnamedInput = const Uuid().v4();
  String? currentValue;
  String? currentDisplayValue;
  bool allowInitialValueChange = true;

  String get fieldName =>
      getAttribute('name') ?? 'unnamed-date-input-$unnamedInput';

  @override
  HandleClickState handleClickState() => HandleClickState.manual;

  @override
  void initState() {
    Future.delayed(Duration.zero, sendInitialFormState);
    super.initState();
  }

  @override
  void onWipeState() {
    allowInitialValueChange = true;
    super.onWipeState();
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, attributes);
    if (allowInitialValueChange) {
      allowInitialValueChange = false;
      currentValue = getAttribute('initialValue');
      currentDisplayValue = getAttribute('displayValue');
    }
  }

  void sendInitialFormState() {
    reloadAttributes(node, attributes);
    FormFieldEvent(
      name: fieldName,
      data: getAttribute('initialValue') ?? '',
      type: FormFieldEventType.initField,
    ).dispatch(context);
  }

  Future<void> pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final initialDate = DateTime.tryParse(currentValue ?? '') ?? today;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) return;

    final value = _isoDate(selected);
    setState(() {
      currentValue = value;
      currentDisplayValue = MaterialLocalizations.of(
        context,
      ).formatMediumDate(selected);
    });
    FormFieldEvent(
      name: fieldName,
      data: value,
      type: FormFieldEventType.change,
    ).dispatch(context);
  }

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Widget render(BuildContext context) {
    return InkWell(
      onTap: pickDate,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(labelText: getAttribute('label')),
        child: Row(
          children: [
            Expanded(child: Text(currentDisplayValue ?? currentValue ?? '')),
            const SizedBox(width: 12),
            const Icon(Icons.calendar_today_outlined, size: 20),
          ],
        ),
      ),
    );
  }
}
