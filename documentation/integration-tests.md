# Integration tests

Integration tests live in `example/integration_test/` and run against a real
StartupKit dev server (`localhost:4000`). Run them from the `example/`
directory:

```
cd example
flutter test integration_test/ -d linux
```

On a headless machine, wrap the command with `xvfb-run`:

```
xvfb-run -a flutter test integration_test/ -d linux
```

## Multi-file runs on desktop: Flutter SDK patch required

Running several integration test files in one invocation on Linux desktop
requires a patched Flutter SDK. `DesktopLogReader`
(`packages/flutter_tools/lib/src/desktop_device.dart` in the SDK) shares a
single stream controller across app launches and permanently closes it when
the first test file's app exits. Every subsequent file then fails to launch
with:

```
Error waiting for a debug connection: The log reader stopped unexpectedly, or never started.
Failed to load "...": Unable to start the app on the device.
```

The fix recreates the controller when it was closed by a previous process
(and is present on this machine's SDK; it is lost on `flutter upgrade` and
should be upstreamed):

```dart
class DesktopLogReader extends DeviceLogReader {
  StreamController<List<int>> _inputController = StreamController<List<int>>.broadcast();

  void initializeProcess(Process process) {
    if (_inputController.isClosed) {
      _inputController = StreamController<List<int>>.broadcast();
    }
    final controller = _inputController;
    final stdoutSub = process.stdout.listen(controller.add);
    final stderrSub = process.stderr.listen(controller.add);
    ...
    process.exitCode.whenComplete(() async {
      ...
      await controller.close();
    });
  }
```

After patching, delete `bin/cache/flutter_tools.snapshot` in the SDK so the
tool is rebuilt on the next invocation.

Without the patch, run the files one by one instead:

```
for f in integration_test/*_test.dart; do
  xvfb-run -a flutter test "$f" -d linux || exit 1
done
```
