import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('big dropdown menu item visibility', (tester) async {
    tester.setScreenSize(const Size(1280, 720));

    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
        <flutter>
          <viewBody>
            <SingleChildScrollView>
              <Form phx-submit="save">
                <Column>
                  <DropdownButton name="transaction[category_id]" initialValue="" isExpanded="true">
                    <DropdownMenuItem label="No category" value="" />
                    <DropdownMenuItem label="Cat 0" value="0" />
                    <DropdownMenuItem label="Cat 1" value="1" />
                    <DropdownMenuItem label="Cat 2" value="2" />
                    <DropdownMenuItem label="Cat 3" value="3" />
                    <DropdownMenuItem label="Cat 4" value="4" />
                    <DropdownMenuItem label="Cat 5" value="5" />
                    <DropdownMenuItem label="Cat 6" value="6" />
                    <DropdownMenuItem label="Cat 7" value="7" />
                    <DropdownMenuItem label="Cat 8" value="8" />
                    <DropdownMenuItem label="Cat 9" value="9" />
                    <DropdownMenuItem label="Cat 10" value="10" />
                    <DropdownMenuItem label="Cat 11" value="11" />
                    <DropdownMenuItem label="Cat 12" value="12" />
                    <DropdownMenuItem label="Cat 13" value="13" />
                    <DropdownMenuItem label="Cat 14" value="14" />
                    <DropdownMenuItem label="Cat 15" value="15" />
                    <DropdownMenuItem label="Cat 16" value="16" />
                    <DropdownMenuItem label="Cat 17" value="17" />
                    <DropdownMenuItem label="Cat 18" value="18" />
                    <DropdownMenuItem label="Cat 19" value="19" />
                    <DropdownMenuItem label="Cat 20" value="20" />
                    <DropdownMenuItem label="Cat 21" value="21" />
                    <DropdownMenuItem label="Cat 22" value="22" />
                    <DropdownMenuItem label="Cat 23" value="23" />
                    <DropdownMenuItem label="Cat 24" value="24" />
                    <DropdownMenuItem label="Cat 25" value="25" />
                    <DropdownMenuItem label="Cat 26" value="26" />
                    <DropdownMenuItem label="Cat 27" value="27" />
                    <DropdownMenuItem label="Cat 28" value="28" />
                    <DropdownMenuItem label="Cat 29" value="29" />
                    <DropdownMenuItem label="Cat 30" value="30" />
                    <DropdownMenuItem label="Cat 31" value="31" />
                    <DropdownMenuItem label="Cat 32" value="32" />
                    <DropdownMenuItem label="Cat 33" value="33" />
                    <DropdownMenuItem label="Cat 34" value="34" />
                    <DropdownMenuItem label="Cat 35" value="35" />
                    <DropdownMenuItem label="Cat 36" value="36" />
                    <DropdownMenuItem label="Cat 37" value="37" />
                    <DropdownMenuItem label="Cat 38" value="38" />
                    <DropdownMenuItem label="Cat 39" value="39" />
                    <DropdownMenuItem label="Cat 40" value="40" />
                    <DropdownMenuItem label="Cat 41" value="41" />
                    <DropdownMenuItem label="Cat 42" value="42" />
                    <DropdownMenuItem label="Cat 43" value="43" />
                    <DropdownMenuItem label="Cat 44" value="44" />
                    <DropdownMenuItem label="Cat 45" value="45" />
                    <DropdownMenuItem label="Cat 46" value="46" />
                    <DropdownMenuItem label="Cat 47" value="47" />
                    <DropdownMenuItem label="Cat 48" value="48" />
                    <DropdownMenuItem label="Cat 49" value="49" />
                    <DropdownMenuItem label="Cat 50" value="50" />
                    <DropdownMenuItem label="Cat 51" value="51" />
                    <DropdownMenuItem label="Cat 52" value="52" />
                    <DropdownMenuItem label="Cat 53" value="53" />
                    <DropdownMenuItem label="Cat 54" value="54" />
                    <DropdownMenuItem label="Cat 55" value="55" />
                    <DropdownMenuItem label="Cat 56" value="56" />
                    <DropdownMenuItem label="Cat 57" value="57" />
                    <DropdownMenuItem label="Cat 58" value="58" />
                    <DropdownMenuItem label="Cat 59" value="59" />
                    <DropdownMenuItem label="Cat 60" value="60" />
                    <DropdownMenuItem label="Cat 61" value="61" />
                    <DropdownMenuItem label="Cat 62" value="62" />
                    <DropdownMenuItem label="Cat 63" value="63" />
                    <DropdownMenuItem label="Cat 64" value="64" />
                    <DropdownMenuItem label="Cat 65" value="65" />
                  </DropdownButton>
                </Column>
              </Form>
            </SingleChildScrollView>
          </viewBody>
        </flutter>
        """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    // ignore: avoid_print
    print(
      'MENUITEMS=' +
          find.byType(DropdownMenuItem<String>).evaluate().length.toString(),
    );
    // ignore: avoid_print
    print('CAT1=' + find.text('Cat 1').evaluate().length.toString());
  });
}
