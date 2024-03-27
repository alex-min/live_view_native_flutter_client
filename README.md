# Live View Native Flutter Client

> [!WARNING]
> This client is a tech preview, it's not ready to be usable for your own app
>
> APIs might break and features might be missing

A Flutter client for LiveView native. [Join our Slack community](https://join.slack.com/t/liveviewflutter/shared_invite/zt-2eyf5yq9v-x1J8Zr031UOCYFGNpLDv5g)

This repo enables you to create an app for any Flutter platform (mobile & desktop) where the full UI is synced to the backend and reflects any change being made, similar as a Live View web client.

## Video Demos

Here is a demo of an Android, a Desktop and a web app synced on the same backend code:

https://github.com/alex-min/live_view_native_flutter_client/assets/1898825/b8bbd652-f4ae-49d4-8b84-777b693952f5

Here is a navigation and theme switching demo (the theme is also defined server side)

https://github.com/alex-min/live_view_native_flutter_client/assets/1898825/a6032bfa-d696-4093-8b1b-bd0771364c87

Please see the announcement here: https://alex-min.fr/live-view-native-flutter-release/

## Getting Started

- [Install Flutter](https://docs.flutter.dev/get-started/install)
- clone [the demo live view flutter server](https://github.com/alex-min/live_view_flutter_demo)
- create a new flutter package
- install this client

```yml
liveview_flutter:
  git:
    url: git@github.com:alex-min/live_view_native_flutter_client.git
```

- replace your lib/main.dart content with this:

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liveview_flutter/liveview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LiveView view = LiveView();

  @override
  initState() {
    Future.microtask(boot);
    super.initState();
  }

  void boot() async {
    if (kIsWeb) {
      view.connectToDocs();
      return;
    }

    await view.connect(
      Platform.isAndroid
          ?
          // android emulator
          'http://10.0.2.2:4000'
          // computer
          : 'http://localhost:4000/',
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return view.rootView;
  }
}
```

- Use "flutter run" to run the client
- You can modify the live view url in lib/main.dart, by default it uses localhost:4000 and 10.0.2.2:4000 for the android emulator

## What is there already?

- Some basic components are partially supported (Container, TextButton, Icon, AppBar, BottomNavigationBar ...)
- Modern Flutter Navigation with router 2.0 (switch pages, transitions go back). Although transitions aren't customizable yet.
- Basic styling (padding, margin and background)
- Basic forms (validation & submit)
- Dynamic attributes & replacement
- Conditional component rendering
- Material Icons
- Server-side themes with JSON, also you can switch & save theme on the server side
- Live reloading
- Responsive navigation
- Basic Images support
- Live Components

## What is missing?

- Documentation
- A full API support of all the components
- Modclasses (same as live view swift native)
- Hooks similar as web hooks
- Animations
- Local storage
- Better Image support & Video
- More server side-events, something like "flutter-onrender"
- Responsive navigation & desktop support (like windows title)
- Sessions & Session storage events
- ...

As you see on this list, the client isn't fully usable for a real app yet.

## Philosophy

- The Flutter client should support absolutely everything to make a real app
- Users of this client should almost never dive into the flutter code, the client should be as complete and extensive as possible.
- The client should be extendable in the future and available as a flutter package

## What does the code looks like?

This is an example of the code on the server:

```elixir
  @impl true
  def render(%{format: :flutter} = assigns) do
    # This UI renders on flutter
    ~FLUTTER"""
      <flutter>
        <AppBar>
          <title>hello</title>
        </AppBar>
        <viewBody>
          <Container padding="10">
            <Container padding={10 + @counter} decoration={bg_color(@counter)}>
              <Text>Margin Counter <%= @counter %></Text>
              <ElevatedButton phx-click={Dart.go_back()}>go back</ElevatedButton>
            </Container>
            <Row>
              <ElevatedButton phx-click={Dart.switch_theme("dark")}>Switch dark theme</ElevatedButton>
              <Container margin="0 20 0 0">
                <ElevatedButton phx-click={Dart.switch_theme("light")}>Switch light theme</ElevatedButton>
              </Container>
            </Row>
          </Container>
        </viewBody>
        <BottomNavigationBar initialValue="0" selectedItemColor="blue-500">
          <BottomNavigationBarItem icon="home" label="Page 1" />
          <BottomNavigationBarItem live-patch="/second-page" icon="home" label="Page 2" />
          <BottomNavigationBarItem phx-click="inc" icon="arrow_upward" label="Increment" />
          <BottomNavigationBarItem phx-click="dec" icon="arrow_downward" label="Decrement" />
        </BottomNavigationBar>
      </flutter>
    """
  end
```
