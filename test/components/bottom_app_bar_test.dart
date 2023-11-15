import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('looks okay', (tester) => tester.checkScreenshot("""
          <flutter>
            <viewBody floatingActionButtonLocation="centerDocked">
              <Container>hello</Container>
            </viewBody>
            <FloatingActionButton shape="CircleBorder"><Icon name="home" /></FloatingActionButton>
            <BottomAppBar elevation="10" padding="0" shape="CircularNotchedRectangle">
              <BottomNavigationBar
                showUnselectedLabel="true"
                backgroundColor="transparent"
                elevation="0"
                initialValue="1" selectedItemColor="blue-500">
                <BottomNavigationBarItem live-patch="/" icon="home" label="Page 1" />
                <BottomNavigationBarItem icon="home" label="Page 2" />
                <BottomNavigationBarItem icon="arrow_upward" label="Increment" />
                <BottomNavigationBarItem icon="arrow_downward" label="Decrement" />
              </BottomNavigationBar>
            </BottomAppBar>
          </flutter>
        """, 'bottom_app_bar_test.png'));
}
