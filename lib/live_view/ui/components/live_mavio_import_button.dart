import 'dart:io';

import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract interface class MavioDatabaseLocator {
  Future<String?> locate(String databaseName);
}

class SqfliteMavioDatabaseLocator implements MavioDatabaseLocator {
  @override
  Future<String?> locate(String databaseName) async {
    if (Platform.isLinux || Platform.isWindows) {
      // sqflite only ships Android/iOS/macOS plugins; use the ffi factory so
      // the legacy database lookup also works on desktop.
      databaseFactory = databaseFactoryFfi;
    }
    var path = p.join(await getDatabasesPath(), databaseName);
    return File(path).existsSync() ? path : null;
  }
}

class MavioImportService {
  MavioImportService._();

  static MavioDatabaseLocator locator = SqfliteMavioDatabaseLocator();
}

class LiveMavioImportButton extends LiveStateWidget<LiveMavioImportButton> {
  const LiveMavioImportButton({super.key, required super.state});

  @override
  State<LiveMavioImportButton> createState() => _LiveMavioImportButtonState();
}

class _LiveMavioImportButtonState extends StateWidget<LiveMavioImportButton> {
  bool _loading = false;
  String? _error;

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, [
      'action',
      'field',
      'databaseName',
      'label',
      'notFoundLabel',
      'errorLabel',
    ]);
  }

  @override
  HandleClickState handleClickState() => HandleClickState.manual;

  Future<void> _import() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      var databaseName = getAttribute('databaseName') ?? 'app_database8.db';
      var path = await MavioImportService.locator.locate(databaseName);
      if (path == null) {
        throw StateError('not-found');
      }
      await liveView.deadViewUploadQuery(
        getAttribute('action') ?? '/settings/import/mavio',
        getAttribute('field') ?? 'mavio[database]',
        path,
      );
      if (mounted) {
        setState(() => _loading = false);
      }
    } on StateError catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              e.message == 'not-found'
                  ? getAttribute('notFoundLabel') ??
                      'No Mavio database found on this device.'
                  : getAttribute('errorLabel') ??
                      'Import failed. Please try again.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              getAttribute('errorLabel') ?? 'Import failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget render(BuildContext context) {
    var label = getAttribute('label') ?? 'Import my old data';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _loading ? null : _import,
          icon:
              _loading
                  ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.upload_file),
          label: Text(label),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
