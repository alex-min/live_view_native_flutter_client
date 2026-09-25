import 'package:flutter_test/flutter_test.dart';

import 'account_picker_scenario.dart' as account_picker;
import 'automated_account_scenario.dart' as automated_account;
import 'legacy_pro_scenario.dart' as legacy_pro;
import 'pro_page_scenario.dart' as pro_page;
import 'pro_upgrade_scenario.dart' as pro_upgrade;

void main() {
  group('Account picker', account_picker.main);
  group('Automated accounts', automated_account.main);
  group('Legacy Pro', legacy_pro.main);
  group('Pro page', pro_page.main);
  group('Pro upgrade', pro_upgrade.main);
}
