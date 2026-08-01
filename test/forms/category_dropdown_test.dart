import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('tapping a form category dropdown shows its items', (
    tester,
  ) async {
    tester.setScreenSize(const Size(800, 800));

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
                  <DropdownButton name="transaction[type]" initialValue="expense" isExpanded="true">
                    <DropdownMenuItem label="Expense" value="expense" />
                    <DropdownMenuItem label="Income" value="income" />
                  </DropdownButton>
                  <DropdownButton name="transaction[category_id]" initialValue="" isExpanded="true">
                    <DropdownMenuItem label="No category" value="" />
                    <DropdownMenuItem label="Bonus" value="1" />
                    <DropdownMenuItem label="Intérêts" value="2" />
                    <DropdownMenuItem label="Actions" value="3" />
                    <DropdownMenuItem label="Salaire" value="4" />
                  </DropdownButton>
                  <DropdownButton name="transaction[account_id]" initialValue="30" isExpanded="true">
                    <DropdownMenuItem label="Compte test" value="30" />
                  </DropdownButton>
                  <ElevatedButton type="submit"><Text>Save</Text></ElevatedButton>
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

    final dropdowns = find.descendant(
      of: find.byType(Form),
      matching: find.byType(DropdownButton<String>),
    );
    expect(dropdowns, findsNWidgets(3));

    await tester.tap(dropdowns.at(1));
    await tester.pumpAndSettle();

    expect(find.text('Salaire'), findsWidgets);
  });
}
