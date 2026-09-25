import 'package:flutter_test/flutter_test.dart';

import 'currency_picker_scenario.dart' as currency_picker;
import 'custom_categories_scenario.dart' as custom_categories;
import 'transaction_category_scenario.dart' as transaction_category;
import 'transaction_form_validation_scenario.dart' as form_validation;

void main() {
  group('Currency picker', currency_picker.main);
  group('Custom categories', custom_categories.main);
  group('Transaction categories', transaction_category.main);
  group('Transaction form validation', form_validation.main);
}
